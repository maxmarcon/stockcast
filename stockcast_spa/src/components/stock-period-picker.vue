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
          autocomplete="off"
          id="stocks"
          v-model="tag"
          :tags="value.stocks"
          :avoidAddingDuplicates="true"
          :autocomplete-items="autocompleteItems"
          :max-tags="maxTags"
          :maxlength="50"
          :add-only-from-autocomplete="true"
          :autocomplete-min-length="autocompleteMinLength"
          @tags-changed="tagsChanged"
          placeholder="Search by name, ticker, or FIGI">

          <template v-slot:autocomplete-item="{item, performAdd}">
            <div @click="performAdd(item)">
              <span>&nbsp; {{ `${item.text} (${item.currency})` }}</span>
              <span v-if="item.isin">&nbsp; {{ '[ISIN:' + item.isin + ']' }}</span>
              <span v-else-if="item.figi">&nbsp; {{ '[FIGI:' + item.figi + ']' }}</span>
              <span class="em small">&nbsp; {{ ellipsize(item.name, 40) }} </span>
            </div>
          </template>
          <template v-slot:tag-right="{tag: {isin, figi}}">
            <span class="ml-1 small" v-if="isin">{{ '[ISIN:' + isin + ']' }}</span>
            <span class="ml-1 small" v-else-if="figi">{{ '[FIGI:' + figi + ']' }}</span>
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
<script lang="ts">
import {max, min, startOfYesterday} from 'date-fns'
import debounce from 'debounce-async'
import Vue, {PropType} from 'vue'
import {SearchResponse} from '../utils/stockMetadata'
import {AxiosResponse} from 'axios'
import {Stock, StockPeriod} from '@/utils/stock'

const DELAY = 800

interface State {
  tag: string;
  yesterday: Date;
  autocompleteItems: Stock[];
  autocompleteMinLength: number;
  debouncedSearch: ((term: string) => Promise<AxiosResponse<SearchResponse>>) | undefined;
  dateFormatOptions: object;
  ongoing: boolean;
}

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
  data(): State {
    return {
      tag: '',
      yesterday: startOfYesterday(),
      autocompleteItems: [],
      autocompleteMinLength: 3,
      dateFormatOptions: {
        year: 'numeric', month: 'numeric', day: 'numeric'
      },
      ongoing: false,
      debouncedSearch: undefined
    }
  },
  mounted() {
    this.debouncedSearch = debounce(this.searchStocks, DELAY)
  },
  methods: {
    async searchStocks(term: string): Promise<AxiosResponse<SearchResponse> | void> {
      try {
        this.ongoing = true
        return this.axios.get<SearchResponse>('stocks/search', {params: {q: term, limit: 10}})
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
    async tag(newTagInput: string): void {
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
