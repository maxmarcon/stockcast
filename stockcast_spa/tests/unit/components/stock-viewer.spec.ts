import stockViewer from '@/components/stock-viewer.ts'
import StockViewer from '@/components/stock-viewer.ts'
import bootstrapVue from 'bootstrap-vue'
import Vue from 'vue'
import {createLocalVue, mount, Wrapper} from '@vue/test-utils'
import {parseISO} from 'date-fns'
// @ts-ignore
import priceApiResponse from './price_api_response.json'
import {HistoricalPrice} from "@/utils/prices";
import {Route} from "vue-router";
import {Stock} from "@/components/stock-period-picker";
import objectContaining = jasmine.objectContaining;

const localVue = createLocalVue()
localVue.use(bootstrapVue)

let routerMock, axiosMock: any
let wrapper: Wrapper<StockViewer>

describe('stockViewer', () => {

    beforeEach(async () => {
        routerMock = {
            push: jest.fn(() => Promise.resolve())
        }

        axiosMock = {
            get: jest.fn(async (path) => {
                let match = path.match(/stocks\/symbol\/(.+)/)

                if (match) {
                    return {
                        data: {
                            data: {
                                currency: "USD",
                                symbol: match[1]
                            }
                        }
                    }
                }

                match = path.match(/prices\/([^/]+)/)

                switch (match[1]) {
                    case 'S1':
                    case 'S2':
                        return {
                            data: {
                                data: {
                                    prices: priceApiResponse.data.slice(1),
                                    performance: {}
                                }
                            }
                        }
                    default:
                        return {
                            data: {
                                data: {
                                    prices: priceApiResponse.data,
                                    performance: {}
                                }
                            }
                        }
                }
            })
        }

        wrapper = mount(stockViewer, {
            propsData: {
                initialStockPeriod: {
                    stocks: [new Stock('S1'), new Stock('S2')],
                    dateFrom: parseISO('2020-01-01'),
                    dateTo: parseISO('2020-03-01')
                }
            },
            localVue,
            mocks: {
                $router: routerMock,
                axios: axiosMock
            },
            stubs: ['messageBar', 'stockPeriodPicker', 'b-icon']
        })
        await Vue.nextTick()
    })

    it('can be mounted', () => {
        expect(wrapper).toBeTruthy()
    })

    it('renders the stock period picker', () => {
        expect(wrapper.find('stockperiodpicker-stub').exists()).toBeTruthy()
    })

    it('initializes the stocks with tags and dates', () => {
        expect(wrapper.vm.stockPeriod).toEqual(objectContaining({
            stocks: [new Stock('S1'), new Stock( 'S2')],
            dateFrom: parseISO('2020-01-01'),
            dateTo: parseISO('2020-03-01')
        }))
    })

    it('initializes the chart object', () => {
        expect(wrapper.vm.chart).toBeTruthy()
    })

    it('renders the stock cards', () => {
        expect(wrapper.findAll('div.container-fluid div.card').length).toEqual(2)
    })

    it("queries the price api", () => {
        expect(axiosMock.get).toHaveBeenCalledWith('/prices/S1/from/2020-01-01/to/2020-03-01', expect.anything())
        expect(axiosMock.get).toHaveBeenCalledWith('/prices/S2/from/2020-01-01/to/2020-03-01', expect.anything())
    })

    it('updates the chart data', () => {
        expect(wrapper.vm.chart.data.datasets!.length).toBe(2)
        expect(wrapper.vm.chart.data.datasets![0].label).toBe("S1 (USD)")
        expect(wrapper.vm.chart.data.datasets![1].label).toBe("S2 (USD)")
        expect(wrapper.vm.chart.data.datasets![0].data).toEqual(
            priceApiResponse.data.slice(1).map(({date, close}: Partial<HistoricalPrice>) => ({
                x: parseISO(date as string),
                y: parseFloat(close as string)
            }))
        )
        expect(wrapper.vm.chart.data.datasets![1].data).toEqual(
            priceApiResponse.data.slice(1).map(({date, close}: Partial<HistoricalPrice>) => ({
                x: parseISO(date as string),
                y: parseFloat(close as string)
            }))
        )

    })

    describe('when stocks are updated', () => {

        beforeEach(async () => {
            wrapper.find('stockperiodpicker-stub').vm.$emit('input', {
                tags: [{text: "S3", isin: "ISIN3"}, {text: "S4", figi: "FIGI4"}, {text: "S5"}],
                dateFrom: parseISO('2019-01-01'),
                dateTo: parseISO('2019-03-01')
            })
        })

        it("updates query parameters", () => {
            expect(routerMock.push).toHaveBeenCalledWith({
                name: "stocks",
                query: {
                    s: JSON.stringify([{s: "S3", i: "ISIN3"}, {s: "S4", f: "FIGI4"}, "S5"]),
                    df: '2019-01-01',
                    dt: '2019-03-01'
                }
            })
        })

        it("queries the prices api", () => {
            expect(axiosMock.get).toHaveBeenCalledWith('/prices/S3/from/2019-01-01/to/2019-03-01', expect.anything())
            expect(axiosMock.get).toHaveBeenCalledWith('/prices/S4/from/2019-01-01/to/2019-03-01', expect.anything())
            expect(axiosMock.get).toHaveBeenCalledWith('/prices/S5/from/2019-01-01/to/2019-03-01', expect.anything())

        })

        it('updates the chart data', () => {
            expect(wrapper.vm.chart.data.datasets!.length).toBe(3)
            expect(wrapper.vm.chart.data.datasets![0].label).toBe("S3 (USD) - ISIN: ISIN3")
            expect(wrapper.vm.chart.data.datasets![1].label).toBe("S4 (USD) - FIGI: FIGI4")
            expect(wrapper.vm.chart.data.datasets![2].label).toBe("S5 (USD)")
            const parsedData = priceApiResponse.data.map(({date, close}: HistoricalPrice) => ({
                x: parseISO(date as string),
                y: parseFloat(close)
            }))
            expect(wrapper.vm.chart.data.datasets![0].data).toEqual(parsedData)
            expect(wrapper.vm.chart.data.datasets![1].data).toEqual(parsedData)
            expect(wrapper.vm.chart.data.datasets![2].data).toEqual(parsedData)
        })
    })

    describe('when the route is updated', () => {
        beforeEach(async () => {
            wrapper.vm.$options.beforeRouteUpdate!.call(wrapper.vm, {
                query: {
                    s: JSON.stringify(['C1', {s: 'C2', i: 'ISIN2'}, {s: 'C3', f: 'FIGI3'}]),
                    df: '2019-01-01',
                    dt: '2019-03-01'
                }
            } as unknown as Route, {} as Route, jest.fn())
        })

        it('updates the stocks', () => {
            expect(wrapper.vm.stockPeriod).toEqual({
                tags: [{text: 'C1'}, {text: 'C2', isin: 'ISIN2'}, {text: 'C3', figi: 'FIGI3'}],
                dateFrom: parseISO('2019-01-01'),
                dateTo: parseISO('2019-03-01')
            })
        })

        it("queries the prices api", () => {
            expect(axiosMock.get).toHaveBeenCalledWith('/prices/C2/from/2019-01-01/to/2019-03-01', expect.anything())
            expect(axiosMock.get).toHaveBeenCalledWith('/prices/C1/from/2019-01-01/to/2019-03-01', expect.anything())
            expect(axiosMock.get).toHaveBeenCalledWith('/prices/C3/from/2019-01-01/to/2019-03-01', expect.anything())
        })

        it('updates the chart data', () => {
            expect(wrapper.vm.chart.data.datasets!.length).toBe(3)
            expect(wrapper.vm.chart.data.datasets![0].label).toBe("C1 (USD)")
            expect(wrapper.vm.chart.data.datasets![1].label).toBe("C2 (USD) - ISIN: ISIN2")
            expect(wrapper.vm.chart.data.datasets![2].label).toBe("C3 (USD) - FIGI: FIGI3")
            const parsedData = priceApiResponse.data.map(({date, close}: HistoricalPrice) => ({
                x: parseISO(date as string),
                y: parseFloat(close)
            }))
            expect(wrapper.vm.chart.data.datasets![0].data).toEqual(parsedData)
            expect(wrapper.vm.chart.data.datasets![1].data).toEqual(parsedData)
            expect(wrapper.vm.chart.data.datasets![2].data).toEqual(parsedData)
        })
    })
})
