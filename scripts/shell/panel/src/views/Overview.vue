<script setup>
import { ref, computed } from 'vue'
import { store, fmtBytes, fmtUptime } from '../store'
import { useT } from '../i18n'
import { Cpu as IconCpu, Database as IconDatabase, Puzzle as IconPuzzle, Terminal2 as IconTerminal2, ChevronDown as IconChevronDown } from '@vicons/tabler'

const t = useT()
const st = computed(() => store.status || {})
const mq = window.matchMedia('(max-width: 700px)')
const isMobile = ref(mq.matches)
mq.addEventListener('change', (e) => (isMobile.value = e.matches))
const open = ref({ svc: true, data: true, paw: true, logs: true })
function toggle(k) {
  if (isMobile.value) open.value[k] = !open.value[k]
}
</script>

<template>
  <div class="grid">
    <div class="card">
      <div class="hd" @click="toggle('svc')"><span><IconCpu /> {{ t.svcCard }}</span><IconChevronDown v-if="isMobile" :style="open.svc ? '' : 'transform:rotate(-90deg)'" /></div>
      <div v-show="open.svc || !isMobile">
        <div class="kv"><span>{{ t.pillService }}</span><span>{{ st.backend && st.backend.running ? t.running : t.stopped }}<template v-if="st.backend && st.backend.pid"> · PID {{ st.backend.pid }}</template><template v-if="st.backend && st.backend.uptime_s != null"> · {{ fmtUptime(st.backend.uptime_s) }}</template></span></div>
        <div class="kv"><span>{{ t.pillShell }}</span><span>PID {{ st.shell && st.shell.pid }} · {{ fmtUptime(st.shell && st.shell.uptime_s) }}</span></div>
        <div class="kv"><span>{{ t.pillPython }}</span><span>{{ (st.python && st.python.venv) || '—' }}</span></div>
      </div>
    </div>

    <div class="card">
      <div class="hd" @click="toggle('data')"><span><IconDatabase /> {{ t.dataCard }}</span><IconChevronDown v-if="isMobile" :style="open.data ? '' : 'transform:rotate(-90deg)'" /></div>
      <div v-show="open.data || !isMobile">
        <div class="kv"><span>{{ t.dataFiles }}</span><span>{{ st.data && st.data.files != null ? st.data.files : '—' }}</span></div>
        <div class="kv"><span>{{ t.dataSize }}</span><span>{{ fmtBytes(st.data && st.data.bytes) }}{{ st.app && st.app.data_capped ? ' (' + t.show + ')' : '' }}</span></div>
      </div>
    </div>

    <div class="card">
      <div class="hd" @click="toggle('paw')"><span><IconPuzzle /> {{ t.qwenpawCard }}</span><IconChevronDown v-if="isMobile" :style="open.paw ? '' : 'transform:rotate(-90deg)'" /></div>
      <div v-show="open.paw || !isMobile">
        <div class="kv"><span>{{ t.pillChannels }}</span><span>{{ st.qwenpaw && st.qwenpaw.channels != null ? st.qwenpaw.channels : '—' }}</span></div>
        <div class="kv"><span>{{ t.pillSkills }}</span><span>{{ st.qwenpaw && st.qwenpaw.skills != null ? st.qwenpaw.skills : '—' }}</span></div>
        <div class="kv"><span>{{ t.footerVersion }}</span><span>{{ (st.app && st.app.version) || '—' }}</span></div>
      </div>
    </div>

    <div class="card">
      <div class="hd" @click="toggle('logs')"><span><IconTerminal2 /> {{ t.logsCard }}</span><IconChevronDown v-if="isMobile" :style="open.logs ? '' : 'transform:rotate(-90deg)'" /></div>
      <div v-show="open.logs || !isMobile">
        <div class="kv"><span>{{ t.logApp }}</span><span>{{ fmtBytes(st.logs && st.logs.app_bytes) }}</span></div>
        <div class="kv"><span>{{ t.logShell }}</span><span>{{ fmtBytes(st.logs && st.logs.shell_bytes) }}</span></div>
      </div>
    </div>
  </div>
</template>
