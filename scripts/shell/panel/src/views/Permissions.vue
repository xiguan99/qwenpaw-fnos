<script setup>
import { ref, computed, onMounted } from 'vue'
import { apiGet, apiPost, toast } from '../store'
import { useT } from '../i18n'
import PageTitle from '../components/PageTitle.vue'
import { ShieldLock as IconShieldLock, Key as IconKey, Logout as IconLogout } from '@vicons/tabler'

const t = useT()
const st = ref(null)        // {ok, authorized, username, no_cli}
const busy = ref(false)
const authUrl = ref('')
const code = ref('')

async function load() {
  try {
    st.value = await apiGet('skill-auth')
  } catch (e) {
    st.value = null
    toast('err', t.value.loadFail + ': ' + e.message)
  }
}

async function authorize() {
  if (busy.value) return
  busy.value = true
  try {
    const j = await apiPost('skill-auth/start')
    if (!j.ok) throw new Error(j.error || 'fail')
    authUrl.value = j.url
    code.value = ''
    if (j.url) {
      // trim-cli 输出 http://localhost:5666/signin?…：把 localhost 换成当前访问主机，保证任何入口都能点开（同源=飞牛 web 端口）
      let u = j.url
      if (u.includes('/signin?')) {
        try {
          const parsed = new URL(u, window.location.origin)
          parsed.hostname = location.hostname
          u = parsed.toString()
        } catch (e) { /* 原样 */ }
      }
      authUrl.value = u
      const w = window.open(u, '_blank')
      if (!w) toast('info', t.value.goToAuthPage)
    }
  } catch (e) {
    toast('err', e.message || 'fail')
  } finally {
    busy.value = false
  }
}

async function confirmCode() {
  if (busy.value) return
  if (!code.value.trim()) { toast('err', t.value.authCodeNeed); return }
  busy.value = true
  try {
    const j = await apiPost('skill-auth/confirm', { code: code.value.trim() })
    if (!j.ok) throw new Error(j.error || 'fail')
    toast('ok', t.value.authOk)
    authUrl.value = ''
    code.value = ''
    load()
  } catch (e) {
    toast('err', (e.message === 'verify_failed' || e.code === 400) ? t.value.authFailMsg : (e.message || 'fail'))
  } finally {
    busy.value = false
  }
}

async function revoke() {
  if (busy.value) return
  if (!window.confirm(t.value.confirmRemoveAuth)) return
  busy.value = true
  try {
    const j = await apiPost('skill-auth/logout')
    if (!j.ok) throw new Error(j.error || 'fail')
    authUrl.value = ''
    code.value = ''
    load()
  } catch (e) {
    toast('err', e.message || 'fail')
  } finally {
    busy.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="vw">
    <PageTitle :title="t.tab_permissions" />
    <div class="grid">
      <div class="card">
        <div class="hd"><IconShieldLock />{{ t.authStatus }}</div>
        <div class="hint">{{ t.authHint }}</div>
        <div class="kv" v-if="st">
          <span>{{ t.authStatus }}</span>
          <span>
            <span v-if="st.no_cli" class="badge-bad">{{ t.authNoCli }}</span>
            <template v-else-if="st.authorized">
              <span class="badge-ok">{{ t.authorizedAs }}</span>
              <b v-if="st.username" style="margin-left:8px">{{ st.username }}</b>
            </template>
            <span v-else class="badge-bad">{{ t.notAuthorized }}</span>
          </span>
        </div>
        <div class="kv" v-else><span>{{ t.authStatus }}</span><span>{{ t.loading }}</span></div>

        <div class="row" v-if="st && !st.no_cli && !st.authorized">
          <button class="act primary" :disabled="busy" @click="authorize"><IconKey />{{ t.clickAuthorize }}</button>
        </div>
        <div class="row" v-if="authUrl">
          <a class="plink" :href="authUrl" target="_blank" rel="noopener">{{ t.goToAuthPage }} ↗</a>
        </div>
        <div class="row" v-if="authUrl">
          <input class="txt" :placeholder="t.pasteCodePh" v-model="code" @keyup.enter="confirmCode" />
          <button class="act primary" :disabled="busy" @click="confirmCode">{{ t.confirmCode }}</button>
        </div>
        <div class="row" v-if="st && !st.no_cli && st.authorized">
          <button class="act danger" :disabled="busy" @click="revoke"><IconLogout />{{ t.removeAuth }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.plink { color: var(--accent); font-size: 13px; text-decoration: none; }
.plink:hover { text-decoration: underline; }
</style>
