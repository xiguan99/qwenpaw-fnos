<script setup>
import { ref, onMounted } from 'vue'
import { appApi, toast } from '../store'
import { useT } from '../i18n'
import ItemCard from '../components/ItemCard.vue'
import { Refresh as IconRefresh, Box as IconBox, ExternalLink as IconExternalLink } from '@vicons/tabler'

const t = useT()
const list = ref(null)
const busy = ref(false)

async function load() {
  busy.value = true
  try {
    list.value = await appApi('qwenpaw/api/models')
  } catch (e) {
    list.value = []
    toast('err', t.value.loadFail + ': ' + e.message)
  } finally {
    busy.value = false
  }
}
onMounted(load)
</script>

<template>
  <div class="mlist">
    <div class="mbar">
      <span class="hint" style="margin:0">{{ list ? list.length + ' ' + t.mCount : '…' }}</span>
      <button class="act" style="margin-left:auto" :disabled="busy" @click="load"><IconRefresh /></button>
    </div>
    <div class="grid">
      <ItemCard v-for="p in list || []" :key="p.id" :title="p.name" :badge-ok="!!p.enabled">
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
.mlist { display: flex; flex-direction: column; min-height: 0; flex: 1; }
.mbar { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.mid { font-size: 11.5px; color: var(--tx2); font-family: var(--mono); }
.mono-s { font-family: var(--mono); font-size: 12px; }
.ok-t { color: var(--accent); }
.bad-t { color: var(--bad); }
.grid { grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }
.lnk { color: var(--accent); }
</style>
