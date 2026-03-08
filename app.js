const STORAGE_KEY = 'allubooklet-items-v1';

const seedItems = [
  { id: crypto.randomUUID(), name: 'iPhone 15', price: 999, purchaseDate: daysAgo(160), usefulLife: 3 },
  { id: crypto.randomUUID(), name: 'MacBook Air M2', price: 1299, purchaseDate: daysAgo(420), usefulLife: 5 }
];

const state = {
  items: loadItems(),
  activePage: 'home'
};

const refs = {
  homeList: document.getElementById('itemList'),
  assetList: document.getElementById('assetList'),
  template: document.getElementById('itemCardTemplate'),
  totalPrice: document.getElementById('totalPrice'),
  totalResidual: document.getElementById('totalResidual'),
  totalAdv: document.getElementById('totalAdv'),
  statsCount: document.getElementById('statsCount'),
  statsDailyDep: document.getElementById('statsDailyDep'),
  statsAvgDays: document.getElementById('statsAvgDays'),
  pageTitle: document.getElementById('pageTitle'),
  modal: document.getElementById('addModal'),
  form: document.getElementById('addItemForm')
};

['openAdd', 'openAddFromFab', 'openAddFromTop'].forEach(id => {
  document.getElementById(id).addEventListener('click', openModal);
});

document.getElementById('closeModal').addEventListener('click', closeModal);
document.getElementById('cancelAdd').addEventListener('click', closeModal);

refs.form.addEventListener('submit', (event) => {
  event.preventDefault();
  const formData = new FormData(refs.form);
  const newItem = {
    id: crypto.randomUUID(),
    name: String(formData.get('name')).trim(),
    price: Number(formData.get('price')),
    purchaseDate: String(formData.get('purchaseDate')),
    usefulLife: Number(formData.get('usefulLife'))
  };

  if (!newItem.name || !newItem.purchaseDate || !Number.isFinite(newItem.price) || newItem.price <= 0) {
    return;
  }

  state.items.unshift(newItem);
  persistItems(state.items);
  render();
  refs.form.reset();
  closeModal();
});

document.querySelectorAll('.tab:not(.fab)').forEach((tab) => {
  tab.addEventListener('click', () => {
    const target = tab.dataset.tab;
    state.activePage = target;
    activatePage(target);

    document.querySelectorAll('.tab:not(.fab)').forEach((t) => t.classList.remove('active'));
    tab.classList.add('active');
  });
});

render();
activatePage(state.activePage);

function render() {
  refs.homeList.innerHTML = '';
  refs.assetList.innerHTML = '';

  if (!state.items.length) {
    const empty = '<p class="glass-card" style="padding:14px;border-radius:14px">No items yet. Add your first physical asset.</p>';
    refs.homeList.innerHTML = empty;
    refs.assetList.innerHTML = empty;
  }

  const totals = { price: 0, rv: 0, adv: 0, heldDays: 0, dailyDep: 0 };

  state.items.forEach((item) => {
    const metrics = calculateMetrics(item);
    totals.price += item.price;
    totals.rv += metrics.rv;
    totals.adv += metrics.adv;
    totals.heldDays += metrics.daysHeld;
    totals.dailyDep += metrics.dailyDepreciation;

    refs.homeList.appendChild(buildItemCard(item, metrics));
    refs.assetList.appendChild(buildItemCard(item, metrics));
  });

  refs.totalPrice.textContent = money(totals.price);
  refs.totalResidual.textContent = money(totals.rv);
  refs.totalAdv.textContent = money(totals.adv);
  refs.statsCount.textContent = String(state.items.length);
  refs.statsDailyDep.textContent = `${money(totals.dailyDep)} / day`;
  refs.statsAvgDays.textContent = state.items.length ? String(Math.round(totals.heldDays / state.items.length)) : '0';
}

function buildItemCard(item, metrics) {
  const node = refs.template.content.cloneNode(true);
  node.querySelector('.item-name').textContent = item.name;
  node.querySelector('.item-price').textContent = money(item.price);
  node.querySelector('.meta').textContent = `Bought ${formatDate(item.purchaseDate)} · Held ${metrics.daysHeld} days · Life ${item.usefulLife}y`;
  node.querySelector('.item-rv').textContent = money(metrics.rv);
  node.querySelector('.item-adv').textContent = `${money(metrics.adv)} / day`;
  return node;
}

function calculateMetrics(item) {
  const msPerDay = 1000 * 60 * 60 * 24;
  const held = Math.max(1, Math.floor((Date.now() - new Date(item.purchaseDate).getTime()) / msPerDay));
  const usefulLifeDays = Math.max(365, item.usefulLife * 365);
  const dailyDepreciation = item.price / usefulLifeDays;

  const rv = Math.max(0, item.price - (dailyDepreciation * held));
  const adv = item.price / held;

  return { rv, adv, daysHeld: held, dailyDepreciation };
}

function activatePage(page) {
  document.querySelectorAll('.page').forEach((el) => {
    el.classList.toggle('active-page', el.dataset.page === page);
  });

  const titleMap = {
    home: 'Asset Bookkeeper',
    stats: 'Analytics & Depreciation',
    assets: 'Assets Center',
    profile: 'Profile & Settings'
  };
  refs.pageTitle.textContent = titleMap[page] || 'Asset Bookkeeper';
}

function money(num) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(num);
}

function formatDate(date) {
  return new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function daysAgo(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d.toISOString().slice(0, 10);
}

function persistItems(items) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
}

function loadItems() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (!saved) {
    persistItems(seedItems);
    return seedItems;
  }

  try {
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? parsed : seedItems;
  } catch {
    return seedItems;
  }
}

function openModal() {
  refs.modal.showModal();
}

function closeModal() {
  refs.modal.close();
}
