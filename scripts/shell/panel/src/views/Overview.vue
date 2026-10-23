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

const official = computed(() => (checked.value && checked.value.official) || null)
const applyState = computed(() => (official.value && official.value.apply_state) || null)
let pollTimer = null

async function applyOfficial() {
  if (!official.value || !official.value.has_update || busy.value) return
  if (!window.confirm(t.value.confirmUpgradeOfficial)) return
  busy.value = true
  try {
    const r = await apiPost('official-apply', { confirm: true })
    if (r && r.ok && (r.state === 'up_to_date' || r.state === 'done')) {
      // 已是最新 / 立即完成：不进入轮询，直接刷新状态
      toast('ok', (r.message || t.value.upToDate) + (r.latest ? ' (' + r.latest + ')' : ''))
      await reloadOfficial()
      refreshStatus()
    } else if (r && r.ok) {
      toast('ok', t.value.upgradeStarted)
      startPoll()
    } else toast('err', (r && r.error) || 'fail')
  } catch (e) {
    toast('err', e.message || 'fail')
  } finally {
    busy.value = false
  }
}

async function reloadOfficial() {
  try {
    const o = await apiGet('official-check')
    checked.value = { ...(checked.value || {}), official: o }
  } catch (e) { /* 保持旧值 */ }
}

function startPoll() {
  if (pollTimer) clearTimeout(pollTimer)
  pollTimer = setTimeout(async () => {
    try {
      const r = await apiGet('official-check')
      checked.value = { ...(checked.value || {}), official: r }
      const s = r && r.apply_state
      if (s && s.state === 'done') {
        const ver = (s.from_version || '?') + ' → ' + (s.to_version || s.target || '?')
        toast(s.restarted === false ? 'err' : 'ok',
              t.value.upgradeDone + ': ' + ver + (s.restarted === false ? ' · ' + t.value.restartFail : ''))
        await reloadOfficial()
        refreshStatus()
      } else if (s && s.state === 'up_to_date') {
        toast('ok', t.value.upToDate)
        await reloadOfficial()
      } else if (s && s.state === 'failed') {
        toast('err', t.value.upgradeFailed)
      } else {
        startPoll()
      }
    } catch (e) {
      startPoll()
    }
  }, 5000)
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
      <div>{{ t.projCh }}: {{ t.curVer }} {{ checked.current || '?' }} · {{ t.latestVer }} {{ checked.latest || '?' }}
        <template v-if="checked.published_at"> · {{ t.publishedAt }} {{ String(checked.published_at).slice(0, 10) }}</template>
        <a v-if="checked.url" :href="checked.url" target="_blank" rel="noopener" class="lnk">{{ t.openRelease }}</a>
      </div>
      <div v-if="official" class="hintrow">
        {{ t.officialCh }}: {{ t.curVer }} {{ official.current || '?' }} · {{ t.latestVer }} {{ official.latest || '?' }}<template v-if="official.runtime"> · {{ t.runtimeVer }} {{ official.runtime }}</template>
        <button v-if="official.has_update" class="lnk pointer" :disabled="busy" @click="applyOfficial">{{ t.clickUpgrade }}</button>
        <span v-else class="lnk is-disabled" title="">{{ t.upToDate }}</span>
        <span v-if="official.runtime_stale" class="lnk">· {{ t.runtimeStale }}</span>
        <span v-if="applyState && applyState.state === 'running'">· {{ t.upgradeRunning }}</span>
        <span v-else-if="applyState && applyState.state === 'done'">· {{ t.upgradeDone }}<template v-if="applyState.restarted === false"> · {{ t.restartFail }}</template></span>
        <span v-else-if="applyState && applyState.state === 'failed'">· {{ t.upgradeFailed }}</span>
        <a :href="official.url" target="_blank" rel="noopener" class="lnk">PyPI</a>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ovwrap { display: flex; flex-direction: column; min-height: 0; flex: 1; overflow-y: auto; }
.lnk { color: var(--accent); border: 0; background: none; font: inherit; padding: 0 2px; }
.lnk.is-disabled { color: var(--muted, #8b949e); cursor: not-allowed; }
.lnk:disabled { opacity: .6; cursor: default; }
.hintrow { margin-top: 6px; }
.pointer { cursor: pointer; }
</style>
