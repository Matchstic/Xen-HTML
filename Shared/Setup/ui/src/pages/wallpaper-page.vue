<template>
    <div class="page wallpaper-page">
        <div class="page-content">
            <slot />

            <div class="page-header">
                <h1>Wallpaper</h1>
                <h2>You can set widgets to appear as part of your wallpaper</h2>
            </div>

            <div class="page-detail">
                <p>Your content can move around on top of these widgets. They can be configured under <code>Background Widgets</code> in Settings.</p>
            </div>

            <div class="page-diagram">
                <DeviceFrame>
                    <div class="page-diagram-content">
                        <vue-particles class="particles-bg" color="#fff" />

                        <transition :name="transitionDirection === 1 ? 'slide-advance' : 'slide-retreat'">
                            <div class="wallpaper-page-diagram first" v-if="currentPage === 0" key="1">
                                <p>{{ currentTime }}</p>
                                <span />
                            </div>
                            <div class="wallpaper-page-diagram second" :class="{ ipad: deviceIsIpad }" v-else-if="currentPage === 1" key="2">
                                <div v-for="i in iconCount" :key="i" class="icon">
                                    <div class="background" />
                                    <span />
                                </div>
                            </div>
                        </transition>
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
import Icon from '../components/svg-icon.vue';
import DeviceFrame from '../components/device-frame.vue';

@Component({
    name: 'wallpaperpage',
    components: {
        Icon,
        DeviceFrame
    }
})
export default class WallpaperPage extends Vue {
    private transitionDirection: number = 1;
    private currentPage: number = 0;

    get currentTime() {
        const now = new Date();

        let hours: string = now.getHours() >= 10 ? '' + now.getHours() : '0' + now.getHours();
        let minutes: string = now.getMinutes() >= 10 ? '' + now.getMinutes() : '0' + now.getMinutes();
        return hours + ':' + minutes;
    }

    get iconCount() {
        return this.deviceIsIpad ? 14 : 6;
    }

    get deviceIsIpad() {
        return navigator.userAgent.indexOf("iPhone;") === -1;
    }

    mounted() {
        setInterval(() => {
            this.$nextTick(() => {
                if (this.currentPage === 1) {
                    this.transitionDirection = -1;
                    this.currentPage = 0;
                } else if (this.currentPage === 0) {
                    this.transitionDirection = 1;
                    this.currentPage = 1;
                }
            });
        }, 1500);
    }
}
</script>

<style lang="scss">

.particles-bg {
    width: 100%;
    height: 100%;

    position: absolute;
    z-index: 0;
}

.wallpaper-page-diagram {
    height: 100%;
    width: 100%;

    z-index: 1;

    &.first {
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
    }

    &.second {
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

    &.second.ipad {
        grid-template-columns:  auto auto auto auto auto auto;
        grid-auto-rows: 12%;

        padding: 4% 4% 0 4%;

        .icon {
            transform: scale(0.6);
        }
    }
}

</style>