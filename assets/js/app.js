// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
topbar.start()
liveSocket.connect()

// Dark mode functionality
const initDarkMode = () => {
  // Check for saved theme preference or default to light mode
  const savedTheme = localStorage.getItem('theme') || 'light'
  document.documentElement.classList.toggle('dark', savedTheme === 'dark')
  
  // Update theme in LiveView if on dashboard
  const themeToggle = document.querySelector('[phx-click="toggle_theme"]')
  if (themeToggle) {
    // Send initial theme to LiveView
    liveSocket.execJS(themeToggle, "toggle_theme", {})
  }
}

// Initialize dark mode on page load
document.addEventListener('DOMContentLoaded', initDarkMode)

// Handle theme toggle clicks
document.addEventListener('click', (e) => {
  if (e.target.closest('[phx-click="toggle_theme"]')) {
    const currentTheme = document.documentElement.classList.contains('dark') ? 'dark' : 'light'
    const newTheme = currentTheme === 'light' ? 'dark' : 'light'
    
    // Toggle dark mode class
    document.documentElement.classList.toggle('dark')
    
    // Save preference
    localStorage.setItem('theme', newTheme)
  }
})

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

