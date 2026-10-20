<script setup>
import { ref, computed } from 'vue'
import { store, refreshStatus, apiPost, apiGet, toast } from '../store'
import { useT } from '../i18n'
import { PlayerPlay as IconPlayerPlay, PlayerStop as IconPlayerStop, Refresh as IconRefresh, Activity as IconActivity, Key as IconKey, ShieldLock as IconShieldLock, Logout as IconLogout } from '@vicons/tabler'

const t = useT()
const st = computed(() => store.status || {})
const busy = ref(false)
const lastResult = ref('')
const pwNew = ref('')
const cfg = ref(null)

async function loadCfg() {
  try {
    cfg.value = await apiGet('config')
  } catch (e) {
    cfg.value = null
  }
}

async function svc(action, confirmKey) {
  if (confirmKey && !window.confirm(t.value[confirmKey])) return
  if (busy.value) return
  busy.value = true
  try {
    const r = await apiPost('service', { action })
    lastResult.value = action + ' → rc=' + r.rc + (r.out ? ' · ' + r.out.split('\n').slice(-3).join(' / ') : r.err ? ' · ' + r.err.split('\n').slice(-3).join(' / ') : '')
    toast('ok', t.value.result + ': ' + action)
  } catch (e) {
    toast('err', e.message || 'fail')
  } finally {
    busy.value = false
    refreshStatus()
  }
}

async function savePw() {
  try {
    await apiPost('config', { access_password: pwNew.value })
    toast('ok', pwNew.value ? t.value.pwSaved : t.value.pwCleared)
    pwNew.value = ''
    loadCfg()
    refreshStatus()
  } catch (e) {
    toast('err', e.message || 'fail')
  }
}

async function logout() {
  try {
    await apiPost('logout')
    refreshStatus()
  } catch (e) {}
}
loadCfg()
</script>

<template>
  <div class="grid ctrl">
    <div class="card">
      <div class="hd"><IconActivity />{{ t.svcCard }}</div>
      <div class="row">
        <button class="act primary" :disabled="busy" @click="svc('start-backend')"><IconPlayerPlay />{{ t.startSvc }}</button>
        <button class="act danger" :disabled="busy" @click="svc('stop-backend', 'confirmStop')"><IconPlayerStop />{{ t.stopSvc }}</button>
        <button class="act" :disabled="busy" @click="svc('restart-backend', 'confirmRestart')"><IconRefresh />{{ t.restartSvc }}</button>
      </div>
      <div class="row">
        <button class="act" :disabled="busy" @click="svc('status')"><IconActivity />{{ t.checkStatus }}</button>
      </div>
      <div class="hint">{{ t.fullViaPanel }}</div>
      <div class="hint" v-if="lastResult" style="font-family:var(--mono)">{{ lastResult }}</div>
    </div>

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
</template>
