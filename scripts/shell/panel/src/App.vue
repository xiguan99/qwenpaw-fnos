<script setup>
import { computed, onMounted, onBeforeUnmount } from 'vue'
import { store, refreshStatus, syncTabFromHash, setTab, setLang, cycleTheme, resolvedTheme } from './store'
import { useT } from './i18n'
import Overview from './views/Overview.vue'
import Workspaces from './views/Workspaces.vue'
import Permissions from './views/Permissions.vue'
import Plugins from './views/Plugins.vue'
import Snapshots from './views/Snapshots.vue'
import Logs from './views/Logs.vue'
import Settings from './views/Settings.vue'
import Login from './components/Login.vue'
import { Paw as IconPaw, Dashboard as IconLayoutDashboard, Folder as IconFolder, ShieldLock as IconShieldLock, Package as IconPackage, History as IconHistory, Terminal2 as IconTerminal2, Settings as IconSettings, Sun as IconSun, Moon as IconMoon, MoonStars as IconSunMoon, Language as IconLanguage } from '@vicons/tabler'

const t = useT()
const VIEWS = { overview: Overview, workspaces: Workspaces, permissions: Permissions, plugins: Plugins, snapshots: Snapshots, logs: Logs, settings: Settings }
const NAV_MAIN = ['overview', 'workspaces', 'permissions', 'plugins', 'snapshots', 'logs']
const NAV_BOTTOM = ['settings']
const TAB_ICONS = { overview: IconLayoutDashboard, workspaces: IconFolder, permissions: IconShieldLock, plugins: IconPackage, snapshots: IconHistory, logs: IconTerminal2, settings: IconSettings }
const CurrentView = computed(() => VIEWS[store.tab] || Overview)
const ThemeIcon = computed(() => (store.theme === 'light' ? IconSun : store.theme === 'dark' ? IconMoon : IconSunMoon))
const authGate = computed(() => store.status && store.status.auth && store.status.auth.required && !store.status.auth.authorized)

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
        <button v-for="tb in NAV_MAIN" :key="tb" :class="{ on: store.tab === tb }" @click="setTab(tb)">
          <component :is="TAB_ICONS[tb]" />
          <span class="tl">{{ t['tab_' + tb] }}</span>
        </button>
      </nav>
      <div class="sidefoot">
        <button :class="{ on: store.tab === 'settings' }" @click="setTab('settings')">
          <IconSettings /><span class="tl">{{ t.tab_settings }}</span>
        </button>
        <button :title="t.langTip" @click="toggleLang"><IconLanguage /><span class="tl">{{ store.lang === 'zh' ? 'EN' : '中文' }}</span></button>
        <button :title="t.themeTip" @click="cycleTheme"><component :is="ThemeIcon" /><span class="tl">{{ store.theme }}</span></button>
      </div>
    </aside>

    <div class="main">
      <main class="content">
        <div v-if="!store.status" class="loading">{{ store.online ? t.loading : t.noStatus }}</div>
        <Login v-else-if="authGate" />
        <component v-else :is="CurrentView" />
      </main>
    </div>
  </div>

  <transition name="fade">
    <div v-if="store.toast" class="toast" :class="store.toast.type">{{ store.toast.msg }}</div>
  </transition>
</template>
