import messageBar from '@/components/message-bar'
import BootstrapVue from 'bootstrap-vue'

import {createLocalVue, shallowMount} from '@vue/test-utils'

const localVue = createLocalVue();
localVue.use(BootstrapVue)

const MESSAGE = "I'm a message"
const VARIANT = 'danger'
const SECONDS = 10

let wrapper
let alert

describe('messageBar', () => {

    describe('without countdown', () => {

        beforeEach(async () => {

            wrapper = shallowMount(messageBar, {
                localVue,
                propsData: {
                    seconds: 0,
                    variant: VARIANT
                }
            })

            wrapper.vm.show(MESSAGE)
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

            wrapper = shallowMount(messageBar, {
                localVue,
                propsData: {
                    seconds: SECONDS,
                    variant: VARIANT
                }
            })

            wrapper.vm.show(MESSAGE)
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
