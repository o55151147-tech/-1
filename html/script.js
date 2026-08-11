const app = document.getElementById('app');
const itemsGrid = document.getElementById('items-grid');
const emptyState = document.getElementById('empty-state');
const categoryTabs = document.getElementById('category-tabs');
const levelLabel = document.getElementById('level-label');
const levelBarFill = document.getElementById('level-bar-fill');
const levelXpLabel = document.getElementById('level-xp-label');
const searchInput = document.getElementById('searchInput');
const closeBtn = document.getElementById('closeBtn');
const toastContainer = document.getElementById('toast-container');

const detailModal = document.getElementById('detail-modal');
const detailModalBackdrop = document.getElementById('detail-modal-backdrop');
const detailCloseBtn = document.getElementById('detailCloseBtn');
const detailIcon = document.getElementById('detail-icon');
const detailName = document.getElementById('detail-name');
const detailDesc = document.getElementById('detail-desc');
const requirementsList = document.getElementById('requirements-list');
const qtyInput = document.getElementById('qtyInput');
const qtyMinus = document.getElementById('qtyMinus');
const qtyPlus = document.getElementById('qtyPlus');
const craftBtn = document.getElementById('craftBtn');
const craftBtnLabel = document.getElementById('craftBtnLabel');
const progressWrap = document.getElementById('progress-wrap');
const progressFill = document.getElementById('progress-fill');
const progressLabel = document.getElementById('progress-label');

const ICONS = {
    lockpick: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="7" cy="16" r="4"/><path d="M9.5 13.5 18 5m0 0h-3.5M18 5v3.5m-3-1 3 3"/></svg>',
    weapon_bat: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20 15 9a3 3 0 1 0-4-4L2 16z"/><path d="M13 6l5 5"/></svg>',
    repairkit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a4 4 0 0 1-5.4 5.4L4 17l3 3 5.3-5.3a4 4 0 0 1 5.4-5.4l-3-3z"/></svg>',
    bandage: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="4"/><path d="M12 8v8M8 12h8"/></svg>',
    binoculars: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="7" cy="16" r="3.5"/><circle cx="17" cy="16" r="3.5"/><path d="M10.3 16h3.4M9 16V9a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v7"/></svg>',
    metalscrap: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/></svg>',
    plastic: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2 3 7v10l9 5 9-5V7z"/></svg>',
    rubber: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3.5"/></svg>',
    cloth: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5v4a3 3 0 0 0 3 3 3 3 0 0 0 0-6M20 5v4a3 3 0 0 1-3 3 3 3 0 0 1 0-6"/><path d="M8 6h8v14H8z"/></svg>',
    copperwire: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12h3l2-6 4 12 2-6h3l2 4h2"/></svg>',
    default: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5"/></svg>',
};

const CATEGORY_LABELS = {
    tools: 'أدوات',
    defense: 'دفاع',
    medical: 'طبي',
    utility: 'منفعة',
};

const LOCK_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="10" width="16" height="10"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>';

let allItems = [];
let counts = {};
let maxAmount = 10;
let selectedItem = null;
let searchTerm = '';
let currentCategory = 'all';
let isCrafting = false;
let levelInfo = { level: 0, xp: 0, maxLevel: 0, xpPerLevel: 100 };

function getIcon(name) {
    return ICONS[name] || ICONS.default;
}

// يحاول يحمّل img/<name>.png أولاً (صورة المستخدم)، ولو ما وجدها (404) يرجع لأيقونة SVG تلقائياً
function iconMarkup(name) {
    return `<img src="img/${name}.png" alt="${name}" onerror="handleIconError(this, '${name}')">`;
}

function handleIconError(imgEl, name) {
    const wrapper = imgEl.parentElement;
    if (wrapper) wrapper.innerHTML = getIcon(name);
}

function getResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'scrap-crafting';
}

function postNui(endpoint, data) {
    return fetch(`https://${getResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    });
}

function showToast(message, type) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    toastContainer.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
}

function hasEnough(item, qty) {
    return item.ingredients.every((ing) => (counts[ing.item] ?? 0) >= ing.amount * qty);
}

function isItemLocked(item) {
    return (item.requiredLevel || 0) > levelInfo.level;
}

function getFilteredItems() {
    return allItems.filter((item) => {
        const matchesCategory = currentCategory === 'all' || item.category === currentCategory;
        const matchesSearch = !searchTerm || item.label.toLowerCase().includes(searchTerm.toLowerCase());
        return matchesCategory && matchesSearch;
    });
}

function renderCategoryTabs() {
    const present = new Set(allItems.map((i) => i.category || 'utility'));
    const cats = ['all', ...Array.from(present)];

    categoryTabs.innerHTML = '';
    cats.forEach((cat) => {
        const label = cat === 'all' ? 'الكل' : (CATEGORY_LABELS[cat] || cat);

        const btn = document.createElement('button');
        btn.className = `category-tab ${cat === currentCategory ? 'active' : ''}`;
        btn.textContent = label;
        btn.addEventListener('click', () => {
            currentCategory = cat;
            renderCategoryTabs();
            renderList();
        });
        categoryTabs.appendChild(btn);
    });
}

function renderLevelWidget() {
    const atMax = levelInfo.level >= levelInfo.maxLevel;
    const xpIntoLevel = levelInfo.xp % levelInfo.xpPerLevel;
    const pct = atMax ? 100 : Math.min(100, (xpIntoLevel / levelInfo.xpPerLevel) * 100);

    levelLabel.textContent = `المستوى ${levelInfo.level}`;
    levelBarFill.style.width = `${pct}%`;
    levelXpLabel.textContent = atMax ? 'أقصى مستوى' : `${xpIntoLevel}/${levelInfo.xpPerLevel}`;
}

function renderList() {
    renderLevelWidget();

    const filtered = getFilteredItems();
    itemsGrid.innerHTML = '';

    if (filtered.length === 0) {
        itemsGrid.classList.add('hidden');
        emptyState.classList.remove('hidden');
        return;
    }

    itemsGrid.classList.remove('hidden');
    emptyState.classList.add('hidden');

    filtered.forEach((item) => {
        const locked = isItemLocked(item);
        const craftable = !locked && hasEnough(item, 1);
        const categoryLabel = CATEGORY_LABELS[item.category] || '';

        const card = document.createElement('div');
        card.className = `item-card ${locked ? 'locked' : ''}`;
        card.innerHTML = `
            ${locked ? '' : `<div class="craftable-dot ${craftable ? 'ok' : ''}"></div>`}
            <div class="card-icon">${iconMarkup(item.name)}</div>
            <div class="card-name">${item.label}</div>
            <div class="card-sub">${categoryLabel} · تصنع ${item.amount}</div>
            ${locked ? `<div class="lock-overlay">${LOCK_ICON}<span>يتطلب مستوى ${item.requiredLevel}</span></div>` : ''}
        `;

        card.addEventListener('click', () => {
            if (locked) {
                showToast(`يتطلب مستوى ${item.requiredLevel} (مستواك الحالي: ${levelInfo.level})`, 'error');
                return;
            }
            openDetail(item.name);
        });
        itemsGrid.appendChild(card);
    });
}

function openDetail(name) {
    selectedItem = allItems.find((i) => i.name === name) || null;
    if (!selectedItem) return;

    qtyInput.value = 1;
    detailModal.classList.remove('hidden');
    renderDetail();
}

function closeDetail() {
    detailModal.classList.add('hidden');
    selectedItem = null;
}

function renderDetail() {
    if (!selectedItem) return;

    detailIcon.innerHTML = iconMarkup(selectedItem.name);
    detailName.textContent = selectedItem.label;
    detailDesc.textContent = selectedItem.description || '';

    const qty = getQty();
    requirementsList.innerHTML = '';
    selectedItem.ingredients.forEach((ing) => {
        const have = counts[ing.item] ?? 0;
        const need = ing.amount * qty;
        const ok = have >= need;

        const row = document.createElement('div');
        row.className = 'req-item';
        row.innerHTML = `
            <div class="req-icon">${iconMarkup(ing.item)}</div>
            <div class="req-name">${ing.item}</div>
            <div class="req-count ${ok ? 'ok' : 'missing'}">${have}/${need}</div>
        `;
        requirementsList.appendChild(row);
    });

    const canCraft = hasEnough(selectedItem, qty) && !isCrafting;
    craftBtn.disabled = !canCraft;
    craftBtnLabel.textContent = isCrafting ? 'جاري التصنيع...' : `تصنيع (يعطي ${selectedItem.amount * qty})`;
}

function getQty() {
    let qty = parseInt(qtyInput.value, 10);
    if (isNaN(qty) || qty < 1) qty = 1;
    if (qty > maxAmount) qty = maxAmount;
    return qty;
}

function setQty(qty) {
    if (qty < 1) qty = 1;
    if (qty > maxAmount) qty = maxAmount;
    qtyInput.value = qty;
    renderDetail();
}

qtyMinus.addEventListener('click', () => setQty(getQty() - 1));
qtyPlus.addEventListener('click', () => setQty(getQty() + 1));
qtyInput.addEventListener('change', () => setQty(getQty()));

detailCloseBtn.addEventListener('click', closeDetail);
detailModalBackdrop.addEventListener('click', closeDetail);

searchInput.addEventListener('input', (e) => {
    searchTerm = e.target.value;
    renderList();
});

craftBtn.addEventListener('click', () => {
    if (!selectedItem || craftBtn.disabled || isCrafting) return;

    const qty = getQty();
    const craftTimeMs = Math.min((selectedItem.time || 5000) * qty, 60000);

    isCrafting = true;
    craftBtn.disabled = true;
    craftBtnLabel.textContent = 'جاري التصنيع...';
    progressWrap.classList.remove('hidden');
    progressLabel.textContent = `جاري تصنيع ${selectedItem.label}...`;
    progressFill.style.transition = 'none';
    progressFill.style.width = '0%';

    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            progressFill.style.transition = `width ${craftTimeMs}ms linear`;
            progressFill.style.width = '100%';
        });
    });

    postNui('craft', { item: selectedItem.name, amount: qty });
});

function openMenu(data) {
    allItems = data.items || [];
    counts = data.counts || {};
    maxAmount = data.maxAmount || 10;
    levelInfo = data.level || levelInfo;
    searchTerm = '';
    currentCategory = 'all';
    isCrafting = false;
    searchInput.value = '';

    app.classList.remove('hidden');
    closeDetail();
    renderCategoryTabs();
    renderList();
}

function closeMenu() {
    app.classList.add('hidden');
    closeDetail();
}

closeBtn.addEventListener('click', () => {
    closeMenu();
    postNui('close');
});

document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;

    if (!detailModal.classList.contains('hidden')) {
        closeDetail();
        return;
    }

    closeMenu();
    postNui('close');
});

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'open':
            openMenu(data);
            break;
        case 'close':
            closeMenu();
            break;
        case 'craftResult':
            isCrafting = false;
            counts = data.counts || counts;
            levelInfo = data.level || levelInfo;
            progressWrap.classList.add('hidden');
            progressFill.style.transition = 'none';
            progressFill.style.width = '0%';
            showToast(data.message, data.success ? 'success' : 'error');
            renderList();
            if (selectedItem) renderDetail();
            break;
    }
});
