// Run: node tests/test_firefox_pip.js
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const event = () => ({ addListener(fn) { this.fire = fn; } });
const windows = new Map([
  [1, { id: 1, type: 'normal', count: 1 }],
  [2, { id: 2, type: 'normal', count: 3 }],
  [3, { id: 3, type: 'popup', count: 1 }],
]);
const updates = [];
const browser = {
  tabs: {
    onCreated: event(), onRemoved: event(), onAttached: event(), onDetached: event(), onUpdated: event(),
    async query(options) {
      // Hidden/pinned tabs must not be filtered out of the total.
      assert.deepEqual(Object.keys(options), ['windowId']);
      return Array.from({ length: windows.get(options.windowId).count }, () => ({}));
    },
  },
  windows: {
    onCreated: event(), onRemoved: event(),
    async getAll() { return [...windows.values()]; },
    async get(id) { if (!windows.has(id)) throw new Error('closed'); return windows.get(id); },
    async update(id, options) { updates.push([id, options.titlePreface]); },
  },
};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../.config/firefox/pip-tabs/background.js'), 'utf8'), { browser });
async function settle() { for (let i = 0; i < 5; i++) await new Promise(resolve => setImmediate(resolve)); }
(async () => {
  await settle();
  assert.deepEqual(updates, [[1, '[1 tab] '], [2, '[3 tabs] ']]);
  windows.get(1).count = 2;
  browser.tabs.onCreated.fire({ windowId: 1 });
  browser.tabs.onUpdated.fire(5, {}, { windowId: 1 });
  await settle();
  assert.deepEqual(updates.at(-1), [1, '[2 tabs] ']);
  assert.equal(updates.filter(([id, prefix]) => id === 1 && prefix === '[2 tabs] ').length, 1);
  windows.get(1).count = 1;
  browser.tabs.onRemoved.fire(5, { windowId: 1 });
  await settle();
  assert.deepEqual(updates.at(-1), [1, '[1 tab] ']);
  windows.delete(1);
  browser.tabs.onRemoved.fire(6, { windowId: 1 });
  browser.windows.onRemoved.fire(1);
  await settle();
  assert.equal(updates.length, 4);
  console.log('Firefox add-on: counts, multiple windows, popup exclusion, event races and closed windows pass.');
})().catch(error => { console.error(error); process.exitCode = 1; });
