import MessageBar from '@/components/message-bar.vue'
import BootstrapVue from 'bootstrap-vue'

import { createLocalVue, shallowMount, Wrapper } from '@vue/test-utils'

const localVue = createLocalVue()
localVue.use(BootstrapVue)

const MESSAGE = "I'm a message"
const VARIANT = 'danger'
const SECONDS = 10

let wrapper: Wrapper<MessageBar>
let alert: Wrapper<any>

describe('messageBar', () => {
  it('can be mounted', () => {
    wrapper = shallowMount(MessageBar, { localVue })
    expect(wrapper.exists()).toBeTruthy
  })

  describe('without countdown', () => {
    beforeEach(async () => {
      wrapper = shallowMount(MessageBar, {
        localVue,
        propsData: {
          seconds: 0,
          variant: VARIANT
        }
      });

      (wrapper.vm as any).show(MESSAGE)
    })

    it('shows a permanent dismissable message', () => {
      alert = wrapper.find('b-alert-stub')

      expect(alert.attributes('show')).toBe('true')
      expect(alert.attributes('dismissible')).toBeTruthy()
      expect(alert.attributes('variant')).toBe(VARIANT)
      expect(alert.text()).toBe(MESSAGE)
    })
  })

  describe('with countdown', () => {
    beforeEach(async () => {
      wrapper = shallowMount(MessageBar, {
        localVue,
        propsData: {
          seconds: SECONDS,
          variant: VARIANT
        }
      });

      (wrapper.vm as any).show(MESSAGE)
    })

    it('shows a message with countdown', () => {
      alert = wrapper.find('b-alert-stub')

      expect(alert.attributes('show')).toEqual(SECONDS.toString())
      expect(alert.attributes('dismissible')).toBeFalsy()
      expect(alert.attributes('variant')).toBe(VARIANT)
      expect(alert.text()).toBe(MESSAGE)
    })
  })
})
