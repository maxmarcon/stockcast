<template>
  <b-form-row>
    <b-col md="4">
      <b-form-group label="Stocks:"
                    label-for="stocks">
        <vue-tags-input
          autocomplete="off"
          id="stocks"
          v-model="tag"
          :tags="value.tags"
          :avoidAddingDuplicates="true"
          :autocomplete-items="autocompleteItems"
          :max-tags="maxTags"
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
                           :value="value.dateFrom"
                           @input="dateFromChanged"
                           :date-format-options="dateFormatOptions"
                           :max="dateTo || yesterday">
        </b-form-datepicker>
      </b-form-group>
    </b-col>
    <b-col md="auto">
      <b-form-group label="To:"
                    label-for="date-to">
        <b-form-datepicker id="date-to"
                           :value="value.dateTo"
                           @input="dateToChanged"
                           :date-format-options="dateFormatOptions"
                           :max="yesterday">
        </b-form-datepicker>
      </b-form-group>
    </b-col>
  </b-form-row>
</template>
<script>
  import {formatISO, max, min, parseISO, startOfYesterday, subMonths} from 'date-fns'
  import debounce from "debounce-async";

  const DELAY = 800

  export default {
    props: {
      value: {
        type: Object,
        default: () => ({
          tags: [],
          dateFrom: subMonths(startOfYesterday(), 3),
          dateTo: startOfYesterday()
        })
      },
      maxTags: {
        type: Number,
        default: 10
      }
    },
    data: () => ({
      tag: '',
      yesterday: startOfYesterday(),
      autocompleteItems: [],
      autocompleteMinLength: 3,
      debouncedSearch: null,
      dateFormatOptions: {year: 'numeric', month: 'numeric', day: 'numeric'}
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
        if (result) {
          this.autocompleteItems = result.data.data.map(({symbol}) => ({text: symbol}))
        }
      }
    },
    methods: {
      dateFromChanged(date) {
        this.value.dateFrom = date
        this.value.dateTo = formatISO(max([date, this.value.dateTo].map(parseISO)), {representation: 'date'})
        this.$emit('input', this.value)
      },
      dateToChanged(date) {
        this.value.dateTo = date
        this.value.dateFrom = formatISO(min([date, this.value.dateFrom].map(parseISO)), {representation: 'date'})
        this.$emit('input', this.value)
      },
      tagsChanged(tags) {
        this.value.tags = tags
        this.$emit('input', this.value)
      },
      async searchStocks(term) {
        try {
          return await this.axios.get("stocks/search", {params: {q: term, limit: 10}})
        } catch (error) {
          this.$emit('error', error)
        }
      }
    }
  }
</script>
