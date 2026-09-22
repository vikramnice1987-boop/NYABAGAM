/**
 * NYABAGAM (ஞாபகம்) — Web Landing Page Interactive Controller
 */

document.addEventListener('DOMContentLoaded', () => {
  initTheme();
  initNavbar();
  initPlayground();
  initFaqAccordion();
  initQrCode();
  initAnalyticsTracking();
});

/* --------------------------------------------------------------------------
   Theme Switcher (Default: Crisp Light Theme, Optional Dark Mode)
   -------------------------------------------------------------------------- */
function initTheme() {
  const toggleBtn = document.getElementById('themeToggleBtn');
  const toggleIcon = document.getElementById('themeToggleIcon');
  const html = document.documentElement;

  // Read saved preference, default to 'light'
  const savedTheme = localStorage.getItem('nyabagam_theme') || 'light';
  applyTheme(savedTheme);

  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      const current = html.getAttribute('data-theme') || 'light';
      const next = current === 'light' ? 'dark' : 'light';
      applyTheme(next);
      localStorage.setItem('nyabagam_theme', next);
    });
  }

  function applyTheme(theme) {
    html.setAttribute('data-theme', theme);
    if (toggleIcon) {
      toggleIcon.textContent = theme === 'light' ? '🌙' : '☀️';
      toggleBtn.setAttribute('title', theme === 'light' ? 'Switch to Dark mode' : 'Switch to Light mode');
    }
    const metaTheme = document.querySelector('meta[name="theme-color"]');
    if (metaTheme) {
      metaTheme.setAttribute('content', theme === 'light' ? '#F6F8FD' : '#05060E');
    }
  }
}

/* --------------------------------------------------------------------------
   1. Navbar Scroll Effect & Mobile Drawer
   -------------------------------------------------------------------------- */
function initNavbar() {
  const navbar = document.getElementById('navbar');
  const mobileBtn = document.getElementById('mobileMenuBtn');
  const navLinks = document.getElementById('navLinks');

  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      navbar.classList.add('scrolled');
    } else {
      navbar.classList.remove('scrolled');
    }
  });

  if (mobileBtn && navLinks) {
    mobileBtn.addEventListener('click', () => {
      navLinks.classList.toggle('active');
      const isExpanded = navLinks.classList.contains('active');
      mobileBtn.setAttribute('aria-expanded', isExpanded);
      mobileBtn.innerHTML = isExpanded ? '✕' : '☰';
    });

    // Close when clicking nav link
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        mobileBtn.innerHTML = '☰';
      });
    });
  }
}

/* --------------------------------------------------------------------------
   2. Interactive 8-Stage Playground Simulation
   -------------------------------------------------------------------------- */
const SCENARIOS = {
  ac: {
    title: 'AC Repair & Warranty',
    raw: 'Ravi from CoolCare repaired the living room AC on August 18th for ₹800. He said the condenser has a 90-day warranty until Nov 18.',
    entities: [
      { type: 'person', label: 'Ravi', kind: 'Person' },
      { type: 'org', label: 'CoolCare Services', kind: 'Organization' },
      { type: 'thing', label: 'Living Room AC', kind: 'Thing' },
      { type: 'amount', label: '₹800', kind: 'Financial' },
      { type: 'date', label: 'Aug 18, 2026', kind: 'Date' },
      { type: 'date', label: 'Warranty: Nov 18, 2026', kind: 'Validity' }
    ],
    canonicalMemory: {
      title: 'Living Room AC Repair & 90-Day Warranty',
      summary: 'Repaired by Ravi (CoolCare) on Aug 18 for ₹800. Condenser under warranty until Nov 18, 2026.',
      status: 'Active (Covered)'
    },
    question: 'When was the AC repaired and how much did it cost?',
    groundedAnswer: 'The living room AC was serviced by **Ravi** from **CoolCare** on **August 18, 2026** for **₹800**. The condenser has a 90-day warranty valid until November 18, 2026.',
    citation: 'Verified Grounded Citation: Memory #0818 • Exact Match • Zero Hallucination',
    triggerStatement: "My AC stopped blowing cold air today.",
    bridgeInsight: "⚠️ Proactive Match: 'Living Room AC' was serviced 34 days ago by Ravi (CoolCare). Currently under warranty until Nov 18, 2026.",
    actionProposal: {
      recipient: 'Ravi (CoolCare)',
      channel: 'WhatsApp Proposal',
      message: 'Hi Ravi, you serviced our living room AC on Aug 18 under warranty. It has stopped cooling properly today. Could you please inspect it?'
    }
  },
  doctor: {
    title: 'Cardiology Prescription & Follow-up',
    raw: 'Dr. Meenakshi at Apollo prescribed Telmisartan 40mg once daily in the morning after breakfast. Next review appointment scheduled for Oct 10th.',
    entities: [
      { type: 'person', label: 'Dr. Meenakshi', kind: 'Person' },
      { type: 'org', label: 'Apollo Hospital', kind: 'Organization' },
      { type: 'thing', label: 'Telmisartan 40mg', kind: 'Prescription' },
      { type: 'date', label: 'Oct 10, 2026', kind: 'Review Date' },
      { type: 'thing', label: 'Daily after breakfast', kind: 'Dosage' }
    ],
    canonicalMemory: {
      title: 'Telmisartan 40mg Prescription',
      summary: 'Prescribed by Dr. Meenakshi (Apollo) once daily. Follow-up review scheduled Oct 10, 2026.',
      status: 'Ongoing Treatment'
    },
    question: 'What is the dosage of Telmisartan prescribed by Dr. Meenakshi?',
    groundedAnswer: '**Telmisartan 40mg**, to be taken once daily in the morning after breakfast. Your next review appointment at Apollo Hospital is on **October 10, 2026**.',
    citation: 'Verified Grounded Citation: Prescription Note #0912 • Apollo Health Record',
    triggerStatement: "I'm heading to the pharmacy to refill my blood pressure tablets.",
    bridgeInsight: "💡 Proactive Match: Active prescription for 'Telmisartan 40mg' by Dr. Meenakshi. Review date approaching in 19 days.",
    actionProposal: {
      recipient: 'Apollo Pharmacy',
      channel: 'WhatsApp Proposal',
      message: 'Hello, please prepare a refill for Telmisartan 40mg (1 month pack) under prescription from Dr. Meenakshi.'
    }
  },
  loan: {
    title: 'Friendly Loan to Sridhar',
    raw: 'Lent ₹5,000 via UPI to Sridhar for his car repair. He promised to return it on September 30th after his salary.',
    entities: [
      { type: 'person', label: 'Sridhar', kind: 'Person' },
      { type: 'thing', label: 'Car Repair Loan', kind: 'Category' },
      { type: 'amount', label: '₹5,000', kind: 'Financial' },
      { type: 'date', label: 'Sep 30, 2026', kind: 'Due Date' }
    ],
    canonicalMemory: {
      title: 'Friendly Loan to Sridhar (₹5,000)',
      summary: 'Transferred via UPI for car repair. Due to be settled on September 30, 2026.',
      status: 'Pending Settlement'
    },
    question: 'How much did I lend Sridhar and when is it due?',
    groundedAnswer: 'You lent **₹5,000** via UPI to **Sridhar** for his car repair. It is due to be returned on **September 30, 2026**.',
    citation: 'Verified Grounded Citation: UPI Memory #0915 • Confirmed Transaction',
    triggerStatement: "Reviewing my pending finances for this month.",
    bridgeInsight: "💡 Proactive Match: Outstanding receivable of ₹5,000 from Sridhar, due in 9 days on Sep 30.",
    actionProposal: {
      recipient: 'Sridhar',
      channel: 'WhatsApp Proposal',
      message: 'Hey Sridhar, hope the car is running well! Just a gentle ping regarding the ₹5,000 loan for the 30th. Thanks!'
    }
  }
};

let currentScenarioKey = 'ac';

function initPlayground() {
  const scenarioBtns = document.querySelectorAll('.scenario-btn');
  const rawInput = document.getElementById('simRawInput');
  const extractBtn = document.getElementById('simExtractBtn');
  const approveActionBtn = document.getElementById('simApproveBtn');

  scenarioBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      scenarioBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentScenarioKey = btn.dataset.scenario;
      loadScenario(currentScenarioKey);
    });
  });

  if (extractBtn) {
    extractBtn.addEventListener('click', () => {
      runExtractionSimulation();
    });
  }

  if (approveActionBtn) {
    approveActionBtn.addEventListener('click', () => {
      approveActionBtn.innerHTML = '✓ Approved & Dispatched to WhatsApp';
      approveActionBtn.style.background = 'var(--status-success)';
      approveActionBtn.style.color = '#FFFFFF';
      setTimeout(() => {
        approveActionBtn.innerHTML = 'Approve & Dispatch Action';
        approveActionBtn.style.background = '';
        approveActionBtn.style.color = '';
      }, 3500);
    });
  }

  // Initial load
  loadScenario('ac');
}

function loadScenario(key) {
  const data = SCENARIOS[key];
  if (!data) return;

  const rawInput = document.getElementById('simRawInput');
  if (rawInput) rawInput.value = data.raw;

  renderEntities(data.entities);
  renderMemoryGraph(data.canonicalMemory);
  renderGroundedQA(data);
  renderContextBridge(data);
}

function renderEntities(entities) {
  const container = document.getElementById('simEntitiesContainer');
  if (!container) return;

  container.innerHTML = '';
  entities.forEach(item => {
    const chip = document.createElement('span');
    chip.className = `entity-chip entity-${item.type}`;
    chip.innerHTML = `<span>${item.label}</span> <small style="opacity:0.75; font-size:10px;">• ${item.kind}</small>`;
    container.appendChild(chip);
  });
}

function renderMemoryGraph(mem) {
  const titleEl = document.getElementById('simMemoryTitle');
  const summaryEl = document.getElementById('simMemorySummary');
  const statusEl = document.getElementById('simMemoryStatus');

  if (titleEl) titleEl.textContent = mem.title;
  if (summaryEl) summaryEl.textContent = mem.summary;
  if (statusEl) statusEl.textContent = mem.status;
}

function renderGroundedQA(data) {
  const qEl = document.getElementById('simUserQuestion');
  const aEl = document.getElementById('simAiAnswer');
  const citeEl = document.getElementById('simCitation');

  if (qEl) qEl.textContent = `"${data.question}"`;
  if (aEl) aEl.innerHTML = data.groundedAnswer.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  if (citeEl) citeEl.textContent = data.citation;
}

function renderContextBridge(data) {
  const triggerEl = document.getElementById('simTriggerStatement');
  const insightEl = document.getElementById('simBridgeInsight');
  const recipientEl = document.getElementById('simActionRecipient');
  const messageEl = document.getElementById('simActionMessage');

  if (triggerEl) triggerEl.textContent = `"${data.triggerStatement}"`;
  if (insightEl) insightEl.textContent = data.bridgeInsight;
  if (recipientEl) recipientEl.textContent = `To: ${data.actionProposal.recipient} • ${data.actionProposal.channel}`;
  if (messageEl) messageEl.textContent = `"${data.actionProposal.message}"`;
}

function runExtractionSimulation() {
  const btn = document.getElementById('simExtractBtn');
  const originalText = btn.innerHTML;
  btn.innerHTML = '⚡ Understanding & Resolving Entities...';
  btn.disabled = true;

  setTimeout(() => {
    btn.innerHTML = '✓ Memory Encoded Into Graph';
    setTimeout(() => {
      btn.innerHTML = originalText;
      btn.disabled = false;
    }, 1500);
  }, 600);
}

/* --------------------------------------------------------------------------
   3. FAQ Accordion
   -------------------------------------------------------------------------- */
function initFaqAccordion() {
  const faqItems = document.querySelectorAll('.faq-item');

  faqItems.forEach(item => {
    const questionBtn = item.querySelector('.faq-question');
    questionBtn.addEventListener('click', () => {
      const isOpen = item.classList.contains('open');
      
      // Close all others
      faqItems.forEach(other => {
        other.classList.remove('open');
        other.querySelector('.faq-question').setAttribute('aria-expanded', 'false');
      });

      // Toggle clicked
      if (!isOpen) {
        item.classList.add('open');
        questionBtn.setAttribute('aria-expanded', 'true');
      }
    });
  });
}

/* --------------------------------------------------------------------------
   4. QR Code Generator (HTML5 Canvas)
   -------------------------------------------------------------------------- */
function initQrCode() {
  const canvas = document.getElementById('qrCanvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const size = 150;
  canvas.width = size;
  canvas.height = size;

  // Draw clean QR stylized pattern
  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(0, 0, size, size);

  ctx.fillStyle = '#05060E';

  // Corner 1 (Top-Left)
  drawFinderPattern(ctx, 12, 12, 36);
  // Corner 2 (Top-Right)
  drawFinderPattern(ctx, size - 48, 12, 36);
  // Corner 3 (Bottom-Left)
  drawFinderPattern(ctx, 12, size - 48, 36);

  // Stylized data grid
  const cellSize = 6;
  for (let r = 0; r < 25; r++) {
    for (let c = 0; c < 25; c++) {
      // Don't draw over finder patterns
      if ((r < 8 && c < 8) || (r < 8 && c > 16) || (r > 16 && c < 8)) continue;
      
      // Seeded pseudorandom based on coordinate
      const val = (r * 19 + c * 31 + (r % 3) * 7 + (c % 2) * 11) % 10;
      if (val > 4) {
        ctx.fillRect(c * cellSize, r * cellSize, cellSize - 1, cellSize - 1);
      }
    }
  }

  // Small center brand dot
  ctx.fillStyle = '#6366F1';
  ctx.fillRect(size / 2 - 8, size / 2 - 8, 16, 16);
}

function drawFinderPattern(ctx, x, y, size) {
  ctx.fillRect(x, y, size, size);
  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(x + 6, y + 6, size - 12, size - 12);
  ctx.fillStyle = '#05060E';
  ctx.fillRect(x + 12, y + 12, size - 24, size - 24);
}

/* --------------------------------------------------------------------------
   5. Analytics & Copy Link Helper
   -------------------------------------------------------------------------- */
function initAnalyticsTracking() {
  const downloadBtns = document.querySelectorAll('.download-apk-btn');
  downloadBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      console.log('NYABAGAM APK download initiated:', 'nyabagam-v1.apk');
    });
  });
}
