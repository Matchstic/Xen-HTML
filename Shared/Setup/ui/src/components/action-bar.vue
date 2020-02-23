<template>
    <div class="action-bar">
        <div class="action-bar-platter">
            <div class="action-bar-item" @click.prevent.stop="$emit('back')" v-if="currentPage > 0">
                <Icon icon="back" /><span class="action-bar-label">Back</span>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';
import Icon from '../components/svg-icon.vue';

@Component({
    name: 'actionbar',
    components: {
        Icon,
    }
})
export default class ActionBar extends Vue {
    @Prop()
    readonly currentPage!: number;
}
</script>

<style lang="scss">

.action-bar {
    width: 100%;
    margin-top: var(--padding-v);
    margin-top: calc(var(--padding-v) + env(safe-area-inset-top));

    .action-bar-platter {
        width: 100%;
        border-radius: 30px;
        height: 22px;

        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;

        padding: 0;
    }

    .action-bar-item {
        .action-bar-label {
            margin-left: 8px;
        }

        svg {
            height: 18px;
            width: 18px;
        }

        cursor: pointer;
        font-size: 18px;

        &:active {
            opacity: 0.6;
        }
    }
}

</style>