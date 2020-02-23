<template>
    <div class="inline-block" v-html="require('!!html-loader!./../assets/' + this.icon + '.svg')"></div>
</template>

<style module>
svg {
    fill: currentColor;
    min-height: 18px;
    margin-top: -4px;
    vertical-align: middle;
    min-width: 18px;
}
</style>
<style scoped>
.inline-block {
    display: inline-block;
}
</style>

<script>
export default {
    props: ['icon'],
}
</script>