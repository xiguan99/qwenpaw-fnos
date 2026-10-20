import { computed } from 'vue'
import { store } from './store'

const DICT = {
  tab_app: ['主视图', 'App'],
  tab_overview: ['总览', 'Overview'],
  tab_logs: ['实时日志', 'Logs'],
  tab_control: ['服务控制', 'Control'],
  pillService: ['本体', 'Backend'],
  pillShell: ['面板', 'Shell'],
  pillPython: ['Python', 'Python'],
  pillStorage: ['数据', 'Data'],
  pillChannels: ['频道', 'Channels'],
  pillSkills: ['技能', 'Skills'],
  running: ['运行中', 'running'],
  stopped: ['未运行', 'stopped'],
  unknown: ['未知', 'unknown'],
  offline: ['离线', 'offline'],
  pid: ['PID', 'PID'],
  uptime: ['运行时长', 'Uptime'],
  dataFiles: ['文件数', 'Files'],
  dataSize: ['占用', 'Size'],
  logApp: ['本体日志', 'App log'],
  logShell: ['面板日志', 'Shell log'],
  autoscroll: ['滚动', 'Follow'],
  clear: ['清空', 'Clear'],
  startSvc: ['启动', 'Start'],
  stopSvc: ['停止', 'Stop'],
  restartSvc: ['重启', 'Restart'],
  checkStatus: ['状态检查', 'Check status'],
  confirmStop: ['确认停止本体？面板不受影响，但停止期间主视图不可用。', 'Stop the backend? The panel survives, but the App tab is unavailable while stopped.'],
  confirmRestart: ['确认重启本体？', 'Restart the backend?'],
  confirmFullRestart: ['整栈重启（含面板）', 'Full restart (incl. shell)'],
  confirmFull: ['确认整栈重启？面板会短暂断开。', 'Full restart? The panel will disconnect briefly.'],
  fullViaPanel: ['整栈重启（含面板）需在 fnOS 应用中心操作', 'Full restart must be done from fnOS app center'],
  loginTitle: ['需要登录', 'Login required'],
  loginHint: ['当前网络不在免登范围（可信网段/本机直连免登）。', 'This network is outside the trusted password-free ranges.'],
  loginPlaceholder: ['访问密码', 'Access password'],
  loginBtn: ['登录', 'Login'],
  badPassword: ['密码错误', 'Wrong password'],
  loginOk: ['登录成功', 'Signed in'],
  logout: ['退出登录', 'Sign out'],
  pwSetTitle: ['访问密码', 'Access password'],
  pwSetHint: ['设置后，非可信网段访问需登录；留空并保存 = 清除密码。', 'Once set, non-trusted networks must log in; save empty to clear.'],
  pwNew: ['新密码', 'New password'],
  save: ['保存', 'Save'],
  pwSaved: ['已保存', 'Saved'],
  pwCleared: ['密码已清除', 'Password cleared'],
  trusted: ['可信网段', 'Trusted networks'],
  loading: ['加载中…', 'Loading…'],
  noStatus: ['面板后端未就绪', 'Panel backend not ready'],
  themeTip: ['主题：自动/亮/暗', 'Theme: auto/light/dark'],
  reload: ['刷新', 'Reload'],
  footerVersion: ['版本', 'Version'],
  svcCard: ['服务状态', 'Services'],
  dataCard: ['存储', 'Storage'],
  qwenpawCard: ['QwenPaw', 'QwenPaw'],
  logsCard: ['日志', 'Logs'],
  show: ['展开', 'show'],
  result: ['结果', 'Result'],
  started: ['已启动', 'started'],
  stoppedMsg: ['已停止', 'stopped'],
  restarted: ['已重启', 'restarted'],
  statusMsg: ['状态', 'Status'],
  langTip: ['中/EN', 'EN/中'],
}

export function dict() {
  return DICT
}

export function useT() {
  return computed(() => {
    const li = store.lang === 'en' ? 1 : 0
    const out = {}
    for (const k in DICT) out[k] = DICT[k][li]
    return out
  })
}
