// Smooth scroll for internal nav links
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener('click', function (e) {
    const href = this.getAttribute('href');
    if (href && href.startsWith('#')) {
      e.preventDefault();
      document.querySelector(href)?.scrollIntoView({ behavior: 'smooth' });
    }
  });
});

// Theme toggle
const root = document.documentElement;
const toggle = document.getElementById('mode-toggle');
const modeIcon = document.getElementById('mode-icon');
const logoImg = document.getElementById('logo-img');
const LIGHT = 'light';
const DARK = 'dark';
const LOGO_LIGHT = 'assets/Black Transparent.png';
const LOGO_DARK = 'assets/White_Transparent.png';

const applyTheme = (theme) => {
  root.setAttribute('data-theme', theme);
  const isLight = theme === LIGHT;
  logoImg.src = isLight ? LOGO_LIGHT : LOGO_DARK;
  modeIcon.textContent = isLight ? '🌙' : '☀️';
  localStorage.setItem('chiaru-theme', theme);
};

const saved = localStorage.getItem('chiaru-theme');
if (saved === LIGHT || saved === DARK) {
  applyTheme(saved);
} else {
  applyTheme(DARK);
}

toggle?.addEventListener('click', () => {
  const current = root.getAttribute('data-theme') === LIGHT ? LIGHT : DARK;
  applyTheme(current === LIGHT ? DARK : LIGHT);
});
