<script setup>
import { ref } from 'vue'
import { ChevronDown as IconChevronDown } from '@vicons/tabler'

const props = defineProps({ title: String, badge: String, badgeOk: Boolean, clickable: Boolean })
const isMobile = window.matchMedia && window.matchMedia('(max-width: 700px)').matches
const open = ref(!isMobile)
</script>

<template>
  <div class="card icard">
    <div class="hd" @click="open = !open">
      <span style="display:inline-flex;align-items:center;gap:8px;min-width:0">
        <i v-if="badge || badgeOk" class="dot" :class="badgeOk ? 'ok' : ''" style="flex:none" />
        {{ title }}
      </span>
      <span style="display:inline-flex;align-items:center;gap:8px;white-space:nowrap">
        <slot name="side" />
        <span class="chev" :class="{ open }"><IconChevronDown /></span>
      </span>
    </div>
    <div v-show="open">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.icard { break-inside: avoid; }
.card .hd { margin-bottom: 0; }
.card .hd + div { margin-top: 8px; }
.chev { display: inline-flex; transition: transform 0.15s; color: var(--tx2); }
.chev.open { transform: rotate(180deg); }
</style>
