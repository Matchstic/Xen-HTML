<template>
    <div class="page end-page">
        <div class="page-content">
            <slot />

            <div class="page-header">
                <h1>Configuration</h1>
                <h2>You can adjust iOS to match your widgets</h2>
            </div>

            <div class="page-detail">
                <p>Options are provided for both the Lockscreen and Homescreen to hide UI elements, and to fine-tune how widgets are displayed.</p>
            </div>
        </div>

        <div class="page-diagram-eh">
            <Icon icon="ios-settings" />
        </div>

        <div class="page-control">
            <div class="page-control-platter">
                <button class="next-button" @click.prevent.stop="$emit('next')">Finish</button>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';
import Icon from '../components/svg-icon.vue';

@Component({
    name: 'endpage',
    components: {
        Icon
    }
})
export default class EndPage extends Vue {

}
</script>

<style lang="scss">

.end-page {
    height: 100%;
}

.end-page .page-diagram-eh {
    opacity: 0.1;
    width: 100%;
    height: fit-content;

    display: flex;
    flex-direction: row;
    justify-content: center;

    svg {
        width: 70vw;
        height: 100%;
    }

    position: absolute;
    bottom: -64px;
}

@media only screen and (min-width: 600px) {
    .end-page .page-diagram-eh {
        svg {
            width: 40vw;
            height: 100%;
        }

        position: absolute;
        bottom: -64px;
    }
}

</style>