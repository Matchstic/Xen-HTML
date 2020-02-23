<template>
    <div class="page homescreen-page">
        <div class="page-content">
            <slot />

            <div class="page-header">
                <h1>Homescreen</h1>
                <h2>Widgets can be placed on any page with app icons</h2>
            </div>

            <div class="page-detail">
                <p>These widgets move when you swipe between pages. They can be configured by editing the Homescreen layout, then pressing <code>Add Widget</code>.</p>
            </div>

            <div class="page-diagram">
                <DeviceFrame>
                    <div class="page-diagram-content">
                        <div class="icon-container" :class="{ ipad: deviceIsIpad }">
                            <div v-for="i in iconCount" :key="i" class="icon">
                                <div class="background" />
                                <span />
                            </div>
                        </div>

                        <WidgetMusic :class="{ ipad: deviceIsIpad }" />
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
import WidgetMusic from '../components/widget-music.vue';

@Component({
    name: 'homescreenpage',
    components: {
        DeviceFrame,
        WidgetMusic
    }
})
export default class HomescreenPage extends Vue {
    get iconCount() {
        return this.deviceIsIpad ? 14 : 6;
    }

    get deviceIsIpad() {
        return navigator.userAgent.indexOf("iPhone;") === -1;
    }
}
</script>

<style lang="scss">

.homescreen-page {
    .page-diagram-content {
        .icon-container {
            height: 100%;
            width: 100%;

            display: grid;
            grid-template-columns:  auto auto auto auto;
            grid-auto-rows: 15%;

            padding: 10% 4% 0 4%;

            .icon {
                .background {
                    background-color: rgba(255, 255, 255, 0.7);
                    border-radius: 25%;

                    height: 0;
                    padding-bottom: 80%;
                    width: 80%;

                    margin: 0 auto;
                }

                span {
                    width: 70%;
                    height: 6%;

                    display: block;
                    position: relative;

                    background-color: rgba(255, 255, 255, 0.2);
                    border-radius: 2px;

                    margin: 0 auto;
                    margin-top: 18%;
                }

                height: 100%;
            }
        }

        .icon-container.ipad {
            grid-template-columns:  auto auto auto auto auto auto;
            grid-auto-rows: 12%;

            padding: 4% 4% 0 4%;

            .icon {
                transform: scale(0.6);
            }
        }

        .widget-music {
            position: absolute;

            top: 36%;

            &.ipad {
                top: calc(32% + 45px);
            }

            left: 6%;
            width: calc(100% - 12%);

            max-width: 240px;
        }
    }
}

</style>