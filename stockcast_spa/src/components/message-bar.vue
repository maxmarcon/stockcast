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
<script>
    export default {
        props: {
            seconds: {
                type: Number,
                default: 5
            },
            variant: {
                type: String,
                default: "info"
            }
        },
        data: () => ({
            dismissCountDown: 0,
            errorMsg: null
        }),
        methods: {
            countDownChanged(dismissCountDown) {
                this.dismissCountDown = dismissCountDown;
            },
            show(errorMsg) {
                this.errorMsg = errorMsg;
                this.dismissCountDown = (this.seconds > 0 ? this.seconds : true);
            }
        }
    }
</script>
