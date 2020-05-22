<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <b-form-row>
          <b-col md="4">
            <b-form-group label="Stocks:"
                          labe-for="stocks">
              <vue-tags-input
                id="stocks"
                v-model="tag"
                :tags="tags"
                :avoidAddingDuplicates="true"
                :autocomplete-items="autocompleteItems"
                :max-tags="10"
                :maxlength="50"
                :add-only-from-autocomplete="true"
                placeholder="Search by name, ticker, or ISIN">
              </vue-tags-input>
            </b-form-group>
          </b-col>
          <b-col md="auto">
            <b-form-group label="From:"
                          labe-for="date-from">
              <b-form-datepicker id="date-from"
                                 v-model="dateFrom"
                                 :date-format-options="dateFormatOptions"
                                 :max="dateTo || yesterday"
              ></b-form-datepicker>
            </b-form-group>
          </b-col>
          <b-col md="auto">
            <b-form-group label="To:"
                          labe-for="date-to">
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

  export default {
    data: () => ({
      tag: '',
      tags: [],
      autocompleteItems: [],
      dateFormatOptions: {year: 'numeric', month: 'numeric', day: 'numeric'},
      yesterday: startOfYesterday(),
      dateFrom: null,
      dateTo: null,
      debouncedSearch: null
    }),
    mounted() {
      this.debouncedSearch = debounce(
        async (term) => await this.axios.get("stocks/search", {params: {q: term, limit: 10}}), 800)
    },
    watch: {
      async tag(newTagInput) {
        if (newTagInput.length < 3) {
          return
        }
        const result = await this.debouncedSearch(newTagInput)
        this.autocompleteItems = result.data.data.map(({symbol}) => ({text: symbol}))
      }
    }
  }
</script>


