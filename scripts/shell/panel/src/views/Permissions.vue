<script setup>
import { ref, computed, onMounted } from 'vue'
import { store, refreshStatus, apiGet, apiPost, toast } from '../store'
import { useT } from '../i18n'
import PageTitle from '../components/PageTitle.vue'
import { Key as IconKey, ShieldLock as IconShieldLock, Logout as IconLogout } from '@vicons/tabler'

const t = useT()
const st = computed(() => store.status || {})
const busy = ref(false)
const pwNew = ref('')
const cfg = ref(null)

async function loadCfg() {
  try {
    cfg.value = await apiGet('config')
  } catch (e) {
    cfg.value = null
  }
}

async function savePw() {
  if (busy.value) return
  busy.value = true
  try {
    await apiPost('config', { access_password: pwNew.value })
    toast('ok', pwNew.value ? t.value.pwSaved : t.value.pwCleared)
    pwNew.value = ''
    loadCfg()
    refreshStatus()
  } catch (e) {
    toast('err', e.message || 'fail')
  } finally {
    busy.value = false
  }
}

async function logout() {
  try {
    await apiPost('logout')
    refreshStatus()
  } catch (e) {}
}
onMounted(loadCfg)
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_permissions" />
    <div class="grid">
      <div class="card">
        <div class="hd"><IconKey />{{ t.pwSetTitle }}</div>
        <div class="hint">{{ t.pwSetHint }}</div>
        <div class="row">
          <input class="txt" type="password" :placeholder="t.pwNew" v-model="pwNew" autocomplete="new-password" />
          <button class="act primary" :disabled="busy" @click="savePw">{{ t.save }}</button>
        </div>
        <div class="kv" v-if="cfg"><span>{{ t.trusted }}</span><span>{{ (cfg.trusted_networks || []).join(', ') || '—' }}</span></div>
        <div class="row" v-if="st.auth && st.auth.required && st.auth.authorized">
          <button class="act" @click="logout"><IconLogout />{{ t.logout }}</button>
        </div>
        <div class="hint" v-if="st.auth"><span><IconShieldLock /></span> {{ st.auth.trusted ? t.trusted : '' }}</div>
      </div>
    </div>
  </div>
</template>
