<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <b-form-row>
          <b-col md="8">
            <stock-period-picker v-model="stockPeriod"
                                 :max-tags=4
                                 @error="errorBar.show($event)"
            >
            </stock-period-picker>
          </b-col>
          <b-col md="auto" align-self="center" class="text-center">
          </b-col>
        </b-form-row>
      </b-form>
    </template>

    <b-container fluid>
      <b-overlay :show="updateOngoing">
        <b-row no-gutters>
          <b-col order-md="1" md="10">
            <h1 v-if="!(hasDataToShow || updateOngoing)" class="text-center display-1">
              <b-icon icon="bar-chart-fill"></b-icon>
            </h1>
            <canvas ref="chartCanvas" :class="{invisible: !hasDataToShow}">
            </canvas>
          </b-col>
          <b-col v-if="hasDataToShow" md="2" class="mt-2 mt-md-0">
            <b-card
              v-for="({prices: {performance}, label, metadata, variant, stock: {symbol}}, index) in nonEmptyStockBags"
              :key="label"
              no-body
              :class="{'mt-1' : index > 0}">
              <b-card-header :header-bg-variant="variant" header-tag="div"
                             header-class="d-flex justify-content-between">
                <b>{{ label }}</b>
                <b-button size="sm" :variant="variant" @click="removeStock(symbol)" :name="symbol">
                  <b-icon icon="x"></b-icon>
                </b-button>
              </b-card-header>
              <b-card-body class="p-2">
                <b-form-checkbox switch @change="tradingMode(symbol, $event)">Trading</b-form-checkbox>
                <b-card-text>
                  {{ metadata.name }}
                </b-card-text>
                <b-card-text>
                  <h6><b>Perf:&nbsp;</b>
                    <b-badge pill :variant="performance.raw < 0 ? 'danger' : 'success'">{{
                        percentage(performance.raw)
                      }}
                    </b-badge>
                  </h6>
                  <h6><b>Trading:&nbsp;</b>
                    <b-badge pill :variant="performance.trading < 0 ? 'danger' : 'success'">
                      {{ percentage(performance.trading) }}
                    </b-badge>
                  </h6>
                  <h6><b>Short:&nbsp;</b>
                    <b-badge pill :variant="performance.short_trading < 0 ? 'danger' : 'success'">
                      {{ percentage(performance.short_trading) }}
                    </b-badge>
                  </h6>
                </b-card-text>
              </b-card-body>
            </b-card>
          </b-col>
        </b-row>
      </b-overlay>
    </b-container>
  </b-card>
</template>
<script lang="ts">
import {differenceInCalendarDays, formatISO, isSameDay, parseISO} from 'date-fns'
import VARIANT_COLORS from '@/scss/main.scss'
import Component from 'vue-class-component'
import Vue, {PropType} from 'vue'
import {
  DATE_FROM_DEFAULT,
  DATE_TO_DEFAULT,
  routeToStockPeriod,
  Stock,
  StockPeriod,
  StockQueryParam as QueryParam
} from '@/utils/stock'
import {Prop, Ref, Watch} from 'vue-property-decorator'
import {Location, Route} from 'vue-router'
import {SymbolResponse} from '@/utils/stockMetadata'
import {AxiosResponse} from 'axios'
import {PriceResponse} from '@/utils/prices'
import MessageBar from '@/components/message-bar.vue'
import Chart from 'chart.js'
import ChartDataLabels from 'chartjs-plugin-datalabels';
import {percentage} from '@/utils/format.ts'
import {StockBag} from "@/utils/stockBag";


const VARIANTS = Object.keys(VARIANT_COLORS).filter(variant => variant !== 'secondary')
const DEFAULT_VARIANT = 'secondary';

const stockToQueryParam = (stock: Stock): QueryParam => {
  const {text: s, figi: f, isin: i} = stock
  if (f === undefined && i === undefined) {
    return s
  }
  if (f === undefined) {
    return {s, i}
  }
  if (i === undefined) {
    return {s, f}
  }
  return {s, f, i}
}

@Component({methods: {percentage}})
export default class StockViewer extends Vue {
  @Prop({
    type: Object as PropType<StockPeriod>,
    default: () => ({
      stocks: [],
      dateFrom: DATE_FROM_DEFAULT,
      dateTo: DATE_TO_DEFAULT
    }),
    validator: (value) => value.stocks instanceof Array &&
      value.stocks.every((stock: any) => stock instanceof Stock) &&
      (value.dateFrom == null || value.dateFrom instanceof Date) &&
      (value.dateTo == null || value.dateTo instanceof Date)
  })
  initialStockPeriod!: StockPeriod

  stockPeriod: StockPeriod = {
    stocks: [],
    dateFrom: DATE_FROM_DEFAULT,
    dateTo: DATE_TO_DEFAULT
  }

  stockBags: { [key: string]: StockBag } = {}

  updateOngoing = false

  dateFrom: Date | null = null

  dateTo: Date | null = null

  @Ref()
  readonly chartCanvas!: HTMLCanvasElement

  @Ref()
  readonly errorBar!: MessageBar

  chart!: Chart

  created() {
    this.stockPeriod = this.initialStockPeriod
  }

  mounted() {
    this.chart = new Chart(this.chartCanvas, {
      type: 'line',
      plugins: [ChartDataLabels],
      data: {
        datasets: []
      },
      options: {
        scales: {
          xAxes: [{
            type: 'time'
          }]
        },
        legend: {
          onClick: () => null,
          labels: {
            generateLabels: (chart) =>
              (chart.data.datasets || []).map(({borderColor, label, data = []}) => ({
                text: label,
                hidden: data.length === 0,
                fillStyle: borderColor as string
              }))
          }
        }
      }
    })
  }

  beforeRouteUpdate(to: Route, from: Route, next: () => void) {
    this.stockPeriod = routeToStockPeriod(to)
    next()
  }

  @Watch('stockPeriod', {deep: true})
  watchStockPeriod(stockPeriod: StockPeriod) {
    const newRoute: Location = {name: 'stocks'}
    newRoute.query = {}
    if (stockPeriod.stocks.length > 0) {
      newRoute.query.s = JSON.stringify(stockPeriod.stocks.map(stockToQueryParam))
    }
    if (stockPeriod.dateFrom) {
      newRoute.query.df = formatISO(stockPeriod.dateFrom, {representation: 'date'})
    }
    if (stockPeriod.dateTo) {
      newRoute.query.dt = formatISO(stockPeriod.dateTo, {representation: 'date'})
    }
    this.$router.push(newRoute).catch(err => err)

    const newTimePeriod = this.dateFrom == null || !isSameDay(this.dateFrom, stockPeriod.dateFrom) ||
      this.dateTo == null || !isSameDay(this.dateTo, stockPeriod.dateTo)

    this.dateFrom = stockPeriod.dateFrom
    this.dateTo = stockPeriod.dateTo

    this.updateStockBags(newTimePeriod)
  }

  async updateStockBags(newTimePeriod: boolean): Promise<void> {
    try {
      this.updateOngoing = true

      if (newTimePeriod) {
        this.stockBags = {}
      } else {
        for (const existingSymbol in this.stockBags) {
          if (!this.stockPeriod.stocks.find(({symbol}) => symbol === existingSymbol)) {
            this.$delete(this.stockBags, existingSymbol)
          }
        }
      }

      const missingStocks = this.stockPeriod.stocks.filter(({symbol}) => !(symbol in this.stockBags))

      const apiResponses = await Promise.all(missingStocks.map(async (stock) =>
        ({
          stock,
          metadataResponse: await this.fetchMetadata(stock.text),
          pricesResponse: await this.fetchPrices(stock.text)
        })))

      apiResponses.map(this.parseResponse)
        .forEach(stockBag => this.$set(this.stockBags, stockBag.stock.symbol, stockBag))

      const usedVariants = Object.values(this.stockBags)
        .map(({variant}) => variant)
        .filter(variant => variant)
      Object.values(this.stockBags).forEach((stockBag, index) => {
        if (stockBag.variant === DEFAULT_VARIANT) {
          if (stockBag.prices.prices.length === 0) {
            return
          }
          const nextVariant = VARIANTS.find(variant => !(usedVariants.includes(variant)))
          if (nextVariant) {
            usedVariants.push(nextVariant)
            stockBag.variant = nextVariant
          } else {
            stockBag.variant = VARIANTS[index % VARIANTS.length]
          }
        }
      })

      this.updateDatasets()
    } catch (error) {
      this.errorBar.show(error)
      console.error(error)
    } finally {
      this.updateOngoing = false
    }
  }

  fetchMetadata(symbol: string): Promise<AxiosResponse<SymbolResponse>> {
    return this.axios.get<SymbolResponse>(`/stocks/symbol/${symbol}`)
  }

  fetchPrices(symbol: string): Promise<AxiosResponse<PriceResponse>> {
    const maxDataPoints = 50
    const days = differenceInCalendarDays(this.stockPeriod.dateTo, this.stockPeriod.dateFrom)
    const sampling = Math.max(Math.round(days / maxDataPoints), 1)
    const dateFrom = formatISO(this.stockPeriod.dateFrom, {representation: 'date'})
    const dateTo = formatISO(this.stockPeriod.dateTo, {representation: 'date'})

    return this.axios.get<PriceResponse>(`/prices/${symbol}/from/${dateFrom}/to/${dateTo}`, {
      params: {sampling}
    })
  }

  parseResponse = ({metadataResponse, pricesResponse, stock}: {
    metadataResponse: AxiosResponse<SymbolResponse>;
    pricesResponse: AxiosResponse<PriceResponse>;
    stock: Stock;
  }): StockBag => {

    const prices = pricesResponse.data.data.prices
    const metadata = metadataResponse.data.data
    return {
      metadata,
      prices: {
        prices,
        performance: pricesResponse.data.data.performance,
      },
      label: `${metadata.symbol} (${metadata.currency})${this.labelSuffix(stock)}`,
      stock,
      variant: DEFAULT_VARIANT,
      tradingMode: false
    }
  }

  makeDataset({prices: {prices, performance}, metadata, variant, label, tradingMode}: StockBag): any {

    if (tradingMode) {
      return {
        type: 'scatter',
        data: performance.strategy.map(({date, price, action}) => ({x: date, y: price, action})),
        datalabels: {
          formatter: (value: any) => value.action[0].toUpperCase()
        }
      }
    } else {
      return {
        data: prices.map(
          ({date, close}) => ({x: typeof (date) === 'string' ? parseISO(date) : date, y: parseFloat(close)})
        ),
        performance,
        metadata,
        label,
        borderColor: VARIANT_COLORS[variant],
        backgroundColor: VARIANT_COLORS[variant],
        variant,
        yAxisID: metadata.currency,
        fill: false,
        datalabels: {
          labels: {
            value: null,
            title: null
          }
        }
      }
    }
  }

  updateDatasets() {
    this.chart.data.datasets = Object.values(this.stockBags).map(this.makeDataset)
    // eslint-disable-next-line
    this.chart.options.scales!.yAxes = this.chart.data.datasets
      .filter(({data = []}) => data.length > 0)
      .map(({yAxisID}) => yAxisID)
      .filter((value, index, self) => self.indexOf(value) === index)
      .map(yAxisID => ({
        id: yAxisID,
        type: 'linear',
        scaleLabel: {
          display: true,
          labelString: yAxisID
        }
      }))

    this.chart.update()
  }

  labelSuffix({isin, figi}: Stock): string {
    if (isin) {
      return ` - ISIN: ${isin}`
    }
    if (figi) {
      return ` - FIGI: ${figi}`
    }
    return ''
  }

  tradingMode(symbol: string, mode: boolean): void {
    this.stockBags[symbol].tradingMode = mode
    this.updateDatasets()
  }

  removeStock(symbol: string): void {
    const index = this.stockPeriod.stocks.findIndex(({symbol: s}) => s === symbol)
    if (index > -1) {
      this.stockPeriod.stocks.splice(index, 1)
    }
  }

  get nonEmptyStockBags(): StockBag[] {
    return Object.values(this.stockBags).filter(({prices: {prices}}) => prices.length > 0)
  }

  get hasDataToShow(): boolean {
    return this.nonEmptyStockBags.length > 0
  }
}
</script>
