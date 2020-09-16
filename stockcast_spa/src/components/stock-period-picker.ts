import {max, min, startOfYesterday} from 'date-fns'
// @ts-ignore
import debounce from "debounce-async"
import Vue from 'vue'
import {Component, Emit, Prop, Watch} from "vue-property-decorator";
//@ts-ignore
import template from './stock-period-picker.html'
import {SearchResponse, Symbol} from '@/utils/symbol'
import {AxiosResponse} from "axios";

const DELAY = 800

export class Stock {
    
    get text() {
        return this.symbol
    }

    static fromSymbol(symbolObject: Symbol, terms: string[] = []) {
        const symbol = symbolObject.symbol
        const name = symbolObject.name
        const currency = symbolObject.currency
        if (!terms.every(term => (symbolObject.figi || '').toUpperCase().search(term.toUpperCase()) !== 0)) {
            const figi = symbolObject.figi
            return new Stock(symbol, name, currency, undefined, figi)
        }
        const matchingIsin = terms && symbolObject.isins.find(isin => terms.find(
            term => isin.toUpperCase().search(term.toUpperCase()) === 0
            )
        )
        if (matchingIsin) {
            const isin = matchingIsin
            return new Stock(symbol, name, currency, isin, undefined)
        }
        return new Stock(symbol, name, currency)
    }

    constructor(readonly symbol: string,
                readonly name?: string,
                readonly currency?: string,
                readonly isin?: string,
                readonly figi?: string) {
    }
}

export type StockPeriod = {
    stocks: Stock[],
    dateFrom: Date,
    dateTo: Date
}

@Component({template})
export default class StockPeriodPicker extends Vue {

    @Prop({
        type: Object, default: () => ({
            stocks: [],
            dateFrom: null,
            dateTo: null
        }),
        validator: (value) => value.stocks instanceof Array
            && value.stocks.every((stock: any) => stock instanceof Stock)
            && (value.dateFrom == null || value.dateFrom instanceof Date)
            && (value.dateTo == null || value.dateTo instanceof Date)
    })
    value!: StockPeriod

    @Prop({type: Number, default: 5})
    maxTags!: number

    tag: string = ''
    yesterday: Date = startOfYesterday()
    autocompleteItems: Stock[] = []
    autocompleteMinLength: number = 3
    debouncedSearch!: (term: string) => Promise<AxiosResponse<SearchResponse>>
    dateFormatOptions: object = {year: 'numeric', month: 'numeric', day: 'numeric'}
    ongoing: boolean = false

    mounted() {
        this.debouncedSearch = debounce(this.searchStocks, DELAY)
    }

    @Watch("tag")
    async watchTag(newTagInput: string): Promise<void> {
        if (newTagInput.length < this.autocompleteMinLength) {
            return
        }
        const result = await this.debouncedSearch(newTagInput)

        if (result) {
            const terms = newTagInput.split(/\s+/).filter(term => term)
            this.autocompleteItems = result.data.data.map(symbol => Stock.fromSymbol(symbol, terms))
        }
    }

    @Emit('input')
    dateFromChanged(date: Date): StockPeriod {
        this.value.dateFrom = date
        if (this.value.dateTo) {
            this.value.dateTo = max([date, this.value.dateTo])
        }
        return this.value
    }

    @Emit('input')
    dateToChanged(date: Date): StockPeriod {
        this.value.dateTo = date
        if (this.value.dateFrom) {
            this.value.dateFrom = min([date, this.value.dateFrom])
        }
        return this.value
    }

    @Emit('input')
    tagsChanged(tags: Stock[]): StockPeriod {
        this.value.stocks = tags
        return this.value
    }

    async searchStocks(term: string): Promise<AxiosResponse<SearchResponse> | void> {
        try {
            this.ongoing = true
            return await this.axios.get<SearchResponse>("stocks/search", {params: {q: term, limit: 10}})
        } catch (error) {
            this.$emit('error', error)
        } finally {
            this.ongoing = false
        }
    }
}
