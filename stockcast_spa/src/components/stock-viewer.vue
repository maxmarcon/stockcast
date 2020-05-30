<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <stock-period-picker v-model="stocks"
                             @error="$refs.errorBar.show($event)"
        >
        </stock-period-picker>
      </b-form>
    </template>
    Money here $$$
  </b-card>
</template>
<script>
  import {formatISO, parseISO, subMonths, startOfYesterday} from 'date-fns'

  const tagPropertyFilter = ({text}) => ({text})

  const DATE_FROM_DEFAULT = subMonths(startOfYesterday(), 3)
  const DATE_TO_DEFAULT = startOfYesterday()

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
      }
    }),
    created() {
      this.stocks.tags = this.tags
      this.stocks.dateFrom = this.dateFrom
      this.stocks.dateTo = this.dateTo
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
        },
        deep: true
      }
    }
  }
</script>


