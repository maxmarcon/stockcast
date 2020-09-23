import { RawStockData } from './rawStockData'
import { Route } from 'vue-router'
import { parseISO, startOfYesterday, subMonths } from 'date-fns'

export class Stock {

  static fromSymbol (symbolObject: RawStockData, terms: string[] = []) {
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

  readonly text: string

  constructor (readonly symbol: string,
                readonly name?: string,
                readonly currency?: string,
                readonly isin?: string,
                readonly figi?: string) {
    this.text = symbol
  }
}

export type StockPeriod = {
    stocks: Stock[];
    dateFrom: Date;
    dateTo: Date;
}

export type StockQueryParam = {
    s: string;
    f?: string;
    i?: string;
} | string

const queryParamToStock = (queryParam: StockQueryParam): Stock => {
  if (typeof (queryParam) === 'string') {
    return new Stock(queryParam)
  }
  const { s: symbol, f: figi, i: isin } = queryParam
  return new Stock(symbol, undefined, undefined, isin, figi)
}

export const DATE_FROM_DEFAULT = subMonths(startOfYesterday(), 3)
export const DATE_TO_DEFAULT = startOfYesterday()

export const routeToStockPeriod = (route: Route): StockPeriod => {
  const stocks = route.query.s ? JSON.parse(route.query.s as string).map(queryParamToStock) : []
  const dateFrom = route.query.df ? parseISO(route.query.df as string) : DATE_FROM_DEFAULT
  const dateTo = route.query.dt ? parseISO(route.query.dt as string) : DATE_TO_DEFAULT

  return {
    stocks,
    dateFrom,
    dateTo
  }
}
