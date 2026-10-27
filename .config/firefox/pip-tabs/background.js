// No page content, URLs, network access, or native-messaging permission needed.
const queues = new Map();
const prefixes = new Map();

function refresh(windowId) {
  if (!Number.isInteger(windowId) || windowId < 0) return;
  const previous = queues.get(windowId) || Promise.resolve();
  const task = previous.catch(() => {}).then(async () => {
    const window = await browser.windows.get(windowId);
    if (window.type !== "normal") return;
    // Count every tab, including pinned, hidden and discarded tabs.
    const tabs = await browser.tabs.query({ windowId });
    const prefix = `[${tabs.length} ${tabs.length === 1 ? "tab" : "tabs"}] `;
    if (prefixes.get(windowId) === prefix) return;
    await browser.windows.update(windowId, { titlePreface: prefix });
    prefixes.set(windowId, prefix);
  }).catch(() => {}); // A window can disappear while querying it.
  queues.set(windowId, task);
  void task.then(() => {
    if (queues.get(windowId) === task) queues.delete(windowId);
  });
}

browser.tabs.onCreated.addListener(tab => refresh(tab.windowId));
browser.tabs.onRemoved.addListener((_id, info) => refresh(info.windowId));
browser.tabs.onAttached.addListener((_id, info) => refresh(info.newWindowId));
browser.tabs.onDetached.addListener((_id, info) => refresh(info.oldWindowId));
browser.tabs.onUpdated.addListener((_id, _changes, tab) => refresh(tab.windowId));
browser.windows.onCreated.addListener(window => refresh(window.id));
browser.windows.onRemoved.addListener(id => prefixes.delete(id));
browser.windows.getAll({ windowTypes: ["normal"] }).then(windows => {
  for (const window of windows) refresh(window.id);
}).catch(() => {});
