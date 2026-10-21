<script setup>
defineProps(['title'])
</script>

<template>
  <div class="pagetitle">
    <span>{{ title }}</span>
    <span class="right" v-if="$slots.default"><slot /></span>
  </div>
</template>
