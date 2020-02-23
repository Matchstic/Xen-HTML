<template>
    <div class="page lockscreen-page">
        <div class="page-content">
            <slot />

            <div class="page-header">
                <h1>Lockscreen</h1>
                <h2>Widgets can be placed alongside, or replace, the iOS clock</h2>
            </div>

            <div class="page-detail">
                <p>These widgets move when you swipe between pages. They can be configured under <code>Lockscreen → Foreground Widgets</code> in Settings.</p>
            </div>

            <div class="page-diagram">
                <DeviceFrame>
                    <div class="page-diagram-content">
                        <p>{{ currentTime }}</p>
                        <span />

                        <WidgetWeather />
                    </div>
                </DeviceFrame>
            </div>
        </div>

        <div class="page-control">
            <div class="page-control-platter">
                <button class="next-button" @click.prevent.stop="$emit('next')">Next</button>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';
import DeviceFrame from '../components/device-frame.vue';
import WidgetWeather from '../components/widget-weather.vue';

@Component({
    name: 'lockscreenpage',
    components: {
        DeviceFrame,
        WidgetWeather
    }
})
export default class LockscreenPage extends Vue {
    get currentTime() {
        const now = new Date();

        let hours: string = now.getHours() >= 10 ? '' + now.getHours() : '0' + now.getHours();
        let minutes: string = now.getMinutes() >= 10 ? '' + now.getMinutes() : '0' + now.getMinutes();
        return hours + ':' + minutes;
    }
}
</script>

<style lang="scss">

.lockscreen-page {
    .page-diagram-content {

        &:before {
            height: 5%;
            width: 1px;

            content: '';
            display: block;
            position: relative;
        }

        p {
            font-size: 44px;

            width: 100%;
            text-align: center;
        }

        span {
            width: 50%;
            max-width: 120px;
            height: 11px;
            display: block;
            position: relative;

            background-color: rgba(255, 255, 255, 0.2);
            border-radius: 5px;

            margin: 0 auto;
            margin-top: 10px;
        }

        // Widgets

        .widget-weather {
            width: 90%;
            max-width: 240px;

            margin: 0 auto;
            margin-top: 10%;

        }
    }
}

</style>