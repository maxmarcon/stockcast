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
import Vue from 'vue'

@Component({})
export default class MessageBar extends Vue {
  @Prop({ type: Number, default: 5 })
  seconds!: number

  @Prop({ type: String, default: 'info' })
  variant!: string

  dismissCountDown: number | boolean = 0;

  errorMsg: string | null = null

  countDownChanged (dismissCountDown: number): void {
    this.dismissCountDown = dismissCountDown
  }

  show (errorMsg: string): void {
    this.errorMsg = errorMsg
    this.dismissCountDown = (this.seconds > 0 ? this.seconds : true)
  }
}
</script>
