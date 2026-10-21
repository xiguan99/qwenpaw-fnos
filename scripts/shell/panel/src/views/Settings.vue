<script setup>
import { ref, onMounted, computed } from 'vue'
import { appApi, toast } from '../store'
import { useT } from '../i18n'
import PageTitle from '../components/PageTitle.vue'
import { Refresh as IconRefresh, ExternalLink as IconExternalLink, Messages as IconMessages } from '@vicons/tabler'

const t = useT()
const cfg = ref(null)
const lang = ref(null)
const tz = ref(null)
const theme = ref(null)
const agents = ref(null)
const busy = ref(false)

async function load() {
  busy.value = true
  try {
    const [c, l, z, th, a] = await Promise.all([
      appApi('qwenpaw/api/config/channels'),
      appApi('qwenpaw/api/settings/language'),
      appApi('qwenpaw/api/settings/timezone'),
      appApi('qwenpaw/api/config/theme'),
      appApi('qwenpaw/api/agents'),
    ])
    cfg.value = c; lang.value = l; tz.value = z; theme.value = th; agents.value = a
  } catch (e) {
    toast('err', t.value.loadFail + ': ' + e.message)
  } finally {
    busy.value = false
  }
}
onMounted(load)

const channels = computed(() => {
  const c = cfg.value || {}
  const keys = Object.keys(c)
  return { total: keys.length, enabled: keys.filter((k) => c[k] && c[k].enabled).length, names: keys.filter((k) => c[k] && c[k].enabled) }
})
const agentList = computed(() => (agents.value && agents.value.agents) || [])
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_settings" />
  <div class="grid s-grid">
    <div class="card">
      <div class="hd">
        <span>{{ t.setGeneral }}</span>
        <button class="act" style="margin-left:auto" :disabled="busy" @click="load"><IconRefresh /></button>
      </div>
      <div class="kv"><span>{{ t.setLang }}</span><span>{{ (lang && lang.language) || '—' }}</span></div>
      <div class="kv"><span>{{ t.setTz }}</span><span>{{ (tz && (tz.timezone || tz.tz)) || '—' }}</span></div>
      <div class="kv"><span>{{ t.setTheme }}</span><span>{{ (theme && (theme.theme || theme.mode)) || t.setThemeAuto }}</span></div>
    </div>
    <div class="card">
      <div class="hd"><span><IconMessages style="vertical-align:-2px" /> {{ t.setChannels }}</span></div>
      <div class="kv"><span>{{ t.setChCount }}</span><span>{{ channels.enabled }} / {{ channels.total }}</span></div>
      <div class="kv" v-if="channels.names.length"><span>{{ t.setChOn }}</span><span>{{ channels.names.join(', ') }}</span></div>
    </div>
    <div class="card">
      <div class="hd"><span>{{ t.setAgents }}</span></div>
      <div class="kv"><span>{{ t.setAgCount }}</span><span>{{ agentList.length }}</span></div>
      <div class="kv" v-for="a in agentList.slice(0, 6)" :key="a.id"><span>{{ a.id }}</span><span style="font-weight:400">{{ a.name || '—' }}</span></div>
    </div>
    <div class="card">
      <div class="hd"><span><IconExternalLink style="vertical-align:-2px" /> {{ t.setEdit }}</span></div>
      <div class="hint" style="margin:0">{{ t.setHint }}<a href="qwenpaw/#/settings" target="_blank" rel="noopener" class="lnk">{{ t.openApp }}</a></div>
    </div>
  </div>
  </div>
</template>

<style scoped>
.s-grid { align-content: start; }
.lnk { color: var(--accent); }
</style>
