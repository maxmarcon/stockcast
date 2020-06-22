import stockViewer from '@/components/stock-viewer'
import bootstrapVue from 'bootstrap-vue'
import {createLocalVue, mount} from '@vue/test-utils'
import {parseISO} from 'date-fns'
import priceApiResponse from './price_api_response.json'

const localVue = createLocalVue()
localVue.use(bootstrapVue)

let routerMock, axiosMock
let wrapper

describe('stockViewer', () => {

  beforeEach(() => {
    routerMock = {
      push: jest.fn(() => Promise.resolve())
    }

    axiosMock = {
      get: jest.fn(async () => ({data: priceApiResponse}))
        .mockImplementationOnce(async () => ({
          data: {
            data: priceApiResponse.data.slice(1)
          }
        }))
        .mockImplementationOnce(async () => ({
          data: {
            data: priceApiResponse.data.slice(1)
          }
        }))
    }

    wrapper = mount(stockViewer, {
      propsData: {
        tags: [{text: 'S1'}, {text: 'S2'}],
        dateFrom: parseISO('2020-01-01'),
        dateTo: parseISO('2020-03-01')
      },
      localVue,
      mocks: {
        $router: routerMock,
        axios: axiosMock
      },
      stubs: ['messageBar', 'stockPeriodPicker', 'b-icon']
    })
  })

  it('can be mounted', () => {
    expect(wrapper).toBeTruthy()
  })

  it('renders the stock period picker', () => {
    expect(wrapper.find('stockperiodpicker-stub').exists()).toBeTruthy()
  })

  it('initializes the stocks with tags and dates', () => {
    expect(wrapper.vm.stocks).toEqual({
      tags: [{text: 'S1'}, {text: 'S2'}],
      dateFrom: parseISO('2020-01-01'),
      dateTo: parseISO('2020-03-01')
    })
  })

  it('initializes the chart object', () => {
    expect(wrapper.vm.chart).toBeTruthy()
  })

  it("queries the price api", () => {
    expect(axiosMock.get).toHaveBeenCalledWith('/prices/S1/from/2020-01-01/to/2020-03-01')
    expect(axiosMock.get).toHaveBeenCalledWith('/prices/S2/from/2020-01-01/to/2020-03-01')
  })

  it('updates the chart data', () => {
    expect(wrapper.vm.chart.data.datasets.length).toBe(2)
    expect(wrapper.vm.chart.data.datasets[0].data).toEqual(
      priceApiResponse.data.slice(1).map(({date, close}) => ({x: parseISO(date), y: parseFloat(close)}))
    )
    expect(wrapper.vm.chart.data.datasets[1].data).toEqual(
      priceApiResponse.data.slice(1).map(({date, close}) => ({x: parseISO(date), y: parseFloat(close)}))
    )

  })

  describe('when stocks are updated', () => {

    beforeEach(() => {
      wrapper.find('stockperiodpicker-stub').vm.$emit('input', {
        tags: [{text: "S3"}, {text: "S4"}],
        dateFrom: parseISO('2019-01-01'),
        dateTo: parseISO('2019-03-01')
      })

      wrapper.vm.chart.data.datasets = []
    })

    it("updates query parameters", () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        name: "stocks",
        query: {
          s: JSON.stringify([{text: "S3"}, {text: "S4"}]),
          df: '2019-01-01',
          dt: '2019-03-01'
        }
      })
    })

    it("queries the prices api", () => {
      expect(axiosMock.get).toHaveBeenCalledWith('/prices/S3/from/2019-01-01/to/2019-03-01')
      expect(axiosMock.get).toHaveBeenCalledWith('/prices/S4/from/2019-01-01/to/2019-03-01')
    })

    it('updates the chart data', () => {
      expect(wrapper.vm.chart.data.datasets.length).toBe(2)
      expect(wrapper.vm.chart.data.datasets[0].data).toEqual(
        priceApiResponse.data.map(({date, close}) => ({x: parseISO(date), y: parseFloat(close)}))
      )
      expect(wrapper.vm.chart.data.datasets[1].data).toEqual(
        priceApiResponse.data.map(({date, close}) => ({x: parseISO(date), y: parseFloat(close)}))
      )
    })
  })

  describe('when the route is updated', () => {
    beforeEach(() => {
      wrapper.vm.$options.beforeRouteUpdate.call(wrapper.vm, {
        query: {
          s: JSON.stringify([{text: 'C1'}, {text: 'C2'}]),
          df: '2019-01-01',
          dt: '2019-03-01'
        }
      }, null, jest.fn())

      wrapper.vm.chart.data.datasets = []
    })

    it('updates the stocks', () => {
      expect(wrapper.vm.stocks).toEqual({
        tags: [{text: 'C1'}, {text: 'C2'}],
        dateFrom: parseISO('2019-01-01'),
        dateTo: parseISO('2019-03-01')
      })
    })

    it("queries the prices api", () => {
      expect(axiosMock.get).toHaveBeenCalledWith('/prices/C2/from/2019-01-01/to/2019-03-01')
      expect(axiosMock.get).toHaveBeenCalledWith('/prices/C1/from/2019-01-01/to/2019-03-01')
    })

    it('updates the chart data', () => {
      expect(wrapper.vm.chart.data.datasets.length).toBe(2)
      expect(wrapper.vm.chart.data.datasets[0].data).toEqual(
        priceApiResponse.data.map(({date, close}) => ({x: parseISO(date), y: parseFloat(close)}))
      )
      expect(wrapper.vm.chart.data.datasets[1].data).toEqual(
        priceApiResponse.data.map(({date, close}) => ({x: parseISO(date), y: parseFloat(close)}))
      )
    })
  })
})
