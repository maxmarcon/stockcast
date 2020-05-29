import stockPeriodPicker from '@/components/stock-period-picker'
import bootstrapVue, {BFormDatepicker} from 'bootstrap-vue'
import VueTagsInput from '@johmun/vue-tags-input';
import {createLocalVue, mount} from '@vue/test-utils'
import {parseISO} from 'date-fns'

const localVue = createLocalVue()
localVue.use(bootstrapVue)
localVue.use(VueTagsInput)

let axiosMock
let wrapper

describe('stockPeriodPicker', () => {

  beforeEach(() => {
    axiosMock = {
      get: jest.fn(async () => ({data: {data: [{symbol: "S1"}, {symbol: "S2"}]}}))
    }

    wrapper = mount(stockPeriodPicker, {
      localVue,
      propsData: {
        value: {
          tags: [{text: 'S1'}],
          dateFrom: parseISO('2015-01-01'),
          dateTo: parseISO('2015-03-01')
        }
      },
      mocks: {
        axios: axiosMock
      }
    })
  })

  it('can be mounted', () => {
    expect(wrapper).toBeTruthy()
  })

  it('renders the tagged stock input', () => {
    expect(wrapper.findComponent(VueTagsInput).exists()).toBeTruthy()
  })

  it('renders the date-from and date-to input', () => {
    expect(wrapper.findAllComponents(BFormDatepicker).length).toBe(2)
  })

  it('initializes the tagged stock input', () => {
    expect(wrapper.findComponent(VueTagsInput).vm.tags).toEqual([{text: 'S1'}])
    expect(wrapper.findComponent(VueTagsInput).vm.maxTags).toEqual(10)
  })

  it('initializes the date-from input', () => {
    expect(wrapper.findAllComponents(BFormDatepicker).at(0).vm.value).toEqual(parseISO('2015-01-01'))
  })

  it('initializes the date-to input', () => {
    expect(wrapper.findAllComponents(BFormDatepicker).at(1).vm.value).toEqual(parseISO('2015-03-01'))
  })

  describe('when a new tag is entered', () => {
    beforeEach(() => {
      wrapper.findComponent(VueTagsInput).vm.$emit('tags-changed', [{text: 'S2'}])
    })

    it('value.tags is updated', () => {
      expect(wrapper.vm.value.tags).toEqual([{text: 'S2'}])
    })

    it('and the input event is emitted', () => {
      expect(wrapper.emitted().input).toEqual([[expect.objectContaining({tags: [{text: 'S2'}]})]])
    })
  })

  describe('when a new date-from is entered', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(0).vm.$emit('input', parseISO('2020-01-01'))
    })

    it('value.dateFrom is updated', () => {
      expect(wrapper.vm.value.dateFrom).toEqual(parseISO('2020-01-01'))
    })

    it('and the input event is emitted', () => {
      expect(wrapper.emitted().input).toEqual([[expect.objectContaining({dateFrom: parseISO('2020-01-01')})]])
    })
  })

  describe('when a new date-to is entered', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(1).vm.$emit('input', parseISO('2020-01-01'))
    })

    it('value.dateTo is updated', () => {
      expect(wrapper.vm.value.dateTo).toEqual(parseISO('2020-01-01'))
    })

    it('and the input event is emitted', () => {
      expect(wrapper.emitted().input).toEqual([[expect.objectContaining({dateTo: parseISO('2020-01-01')})]])
    })
  })

  describe('when a date-from is entered which is later than date-to', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(0).vm.$emit('input', parseISO('2015-03-02'))
    })

    it('date-to is set to date-from', () => {
      expect(wrapper.vm.value.dateTo).toEqual(wrapper.vm.value.dateFrom)
    })
  })

  describe('when a date-to is entered which is before than date-from', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(1).vm.$emit('input', parseISO('2014-12-31'))
    })

    it('date-from is set to date-to', () => {
      expect(wrapper.vm.value.dateFrom).toEqual(wrapper.vm.value.dateTo)
    })
  })

  describe('when entering text in the stocks input field', () => {

    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.findComponent(VueTagsInput).find('input').setValue('123')
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

  describe('when entering text in the stocks input field and axios returns an error', () => {

    beforeEach(() => {
      axiosMock = {
        get: jest.fn(() => Promise.reject('AxiosError'))
      }

      wrapper = mount(stockPeriodPicker, {
        localVue,
        mocks: {
          axios: axiosMock
        }
      })
    })

    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.findComponent(VueTagsInput).find('input').setValue('123')
    })

    beforeEach(() => jest.runAllTimers())

    it('the error is emitted', () => {
      expect(wrapper.emitted().error).toEqual([['AxiosError']])
    })
  })


  describe('when entering text in the search input field in quick succession', () => {

    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.findComponent(VueTagsInput).find('input').setValue('123')
      wrapper.findComponent(VueTagsInput).find('input').setValue('1234')
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
})
