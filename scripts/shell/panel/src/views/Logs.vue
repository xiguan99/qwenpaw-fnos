<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useT } from '../i18n'
import { Trash as IconTrash } from '@vicons/tabler'

const t = useT()
const src = ref('app')
const lines = ref([])
const follow = ref(true)
const box = ref(null)
let es = null
let retry = null

function classify(line) {
  if (/ERROR|Traceback|CRITICAL|FATAL|\berror\b/i.test(line)) return 'ln err'
  if (/WARN/i.test(line)) return 'ln warn'
  return 'ln'
}

function scroll() {
  if (follow.value && box.value) box.value.scrollTop = box.value.scrollHeight
}

function connect() {
  if (es) es.close()
  es = new EventSource('shell/api/logs?src=' + src.value)
  es.onmessage = (e) => {
    lines.value.push(e.data)
    if (lines.value.length > 2000) lines.value.splice(0, lines.value.length - 2000)
    scroll()
  }
  es.onerror = () => {
    es.close()
    es = null
    clearTimeout(retry)
    retry = setTimeout(connect, 3000)
  }
}

function switchTo(s) {
  if (src.value === s) return
  src.value = s
  lines.value = []
  connect()
}

function clear() {
  lines.value = []
}

onMounted(connect)
onBeforeUnmount(() => {
  clearTimeout(retry)
  if (es) es.close()
})
</script>

<template>
  <div class="logbox">
    <div class="bar">
      <button class="act" :class="{ primary: src === 'app' }" @click="switchTo('app')">{{ t.logApp }}</button>
      <button class="act" :class="{ primary: src === 'shell' }" @click="switchTo('shell')">{{ t.logShell }}</button>
      <label style="display:inline-flex;align-items:center;gap:6px;cursor:pointer"><input type="checkbox" v-model="follow" />{{ t.autoscroll }}</label>
      <button class="act" @click="clear"><IconTrash />{{ t.clear }}</button>
    </div>
    <pre ref="box"><div v-for="(l, i) in lines" :key="i" :class="classify(l)">{{ l }}</div></pre>
  </div>
</template>
