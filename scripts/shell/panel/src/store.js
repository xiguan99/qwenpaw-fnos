import { reactive } from 'vue'

export const store = reactive({
  status: null,
  online: false,
  tab: 'app',
  lang: localStorage.getItem('qwp_lang') || (String(navigator.language).toLowerCase().startsWith('zh') ? 'zh' : 'en'),
  theme: localStorage.getItem('qwp_theme') || 'auto',
  toast: null,
})

export function toast(type, msg) {
  store.toast = { type, msg, id: Date.now() }
  clearTimeout(toast._t)
  toast._t = setTimeout(() => {
    if (store.toast && Date.now() - store.toast.id > 2500) store.toast = null
  }, 3000)
}

export async function refreshStatus() {
  try {
    const r = await fetch('shell/api/status')
    store.status = await r.json()
    store.online = true
    return store.status
  } catch (e) {
    store.online = false
    return null
  }
}

export async function apiGet(path) {
  const r = await fetch('shell/api/' + path)
  let j = null
  try { j = await r.json() } catch (e) {}
  if (r.status === 401) {
    refreshStatus()
    const err = new Error('unauthorized')
    err.code = 401
    throw err
  }
  if (!r.ok) {
    const err = new Error('HTTP ' + r.status)
    err.code = r.status
    throw err
  }
  return j
}

export async function apiPost(path, body) {
  const r = await fetch('shell/api/' + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
  })
  let j = null
  try { j = await r.json() } catch (e) {}
  if (r.status === 401) {
    refreshStatus()
    const err = new Error('unauthorized')
    err.code = 401
    throw err
  }
  if (!r.ok || (j && j.ok === false)) {
    const err = new Error((j && j.error) || 'HTTP ' + r.status)
    err.code = r.status
    throw err
  }
  return j
}

export async function appApi(path, opts = {}) {
  // qwenpaw 官方 API：相对路径 'qwenpaw/api/…'，单包/双 app 两种模式都经壳反代直达本体
  const r = await fetch(path, {
    method: opts.method || 'GET',
    headers: opts.body ? { 'Content-Type': 'application/json' } : {},
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  })
  let j = null
  try { j = await r.json() } catch (e) {}
  if (r.status === 401) {
    const err = new Error('unauthorized')
    err.code = 401
    throw err
  }
  if (!r.ok) {
    const det = j && (j.detail || j.error)
    const err = new Error(typeof det === 'string' ? det : 'HTTP ' + r.status)
    err.code = r.status
    throw err
  }
  return j
}

export const TABS = ['app', 'overview', 'update', 'plugins', 'workspaces', 'models', 'snapshots', 'settings', 'logs', 'control']

export function setTab(t) {
  store.tab = t
  if (location.hash !== '#/' + t) location.hash = '#/' + t
}

export function syncTabFromHash() {
  const t = location.hash.replace(/^#\/?/, '').split('?')[0]
  if (TABS.includes(t)) store.tab = t
}

export function fmtBytes(n) {
  if (n == null) return '—'
  const u = ['B', 'KB', 'MB', 'GB', 'TB']
  let i = 0
  while (n >= 1024 && i < u.length - 1) {
    n /= 1024
    i++
  }
  return (i ? n.toFixed(1) : String(n)) + ' ' + u[i]
}

export function fmtUptime(s) {
  if (s == null) return '—'
  if (s < 90) return s + 's'
  const d = Math.floor(s / 86400)
  s -= d * 86400
  const h = Math.floor(s / 3600)
  s -= h * 3600
  const m = Math.floor(s / 60)
  return (d ? d + 'd ' : '') + h + 'h ' + m + 'm'
}

export function setLang(l) {
  store.lang = l
  localStorage.setItem('qwp_lang', l)
}

export function cycleTheme() {
  const order = ['auto', 'light', 'dark']
  store.theme = order[(order.indexOf(store.theme) + 1) % 3]
  localStorage.setItem('qwp_theme', store.theme)
  document.documentElement.dataset.theme = resolvedTheme()
}

export function resolvedTheme() {
  if (store.theme === 'auto') {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }
  return store.theme
}
