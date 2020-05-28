<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <stock-period-picker :value="{tags}"
                             @input="stockPeriodChanged"
                             @error="this.$refs.errorBar.show($event)"
        >
        </stock-period-picker>
      </b-form>
    </template>
    Money here $$$
  </b-card>
</template>
<script>
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
      tags: []
    }),
    mounted() {
      this.tags = this.initialTags
    },
    beforeRouteUpdate(to, from, next) {
      this.tags = routeToProps(to).initialTags
      next()
    },
    methods: {
      stockPeriodChanged({tags}) {
        this.$router.push({name: "stocks", query: {s: JSON.stringify(tags.map(tagPropertyFilter))}})
      }
    }
  }
</script>


