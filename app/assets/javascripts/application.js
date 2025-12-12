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
})();

