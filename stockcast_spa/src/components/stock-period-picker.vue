<template>
  <b-form-row>
    <b-col md>
      <b-form-group
        label-for="stocks">
        <template v-slot:label>
          Stocks:
          <b-icon v-if="ongoing" icon="arrow-clockwise" animation="spin" font-scale="1"></b-icon>
        </template>
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
              <span v-if="item.isin || item.figi">&nbsp; {{ '[' + (item.isin || item.figi) + ']' }}</span>
              <span class="em small">&nbsp; {{ ellipsize(item.name, 40) }} </span>
            </div>
          </template>
          <template v-slot:tag-right="{tag: {isin, figi}}">
            <span class="ml-1 small" v-if="isin || figi">{{ '[' + (isin || figi) + ']' }}</span>
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
  import debounce from "debounce-async"
  import ellipsize from "ellipsize"

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
      dateFormatOptions: {year: 'numeric', month: 'numeric', day: 'numeric'},
      ongoing: false
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
          const terms = newTagInput.split(/\s+/).filter(term => term)
          this.autocompleteItems = result.data.data.map(symbol =>
            Object.assign({text: symbol.symbol}, symbol)
          ).map(item => {
            const {figi, isins} = item
            if (terms.every(term => (figi || '').toUpperCase().search(term.toUpperCase()) !== 0)) {
              delete item.figi
            }
            const matchingIsin = isins.find(isin =>
              terms.find(term => isin.toUpperCase().search(term.toUpperCase()) === 0)
            )
            if (matchingIsin) {
              item.isin = matchingIsin
            }
            delete item.isins
            return item
          })
        }
      }
    },
    methods: {
      ellipsize,
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
          this.ongoing = true
          return await this.axios.get("stocks/search", {params: {q: term, limit: 10}})
        } catch (error) {
          this.$emit('error', error)
        } finally {
          this.ongoing = false
        }
      }
    }
  }
</script>
