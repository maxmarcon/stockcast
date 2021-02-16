<template>
  <b-alert :show="dismissCountDown"
           fade
           :dismissible="seconds <= 0"
           :variant="variant"
           @dismissed="dismissCountDown = false"
           @dismiss-count-down="countDownChanged">
    {{ errorMsg }}
  </b-alert>
</template>
<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import Vue, {PropType} from 'vue'


interface State {
  dismissCountDown: number | boolean,
  errorMsg: string | undefined
}

export default Vue.extend({
  props: {
    seconds: {
       type: Number, default: 5
    },
    variant: {
      type: String
    },
  },
  data(): State {
    return {
      dismissCountDown: 0,
      errorMsg: undefined
    }
  },
  methods: {
    countDownChanged (dismissCountDown: number): void {
      this.dismissCountDown = dismissCountDown
    },
    show (errorMsg: string): void {
      this.errorMsg = errorMsg
      this.dismissCountDown = (this.seconds > 0 ? this.seconds : true)
    }
  }
})
</script>
