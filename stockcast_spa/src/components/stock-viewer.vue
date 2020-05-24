<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <b-form-row>
          <b-col md="4">
            <b-form-group label="Stocks:"
                          label-for="stocks">
              <vue-tags-input
                autocomplete="off"
                id="stocks"
                v-model="tag"
                :tags="tags"
                :avoidAddingDuplicates="true"
                :autocomplete-items="autocompleteItems"
                :max-tags="10"
                :maxlength="50"
                :add-only-from-autocomplete="true"
                :autocomplete-min-length="autocompleteMinLength"
                @tags-changed="tagsChanged"
                placeholder="Search by name, ticker, or ISIN">
              </vue-tags-input>
            </b-form-group>
          </b-col>
          <b-col md="auto">
            <b-form-group label="From:"
                          label-for="date-from">
              <b-form-datepicker id="date-from"
                                 v-model="dateFrom"
                                 :date-format-options="dateFormatOptions"
                                 :max="dateTo || yesterday"
              ></b-form-datepicker>
            </b-form-group>
          </b-col>
          <b-col md="auto">
            <b-form-group label="To:"
                          label-for="date-to">
              <b-form-datepicker id="date-to"
                                 v-model="dateTo"
                                 :date-format-options="dateFormatOptions"
                                 :max="yesterday"
              ></b-form-datepicker>
            </b-form-group>
          </b-col>
        </b-form-row>
      </b-form>
    </template>
    Money here $$$
  </b-card>
</template>
<script>
  import {startOfYesterday} from 'date-fns'
  import debounce from 'debounce-async'

  const DELAY = 800

  const tagsToSymbols = (tags) => tags.map(({text}) => text)

  export default {
    props: {
      symbols: Array
    },
    data: () => ({
      tag: '',
      tags: [],
      autocompleteItems: [],
      autocompleteMinLength: 3,
      dateFormatOptions: {year: 'numeric', month: 'numeric', day: 'numeric'},
      yesterday: startOfYesterday(),
      dateFrom: null,
      dateTo: null,
      debouncedSearch: null
    }),
    mounted() {
      this.debouncedSearch = debounce(this.searchStocks, DELAY)
    },
    watch: {
      async tag(newTagInput) {
        if (newTagInput.length < this.autocompleteMinLength) {
          return
        }
        const result = await this.debouncedSearch(newTagInput)
        this.autocompleteItems = result.data.data.map(({symbol}) => ({text: symbol}))
      }
    },
    methods: {
      async searchStocks(term) {
        try {
          return await this.axios.get("stocks/search", {params: {q: term, limit: 10}})
        } catch (error) {
          this.$refs.errorBar.show(error)
          throw error
        }
      },
      tagsChanged(tags) {
        this.$router.push({name: "stocks", query: {symbols: tagsToSymbols(tags)}})
      }
    }
  }
</script>


