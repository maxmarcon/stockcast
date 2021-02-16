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
import Vue from 'vue'

export default Vue.extend({
  props: {
    seconds: {
      type: Number, default: 5
    },
    variant: {
      type: String
    },
  },
  data() {
    return {
      dismissCountDown: 0 as number | boolean,
      errorMsg: null as string
    }
  },
  methods: {
    countDownChanged(dismissCountDown: number): void {
      this.dismissCountDown = dismissCountDown
    },
    show(errorMsg: string): void {
      this.errorMsg = errorMsg
      this.dismissCountDown = (this.seconds > 0 ? this.seconds : true)
    }
  }
})
</script>
