//@ts-ignore
import template from './message-bar.html'
import {Prop, Component} from "vue-property-decorator";
import Vue from 'vue'

@Component({
    template
})
export default class MessageBar extends Vue {

    @Prop({type: Number, default: 5})
    private seconds!: number

    @Prop({type: String, default: 'info'})
    private variant!: string

    private dismissCountDown: number | boolean = 0;

    private errorMsg: string | null = null

    public countDownChanged(dismissCountDown: number): void {
        this.dismissCountDown = dismissCountDown;
    }

    public show(errorMsg: string): void {
        this.errorMsg = errorMsg;
        this.dismissCountDown = (this.seconds > 0 ? this.seconds : true);
    }
};