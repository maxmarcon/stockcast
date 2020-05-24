import Vue from 'vue'
import VueRouter from 'vue-router'
import {BootstrapVue, IconsPlugin} from 'bootstrap-vue'
import VueTagsInput from '@johmun/vue-tags-input';
import axios from 'axios'
import VueAxios from "vue-axios";
import './scss/main.scss'

import App from '@/components/app.vue'
import StockViewer from '@/components/stock-viewer.vue'
import MessageBar from '@/components/message-bar.vue'
// Install BootstrapVue
Vue.use(BootstrapVue)
// Optionally install the BootstrapVue icon components plugin
Vue.use(IconsPlugin)
Vue.use(VueAxios, axios)

Vue.axios.defaults.baseURL = [process.env.VUE_APP_APIBASE, 'v1'].join('/')

Vue.config.productionTip = false

Vue.component('vueTagsInput', VueTagsInput)
Vue.component('messageBar', MessageBar)

Vue.use(VueRouter)

const router = new VueRouter({
  mode: 'history',
  routes: [
    {name: 'stocks', path: '/stocks', component: StockViewer},
    {path: '*', redirect: {name: 'stocks'}}
  ]
})

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')
