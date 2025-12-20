//= require action_cable
//= require_self
// Basic interactivity: mobile nav toggle, current year, contact form handling
(function () {
  const navToggle = document.querySelector('.nav-toggle');
  const nav = document.getElementById('primary-nav');
  if (navToggle && nav) {
    navToggle.addEventListener('click', () => {
      const open = nav.classList.toggle('open');
      navToggle.setAttribute('aria-expanded', String(open));
    });
  }

  const yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // Progressive enhancement for contact form demo-only handling
  const form = document.querySelector('form[data-enhanced="contact"]');
  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const out = document.getElementById('form-status');
      const data = new FormData(form);
      const name = (data.get('name') || '').toString().trim();
      const email = (data.get('email') || '').toString().trim();
      const message = (data.get('message') || '').toString().trim();

      const errors = [];
      if (!name) errors.push('Name is required');
      if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.push('Valid email is required');
      if (!message) errors.push('Please include a short message');

      if (errors.length) {
        out.className = 'error';
        out.textContent = errors.join(' • ');
        out.hidden = false;
        return;
      }

      out.className = 'success';
      out.textContent = 'Thanks! We\'ll reach out shortly to schedule next steps.';
      out.hidden = false;
      form.reset();
    });
  }

  // Admin dropdown click-to-toggle
  const adminDropdowns = document.querySelectorAll('.dropdown');
  adminDropdowns.forEach((dropdown) => {
    const btn = dropdown.querySelector('.dropdown-toggle');
    const menu = dropdown.querySelector('.dropdown-menu');
    if (!btn || !menu) return;
    const close = () => {
      dropdown.classList.remove('open');
      btn.setAttribute('aria-expanded', 'false');
      menu.hidden = true;
      menu.style.display = 'none';
    };
    const open = () => {
      dropdown.classList.add('open');
      btn.setAttribute('aria-expanded', 'true');
      menu.hidden = false;
      menu.style.display = 'block';
    };
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const isOpen = dropdown.classList.contains('open');
      if (isOpen) { close(); } else { open(); }
    });
    document.addEventListener('click', (e) => {
      if (!dropdown.contains(e.target)) close();
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') close();
    });
  });

  // Make tweets clickable to open thread, but ignore interactive targets
  document.querySelectorAll('.tweet[data-url]').forEach((el) => {
    el.addEventListener('click', (e) => {
      const target = e.target;
      if (target.closest('a,button,input,textarea,form,label')) return;
      const url = el.getAttribute('data-url');
      if (url) {
        window.location.href = url;
      }
    });
  });

  // Theme: dark/light toggle
  try {
    const root = document.documentElement;
    const saved = localStorage.getItem('theme');
    if (saved === 'dark') root.classList.add('dark');
    if (saved === 'light') root.classList.remove('dark');
    const toggle = document.getElementById('theme-toggle');
    if (toggle) {
      toggle.addEventListener('click', () => {
        const isDark = root.classList.toggle('dark');
        localStorage.setItem('theme', isDark ? 'dark' : 'light');
      });
    }
  } catch (_) {}

  // Notifications badge polling (fallback if no websockets)
  try {
    const badge = document.getElementById('notif-badge');
    // Setup Action Cable
    window.App = window.App || {};
    if (window.ActionCable) {
      App.cable = App.cable || ActionCable.createConsumer('/cable');
      if (badge) {
        App.notifications = App.cable.subscriptions.create({ channel: 'NotificationsChannel' }, {
          received: (data) => {
            try {
              if (data && data.type === 'count' && typeof data.count !== 'undefined') {
                const n = Number(data.count || 0);
                if (n > 0) {
                  badge.textContent = String(n);
                  badge.classList.remove('hidden');
                } else {
                  badge.textContent = '0';
                  badge.classList.add('hidden');
                }
              }
            } catch (e) {}
          }
        });
      }
    }
    async function refreshNotifCount() {
      if (!badge) return;
      try {
        const res = await fetch('/notifications/count.json', { headers: { 'Accept': 'application/json' }, credentials: 'same-origin' });
        if (!res.ok) return;
        const data = await res.json();
        const n = Number(data.count || 0);
        if (n > 0) {
          badge.textContent = String(n);
          badge.classList.remove('hidden');
        } else {
          badge.textContent = '0';
          badge.classList.add('hidden');
        }
      } catch (e) {}
    }
    refreshNotifCount();
    let notifTimer = setInterval(refreshNotifCount, 30000);
    // If websockets connected, reduce polling frequency
    if (window.App && App.notifications) {
      clearInterval(notifTimer);
      notifTimer = setInterval(refreshNotifCount, 180000);
    }
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) return;
      refreshNotifCount();
    });
  } catch (_) {}
  // Community feed: show a small banner when new posts arrive
  try {
    const mount = document.getElementById('community-feed');
    if (mount && window.ActionCable) {
      const slug = mount.getAttribute('data-community-slug');
      if (slug) {
        window.App = window.App || {};
        App.cable = App.cable || ActionCable.createConsumer('/cable');
        let newCount = 0;
        const banner = document.createElement('div');
        banner.className = 'fixed bottom-4 left-1/2 -translate-x-1/2 z-50 px-3 py-2 rounded-lg bg-slate-900 text-white text-sm hidden';
        banner.textContent = 'New posts available — refresh';
        document.body.appendChild(banner);
        const showBanner = () => { banner.classList.remove('hidden'); };
        App.communityFeed = App.cable.subscriptions.create({ channel: 'CommunityFeedChannel', slug: slug }, {
          received: (data) => {
            if (data && data.type === 'new_post') {
              newCount += 1;
              banner.textContent = `${newCount} new post${newCount>1?'s':''} — refresh`;
              showBanner();
            }
          }
        });
      }
    }
  } catch (_) {}
})();
