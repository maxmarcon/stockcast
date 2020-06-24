<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <b-form-row>
          <b-col md="8">
            <stock-period-picker v-model="stocks"
                                 @error="$refs.errorBar.show($event)"
            >
            </stock-period-picker>
          </b-col>
          <b-col md="auto" align-self="center" class="text-center">
            <b-icon v-if="ongoing"
                    icon="arrow-clockwise"
                    animation="spin"
                    font-scale="2"
                    class="mx-auto">
            </b-icon>
          </b-col>
        </b-form-row>
      </b-form>
    </template>
    <canvas ref="chart" id="stocks_chart">
    </canvas>
  </b-card>
</template>
<script>
  import {formatISO, parseISO, startOfYesterday, subMonths} from 'date-fns'
  import Chart from 'chart.js'

  const tagPropertyFilter = ({text, currency}) => ({text, currency})

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

  export const routeToProps = (route) => {
    const tags = route.query.s ? JSON.parse(route.query.s).map(tagPropertyFilter) : []
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
      ongoing: false
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
              scaleLabel: {
                display: true,
                labelString: 'Date'
              }
            }]
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
            newRoute.query.s = JSON.stringify(stocks.tags.map(tagPropertyFilter))
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
          this.ongoing = true

          this.chart.options.scales.yAxes = this.stocks.tags.map(({currency}) => currency)
            .filter((value, index, self) => self.indexOf(value) === index)
            .map(currency => ({
              id: currency,
              type: 'linear',
              scaleLabel: {
                display: true,
                labelString: currency
              }
            }))

          const responses_with_metadata = await Promise.all(this.stocks.tags.map(async ({text: symbol, currency}) =>
            ({
              response: await this.fetchPrices(symbol),
              symbol,
              currency
            })))
          
          this.chart.data.datasets = responses_with_metadata
            .map(this.parseResponse)
            .map(this.makeDataset)
          
          this.chart.update()
        } catch (error) {
          this.$refs.errorBar.show(error)
        } finally {
          this.ongoing = false
        }
      },
      fetchPrices(symbol) {
        const dateFrom = formatISO(this.stocks.dateFrom, {representation: 'date'})
        const dateTo = formatISO(this.stocks.dateTo, {representation: 'date'})

        return this.axios.get(`/prices/${symbol}/from/${dateFrom}/to/${dateTo}`)
      },
      parseResponse: ({response, symbol, currency}) => ({
        symbol,
        currency,
        datapoints: response.data.data.map(
          ({date, close}) => ({x: parseISO(date), y: parseFloat(close)})
        )
      }),
      makeDataset: ({datapoints, symbol, currency}, index) =>
        ({
          data: datapoints,
          fill: false,
          label: `${symbol} (${currency})`,
          borderColor: COLORS[index % COLORS.length],
          yAxisID: currency
        })
    }
  }
</script>


