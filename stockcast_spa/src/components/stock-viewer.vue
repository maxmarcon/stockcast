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
  import {startOfYesterday, subMonths} from 'date-fns'

  const tagPropertyFilter = ({text}) => ({text})

  export const routeToProps = (route) => {
    let tags = route.query.s || "[]"
    return {initialTags: JSON.parse(tags).map(tagPropertyFilter)}
  }

  export default {
    props: {
      initialTags: {
        type: Array,
        default: () => []
      }
    },
    data: () => ({
      stocks: {
        tags: null,
        dateFrom: subMonths(startOfYesterday(), 3),
        dateTo: startOfYesterday()
      }
    }),
    created() {
      this.stocks.tags = this.initialTags
    },
    beforeRouteUpdate(to, from, next) {
      this.stocks.tags = routeToProps(to).initialTags
      next()
    },
    watch: {
      stocks: {
        handler(stocks) {
          let newRoute = null
          if (stocks.tags.length > 0) {
            newRoute = {name: "stocks", query: {s: JSON.stringify(stocks.tags.map(tagPropertyFilter))}}
          } else {
            newRoute = {name: "stocks"}
          }
          this.$router.push(newRoute).catch(err => err)
        },
        deep: true
      }
    }
  }
</script>


