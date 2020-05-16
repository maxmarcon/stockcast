import stockViewer from '@/components/stock-viewer'

import {shallowMount} from '@vue/test-utils'

let wrapper

describe('stockViewer', () => {

    beforeEach(() => {
        wrapper = shallowMount(stockViewer)
    })

    it('can be mounted', () => {
        expect(wrapper.isVueInstance()).toBeTruthy()
    })
})
