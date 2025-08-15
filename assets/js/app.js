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

// Chat-specific hooks
const ChatHooks = {
  ChatScroll() {
    this.mounted = () => {
      this.scrollToBottom();
    }
    
    this.updated = () => {
      this.scrollToBottom();
    }
    
    this.scrollToBottom = () => {
      const container = this.el;
      container.scrollTop = container.scrollHeight;
    }
  },
  
  AutoResize() {
    this.mounted = () => {
      this.resize();
    }
    
    this.updated = () => {
      this.resize();
    }
    
    this.resize = () => {
      const input = this.el;
      input.style.height = 'auto';
      input.style.height = Math.min(input.scrollHeight, 120) + 'px';
    }
    
    this.el.addEventListener('input', () => {
      this.resize();
    });
  }
}

// Modern dropdown hooks for LiveView integration
const ModernDropdownHooks = {
  mounted() {
    // Set initial value
    const select = this.el.querySelector('select');
    if (select) {
      const selectedOption = select.querySelector('option[selected]');
      if (selectedOption) {
        const alpineComponent = this.el._x_dataStack[0];
        if (alpineComponent) {
          alpineComponent.selected = selectedOption.textContent.trim();
        }
      }
    }
    
    // Listen for dropdown change events from Alpine.js
    this.el.addEventListener('dropdown-change', (event) => {
      const { value, label } = event.detail;
      
      // Update the hidden select element
      if (select) {
        select.value = value;
        
        // Trigger change event for LiveView
        const changeEvent = new Event('change', { bubbles: true });
        select.dispatchEvent(changeEvent);
      }
    });
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: { ...ChatHooks, ...ModernDropdownHooks }
})

liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Mobile menu functionality
document.addEventListener('DOMContentLoaded', function() {
  const mobileMenuButton = document.getElementById('mobile-menu-button');
  const mobileMenu = document.getElementById('mobile-menu');
  
  if (mobileMenuButton && mobileMenu) {
    mobileMenuButton.addEventListener('click', function() {
      const isHidden = mobileMenu.classList.contains('hidden');
      
      if (isHidden) {
        mobileMenu.classList.remove('hidden');
        mobileMenuButton.setAttribute('aria-expanded', 'true');
      } else {
        mobileMenu.classList.add('hidden');
        mobileMenuButton.setAttribute('aria-expanded', 'false');
      }
    });
    
    // Close menu when clicking outside
    document.addEventListener('click', function(event) {
      if (!mobileMenuButton.contains(event.target) && !mobileMenu.contains(event.target)) {
        mobileMenu.classList.add('hidden');
        mobileMenuButton.setAttribute('aria-expanded', 'false');
      }
    });
    
    // Close menu when pressing Escape key
    document.addEventListener('keydown', function(event) {
      if (event.key === 'Escape') {
        mobileMenu.classList.add('hidden');
        mobileMenuButton.setAttribute('aria-expanded', 'false');
      }
    });
  }
});

// Chat-specific enhancements
document.addEventListener('DOMContentLoaded', function() {
  // Auto-focus on message input when chat loads
  const messageInput = document.querySelector('input[name="message"]');
  if (messageInput) {
    messageInput.focus();
  }
});

// Listen for clear_input event from LiveView
window.addEventListener('clear_input', () => {
  const messageInput = document.querySelector('input[name="message"]');
  if (messageInput) {
    messageInput.value = '';
    messageInput.focus();
  }
});

