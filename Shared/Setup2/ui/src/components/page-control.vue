<template>
    <div class="page-control">
        <div class="page-control-platter">
            <div class="page-control-dot"
                :class="{ active: n === currentPage + 1 }"
                :key="n"
                v-for="n in pageCount">
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';

@Component({
    name: 'pagecontrol'
})
export default class PageControl extends Vue {
    @Prop()
    readonly pageCount!: number;

    @Prop()
    readonly currentPage!: number;
}
</script>

<style lang="scss">



</style>