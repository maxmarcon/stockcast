import stockViewer from '@/components/stock-viewer'
import bootstrapVue from 'bootstrap-vue'
import {createLocalVue, mount} from '@vue/test-utils'

const localVue = createLocalVue()
localVue.use(bootstrapVue)

let routerMock
let wrapper

describe('stockViewer', () => {

  beforeEach(() => {
    routerMock = {
      push: jest.fn()
    }

    wrapper = mount(stockViewer, {
      propsData: {
        initialTags: [{text: 'S1'}, {text: 'S2'}]
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

  // TODO add dates
  it('initializes the stocks with tags', () => {
    expect(wrapper.vm.stocks).toEqual(expect.objectContaining({
      tags: [{text: 'S1'}, {text: 'S2'}]
    }))
  })

  describe('when new tags are entered', () => {

    beforeEach(() => {
      wrapper.find('stockperiodpicker-stub').vm.$emit('input', {tags: [{text: "S3"}, {text: "S4"}]})
    })

    it("the url query parameters are updated", () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        name: "stocks",
        query: {s: JSON.stringify([{text: "S3"}, {text: "S4"}])}
      })
    })
  })

  describe('when all tags are deleted', () => {

    beforeEach(() => {
      wrapper.find('stockperiodpicker-stub').vm.$emit('input', {tags: []})
    })

    it("the url query parameters are updated", () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        name: "stocks"
      })
    })
  })

  describe('when the time period changes', () => {
    //TODO
  })

  describe('when the route is updated', () => {
    beforeEach(() => {
      wrapper.vm.$options.beforeRouteUpdate.call(wrapper.vm, {query: {s: JSON.stringify([{text: 'C1'}, {text: 'C2'}])}}, null, jest.fn())
    })

    it('the form fields are updated', () => {
      expect(wrapper.vm.stocks.tags).toEqual([{text: 'C1'}, {text: 'C2'}])
    })
  })
})
