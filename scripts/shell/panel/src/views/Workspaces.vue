<script setup>
import { ref, onMounted } from 'vue'
import { appApi, toast } from '../store'
import { useT } from '../i18n'
import PageTitle from '../components/PageTitle.vue'
import { Refresh as IconRefresh, Folder as IconFolder, File as IconFile, ChevronLeft as IconChevronLeft, ChevronRight as IconChevronRight } from '@vicons/tabler'

const t = useT()
const browse = ref(false)
const agents = ref([])
const dir = ref('')
const entries = ref(null)
const busy = ref(false)

async function loadAgents() {
  try {
    const j = await appApi('qwenpaw/api/agents')
    const list = j.agents || []
    agents.value = await Promise.all(list.map(async (a) => {
      let chats = []
      try {
        const c = await appApi('qwenpaw/api/chats', { headers: { 'X-Agent-Id': a.id } })
        chats = Array.isArray(c) ? c : (c.chats || c.items || [])
      } catch (e) {}
      const up = chats.map((c) => c.updated_at).filter(Boolean).sort()
      const cr = chats.map((c) => c.created_at).filter(Boolean).sort()
      return { ...a, n: chats.length, updated: up[up.length - 1] || null, created: cr[0] || null }
    }))
  } catch (e) {
    toast('err', t.value.loadFail + ': ' + e.message)
  }
}

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

function showBrowse() {
  browse.value = !browse.value
  if (browse.value && entries.value === null) load()
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
function fmtTime(iso) {
  if (!iso) return '—'
  const d = new Date(iso)
  return isNaN(d.getTime()) ? '—' : d.toLocaleString()
}
onMounted(loadAgents)
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_workspaces">
      <span class="cnt">{{ t.wsTotal.replace('{n}', agents.length) }}</span>
      <button class="act" @click="showBrowse">{{ t.wsDataDir }}</button>
    </PageTitle>

    <div v-if="browse" class="wbox">
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
        </div>
        <div v-if="entries && !entries.length" class="hint">{{ t.wsEmpty }}</div>
      </div>
    </div>

    <div v-else class="wgrid">
      <div v-for="a in agents" :key="a.id" class="wcard">
        <div class="whd">
          <span class="wi"><IconFolder /></span>
          <span class="wn">{{ a.name }}</span>
          <span class="wns">{{ t.wsSessions.replace('{n}', a.n) }}</span>
        </div>
        <div class="wpath">{{ a.workspace_dir }}</div>
        <div class="wfoot">
          <span>{{ t.wsUpdated }} {{ fmtTime(a.updated) }}</span>
          <span>{{ t.wsCreated }} {{ fmtTime(a.created) }}</span>
        </div>
      </div>
      <div v-if="!agents.length" class="hint">{{ t.wsEmpty }}</div>
    </div>
  </div>
</template>

<style scoped>
.cnt { color: var(--tx2); font-weight: 400; font-size: 13px; }
.wgrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 12px; align-content: start; }
.wcard { background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; }
.whd { display: flex; align-items: center; gap: 8px; min-width: 0; }
.whd .wn { font-weight: 600; font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.whd .wi { display: inline-flex; color: var(--warn); flex: none; }
.whd .wi svg { width: 18px; height: 18px; }
.wns { margin-left: auto; color: var(--accent); font-size: 13px; white-space: nowrap; }
.wpath { font-family: var(--mono); font-size: 12px; color: var(--tx2); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.wfoot { display: flex; gap: 16px; color: var(--tx2); font-size: 12px; flex-wrap: wrap; }
.wbox { display: flex; flex-direction: column; min-height: 0; flex: 1; background: var(--card); border: 1px solid var(--line); border-radius: 12px; overflow: hidden; }
.wbar { display: flex; align-items: center; gap: 6px; padding: 8px 12px; border-bottom: 1px solid var(--line); flex-wrap: wrap; }
button.crumb { border: none; background: none; padding: 4px 6px; font-size: 13px; color: var(--tx); cursor: pointer; }
.wlist { flex: 1; min-height: 0; overflow: auto; }
.wrow { display: flex; align-items: center; gap: 10px; padding: 7px 14px; border-bottom: 1px solid var(--line); font-size: 13px; }
.wrow:last-child { border-bottom: none; }
.dirrow { cursor: pointer; }
.dirrow:hover { background: rgba(0,0,0,0.03); }
html[data-theme='dark'] .dirrow:hover { background: rgba(255,255,255,0.04); }
.wlist .wi { display: inline-flex; color: var(--tx2); flex: none; }
.dirrow .wi { color: var(--warn); }
.wlist .wn { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.wm { color: var(--tx2); font-size: 12px; white-space: nowrap; }
@media (max-width: 700px) { .wm { display: none; } }
</style>
