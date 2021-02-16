import StockPeriodPicker from '@/components/stock-period-picker.vue'
import {Stock} from '@/utils/stock'
import bootstrapVue, {BFormDatepicker} from 'bootstrap-vue'
import VueTagsInput from '@johmun/vue-tags-input'
import {createLocalVue, mount, Wrapper} from '@vue/test-utils'
import {parseISO} from 'date-fns'

const localVue = createLocalVue()
localVue.use(bootstrapVue)
localVue.use(VueTagsInput)

let axiosMock: any
let wrapper: Wrapper<Vue>

const S1 = {symbol: 'S1', currency: 'EUR', name: 'Stock 1', isins: ['ISIN1', 'ISIN2'], figi: 'FIGI1'}
const S2 = {symbol: 'S2', currency: 'USD', name: 'Stock 2', isins: ['ISIN1', 'ISIN2'], figi: 'FIGI1'}

describe('Stock', () => {
  it('can be created from symbol', () => {
    const stock: Stock = Stock.fromSymbol(S1)

    expect(stock).toEqual(expect.objectContaining({
      symbol: 'S1',
      name: 'Stock 1',
      currency: 'EUR'
    }))

    expect(stock.text).toEqual('S1')
  })

  it('can be created from symbol and search terms', () => {
    const stock: Stock = Stock.fromSymbol(S1, ['ABC', '2020'])

    expect(stock).toEqual(expect.objectContaining({
      symbol: 'S1',
      name: 'Stock 1',
      currency: 'EUR'
    }))

    expect(stock.text).toEqual('S1')
  })

  it('can be created from symbol and search terms matching an isin', () => {
    const stock: Stock = Stock.fromSymbol(S1, ['ABC', 'ISI'])

    expect(stock).toEqual(expect.objectContaining({
      symbol: 'S1',
      name: 'Stock 1',
      currency: 'EUR',
      isin: 'ISIN1'
    }))

    expect(stock.text).toEqual('S1')
  })

  it('can be created from symbol and search terms matching figi', () => {
    const stock: Stock = Stock.fromSymbol(S1, ['FI'])

    expect(stock).toEqual(expect.objectContaining({
      symbol: 'S1',
      name: 'Stock 1',
      currency: 'EUR',
      figi: 'FIGI1'
    }))

    expect(stock.text).toEqual('S1')
  })
})

describe('StockPeriodPicker', () => {
  beforeEach(() => {
    axiosMock = {
      get: jest.fn(async () => ({
          data: {
            data: [
              S1, S2
            ]
          }
        })
      )
    }

    wrapper = mount(StockPeriodPicker, {
      localVue,
      propsData: {
        value: {
          stocks: [Stock.fromSymbol(S1)],
          dateFrom: parseISO('2015-01-01'),
          dateTo: parseISO('2015-03-01')
        },
        maxTags: 10
      },
      mocks: {
        axios: axiosMock
      },
      stubs: ['b-icon']
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
    expect(wrapper.findComponent(VueTagsInput).vm.$props.tags).toEqual([expect.objectContaining({text: 'S1'})])
    expect(wrapper.findComponent(VueTagsInput).vm.$props.maxTags).toEqual(10)
  })

  it('initializes the date-from input', () => {
    expect(wrapper.findAllComponents(BFormDatepicker).at(0).vm.$props.value).toEqual(parseISO('2015-01-01'))
  })

  it('initializes the date-to input', () => {
    expect(wrapper.findAllComponents(BFormDatepicker).at(1).vm.$props.value).toEqual(parseISO('2015-03-01'))
  })

  describe('when a new tag is entered', () => {
    beforeEach(() => {
      wrapper.findComponent(VueTagsInput).vm.$emit('tags-changed', [{text: 'S2'}])
    })

    it('value.tags is updated', () => {
      expect(wrapper.vm.$props.value.stocks).toEqual([{text: 'S2'}])
    })

    it('and the input event is emitted', () => {
      expect(wrapper.emitted('input')).toEqual([expect.arrayContaining([expect.objectContaining({stocks: [{text: 'S2'}]})])])
    })
  })

  describe('when a new date-from is entered', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(0).vm.$emit('input', parseISO('2020-01-01'))
    })

    it('value.dateFrom is updated', () => {
      expect(wrapper.vm.$props.value.dateFrom).toEqual(parseISO('2020-01-01'))
    })

    it('and the input event is emitted', () => {
      expect(wrapper.emitted().input).toEqual([expect.arrayContaining([expect.objectContaining({dateFrom: parseISO('2020-01-01')})])])
    })
  })

  describe('when a new date-to is entered', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(1).vm.$emit('input', parseISO('2020-01-01'))
    })

    it('value.dateTo is updated', () => {
      expect(wrapper.vm.$props.value.dateTo).toEqual(parseISO('2020-01-01'))
    })

    it('and the input event is emitted', () => {
      expect(wrapper.emitted().input).toEqual([expect.arrayContaining([expect.objectContaining({dateTo: parseISO('2020-01-01')})])])
    })
  })

  describe('when a date-from is entered which is later than date-to', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(0).vm.$emit('input', parseISO('2015-03-02'))
    })

    it('date-to is set to date-from', () => {
      expect(wrapper.vm.$props.value.dateTo).toEqual(wrapper.vm.$props.value.dateFrom)
    })
  })

  describe('when a date-to is entered which is before date-from', () => {
    beforeEach(() => {
      wrapper.findAllComponents(BFormDatepicker).at(1).vm.$emit('input', parseISO('2014-12-31'))
    })

    it('date-from is set to date-to', () => {
      expect(wrapper.vm.$props.value.dateFrom).toEqual(wrapper.vm.$props.value.dateTo)
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
        {params: expect.objectContaining({q: '123'})}
      )
    })

    it('stores the result of the search', () => {
      expect(wrapper.vm.$data.autocompleteItems).toEqual([
        expect.objectContaining({symbol: 'S1', name: 'Stock 1'}),
        expect.objectContaining({symbol: 'S2', name: 'Stock 2'})
      ])
    })
  })

  describe('when entering an ISIN in the stocks input field', () => {
    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.findComponent(VueTagsInput).find('input').setValue('IsIN2')
    })

    beforeEach(() => jest.runAllTimers())

    it('issues a search request to the server after delay', () => {
      expect(axiosMock.get).toHaveBeenCalledWith(
        'stocks/search',
        {params: expect.objectContaining({q: 'IsIN2'})}
      )
    })

    it('stores the result of the search including the matching ISIN', () => {
      expect(wrapper.vm.$data.autocompleteItems).toEqual([
        expect.objectContaining({symbol: 'S1', name: 'Stock 1', isin: 'ISIN2'}),
        expect.objectContaining({symbol: 'S2', name: 'Stock 2', isin: 'ISIN2'})
      ])
    })
  })

  describe('when entering a FIGI in the stocks input field', () => {
    beforeEach(() => {
      jest.useFakeTimers()
      wrapper.findComponent(VueTagsInput).find('input').setValue('FiGI1')
    })

    beforeEach(() => jest.runAllTimers())

    it('issues a search request to the server after delay', () => {
      expect(axiosMock.get).toHaveBeenCalledWith(
        'stocks/search',
        {params: expect.objectContaining({q: 'FiGI1'})}
      )
    })

    it('stores the result of the search including the matching FIGI', () => {
      expect(wrapper.vm.$data.autocompleteItems).toEqual([
        expect.objectContaining({symbol: 'S1', name: 'Stock 1', figi: 'FIGI1'}),
        expect.objectContaining({symbol: 'S2', name: 'Stock 2', figi: 'FIGI1'})
      ])
    })
  })

  describe('when text is entered in the stocks input field and axios returns an error', () => {
    beforeEach(() => {
      axiosMock = {
        get: jest.fn(() => Promise.reject('AxiosError'))
      }

      wrapper = mount(StockPeriodPicker, {
        localVue,
        mocks: {
          axios: axiosMock
        },
        stubs: ['b-icon']
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
        {params: expect.objectContaining({q: '1234'})}
      )
      expect(axiosMock.get).toHaveBeenCalledTimes(1)
    })
  })
})
