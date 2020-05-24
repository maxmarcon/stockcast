import stockViewer from '@/components/stock-viewer'
import bootstrapVue from 'bootstrap-vue'
import VueTagsInput from '@johmun/vue-tags-input';
import {createLocalVue, mount} from '@vue/test-utils'

const localVue = createLocalVue()
localVue.use(bootstrapVue)
localVue.use(VueTagsInput)

let axiosMock
let routerMock
let wrapper

describe('stockViewer', () => {

  beforeEach(() => {
    axiosMock = {
      get: jest.fn(async () => ({data: {data: [{symbol: "S1"}, {symbol: "S2"}]}}))
    }

    routerMock = {
      push: jest.fn()
    }

    wrapper = mount(stockViewer, {
      localVue,
      mocks: {
        axios: axiosMock,
        $router: routerMock
      },
      stubs: ['messageBar']
    })
  })

  it('can be mounted', () => {
    expect(wrapper).toBeTruthy()
  })

  it('renders the stocks input field', () => {
    expect(wrapper.find('input#stocks').exists()).toBeTruthy()
  })

  describe('when props are passed', () => {
    beforeEach(() => {
      wrapper = mount(stockViewer, {
        localVue,
        propsData: {
          symbols: ['S1', 'S2']
        },
        stubs: ['messageBar']
      })
    })

    it('they are used to fill the form fields', () => {
      expect(wrapper.vm.tags).toEqual([{text: 'S1'}, {text: 'S2'}])
    })
  })

  describe('when entering text in the stocks input field', () => {

    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.get('input#stocks').setValue("123")
    })

    beforeEach(() => jest.runAllTimers())

    it('issues a search request to the server after delay', () => {
      expect(axiosMock.get).toHaveBeenCalledWith(
        'stocks/search',
        {params: expect.objectContaining({q: "123"})}
      )
    })

    it('stores the result of the search', () => {
      expect(wrapper.vm.autocompleteItems).toEqual([{text: "S1"}, {text: "S2"}])
    })
  })

  describe('when entering text in the search input field in quick succession', () => {

    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.get('input#stocks').setValue("123")
      wrapper.get('input#stocks').setValue("1234")
    })

    beforeEach(() => jest.runAllTimers())

    it('issues a search request to the server for the last value entered', () => {
      expect(axiosMock.get).toHaveBeenCalledWith(
        'stocks/search',
        {params: expect.objectContaining({q: "1234"})}
      )
      expect(axiosMock.get).toHaveBeenCalledTimes(1)
    })
  })

  describe('when new tags are entered', () => {

    beforeEach(() => {
      // await wrapper.get('div.vue-tags-input').trigger('tags-changed', [{text: "S1"}, {text: "S2"}])
      // for some reason, the above does not work and we have to resort to this:
      wrapper.vm.tagsChanged([{text: "S1"}, {text: "S2"}])
    })

    it("the url query parameters are updated", () => {
      expect(routerMock.push).toHaveBeenCalledWith({name: "stocks", query: {s: ["S1", "S2"]}})
    })
  })

  describe('when the route is updated', () => {
    beforeEach(() => {
      wrapper.vm.$options.beforeRouteUpdate.call(wrapper.vm, {query: {s: ['C1', 'C2']}}, null, jest.fn())
    })

    it('the form fields are updated', () => {
      expect(wrapper.vm.tags).toEqual([{text: 'C1'}, {text: 'C2'}])
    })
  })
})
