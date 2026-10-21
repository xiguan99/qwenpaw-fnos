<script setup>
import { ref, onMounted } from 'vue'
import { appApi, toast } from '../store'
import { useT } from '../i18n'
import ItemCard from '../components/ItemCard.vue'
import PageTitle from '../components/PageTitle.vue'
import { Refresh as IconRefresh, Trash as IconTrash } from '@vicons/tabler'

const t = useT()
const list = ref(null)
const busy = ref(false)

async function load() {
  busy.value = true
  try {
    list.value = await appApi('qwenpaw/api/plugins')
  } catch (e) {
    list.value = []
    toast('err', t.value.loadFail + ': ' + e.message)
  } finally {
    busy.value = false
  }
}

async function uninstall(p) {
  if (!window.confirm(t.value.confirmUninstall.replace('{n}', p.name))) return
  try {
    await appApi('qwenpaw/api/plugins/' + encodeURIComponent(p.id), { method: 'DELETE' })
    toast('ok', t.value.uninstalled + ': ' + p.name)
    load()
  } catch (e) {
    toast('err', e.message)
  }
}

onMounted(load)
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_plugins" />
  <div class="plist">
    <div class="pbar">
      <span class="hint" style="margin:0">{{ list ? list.length + ' ' + t.pluginsCount : '…' }}</span>
      <button class="act" style="margin-left:auto" :disabled="busy" @click="load"><IconRefresh /></button>
    </div>
    <div class="grid">
      <ItemCard v-for="p in list || []" :key="p.id" :title="p.name + ' · ' + p.version" :badge-ok="!!p.enabled">
        <template #side><span class="ptype">{{ p.plugin_type || '—' }}</span></template>
        <div class="kv"><span>{{ t.pAuthor }}</span><span>{{ p.author || '—' }}</span></div>
        <div class="kv"><span>{{ t.pStatus }}</span><span :class="p.enabled ? 'ok-t' : 'bad-t'">{{ p.enabled ? t.pEnabled : t.pDisabled }} · {{ p.loaded ? t.pLoaded : t.pUnloaded }}</span></div>
        <div class="kv" v-if="p.description"><span>{{ t.pDesc }}</span><span style="font-weight:400;text-align:right">{{ p.description }}</span></div>
        <div class="prow">
          <button class="act danger" @click="uninstall(p)"><IconTrash />{{ t.uninstall }}</button>
        </div>
      </ItemCard>
    </div>
  </div>
  </div>
</template>

<style scoped>
.plist { display: flex; flex-direction: column; min-height: 0; flex: 1; }
.pbar { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.ptype { font-size: 11.5px; color: var(--tx2); border: 1px solid var(--line); border-radius: 999px; padding: 1px 8px; }
.prow { display: flex; gap: 8px; margin-top: 8px; flex-wrap: wrap; }
.ok-t { color: var(--accent); }
.bad-t { color: var(--bad); }
.grid { grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }
</style>
