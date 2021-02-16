<template>
  <b-form-row>
    <b-col md>
      <b-form-group
        label-for="stocks">
        <template v-slot:label>
          Stocks:
          <b-spinner v-if="ongoing" small></b-spinner>
        </template>
        <vue-tags-input
          id="stocks"
          v-model="tag"
          :add-only-from-autocomplete="true"
          :autocomplete-items="autocompleteItems"
          :autocomplete-min-length="autocompleteMinLength"
          :avoidAddingDuplicates="true"
          :max-tags="maxTags"
          :maxlength="50"
          :tags="value.stocks"
          autocomplete="off"
          placeholder="Search by name, ticker, or FIGI"
          @tags-changed="tagsChanged">

          <template v-slot:autocomplete-item="{item, performAdd}">
            <div @click="performAdd(item)">
              <span>&nbsp; {{ `${item.text} (${item.currency})` }}</span>
              <span v-if="item.isin">&nbsp; {{ '[ISIN:' + item.isin + ']' }}</span>
              <span v-else-if="item.figi">&nbsp; {{ '[FIGI:' + item.figi + ']' }}</span>
              <span class="em small">&nbsp; {{ ellipsize(item.name, 40) }} </span>
            </div>
          </template>
          <template v-slot:tag-right="{tag: {isin, figi}}">
            <span v-if="isin" class="ml-1 small">{{ '[ISIN:' + isin + ']' }}</span>
            <span v-else-if="figi" class="ml-1 small">{{ '[FIGI:' + figi + ']' }}</span>
          </template>
        </vue-tags-input>
      </b-form-group>
    </b-col>
    <b-col md="auto">
      <b-form-group label="From:"
                    label-for="date-from">
        <b-form-datepicker id="date-from"
                           :date-format-options="dateFormatOptions"
                           :max="yesterday"
                           :value="value.dateFrom"
                           :value-as-date="true"
                           @input="dateFromChanged">
        </b-form-datepicker>
      </b-form-group>
    </b-col>
    <b-col md="auto">
      <b-form-group label="To:"
                    label-for="date-to">
        <b-form-datepicker id="date-to"
                           :date-format-options="dateFormatOptions"
                           :max="yesterday"
                           :value="value.dateTo"
                           :value-as-date="true"
                           @input="dateToChanged">
        </b-form-datepicker>
      </b-form-group>
    </b-col>
  </b-form-row>
</template>
<script lang="ts">
import {max, min, startOfYesterday} from 'date-fns'
import debounce from 'debounce-async'
import Vue, {PropType} from 'vue'
import {SearchResponse} from '../utils/stockMetadata'
import {AxiosResponse} from 'axios'
import {Stock, StockPeriod} from '@/utils/stock'
import ellipsize from "ellipsize";

const DELAY = 800

export default Vue.extend({
  props: {
    value: {
      type: Object as PropType<StockPeriod>,
      default: () => ({
        stocks: [],
        dateFrom: null,
        dateTo: null
      }),
      validator: (value) => value.stocks instanceof Array &&
        value.stocks.every((stock: any) => stock.text) &&
        (value.dateFrom == null || value.dateFrom instanceof Date) &&
        (value.dateTo == null || value.dateTo instanceof Date)
    },
    maxTags: {
      type: Number, default: 5
    }
  },
  data() {
    return {
      tag: '',
      yesterday: startOfYesterday(),
      autocompleteItems: [] as Stock[],
      autocompleteMinLength: 3,
      dateFormatOptions: {
        year: 'numeric', month: 'numeric', day: 'numeric'
      },
      ongoing: false,
      debouncedSearch: undefined as ((term: string) => Promise<AxiosResponse<SearchResponse>>) | undefined
    }
  },
  mounted() {
    this.debouncedSearch = debounce(this.searchStocks, DELAY)
  },
  methods: {
    ellipsize,
    async searchStocks(term: string): Promise<AxiosResponse<SearchResponse> | void> {
      try {
        this.ongoing = true
        return await this.axios.get<SearchResponse>('stocks/search', {params: {q: term, limit: 10}})
      } catch (error) {
        this.$emit('error', error)
      } finally {
        this.ongoing = false
      }
    },
    dateFromChanged(date: Date): void {
      this.value.dateFrom = date
      if (this.value.dateTo) {
        this.value.dateTo = max([date, this.value.dateTo])
      }
      this.$emit('input', this.value)
    },
    dateToChanged(date: Date): void {
      this.value.dateTo = date
      if (this.value.dateFrom) {
        this.value.dateFrom = min([date, this.value.dateFrom])
      }
      this.$emit('input', this.value)
    },
    tagsChanged(stocks: Stock[]): void {
      this.value.stocks = stocks
      this.$emit('input', this.value)
    }
  },
  watch: {
    async tag(newTagInput: string): Promise<void> {
      if (newTagInput.length < this.autocompleteMinLength) {
        return
      }
      if (this.debouncedSearch) {
        const result = await this.debouncedSearch(newTagInput)
        if (result) {
          const terms = newTagInput.split(/\s+/).filter(term => term)
          this.autocompleteItems = result.data.data.map(symbol => Stock.fromSymbol(symbol, terms))
        }
      }
    }
  }
})
</script>
