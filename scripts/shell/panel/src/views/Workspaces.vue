<script setup>
import { ref, onMounted } from 'vue'
import { appApi, fmtBytes, toast } from '../store'
import { useT } from '../i18n'
import PageTitle from '../components/PageTitle.vue'
import ItemCard from '../components/ItemCard.vue'
import { Refresh as IconRefresh, Folder as IconFolder, File as IconFile, ChevronLeft as IconChevronLeft, ChevronRight as IconChevronRight, ExternalLink as IconExternalLink } from '@vicons/tabler'

const t = useT()
const dir = ref('')
const entries = ref(null)
const busy = ref(false)
const models = ref(null)
const busyM = ref(false)

async function load() {
  if (busy.value) return
  busy.value = true
  try {
    const j = await appApi('qwenpaw/api/workspace/tree?directory=' + encodeURIComponent(dir.value))
    entries.value = (j.entries || []).slice().sort((a, b) => (a.kind === b.kind ? a.name.localeCompare(b.name) : a.kind === 'directory' ? -1 : 1))
  } catch (e) {
    entries.value = []
    toast('err', t.value.loadFail + ': ' + e.message)
  } finally {
    busy.value = false
  }
}

async function loadModels() {
  if (busyM.value) return
  busyM.value = true
  try {
    models.value = await appApi('qwenpaw/api/models')
  } catch (e) {
    models.value = []
    toast('err', t.value.loadFail + ': ' + e.message)
  } finally {
    busyM.value = false
  }
}

function open(e) {
  if (e.kind !== 'directory') return
  dir.value = (dir.value ? dir.value + '/' : '') + e.name
  load()
}
function up() {
  const p = dir.value.split('/').filter(Boolean)
  p.pop()
  dir.value = p.join('/')
  load()
}
const crumbs = () => dir.value.split('/').filter(Boolean)
onMounted(() => {
  load()
  loadModels()
})
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_workspaces" />
    <div class="wbox">
      <div class="wbar">
        <button class="act" :disabled="!dir" @click="up"><IconChevronLeft /></button>
        <button class="act" @click="dir = ''; load()">{{ t.wsRoot }}</button>
        <span v-for="(c, i) in crumbs()" :key="i">
          <IconChevronRight style="color:var(--tx2)" />
          <button class="act crumb" @click="dir = crumbs().slice(0, i + 1).join('/'); load()">{{ c }}</button>
        </span>
        <button class="act" style="margin-left:auto" :disabled="busy" @click="load"><IconRefresh /></button>
      </div>
      <div class="wlist">
        <div v-for="e in entries || []" :key="e.path" class="wrow" :class="{ dirrow: e.kind === 'directory' }" @click="open(e)">
          <span class="wi"><IconFolder v-if="e.kind === 'directory'" /><IconFile v-else /></span>
          <span class="wn">{{ e.name }}</span>
          <span class="wm">{{ (e.modified_at || '').replace('T', ' ').replace(/(\+|Z).*$/, ' UTC') }}</span>
          <span class="ws">{{ e.kind === 'directory' ? '' : fmtBytes(e.size) }}</span>
        </div>
        <div v-if="entries && !entries.length" class="hint">{{ t.wsEmpty }}</div>
      </div>
    </div>

    <div class="sec" style="margin-top:18px">{{ t.tab_modelssec }}</div>
    <div class="grid">
      <ItemCard v-for="p in models || []" :key="p.id" :title="p.name" :badge-ok="!!p.enabled">
        <template #side><span class="mid">{{ p.id }}</span></template>
        <div class="kv"><span>{{ t.mStatus }}</span><span :class="p.enabled ? 'ok-t' : 'bad-t'">{{ p.enabled ? t.mEnabled : t.mDisabled }}</span></div>
        <div class="kv"><span>{{ t.mModels }}</span><span>{{ p.model_count == null ? t.mNotQuery : p.model_count }}</span></div>
        <div class="kv"><span>{{ t.mChat }}</span><span>{{ p.chat_model || '—' }}</span></div>
        <div class="kv" v-if="p.base_url"><span>Base URL</span><span class="mono-s">{{ p.base_url }}</span></div>
      </ItemCard>
    </div>
    <div class="hint" style="margin-top:10px">
      <IconExternalLink style="vertical-align:-2px" /> {{ t.mEditHint }}
      <a href="qwenpaw/#/settings" target="_blank" rel="noopener" class="lnk">{{ t.openApp }}</a>
    </div>
  </div>
</template>

<style scoped>
.wbox { display: flex; flex-direction: column; min-height: 0; flex: 1; background: var(--card); border: 1px solid var(--line); border-radius: 12px; overflow: hidden; }
.wbar { display: flex; align-items: center; gap: 6px; padding: 8px 12px; border-bottom: 1px solid var(--line); flex-wrap: wrap; }
button.crumb { border: none; background: none; padding: 4px 6px; font-size: 13px; color: var(--tx); cursor: pointer; }
.wlist { flex: 1; min-height: 0; overflow: auto; }
.wrow { display: flex; align-items: center; gap: 10px; padding: 7px 14px; border-bottom: 1px solid var(--line); font-size: 13px; }
.wrow:last-child { border-bottom: none; }
.dirrow { cursor: pointer; }
.dirrow:hover { background: rgba(0,0,0,0.03); }
html[data-theme='dark'] .dirrow:hover { background: rgba(255,255,255,0.04); }
.wi { display: inline-flex; color: var(--tx2); flex: none; }
.dirrow .wi { color: var(--warn); }
.wn { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.wm { color: var(--tx2); font-size: 12px; white-space: nowrap; }
.ws { color: var(--tx2); font-size: 12px; min-width: 70px; text-align: right; white-space: nowrap; }
.mid { font-size: 11.5px; color: var(--tx2); font-family: var(--mono); }
.mono-s { font-family: var(--mono); font-size: 12px; }
.ok-t { color: var(--ok); }
.bad-t { color: var(--bad); }
.lnk { color: var(--accent); }
@media (max-width: 700px) { .wm { display: none; } }
</style>
