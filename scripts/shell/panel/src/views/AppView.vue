<script setup>
import { useT } from '../i18n'
import { Refresh as IconRefresh, ExternalLink as IconExternalLink } from '@vicons/tabler'
const t = useT()
let frame = null
function reload() {
  try {
    frame.contentWindow.location.reload()
  } catch (e) {
    frame.src = 'qwenpaw/'
  }
}
function openTab() {
  window.open('qwenpaw/', '_blank')
}
</script>

<template>
  <div class="framebox">
    <div class="bar">
      <button class="act" @click="reload"><IconRefresh />{{ t.reload }}</button>
      <button class="act" :title="t.reload" @click="openTab"><IconExternalLink /></button>
    </div>
    <iframe :ref="(el) => (frame = el)" src="qwenpaw/" title="QwenPaw"></iframe>
  </div>
</template>
