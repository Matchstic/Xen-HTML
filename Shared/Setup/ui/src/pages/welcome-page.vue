<template>
    <div class="page welcome-page">
        <div class="page-content">
            <slot />

            <div class="page-header">
                <h1>Xen HTML has been successfully installed</h1>
                <h2>A world of customisation awaits</h2>
            </div>

        </div>

         <div class="page-control">
            <div class="page-control-platter">
                <button class="next-button" @click.prevent.stop="$emit('next')">Get Started</button>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator';

@Component({
    name: 'welcomepage',
    components: {
    }
})
export default class WelcomePage extends Vue {

}
</script>

<style lang="scss">

</style>