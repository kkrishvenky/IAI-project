/* ====================================================
   MCQ System — Main JavaScript
   ==================================================== */

// ── Modal Helpers ──────────────────────────────────────
const MCQ = {
    openModal(id) {
        const overlay = document.getElementById(id);
        if (overlay) {
            overlay.classList.add('open');
            document.body.style.overflow = 'hidden';
        }
    },
    closeModal(id) {
        const overlay = document.getElementById(id);
        if (overlay) {
            overlay.classList.remove('open');
            document.body.style.overflow = '';
        }
    },
    // Close modal when clicking backdrop
    initModals() {
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    overlay.classList.remove('open');
                    document.body.style.overflow = '';
                }
            });
        });
        document.querySelectorAll('[data-modal-open]').forEach(btn => {
            btn.addEventListener('click', () => MCQ.openModal(btn.dataset.modalOpen));
        });
        document.querySelectorAll('[data-modal-close]').forEach(btn => {
            btn.addEventListener('click', () => MCQ.closeModal(btn.dataset.modalClose));
        });
    },

    // ── Flash auto-dismiss ─────────────────────────────
    initFlash() {
        const alerts = document.querySelectorAll('.alert');
        alerts.forEach(alert => {
            setTimeout(() => {
                alert.style.transition = 'opacity 0.5s ease';
                alert.style.opacity = '0';
                setTimeout(() => alert.remove(), 500);
            }, 4000);
        });
    },

    // ── Inline Filter Table ────────────────────────────
    initTableSearch(inputId, tableBodyId) {
        const input = document.getElementById(inputId);
        const tbody = document.getElementById(tableBodyId);
        if (!input || !tbody) return;
        input.addEventListener('input', () => {
            const q = input.value.toLowerCase();
            Array.from(tbody.rows).forEach(row => {
                row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
            });
        });
    },

    // ── Confirm dialog ────────────────────────────────
    confirmDelete(message) {
        return confirm(message || 'Are you sure you want to delete this item? This action cannot be undone.');
    },

    // ── Charts defaults ───────────────────────────────
    setChartDefaults() {
        if (typeof Chart !== 'undefined') {
            Chart.defaults.color = '#9999bb';
            Chart.defaults.borderColor = 'rgba(42,42,58,0.8)';
            Chart.defaults.font.family = "'Inter', sans-serif";
            Chart.defaults.font.size = 12;
        }
    }
};

// ── Test Timer ─────────────────────────────────────────
class TestTimer {
    constructor(durationMinutes, onTimeUp) {
        this.remaining = durationMinutes * 60;
        this.onTimeUp = onTimeUp;
        this.intervalId = null;
        this.display = document.getElementById('timerDisplay');
        this.urgentThreshold = 60; // under 1 min = urgent
    }

    start() {
        this.render();
        this.intervalId = setInterval(() => {
            this.remaining--;
            this.render();
            if (this.remaining <= 0) {
                clearInterval(this.intervalId);
                this.onTimeUp();
            }
        }, 1000);
    }

    render() {
        if (!this.display) return;
        const m = Math.floor(this.remaining / 60);
        const s = this.remaining % 60;
        const mm = String(m).padStart(2, '0');
        const ss = String(s).padStart(2, '0');
        this.display.textContent = `⏱ ${mm}:${ss}`;
        if (this.remaining <= this.urgentThreshold) {
            this.display.closest('.timer-display')?.classList.add('urgent');
        }
    }

    stop() {
        if (this.intervalId) clearInterval(this.intervalId);
    }
}

// ── Test Progress Tracker ──────────────────────────────
class TestProgressTracker {
    constructor(totalQuestions) {
        this.total = totalQuestions;
        this.bar = document.getElementById('progressBar');
        this.progressText = document.getElementById('progressText');
        this.answeredText = document.getElementById('answeredCount');
    }

    init() {
        document.querySelectorAll('input[type="radio"]').forEach(radio => {
            radio.addEventListener('change', () => this.update());
        });
        this.update();
    }

    update() {
        const answered = document.querySelectorAll('input[type="radio"]:checked').length;
        const pct = this.total > 0 ? (answered / this.total) * 100 : 0;
        if (this.bar) this.bar.style.width = pct + '%';
        if (this.progressText) this.progressText.textContent = `${Math.round(pct)}%`;
        if (this.answeredText) this.answeredText.textContent = `${answered} / ${this.total}`;
    }
}

// ── Edit Question Population ──────────────────────────
function populateEditModal(qid, qtext, subject, difficulty, options) {
    document.getElementById('edit_question_id').value = qid;
    document.getElementById('edit_question_text').value = qtext;
    document.getElementById('edit_subject').value = subject;
    document.getElementById('edit_difficulty').value = difficulty;

    options.forEach((opt, i) => {
        const i1 = i + 1;
        const el = document.getElementById(`edit_option_${i1}`);
        if (el) el.value = opt.text;

        const radio = document.getElementById(`edit_correct_${i1}`);
        if (radio) radio.checked = opt.is_correct;
    });

    MCQ.openModal('editModal');
}

// ── Initialize on DOMContentLoaded ────────────────────
document.addEventListener('DOMContentLoaded', () => {
    MCQ.setChartDefaults();
    MCQ.initModals();
    MCQ.initFlash();

    // Generic table search
    MCQ.initTableSearch('tableSearch', 'tableBody');
});
