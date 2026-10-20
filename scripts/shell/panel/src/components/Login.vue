<script setup>
import { ref, computed, onMounted } from 'vue'
import { useT } from '../i18n'
import { refreshStatus, toast, apiPost } from '../store'
import { ShieldLock as IconShieldLock } from '@vicons/tabler'

const t = useT()
const pw = ref('')
const busy = ref(false)

async function submit() {
  if (!pw.value || busy.value) return
  busy.value = true
  try {
    await apiPost('login', { password: pw.value })
    toast('ok', t.value.loginOk)
    pw.value = ''
    refreshStatus()
  } catch (e) {
    toast('err', t.value.badPassword)
  } finally {
    busy.value = false
  }
}
onMounted(refreshStatus)
</script>

<template>
  <div class="loginwrap">
    <div class="card">
      <div class="hd"><IconShieldLock />{{ t.loginTitle }}</div>
      <div class="hint">{{ t.loginHint }}</div>
      <div class="row">
        <input class="txt" type="password" :placeholder="t.loginPlaceholder" v-model="pw" @keyup.enter="submit" autocomplete="current-password" />
        <button class="act primary" :disabled="!pw || busy" @click="submit">{{ t.loginBtn }}</button>
      </div>
    </div>
  </div>
</template>
