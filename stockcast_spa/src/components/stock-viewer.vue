<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <b-form-row>
          <b-col md="8">
            <stock-period-picker v-model="stocks"
                                 :max-tags=4
                                 @error="$refs.errorBar.show($event)"
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
        <b-row>
          <b-col md="9" order-md="1">
            <h1 v-if="!(hasData || updateOngoing)" class="text-center display-1">
              <b-icon icon="bar-chart-fill"></b-icon>
            </h1>
            <canvas ref="chart" id="stocks_chart" :class="{invisible: !hasData}">
            </canvas>
          </b-col>
          <b-col md="3" v-if="hasData">
            <b-card v-for="ds in chart.data.datasets" :key="ds.label"
                    :header="ds.label"
                    header-tag="b">
              <b-card-text>
                {{ ds.metadata.name }}
              </b-card-text>
              <b-card-text>
                Perf: +40%
              </b-card-text>

              <b-card-text>
                MaxTr: +700%
              </b-card-text>
            </b-card>
          </b-col>
        </b-row>
      </b-overlay>

    </b-container>
  </b-card>
</template>
<script>
  import {differenceInCalendarDays, formatISO, parseISO, startOfYesterday, subMonths} from 'date-fns'
  import Chart from 'chart.js'

  const DATE_FROM_DEFAULT = subMonths(startOfYesterday(), 3)
  const DATE_TO_DEFAULT = startOfYesterday()

  const COLORS = [
    '#FF0000',
    '#00FF00',
    '#0000FF',
    '#FFFF00',
    '#00FFFF',
    '#FF00FF'
  ]

  const GRAY = '#847878'

  const tagToQueryParam = (tag) => {
    const {text: s, figi: f, isin: i} = tag
    if (f === undefined && i === undefined) {
      return s
    }
    return {s, f, i}
  }

  const queryParamToTag = (queryParam) => {
    if (typeof (queryParam) === 'string') {
      return {text: queryParam}
    }
    const {s: text, f: figi, i: isin} = queryParam
    return {text, figi, isin}
  }


  export const routeToProps = (route) => {
    const tags = route.query.s ? JSON.parse(route.query.s).map(queryParamToTag) : []
    const dateFrom = route.query.df ? parseISO(route.query.df) : DATE_FROM_DEFAULT
    const dateTo = route.query.dt ? parseISO(route.query.dt) : DATE_TO_DEFAULT

    return {
      tags,
      dateFrom,
      dateTo
    }
  }

  export default {
    props: {
      tags: {
        type: Array,
        default: () => []
      },
      dateFrom: Date,
      dateTo: Date
    },
    data: () => ({
      stocks: {
        tags: null,
        dateFrom: null,
        dateTo: null
      },
      chart: null,
      updateOngoing: false
    }),
    created() {
      this.stocks.tags = this.tags
      this.stocks.dateFrom = this.dateFrom
      this.stocks.dateTo = this.dateTo
    },
    mounted() {
      this.chart = new Chart(this.$refs.chart, {
        type: 'line',
        data: {
          datasets: []
        },
        options: {
          scales: {
            xAxes: [{
              type: 'time',
              ticks: {
                source: 'data'
              }
            }]
          },
          legend: {
            onClick: () => null,
            labels: {
              generateLabels: (chart) =>
                chart.data.datasets.map(({borderColor, label, data}) => ({
                  text: label,
                  hidden: data.length === 0,
                  fillStyle: borderColor
                }))
            }
          }
        }
      })
    },
    beforeRouteUpdate(to, from, next) {
      this.stocks = routeToProps(to)
      next()
    },
    watch: {
      stocks: {
        handler(stocks) {
          const newRoute = {name: "stocks", query: {}}
          if (stocks.tags.length > 0) {
            newRoute.query.s = JSON.stringify(stocks.tags.map(tagToQueryParam))
          }
          if (stocks.dateFrom) {
            newRoute.query.df = formatISO(stocks.dateFrom, {representation: 'date'})
          }
          if (stocks.dateTo) {
            newRoute.query.dt = formatISO(stocks.dateTo, {representation: 'date'})
          }
          this.$router.push(newRoute).catch(err => err)

          this.updateChart()
        },
        deep: true
      }
    },
    methods: {
      async updateChart() {
        try {
          this.updateOngoing = true

          const api_responses = await Promise.all(this.stocks.tags.map(async (tag) =>
            ({
              tag,
              metadata_response: await this.fetchMetadata(tag.text),
              prices_response: await this.fetchPrices(tag.text)
            })))

          this.chart.data.datasets = api_responses
            .map(this.parseResponse)
            .map(this.makeDataset)

          this.chart.options.scales.yAxes = this.chart.data.datasets
            .filter(({data}) => data.length > 0)
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
          this.$refs.errorBar.show(error)
          console.error(error)
        } finally {
          this.updateOngoing = false
        }
      },

      fetchMetadata(symbol) {
        return this.axios.get(`/stocks/symbol/${symbol}`)
      },
      fetchPrices(symbol) {
        const maxDataPoints = 50
        const days = differenceInCalendarDays(this.stocks.dateTo, this.stocks.dateFrom);
        const sampling = Math.max(Math.round(days / maxDataPoints), 1)

        const dateFrom = formatISO(this.stocks.dateFrom, {representation: 'date'})
        const dateTo = formatISO(this.stocks.dateTo, {representation: 'date'})

        return this.axios.get(`/prices/${symbol}/from/${dateFrom}/to/${dateTo}`, {
          params: {sampling}
        })
      },
      parseResponse: ({metadata_response, prices_response, tag}) => ({
        metadata: metadata_response.data.data,
        datapoints: prices_response.data.data.map(
          ({date, close}) => ({x: parseISO(date), y: parseFloat(close)})
        ),
        tag
      }),
      makeDataset({datapoints, metadata, tag}, index) {
        return {
          data: datapoints,
          fill: false,
          metadata,
          label: `${metadata.symbol} (${metadata.currency})${this.labelSuffix(tag)}`,
          borderColor: datapoints.length === 0 ? GRAY : COLORS[index % COLORS.length],
          yAxisID: metadata.currency
        }
      },
      labelSuffix({isin, figi}) {
        if (isin) {
          return ` - ISIN: ${isin}`
        }
        if (figi) {
          return ` - FIGI: ${figi}`
        }
        return ''
      }
    },
    computed: {
      hasData() {
        return this.chart &&
          this.chart.data &&
          this.chart.data.datasets &&
          this.chart.data.datasets.length > 0
      }
    }
  }
</script>


