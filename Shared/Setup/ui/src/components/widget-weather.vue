<template>
    <div class="widget-weather">
        <Icon class="current-condition" icon="sun" />

        <div class="description">
            <div class="description-item main" />
            <div class="description-item subtitle" />
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';
import Icon from './svg-icon.vue';

@Component({
    name: 'widget-weather',
    components: {
        Icon
    }
})
export default class WidgetWeather extends Vue {

}
</script>

<style lang="scss">

.widget-weather {
    background-color: rgba(255, 255, 255, 0.2);
    height: 60px;
    width: 100%;

    border-radius: 5px;

    display: flex;
    flex-direction: row;
    align-items: center;

    .current-condition {
        margin: var(--padding-v) var(--padding-h);
    }

    .description {
        flex: 1 1 auto;

        .description-item {
            height: 12px;
            max-width: calc(100% - var(--padding-h));
            background-color: var(--text-color);
            border-radius: 3px;

            &.main {
                margin-bottom: var(--padding-v-small);
                width: 60px;
            }

            &.subtitle {
                width: 120px;
                background-color: var(--subtext-color);
            }
        }
    }
}

</style>