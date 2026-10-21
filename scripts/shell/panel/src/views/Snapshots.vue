<script setup>
import { ref, onMounted } from 'vue'
import { appApi, toast } from '../store'
import { useT } from '../i18n'
import ItemCard from '../components/ItemCard.vue'
import PageTitle from '../components/PageTitle.vue'
import { Refresh as IconRefresh, Plus as IconPlus, Rotate as IconRotate, Trash as IconTrash } from '@vicons/tabler'

const t = useT()
const list = ref(null)
const busy = ref(false)
const creating = ref(false)
const newName = ref('')

async function load() {
  busy.value = true
  try {
    list.value = await appApi('qwenpaw/api/backups')
  } catch (e) {
    list.value = []
    toast('err', t.value.loadFail + ': ' + e.message)
  } finally {
    busy.value = false
  }
}

async function create() {
  const name = newName.value.trim() || ('panel-' + new Date().toISOString().replace(/[-:T]/g, '').slice(0, 12))
  creating.value = true
  try {
    const j = await appApi('qwenpaw/api/backups/jobs', { method: 'POST', body: { name } })
    pollJob(j && j.job_id ? j.job_id : j && j.id ? j.id : '')
    toast('ok', t.value.jobStarted)
    newName.value = ''
  } catch (e) {
    toast('err', e.message)
  } finally {
    creating.value = false
  }
}

async function pollJob(id) {
  if (!id) return load()
  for (let i = 0; i < 40; i++) {
    await new Promise((r) => setTimeout(r, 3000))
    let j = null
    try { j = await appApi('qwenpaw/api/backups/jobs/' + encodeURIComponent(id)) } catch (e) { break }
    const st = j && (j.status || j.state)
    if (st === 'completed' || st === 'done' || st === 'success' || (j && j.result)) { toast('ok', t.value.createdMsg); break }
    if (st === 'failed' || st === 'error' || st === 'cancelled') { toast('err', t.value.jobFail + (j && j.error ? ': ' + j.error : '')); break }
  }
  load()
}

async function restore(b) {
  if (!window.confirm(t.value.confirmRestore.replace('{n}', b.name))) return
  try {
    await appApi('qwenpaw/api/backups/' + encodeURIComponent(b.id) + '/restore', { method: 'POST' })
    toast('ok', t.value.restoreDone)
    load()
  } catch (e) {
    toast('err', e.message)
  }
}

async function del(b) {
  if (!window.confirm(t.value.confirmDeleteMsg.replace('{n}', b.name))) return
  try {
    await appApi('qwenpaw/api/backups/delete', { method: 'POST', body: { ids: [b.id] } })
    toast('ok', t.value.deleteDone)
    load()
  } catch (e) {
    toast('err', e.message)
  }
}

onMounted(load)
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_snapshots" />
  <div class="sbox">
    <div class="sbar">
      <input class="txt" v-model="newName" :placeholder="t.snapNamePh" @keyup.enter="create" />
      <button class="act primary" :disabled="creating" @click="create"><IconPlus />{{ t.createSnap }}</button>
      <button class="act" style="margin-left:auto" :disabled="busy" @click="load"><IconRefresh /></button>
    </div>
    <div class="grid">
      <ItemCard v-for="b in list || []" :key="b.id" :title="b.name">
        <template #side><span class="mono-s">{{ (b.created_at || '').replace('T', ' ').replace(/(\+|Z).*$/, ' UTC') }}</span></template>
        <div class="kv"><span>ID</span><span class="mono-s">{{ b.id }}</span></div>
        <div class="kv" v-if="b.description"><span>{{ t.snapDesc }}</span><span style="font-weight:400">{{ b.description }}</span></div>
        <div class="srow">
          <button class="act" @click="restore(b)"><IconRotate />{{ t.restore }}</button>
          <button class="act danger" @click="del(b)"><IconTrash />{{ t.del }}</button>
        </div>
      </ItemCard>
    </div>
    <div v-if="list && !list.length" class="hint" style="margin-top:8px">{{ t.snapEmpty }}</div>
    <div class="hint" style="margin-top:8px">{{ t.restoreHint }}</div>
  </div>
  </div>
</template>

<style scoped>
.sbox { display: flex; flex-direction: column; min-height: 0; flex: 1; }
.sbar { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.srow { display: flex; gap: 8px; margin-top: 8px; }
.mono-s { font-family: var(--mono); font-size: 12px; }
.grid { grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); align-content: start; flex: 0 1 auto; overflow: auto; }
.grid > div { margin-bottom: 10px; }
</style>
