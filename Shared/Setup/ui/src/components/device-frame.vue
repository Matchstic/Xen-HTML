<template>
    <div class="device-frame-content">
        <div class="device-frame-content-framed" :class="{ ipad: deviceIsIpad }">
            <slot />
        </div>
        <Icon class="device-frame-ipad" icon="device-ipad-frame" v-if="deviceIsIpad" />
        <Icon class="device-frame" icon="device-frame" v-else />
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';
import Icon from './svg-icon.vue';

@Component({
    name: 'deviceframe',
    components: {
        Icon,
    }
})
export default class DeviceFrame extends Vue {
    get deviceIsIpad() {
        return navigator.userAgent.indexOf("iPhone;") === -1;
    }
}
</script>

<style lang="scss">

.device-frame-content {
    position: relative;

    height: fit-content;
    width: fit-content;

    .device-frame {
        height: 100%;
        width: 90vw;

        position: relative;
        z-index: 1;
    }

    .device-frame-ipad {
        margin-top: 36px;
        height: 100%;
        width: 50vw;

        position: relative;
        z-index: 1;
    }

    .device-frame-content-framed {
        position: absolute;
        top: 11.5%;
        left: 17.5%;
        right: 17%;

        z-index: 0;

        height: calc(100% - 20%);
        width: calc(100% - 17% - 17.5%);

        overflow: hidden;

        * {
            padding: 0;
            margin: 0;
        }

        &.ipad {
            top: calc(36px + 3%);
            left: 4.6%;
            right: 5%;

            height: calc(100% - 36px - 3%);
            width: calc(100% - 5% - 5%);
        }
    }
}

</style>