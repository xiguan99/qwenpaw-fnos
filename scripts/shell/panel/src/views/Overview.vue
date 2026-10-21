<script setup>
import { ref, computed } from 'vue'
import { store, refreshStatus, apiPost, apiGet, appApi, toast, fmtUptime } from '../store'
import { useT } from '../i18n'
import PageTitle from '../components/PageTitle.vue'
import { PlayerStop as IconPlayerStop, Refresh as IconRefresh, Download as IconDownload, Camera as IconCamera, ExternalLink as IconExternalLink } from '@vicons/tabler'

const t = useT()
const st = computed(() => store.status || {})
const busy = ref(false)
const checked = ref(null)

async function svc(action, confirmKey) {
  if (confirmKey && !window.confirm(t.value[confirmKey])) return
  if (busy.value) return
  busy.value = true
  try {
    const r = await apiPost('service', { action })
    toast('ok', t.value.result + ': ' + action + (r && r.rc != null ? ' rc=' + r.rc : ''))
  } catch (e) {
    toast('err', e.message || 'fail')
  } finally {
    busy.value = false
    refreshStatus()
  }
}

async function checkUpdate() {
  if (busy.value) return
  busy.value = true
  try {
    const r = await apiGet('check-update')
    checked.value = r
    if (r.has_update) toast('ok', t.value.hasUpdate + ': ' + r.latest)
    else toast('ok', t.value.curVer + ' ' + (r.current || '?') + ' = ' + (r.latest || '?'))
  } catch (e) {
    toast('err', t.value.checkFail + ': ' + (e.message || ''))
  } finally {
    busy.value = false
  }
}

async function quickSnap() {
  if (busy.value) return
  busy.value = true
  try {
    const name = 'panel-' + new Date().toISOString().slice(0, 16).replace(/[-:T]/g, '')
    const j = await appApi('qwenpaw/api/backups/jobs', { method: 'POST', body: { name } })
    toast('ok', t.value.jobStarted + ': ' + (j.job_id || j.id || name))
  } catch (e) {
    toast('err', t.value.jobFail + ': ' + (e.message || ''))
  } finally {
    busy.value = false
  }
}

function checkedAt() {
  return new Date().toLocaleString(store.lang === 'zh' ? 'zh-CN' : 'en-US', { hour12: false })
}
const appUrl = computed(() => (st.value.app && st.value.app.app_url) || null)
</script>

<template>
  <div class="ovwrap">
    <PageTitle :title="t.tab_overview">
      <template v-if="checked"><span>{{ t.checkTime }} {{ checkedAt() }}</span></template>
    </PageTitle>

    <div class="appcard">
      <div>
        <div class="big">QwenPaw</div>
        <div class="ver">{{ t.versionL }}: {{ (st.app && st.app.version) || '?' }}</div>
      </div>
      <a v-if="appUrl" class="bigbtn" :href="appUrl" target="_blank" rel="noopener"><IconExternalLink />{{ t.enterApp }}</a>
    </div>

    <div class="statgrid">
      <div class="statcard">
        <div class="lb">{{ t.statState }}</div>
        <div class="vl"><span :class="st.backend && st.backend.running ? 'badge-ok' : 'badge-bad'">{{ st.backend && st.backend.running ? t.running : t.stopped }}</span></div>
      </div>
      <div class="statcard"><div class="lb">{{ t.statUptimeFull }}</div><div class="vl">{{ st.backend && st.backend.uptime_s != null ? fmtUptime(st.backend.uptime_s) : '—' }}</div></div>
      <div class="statcard"><div class="lb">{{ t.statPidFull }}</div><div class="vl">{{ (st.backend && st.backend.pid) || '—' }}</div></div>
      <div class="statcard"><div class="lb">{{ t.statCpuFull }}</div><div class="vl">{{ st.backend && st.backend.cpu_pct != null ? st.backend.cpu_pct + ' %' : '—' }}</div></div>
      <div class="statcard"><div class="lb">{{ t.statMemFull }}</div><div class="vl">{{ st.backend && st.backend.mem_kb != null ? (st.backend.mem_kb >= 1048576 ? (st.backend.mem_kb / 1048576).toFixed(2) + ' GB' : (st.backend.mem_kb / 1024).toFixed(1) + ' MB') : '—' }}</div></div>
    </div>

    <div class="sec">{{ t.controlSec }}</div>
    <div class="ctrlgrid">
      <div class="ctrlcard" :class="{ disabled: busy }" @click="svc('stop-backend', 'confirmStop')">
        <div class="ic red"><IconPlayerStop /></div><div class="tx">{{ t.actionStop }}</div>
      </div>
      <div class="ctrlcard" :class="{ disabled: busy }" @click="svc('restart-backend', 'confirmRestart')">
        <div class="ic amber"><IconRefresh /></div><div class="tx">{{ t.actionRestart }}</div>
      </div>
      <div class="ctrlcard" :class="{ disabled: busy }" @click="checkUpdate">
        <div class="ic blue"><IconDownload /></div><div class="tx">{{ t.actionCheckSec }}</div>
      </div>
      <div class="ctrlcard" :class="{ disabled: busy }" @click="quickSnap">
        <div class="ic purple"><IconCamera /></div><div class="tx">{{ t.actionSnapSec }}</div>
      </div>
    </div>

    <div class="hint" style="margin-top:16px" v-if="checked">
      {{ t.checkResult }}: {{ t.curVer }} {{ checked.current || '?' }} · {{ t.latestVer }} {{ checked.latest || '?' }}
      <template v-if="checked.published_at"> · {{ t.publishedAt }} {{ String(checked.published_at).slice(0, 10) }}</template>
      <a v-if="checked.url" :href="checked.url" target="_blank" rel="noopener" class="lnk">{{ t.openRelease }}</a>
    </div>
  </div>
</template>

<style scoped>
.ovwrap { display: flex; flex-direction: column; min-height: 0; flex: 1; overflow-y: auto; }
.lnk { color: var(--accent); }
</style>
