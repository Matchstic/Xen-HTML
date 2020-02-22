<template>
    <div class="widget-music">
        <div class="widget-music-container">
            <div class="artwork">
                <Icon icon="music" />
            </div>

            <div class="description">
                <div class="description-item main" />
                <div class="description-item subtitle" />
            </div>
        </div>

        <div class="controls">
            <Icon class="control-item" icon="previous" />
            <Icon class="control-item" icon="play" />
            <Icon class="control-item" icon="next" />
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';
import Icon from './svg-icon.vue';

@Component({
    name: 'widget-music',
    components: {
        Icon
    }
})
export default class WidgetMusic extends Vue {

}
</script>

<style lang="scss">

.widget-music {
    width: 100%;

    .controls {
        display: flex;
        flex-direction: row;
        align-items: center;
        justify-content: space-between;

        position: absolute;
        bottom: -15px;
        right: var(--padding-h-small);

        background-color: var(--app-color);
        border-radius: 10px;
        height: 20px;
        width: 80px;

        padding: 5px var(--padding-h-small);

        .control-item {
            transform: scale(0.5);
        }
    }
}

.widget-music-container {
    background-color: rgba(255, 255, 255, 0.2);
    height: 60px;
    width: 100%;

    border-radius: 5px;

    display: flex;
    flex-direction: row;
    align-items: center;

    .artwork {
        flex: 0 0 35px;
        background-color: var(--app-color);
        width: 35px;
        height: 35px;
        border-radius: 5px;
        margin: var(--padding-v) var(--padding-h);

        display: flex;
        flex-direction: row;
        align-items: center;

        .inline-block {
            margin: 0 auto;

            svg {
                fill: var(--text-color);
            }
        }
    }

    .description {
        flex: 1 1 auto;
        padding-right: var(--padding-h);

        .description-item {
            height: 12px;
            background-color: var(--text-color);
            border-radius: 3px;

            &.main {
                margin-bottom: var(--padding-v-small);
                width: 120px;
            }

            &.subtitle {
                width: 70px;
                background-color: var(--subtext-color);
            }
        }
    }
}

</style>