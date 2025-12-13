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
})();
