import {differenceInCalendarDays, formatISO, parseISO, startOfYesterday, subMonths} from 'date-fns'
// @ts-ignore
import VARIANT_COLORS from '@/scss/main.scss'
import Component from "vue-class-component";
import Vue from 'vue'
import {Stock, StockPeriod} from "@/components/stock-period-picker";
import {Prop, Ref, Watch} from "vue-property-decorator";
//@ts-ignore
import template from './stock-viewer.html'
import {Location, Route} from "vue-router";
import {Symbol, SymbolResponse} from "@/utils/symbol";
import {AxiosResponse} from "axios";
import {HistoricalPrice, Performance, PriceResponse} from "@/utils/prices";
import MessageBar from "@/components/message-bar";
import Chart, {ChartDataSets} from 'chart.js'
import {percentage} from '@/utils/format.ts'

const DATE_FROM_DEFAULT = subMonths(startOfYesterday(), 3)
const DATE_TO_DEFAULT = startOfYesterday()
const VARIANTS = Object.keys(VARIANT_COLORS).filter(variant => variant !== 'secondary')

type QueryParam = {
    s: string
    f?: string
    i?: string
} | string

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

const queryParamToStock = (queryParam: QueryParam): Stock => {
    if (typeof (queryParam) === 'string') {
        return new Stock(queryParam)
    }
    const {s: symbol, f: figi, i: isin} = queryParam
    return new Stock(symbol, undefined, undefined, isin, figi)
}

export const routeToStockPeriod = (route: Route): StockPeriod => {
    const stocks = route.query.s ? JSON.parse(route.query.s as string).map(queryParamToStock) : []
    const dateFrom = route.query.df ? parseISO(route.query.df as string) : DATE_FROM_DEFAULT
    const dateTo = route.query.dt ? parseISO(route.query.dt as string) : DATE_TO_DEFAULT

    return {
        stocks,
        dateFrom,
        dateTo
    }
}

@Component({template, methods: {percentage}})
export default class StockViewer extends Vue {

    @Prop({
        type: Object, default: () => ({
            stocks: [],
            dateFrom: null,
            dateTo: null
        }),
        validator: (value) => value.stocks instanceof Array
            && value.stocks.every((stock: any) => stock instanceof Stock)
            && (value.dateFrom == null || value.dateFrom instanceof Date)
            && (value.dateTo == null || value.dateTo instanceof Date)
    })
    initialStockPeriod!: StockPeriod

    stockPeriod: StockPeriod = {
        stocks: [],
        dateFrom: DATE_FROM_DEFAULT,
        dateTo: DATE_TO_DEFAULT
    }

    updateOngoing: boolean = false

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


    @Watch("stockPeriod", {deep: true})
    watchStockPeriod(newStockPeriod: StockPeriod) {
        const newRoute: Location = {name: "stocks"}
        newRoute.query = {}
        if (newStockPeriod.stocks.length > 0) {
            newRoute.query.s = JSON.stringify(newStockPeriod.stocks.map(stockToQueryParam))
        }
        if (newStockPeriod.dateFrom) {
            newRoute.query.df = formatISO(newStockPeriod.dateFrom, {representation: 'date'})
        }
        if (newStockPeriod.dateTo) {
            newRoute.query.dt = formatISO(newStockPeriod.dateTo, {representation: 'date'})
        }
        this.$router.push(newRoute).catch(err => err)

        this.updateChart()
    }

    async updateChart() {
        try {
            this.updateOngoing = true

            const api_responses = await Promise.all(this.stockPeriod.stocks.map(async (stock) =>
                ({
                    stock,
                    metadata_response: await this.fetchMetadata(stock.text),
                    prices_response: await this.fetchPrices(stock.text)
                })))

            this.chart.data.datasets = api_responses
                .map(this.parseResponse)
                .map(this.makeDataset)

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
        const days = differenceInCalendarDays(this.stockPeriod.dateTo, this.stockPeriod.dateFrom);
        const sampling = Math.max(Math.round(days / maxDataPoints), 1)

        const dateFrom = formatISO(this.stockPeriod.dateFrom, {representation: 'date'})
        const dateTo = formatISO(this.stockPeriod.dateTo, {representation: 'date'})

        return this.axios.get<PriceResponse>(`/prices/${symbol}/from/${dateFrom}/to/${dateTo}`, {
            params: {sampling}
        })
    }

    parseResponse = ({metadata_response, prices_response, stock}: {
        metadata_response: AxiosResponse<SymbolResponse>,
        prices_response: AxiosResponse<PriceResponse>,
        stock: Stock
    }) => ({
        metadata: metadata_response.data.data,
        performance: prices_response.data.data.performance,
        prices: prices_response.data.data.prices,
        stock
    })

    makeDataset({prices, performance, metadata, stock}: {
        prices: HistoricalPrice[],
        performance: Performance,
        metadata: Symbol,
        stock: Stock
    }, index: number): any {
        const variant = prices.length === 0
            ? 'secondary'
            : VARIANTS[index % VARIANTS.length]
        return {
            data: prices.map(
                ({date, close}) => ({x: typeof (date) === 'string' ? parseISO(date) : date, y: parseFloat(close)})
            ),
            performance,
            metadata,
            label: `${metadata.symbol} (${metadata.currency})${this.labelSuffix(stock)}`,
            borderColor: VARIANT_COLORS[variant],
            backgroundColor: VARIANT_COLORS[variant],
            variant,
            yAxisID: metadata.currency,
            fill: false
        }
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

    get nonEmptyDatasets(): ChartDataSets[] {
        return (this.chart.data.datasets || []).filter(({data = []}) => data.length > 0)
    }

    hasData(): boolean {
        return this.chart && (this.chart.data.datasets || []).length > 0
    }
}