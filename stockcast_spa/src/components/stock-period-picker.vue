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

          <template v-slot:autocomplete-item="{item, performAdd}">
            <div @click="performAdd(item)">
              <span>&nbsp; {{ `${item.text} (${item.currency})` }}</span>
              <span v-if="item.isin">&nbsp; {{ '[' + item.isin + ']' }}</span>
              <span class="em small">&nbsp; {{ item.name.substr(0,20) }} </span>
            </div>
          </template>
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
                           :value-as-date="true"
                           :max="yesterday">
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
                           :value-as-date="true"
                           :max="yesterday">
        </b-form-datepicker>
      </b-form-group>
    </b-col>
  </b-form-row>
</template>
<script>
  import {max, min, startOfYesterday} from 'date-fns'
  import debounce from "debounce-async";

  const DELAY = 800

  export default {
    props: {
      value: {
        type: Object,
        default: () => ({
          tags: [],
          dateFrom: null,
          dateTo: null
        }),
        validator: (value) => {
          return value.tags instanceof Array
            && (value.dateFrom == null || value.dateFrom instanceof Date)
            && (value.dateTo == null || value.dateTo instanceof Date)
        }
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
          this.autocompleteItems = result.data.data.map(symbol =>
            Object.assign({text: symbol.symbol}, symbol)
          )
        }
      }
    },
    methods: {
      dateFromChanged(date) {
        this.value.dateFrom = date
        if (this.value.dateTo) {
          this.value.dateTo = max([date, this.value.dateTo])
        }
        this.$emit('input', this.value)
      },
      dateToChanged(date) {
        this.value.dateTo = date
        if (this.value.dateFrom) {
          this.value.dateFrom = min([date, this.value.dateFrom])
        }
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
