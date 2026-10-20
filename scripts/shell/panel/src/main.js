import { createApp } from 'vue'
import App from './App.vue'
import './styles.css'
import { resolvedTheme } from './store'

document.documentElement.dataset.theme = resolvedTheme()
createApp(App).mount('#app')
