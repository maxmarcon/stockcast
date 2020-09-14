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

    readonly symbol: string
    readonly name: string
    readonly currency: string
    readonly isin?: string
    readonly figi?: string

    get text() {
        return this.symbol
    }
    
    constructor(symbol: Symbol, terms?: string[]) {
        this.symbol = symbol.symbol
        this.name = symbol.name
        this.currency = symbol.currency
        if (terms && !terms.every(term => (symbol.figi || '').toUpperCase().search(term.toUpperCase()) !== 0)) {
            this.figi = symbol.figi
        }
        const matchingIsin = terms && symbol.isins.find(isin => terms.find(
            term => isin.toUpperCase().search(term.toUpperCase()) === 0
            )
        )
        if (matchingIsin) {
            this.isin = matchingIsin
        }
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
        type: Object, default: {
            stocks: [],
            dateFrom: null,
            dateTo: null
        },
        validator: (value) => value.stocks instanceof Array
            && (value.dateFrom == null || value.dateFrom instanceof Date)
            && (value.dateTo == null || value.dateTo instanceof Date)
    })
    private value!: StockPeriod

    @Prop({type: Number, default: 5})
    private maxTags!: number

    private tag: string = ''
    private yesterday: Date = startOfYesterday()
    private autocompleteItems: Stock[] = []
    private autocompleteMinLength: number = 3
    private debouncedSearch!: (term: string) => Promise<AxiosResponse<SearchResponse>>
    private dateFormatOptions: object = {year: 'numeric', month: 'numeric', day: 'numeric'}
    private ongoing: boolean = false

    mounted() {
        this.debouncedSearch = debounce(this.searchStocks, DELAY)
    }

    @Watch("tag")
    private async watchTag(newTagInput: string): Promise<void> {
        if (newTagInput.length < this.autocompleteMinLength) {
            return
        }
        const result = await this.debouncedSearch(newTagInput)

        if (result) {
            const terms = newTagInput.split(/\s+/).filter(term => term)
            this.autocompleteItems = result.data.data.map(symbol => new Stock(symbol, terms))
        }
    }

    @Emit('input')
    private dateFromChanged(date: Date): StockPeriod {
        this.value.dateFrom = date
        if (this.value.dateTo) {
            this.value.dateTo = max([date, this.value.dateTo])
        }
        return this.value
    }

    @Emit('input')
    private dateToChanged(date: Date): StockPeriod {
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

    private async searchStocks(term: string): Promise<AxiosResponse<SearchResponse> | void> {
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
