<script setup>
import { computed, onMounted, onBeforeUnmount } from 'vue'
import { store, refreshStatus, syncTabFromHash, setTab, setLang, cycleTheme, resolvedTheme, TABS, fmtBytes, fmtUptime } from './store'
import { useT } from './i18n'
import Overview from './views/Overview.vue'
import Update from './views/Update.vue'
import Plugins from './views/Plugins.vue'
import Workspaces from './views/Workspaces.vue'
import Models from './views/Models.vue'
import Snapshots from './views/Snapshots.vue'
import Settings from './views/Settings.vue'
import Logs from './views/Logs.vue'
import Control from './views/Control.vue'
import Login from './components/Login.vue'
import { Paw as IconPaw, Dashboard as IconLayoutDashboard, Terminal2 as IconTerminal2, Settings as IconSettings, Sun as IconSun, Moon as IconMoon, MoonStars as IconSunMoon, Language as IconLanguage, Refresh as IconRefresh, Package as IconPackage, Folder as IconFolder, Cpu as IconCpu, History as IconHistory, Adjustments as IconSettings2 } from '@vicons/tabler'

const t = useT()
const VIEWS = { overview: Overview, update: Update, plugins: Plugins, workspaces: Workspaces, models: Models, snapshots: Snapshots, settings: Settings, logs: Logs, control: Control }
const TAB_ICONS = { overview: IconLayoutDashboard, update: IconRefresh, plugins: IconPackage, workspaces: IconFolder, models: IconCpu, snapshots: IconHistory, settings: IconSettings2, logs: IconTerminal2, control: IconSettings }
const CurrentView = computed(() => VIEWS[store.tab] || Overview)
const ThemeIcon = computed(() => (store.theme === 'light' ? IconSun : store.theme === 'dark' ? IconMoon : IconSunMoon))
const authGate = computed(() => store.status && store.status.auth && store.status.auth.required && !store.status.auth.authorized)
const svcDot = computed(() => {
  if (!store.status) return ''
  return store.status.backend && store.status.backend.running ? 'ok' : 'bad'
})
const shellDot = 'ok'
const st = computed(() => store.status || {})

function toggleLang() {
  setLang(store.lang === 'zh' ? 'en' : 'zh')
}

let poll = null
onMounted(() => {
  document.documentElement.dataset.theme = resolvedTheme()
  syncTabFromHash()
  window.addEventListener('hashchange', syncTabFromHash)
  refreshStatus()
  poll = setInterval(refreshStatus, 5000)
})
onBeforeUnmount(() => clearInterval(poll))
</script>

<template>
  <div class="app-shell">
    <aside class="sidebar">
      <div class="brand"><span class="logo"><IconPaw /></span><span class="bl">QwenPaw</span></div>
      <nav class="sidenav">
        <button v-for="tb in TABS" :key="tb" :class="{ on: store.tab === tb }" @click="setTab(tb)">
          <component :is="TAB_ICONS[tb]" />
          <span class="tl">{{ t['tab_' + tb] }}</span>
        </button>
      </nav>
      <div class="sidefoot">
        <button :title="t.langTip" @click="toggleLang"><IconLanguage /><span class="tl">{{ store.lang === 'zh' ? 'EN' : '中文' }}</span></button>
        <button :title="t.themeTip" @click="cycleTheme"><component :is="ThemeIcon" /><span class="tl">{{ store.theme }}</span></button>
      </div>
    </aside>

    <div class="main">
      <div class="stats" v-if="store.status">
        <span class="pill"><i class="dot" :class="svcDot" />{{ t.pillService }} <b>{{ st.backend && (st.backend.running ? t.running : t.stopped) }}</b></span>
        <span class="pill"><i class="dot" :class="shellDot" />{{ t.pillShell }} <b>{{ fmtUptime(st.shell && st.shell.uptime_s) }}</b></span>
        <span class="pill">{{ t.pillPython }} <b>{{ (st.python && st.python.venv) || '—' }}</b></span>
        <span class="pill">{{ t.pillStorage }} <b>{{ st.data && st.data.files != null ? st.data.files : '—' }} · {{ fmtBytes(st.data && st.data.bytes) }}</b></span>
        <span class="pill">{{ t.pillChannels }} <b>{{ st.qwenpaw && st.qwenpaw.channels != null ? st.qwenpaw.channels : '—' }}</b></span>
        <span class="pill">{{ t.pillSkills }} <b>{{ st.qwenpaw && st.qwenpaw.skills != null ? st.qwenpaw.skills : '—' }}</b></span>
      </div>

      <main class="content">
        <div v-if="!store.status" class="loading">{{ store.online ? t.loading : t.noStatus }}</div>
        <Login v-else-if="authGate" />
        <component v-else :is="CurrentView" />
      </main>

      <footer class="foot" v-if="store.status">
        <span>{{ t.footerVersion }} {{ (st.app && st.app.version) || '?' }} · {{ store.online ? '●' : '○' }} {{ store.online ? '' : t.offline }}</span>
      </footer>
    </div>
  </div>

  <transition name="fade">
    <div v-if="store.toast" class="toast" :class="store.toast.type">{{ store.toast.msg }}</div>
  </transition>
</template>
