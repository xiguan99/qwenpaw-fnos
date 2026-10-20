<script setup>
import { ref, onMounted } from 'vue'
import { apiGet, toast } from '../store'
import { useT } from '../i18n'
import { Refresh as IconRefresh, ExternalLink as IconExternalLink } from '@vicons/tabler'

const t = useT()
const d = ref(null)
const busy = ref(false)

async function load() {
  busy.value = true
  try {
    d.value = await apiGet('check-update')
  } catch (e) {
    d.value = { ok: false, error: e.message }
    toast('err', e.message)
  } finally {
    busy.value = false
  }
}
onMounted(load)
</script>

<template>
  <div class="grid u-grid">
    <div class="card" v-if="d">
      <div class="hd">
        <span>{{ t.upCard }}</span>
        <button class="act" style="margin-left:auto" :disabled="busy" @click="load"><IconRefresh /></button>
      </div>
      <div v-if="!d.ok" class="hint">{{ d.error || t.checkFail }}</div>
      <template v-else>
        <div class="kv"><span>{{ t.curVer }}</span><span>{{ d.current || '—' }}</span></div>
        <div class="kv"><span>{{ t.latestVer }}</span><span :class="{ up: d.has_update }">{{ d.latest || '—' }} <b v-if="d.has_update" class="upbadge">{{ t.hasUpdate }}</b></span></div>
        <div class="kv"><span>{{ t.publishedAt }}</span><span>{{ (d.published_at || '').replace('T', ' ').replace(/(\+|Z).*$/, ' UTC') || '—' }}</span></div>
        <pre v-if="d.notes" class="notes">{{ d.notes }}</pre>
        <div class="u-row" v-if="d.url">
          <a class="act primary" :href="d.url" target="_blank" rel="noopener"><IconExternalLink />{{ t.openRelease }}</a>
          <span class="hint" style="margin:0">{{ t.releaseHint }}</span>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.u-grid { align-content: start; max-width: 640px; }
.up { color: var(--accent); }
.upbadge { background: var(--accent); color: #fff; border-radius: 999px; padding: 1px 8px; font-size: 11px; margin-left: 6px; }
.notes { margin: 8px 0 0; padding: 8px 10px; background: rgba(0,0,0,0.02); border-radius: 8px; font-family: var(--mono); font-size: 12px; white-space: pre-wrap; word-break: break-word; max-height: 240px; overflow: auto; }
html[data-theme='dark'] .notes { background: rgba(255,255,255,0.02); }
.u-row { display: flex; align-items: center; gap: 10px; margin-top: 10px; flex-wrap: wrap; }
a.act { text-decoration: none; }
</style>
