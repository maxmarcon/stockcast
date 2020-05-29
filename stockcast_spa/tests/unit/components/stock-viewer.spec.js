import stockViewer from '@/components/stock-viewer'
import bootstrapVue from 'bootstrap-vue'
import {createLocalVue, mount} from '@vue/test-utils'
import {parseISO} from 'date-fns'

const localVue = createLocalVue()
localVue.use(bootstrapVue)

let routerMock
let wrapper

describe('stockViewer', () => {

  beforeEach(() => {
    routerMock = {
      push: jest.fn(() => Promise.resolve())
    }

    wrapper = mount(stockViewer, {
      propsData: {
        tags: [{text: 'S1'}, {text: 'S2'}],
        dateFrom: parseISO('2020-01-01'),
        dateTo: parseISO('2020-03-01')
      },
      localVue,
      mocks: {
        $router: routerMock
      },
      stubs: ['messageBar', 'stockPeriodPicker']
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

  describe('when stocks are updated', () => {

    beforeEach(() => {
      wrapper.find('stockperiodpicker-stub').vm.$emit('input', {
        tags: [{text: "S3"}, {text: "S4"}],
        dateFrom: parseISO('2019-01-01'),
        dateTo: parseISO('2019-03-01')
      })
    })

    it("the url query parameters are updated", () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        name: "stocks",
        query: {
          s: JSON.stringify([{text: "S3"}, {text: "S4"}]),
          df: '2019-01-01',
          dt: '2019-03-01'
        }
      })
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
    })

    it('the form fields are updated', () => {
      expect(wrapper.vm.stocks).toEqual({
        tags: [{text: 'C1'}, {text: 'C2'}],
        dateFrom: parseISO('2019-01-01'),
        dateTo: parseISO('2019-03-01')
      })
    })
  })
})
