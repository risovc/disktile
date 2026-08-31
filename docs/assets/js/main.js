/**
 * DiskTile — Official Website Controller & Interactive Showcase
 * Author: Risov Chakrabortty (risov@chakrabortty.in)
 */

document.addEventListener('DOMContentLoaded', () => {
  initClock();
  initThemeToggle();
  initShowcase();
  initCopyButtons();
  initFaqAccordion();
  initDock();
});

// MARK: - Live macOS Menu Bar Clock
function initClock() {
  const clockEl = document.getElementById('menubarClock');
  if (!clockEl) return;

  function update() {
    const now = new Date();
    const options = { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true };
    clockEl.innerText = now.toLocaleDateString('en-US', options).replace(/,/g, '');
  }
  update();
  setInterval(update, 1000);
}

// MARK: - Dark / Light Theme Toggle
function initThemeToggle() {
  const toggleBtn = document.getElementById('themeToggleBtn');
  if (!toggleBtn) return;

  const savedTheme = localStorage.getItem('disktile-theme') || 'dark';
  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeIcon(savedTheme);

  toggleBtn.addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme') || 'dark';
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('disktile-theme', next);
    updateThemeIcon(next);
    showToast(next === 'dark' ? "🌙 macOS Dark Appearance" : "☀️ macOS Light Appearance");
    // Trigger treemap re-render to update colors
    if (window.showcaseApp) window.showcaseApp.render();
  });
}

function updateThemeIcon(theme) {
  const toggleBtn = document.getElementById('themeToggleBtn');
  if (!toggleBtn) return;
  toggleBtn.innerHTML = theme === 'dark' ? '☀️' : '🌙';
  toggleBtn.setAttribute('title', `Switch to ${theme === 'dark' ? 'Light' : 'Dark'} mode`);
}

// MARK: - Interactive Showcase App Sandbox
function initShowcase() {
  const devData = {
    name: "MacBook Pro (~/)",
    path: "/Users/alex",
    size: 348200000000,
    category: "System & App Support",
    isDirectory: true,
    children: [
      {
        name: "Library",
        path: "/Users/alex/Library",
        size: 138400000000,
        category: "System & App Support",
        isDirectory: true,
        children: [
          {
            name: "Developer",
            path: "/Users/alex/Library/Developer",
            size: 78200000000,
            category: "Developer & Builds",
            isDirectory: true,
            children: [
              {
                name: "Xcode",
                path: "/Users/alex/Library/Developer/Xcode",
                size: 64100000000,
                category: "Developer & Builds",
                isDirectory: true,
                children: [
                  {
                    name: "DerivedData (Module Caches)",
                    path: "/Users/alex/Library/Developer/Xcode/DerivedData",
                    size: 48600000000,
                    category: "Developer & Builds",
                    isDirectory: true,
                    children: []
                  },
                  {
                    name: "Archives (IPA Builds)",
                    path: "/Users/alex/Library/Developer/Xcode/Archives",
                    size: 15500000000,
                    category: "Archives & Disk Images",
                    isDirectory: true,
                    children: []
                  }
                ]
              },
              {
                name: "CoreSimulator Caches",
                path: "/Users/alex/Library/Developer/CoreSimulator",
                size: 14100000000,
                category: "System & App Support",
                isDirectory: true,
                children: []
              }
            ]
          },
          {
            name: "Caches",
            path: "/Users/alex/Library/Caches",
            size: 36400000000,
            category: "Caches & Temporary",
            isDirectory: true,
            children: [
              { name: "com.apple.dt.Xcode", path: "/Users/alex/Library/Caches/Xcode", size: 14200000000, category: "Caches & Temporary", isDirectory: false },
              { name: "Google/Chrome Cache", path: "/Users/alex/Library/Caches/Chrome", size: 9800000000, category: "Caches & Temporary", isDirectory: false },
              { name: "Homebrew Caches", path: "/Users/alex/Library/Caches/Homebrew", size: 7500000000, category: "Caches & Temporary", isDirectory: false },
              { name: "CocoaPods Cache", path: "/Users/alex/Library/Caches/CocoaPods", size: 4900000000, category: "Caches & Temporary", isDirectory: false }
            ]
          },
          {
            name: "Application Support",
            path: "/Users/alex/Library/Application Support",
            size: 23800000000,
            category: "System & App Support",
            isDirectory: true,
            children: [
              { name: "Docker Desktop VM Disk", path: "/Users/alex/Library/Application Support/Docker", size: 16200000000, category: "Developer & Builds", isDirectory: false },
              { name: "VS Code Extensions", path: "/Users/alex/Library/Application Support/Code", size: 7600000000, category: "Developer & Builds", isDirectory: false }
            ]
          }
        ]
      },
      {
        name: "Projects",
        path: "/Users/alex/Projects",
        size: 94500000000,
        category: "Developer & Builds",
        isDirectory: true,
        children: [
          {
            name: "node_modules (React & Next.js)",
            path: "/Users/alex/Projects/App/node_modules",
            size: 24600000000,
            category: "Developer & Builds",
            isDirectory: true,
            children: []
          },
          {
            name: "Rust target (Debug & Release)",
            path: "/Users/alex/Projects/Engine/target",
            size: 19800000000,
            category: "Developer & Builds",
            isDirectory: true,
            children: []
          },
          {
            name: ".venv (PyTorch & ML Models)",
            path: "/Users/alex/Projects/AI/.venv",
            size: 18400000000,
            category: "Hidden & Dotfiles",
            isHidden: true,
            isDirectory: true,
            children: []
          },
          {
            name: ".git Repositories",
            path: "/Users/alex/Projects/.git",
            size: 9400000000,
            category: "Hidden & Dotfiles",
            isHidden: true,
            isDirectory: true,
            children: []
          },
          {
            name: "Source Code & Assets",
            path: "/Users/alex/Projects/src",
            size: 22300000000,
            category: "Developer & Builds",
            isDirectory: true,
            children: []
          }
        ]
      },
      {
        name: ".cache (Package Managers)",
        path: "/Users/alex/.cache",
        size: 46200000000,
        category: "Hidden & Dotfiles",
        isHidden: true,
        isDirectory: true,
        children: [
          { name: ".npm/_cacache", path: "/Users/alex/.npm/_cacache", size: 18200000000, category: "Caches & Temporary", isHidden: true, isDirectory: false },
          { name: ".cargo/registry", path: "/Users/alex/.cargo/registry", size: 14600000000, category: "Caches & Temporary", isHidden: true, isDirectory: false },
          { name: ".gradle/caches", path: "/Users/alex/.gradle/caches", size: 13400000000, category: "Caches & Temporary", isHidden: true, isDirectory: false }
        ]
      },
      {
        name: "Downloads",
        path: "/Users/alex/Downloads",
        size: 42800000000,
        category: "Archives & Disk Images",
        isDirectory: true,
        children: [
          { name: "Xcode_16_Beta_4.xip", path: "/Users/alex/Downloads/Xcode_16.xip", size: 16800000000, category: "Archives & Disk Images", isDirectory: false },
          { name: "macOS_Sequoia_Installer.dmg", path: "/Users/alex/Downloads/macOS.dmg", size: 14200000000, category: "Archives & Disk Images", isDirectory: false },
          { name: "Android_Studio.dmg", path: "/Users/alex/Downloads/Android_Studio.dmg", size: 6200000000, category: "Archives & Disk Images", isDirectory: false },
          { name: "Ubuntu_ARM64.iso", path: "/Users/alex/Downloads/Ubuntu.iso", size: 5600000000, category: "Archives & Disk Images", isDirectory: false }
        ]
      },
      {
        name: "Documents",
        path: "/Users/alex/Documents",
        size: 16200000000,
        category: "Documents & Data",
        isDirectory: true,
        children: [
          { name: "Database_Dump.sql.gz", path: "/Users/alex/Documents/db.sql.gz", size: 12400000000, category: "Archives & Disk Images", isDirectory: false },
          { name: "Design_Spec_v4.pdf", path: "/Users/alex/Documents/spec.pdf", size: 3800000000, category: "Documents & Data", isDirectory: false }
        ]
      },
      {
        name: ".Trash",
        path: "/Users/alex/.Trash",
        size: 10100000000,
        category: "Hidden & Dotfiles",
        isHidden: true,
        isDirectory: true,
        children: []
      }
    ]
  };

  const mediaData = {
    name: "Media Studio Mac (~/)",
    path: "/Users/creator",
    size: 420500000000,
    category: "Media & Videos",
    isDirectory: true,
    children: [
      {
        name: "Final Cut Projects",
        path: "/Users/creator/Movies/Final Cut Projects",
        size: 182400000000,
        category: "Media & Videos",
        isDirectory: true,
        children: [
          { name: "Commercial_4K_ProRes.mov", path: "/Users/creator/Movies/FCP/4K.mov", size: 78200000000, category: "Media & Videos", isDirectory: false },
          { name: "Render & Optical Flow Files", path: "/Users/creator/Movies/FCP/Render", size: 64500000000, category: "Caches & Temporary", isDirectory: true },
          { name: "120fps High-Speed B-Roll", path: "/Users/creator/Movies/FCP/BRoll", size: 39700000000, category: "Media & Videos", isDirectory: false }
        ]
      },
      {
        name: "Lightroom Catalog & RAWs",
        path: "/Users/creator/Pictures/Lightroom",
        size: 115000000000,
        category: "Media & Videos",
        isDirectory: true,
        children: [
          { name: "2026_Studio_RAWs", path: "/Users/creator/Pictures/RAWs", size: 73000000000, category: "Media & Videos", isDirectory: true },
          { name: "Previews.lrdata (Cache)", path: "/Users/creator/Pictures/Previews", size: 42000000000, category: "Caches & Temporary", isDirectory: true }
        ]
      },
      {
        name: "Sound Effects & Audio FX",
        path: "/Users/creator/Audio/SFX",
        size: 48500000000,
        category: "Media & Videos",
        isDirectory: true,
        children: []
      },
      {
        name: "Downloads & Video Assets",
        path: "/Users/creator/Downloads",
        size: 58600000000,
        category: "Archives & Disk Images",
        isDirectory: true,
        children: [
          { name: "DaVinci_Resolve_Studio.dmg", path: "/Users/creator/Downloads/DaVinci.dmg", size: 14800000000, category: "Archives & Disk Images", isDirectory: false },
          { name: "Master_Audio_Library.zip", path: "/Users/creator/Downloads/Audio.zip", size: 28400000000, category: "Archives & Disk Images", isDirectory: false }
        ]
      },
      {
        name: ".Trash",
        path: "/Users/creator/.Trash",
        size: 16000000000,
        category: "Hidden & Dotfiles",
        isHidden: true,
        isDirectory: true,
        children: []
      }
    ]
  };

  class ShowcaseController {
    constructor() {
      this.currentData = JSON.parse(JSON.stringify(devData));
      this.currentScope = this.currentData;
      this.selectedItem = this.currentData.children[0];
      this.showHidden = true;
      this.history = [];

      this.canvas = document.getElementById('showcaseCanvas');
      this.breadcrumbs = document.getElementById('showcaseBreadcrumbs');
      this.inspector = document.getElementById('showcaseInspector');
      this.trashZone = document.getElementById('showcaseTrashZone');

      this.bindEvents();
      this.render();
    }

    bindEvents() {
      window.addEventListener('resize', () => this.render());

      // Dataset tabs
      document.querySelectorAll('.showcase-tab').forEach(tab => {
        tab.addEventListener('click', () => {
          document.querySelectorAll('.showcase-tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          const type = tab.dataset.preset;
          this.currentData = JSON.parse(JSON.stringify(type === 'media' ? mediaData : devData));
          this.currentScope = this.currentData;
          this.selectedItem = this.currentData.children[0];
          this.history = [];
          this.render();
          showToast(`Switched demo dataset to: ${tab.innerText}`);
        });
      });

      // Hidden files toggle
      const hiddenBtn = document.getElementById('showcaseHiddenBtn');
      if (hiddenBtn) {
        hiddenBtn.addEventListener('click', () => {
          this.showHidden = !this.showHidden;
          hiddenBtn.classList.toggle('active', this.showHidden);
          this.render();
          showToast(this.showHidden ? "👁️ Showing dotfiles & hidden directories" : "🚫 Hiding dotfiles");
        });
      }

      // Rescan button
      const rescanBtn = document.getElementById('showcaseRescanBtn');
      if (rescanBtn) {
        rescanBtn.addEventListener('click', () => {
          showToast("🔄 Storage tree rescanned");
          this.render();
        });
      }

      // Drag & Drop to Trash
      if (this.trashZone) {
        this.trashZone.addEventListener('dragover', (e) => {
          e.preventDefault();
          this.trashZone.classList.add('dragover');
        });
        this.trashZone.addEventListener('dragleave', () => {
          this.trashZone.classList.remove('dragover');
        });
        this.trashZone.addEventListener('drop', (e) => {
          e.preventDefault();
          this.trashZone.classList.remove('dragover');
          const path = e.dataTransfer.getData('text/plain');
          if (path) {
            this.deleteItem(path);
          }
        });
      }
    }

    deleteItem(path) {
      const freed = this.removeNode(this.currentData, path);
      if (freed > 0) {
        showToast(`🗑️ Moved to Trash! Reclaimed ${formatBytes(freed)}`);
        this.currentScope = this.findNode(this.currentData, this.currentScope.path) || this.currentData;
        this.selectedItem = (this.currentScope.children && this.currentScope.children.length > 0) ? this.currentScope.children[0] : this.currentScope;
        this.render();
      }
    }

    removeNode(parent, path) {
      if (!parent || !parent.children) return 0;
      for (let i = 0; i < parent.children.length; i++) {
        const c = parent.children[i];
        if (c.path === path) {
          const freed = c.size;
          parent.children.splice(i, 1);
          parent.size = Math.max(0, parent.size - freed);
          return freed;
        }
        const freed = this.removeNode(c, path);
        if (freed > 0) {
          parent.size = Math.max(0, parent.size - freed);
          return freed;
        }
      }
      return 0;
    }

    findNode(parent, path) {
      if (!parent) return null;
      if (parent.path === path) return parent;
      if (!parent.children) return null;
      for (const c of parent.children) {
        const f = this.findNode(c, path);
        if (f) return f;
      }
      return null;
    }

    render() {
      this.renderBreadcrumbs();
      this.renderTreemap();
      this.renderInspector();
    }

    renderBreadcrumbs() {
      this.breadcrumbs.innerHTML = '';
      const trail = [];
      let curr = this.currentScope;
      while (curr) {
        trail.unshift(curr);
        curr = this.findParent(this.currentData, curr.path);
      }

      trail.forEach((item, idx) => {
        const isLast = idx === trail.length - 1;
        const crumb = document.createElement('div');
        crumb.className = `crumb-item ${isLast ? 'current' : ''}`;
        crumb.innerHTML = `<span>${getEmoji(item.category)}</span> <span>${item.name}</span>`;
        crumb.addEventListener('click', () => {
          this.currentScope = item;
          this.selectedItem = item;
          this.render();
        });
        this.breadcrumbs.appendChild(crumb);

        if (!isLast) {
          const sep = document.createElement('span');
          sep.style.cssText = 'color:var(--text-muted);font-size:10px;';
          sep.innerText = '›';
          this.breadcrumbs.appendChild(sep);
        }
      });
    }

    findParent(root, path) {
      if (!root || !root.children) return null;
      for (const c of root.children) {
        if (c.path === path) return root;
        const found = this.findParent(c, path);
        if (found) return found;
      }
      return null;
    }

    renderTreemap() {
      this.canvas.innerHTML = '';
      const rect = this.canvas.getBoundingClientRect();
      const bounds = { x: 0, y: 0, width: rect.width - 12, height: rect.height - 12 };

      const items = (this.currentScope.children || []).filter(n => {
        if (!this.showHidden && n.isHidden) return false;
        return n.size > 0;
      });

      const tiles = this.computeTreemap(items, bounds);

      tiles.forEach(tile => {
        const el = document.createElement('div');
        el.className = `interactive-tile ${getCategoryGradientClass(tile.node.category)}`;
        el.style.left = `${tile.x}px`;
        el.style.top = `${tile.y}px`;
        el.style.width = `${tile.width}px`;
        el.style.height = `${tile.height}px`;

        if (this.selectedItem && this.selectedItem.path === tile.node.path) {
          el.classList.add('selected');
        }

        el.draggable = true;
        el.dataset.path = tile.node.path;

        const isLarge = tile.width > 70 && tile.height > 48;
        const isMed = tile.width > 40 && tile.height > 28;

        if (isLarge) {
          el.innerHTML = `
            <div style="display:flex;align-items:center;gap:4px;overflow:hidden;">
              <span style="font-size:11px;">${getEmoji(tile.node.category)}</span>
              <span style="font-size:11px;font-weight:600;color:white;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${tile.node.name}</span>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:flex-end;">
              <span style="font-size:12px;font-weight:700;color:white;">${formatBytes(tile.node.size)}</span>
              ${tile.node.isHidden ? '<span style="font-size:8px;font-weight:700;background:rgba(0,0,0,0.4);color:#eee;padding:1px 4px;border-radius:3px;">HIDDEN</span>' : ''}
            </div>
          `;
        } else if (isMed) {
          el.innerHTML = `
            <span style="font-size:10px;font-weight:600;color:white;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${tile.node.name}</span>
            <span style="font-size:10px;font-weight:700;color:white;">${formatBytes(tile.node.size)}</span>
          `;
        }

        // Single click: Select
        el.addEventListener('click', (e) => {
          e.stopPropagation();
          this.selectedItem = tile.node;
          document.querySelectorAll('.interactive-tile').forEach(t => t.classList.toggle('selected', t.dataset.path === tile.node.path));
          this.renderInspector();
        });

        // Double click: Drill down
        el.addEventListener('dblclick', (e) => {
          e.stopPropagation();
          if (tile.node.isDirectory && tile.node.children && tile.node.children.length > 0) {
            this.currentScope = tile.node;
            this.selectedItem = tile.node.children[0];
            this.render();
          } else {
            showToast(`Inspecting: ${tile.node.name} (${formatBytes(tile.node.size)})`);
          }
        });

        // Drag handlers
        el.addEventListener('dragstart', (e) => {
          el.classList.add('dragging');
          e.dataTransfer.setData('text/plain', tile.node.path);
        });
        el.addEventListener('dragend', () => {
          el.classList.remove('dragging');
        });

        this.canvas.appendChild(el);
      });
    }

    computeTreemap(items, bounds) {
      if (!items || items.length === 0 || bounds.width <= 4 || bounds.height <= 4) return [];
      const totalSize = items.reduce((acc, c) => acc + c.size, 0);
      if (totalSize <= 0) return [];
      const totalArea = bounds.width * bounds.height;
      const elements = items.map(n => ({ node: n, area: (n.size / totalSize) * totalArea }));

      const tiles = [];
      let rem = { x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height };
      let row = [];

      const worst = (r, len) => {
        if (!r.length || len <= 0) return Infinity;
        const area = r.reduce((s, i) => s + i.area, 0);
        const w = area / len;
        if (w <= 0) return Infinity;
        let max = 0;
        for (const it of r) {
          const h = it.area / w;
          if (h <= 0) continue;
          const ratio = Math.max(w / h, h / w);
          if (ratio > max) max = ratio;
        }
        return max;
      };

      const layout = (r, box) => {
        if (!r.length) return;
        const area = r.reduce((s, i) => s + i.area, 0);
        const isH = box.width >= box.height;
        if (isH) {
          const w = area / box.height;
          let curY = box.y;
          for (const it of r) {
            const h = it.area / w;
            tiles.push({ node: it.node, x: box.x + 2, y: curY + 2, width: Math.max(2, w - 4), height: Math.max(2, h - 4) });
            curY += h;
          }
          box.x += w;
          box.width = Math.max(0, box.width - w);
        } else {
          const h = area / box.width;
          let curX = box.x;
          for (const it of r) {
            const w = it.area / h;
            tiles.push({ node: it.node, x: curX + 2, y: box.y + 2, width: Math.max(2, w - 4), height: Math.max(2, h - 4) });
            curX += w;
          }
          box.y += h;
          box.height = Math.max(0, box.height - h);
        }
      };

      for (const it of elements) {
        const short = Math.min(rem.width, rem.height);
        if (!row.length) {
          row.push(it);
        } else {
          const curW = worst(row, short);
          const nextW = worst([...row, it], short);
          if (nextW <= curW) {
            row.push(it);
          } else {
            layout(row, rem);
            row = [it];
          }
        }
      }
      if (row.length) layout(row, rem);
      return tiles;
    }

    renderInspector() {
      if (!this.selectedItem) return;
      const node = this.selectedItem;
      const scopeSize = this.currentScope.size || 1;
      const pct = Math.min(100, Math.max(0, (node.size / scopeSize) * 100));

      this.inspector.innerHTML = `
        <div class="inspector-node-header">
          <div class="inspector-icon-box ${getCategoryGradientClass(node.category)}">
            ${getEmoji(node.category)}
          </div>
          <div>
            <div style="font-size:13px;font-weight:600;line-height:1.2;">${node.name}</div>
            <div style="font-size:11px;color:var(--text-secondary);">${node.category}</div>
          </div>
        </div>

        <div class="inspector-stats-box">
          <div class="stat-row">
            <span class="stat-name">Size</span>
            <span class="stat-val" style="color:var(--accent-teal);font-size:13px;">${formatBytes(node.size)}</span>
          </div>
          <div>
            <div style="display:flex;justify-content:space-between;font-size:10px;color:var(--text-muted);">
              <span>% of view</span>
              <span>${pct.toFixed(1)}%</span>
            </div>
            <div class="stat-progress-bar">
              <div class="stat-progress-fill" style="width:${pct}%"></div>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-name">Type</span>
            <span class="stat-val">${node.isDirectory ? 'Folder' : 'File'}</span>
          </div>
          ${node.isHidden ? `
          <div class="stat-row">
            <span class="stat-name">Visibility</span>
            <span class="stat-val" style="color:var(--accent-orange);">Hidden (.dotfile)</span>
          </div>` : ''}
        </div>

        <div>
          <div style="font-size:10px;color:var(--text-muted);margin-bottom:4px;">POSIX Path</div>
          <div style="font-family:var(--font-mono);font-size:9px;background:var(--bg-glass);border:1px solid var(--border-glass);padding:6px;border-radius:4px;word-break:break-all;color:var(--text-secondary);">${node.path}</div>
        </div>

        <div style="margin-top:auto;display:flex;flex-direction:column;gap:6px;">
          ${node.isDirectory ? `
          <button class="tool-btn" id="showcaseDrillBtn" style="justify-content:center;padding:6px;">
            <span>🔍 Drill Down</span>
          </button>` : ''}
          <button class="tool-btn" id="showcaseDeleteBtn" style="justify-content:center;padding:6px;background:rgba(255,69,58,0.15);border-color:rgba(255,69,58,0.3);color:var(--accent-red);">
            <span>🗑️ Move to Trash</span>
          </button>
        </div>
      `;

      const drillBtn = document.getElementById('showcaseDrillBtn');
      if (drillBtn) {
        drillBtn.addEventListener('click', () => {
          this.currentScope = node;
          this.selectedItem = (node.children && node.children.length > 0) ? node.children[0] : node;
          this.render();
        });
      }

      const delBtn = document.getElementById('showcaseDeleteBtn');
      if (delBtn) {
        delBtn.addEventListener('click', () => this.deleteItem(node.path));
      }
    }
  }

  window.showcaseApp = new ShowcaseController();
}

// MARK: - Clipboard Copy Utilities
function initCopyButtons() {
  document.querySelectorAll('.copy-cmd-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const textToCopy = btn.dataset.copyText || btn.parentElement.querySelector('.cmd-text')?.innerText;
      if (textToCopy) {
        navigator.clipboard.writeText(textToCopy.trim());
        const original = btn.innerHTML;
        btn.innerHTML = '✓ Copied!';
        btn.style.background = 'var(--accent-green)';
        btn.style.borderColor = 'transparent';
        btn.style.color = 'white';
        showToast("📋 Command copied to clipboard!");
        setTimeout(() => {
          btn.innerHTML = original;
          btn.style.background = '';
          btn.style.borderColor = '';
          btn.style.color = '';
        }, 2200);
      }
    });
  });
}

// MARK: - FAQ Accordion
function initFaqAccordion() {
  document.querySelectorAll('.faq-question').forEach(q => {
    q.addEventListener('click', () => {
      const item = q.parentElement;
      const isActive = item.classList.contains('active');
      document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('active'));
      if (!isActive) {
        item.classList.add('active');
      }
    });
  });
}

// MARK: - Interactive macOS Dock
function initDock() {
  const dockItems = document.querySelectorAll('.dock-item');
  dockItems.forEach(item => {
    item.addEventListener('click', () => {
      const targetId = item.dataset.target;
      if (targetId) {
        const el = document.getElementById(targetId);
        if (el) {
          el.scrollIntoView({ behavior: 'smooth' });
        }
      }
    });
  });
}

// MARK: - Global Toast
function showToast(msg) {
  let toast = document.getElementById('siteToast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'siteToast';
    toast.className = 'web-toast';
    document.body.appendChild(toast);
  }
  toast.innerText = msg;
  toast.classList.add('show');
  clearTimeout(window.toastTimer);
  window.toastTimer = setTimeout(() => toast.classList.remove('show'), 2600);
}

function formatBytes(bytes) {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1000;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(1)} ${sizes[i]}`;
}

function getEmoji(cat) {
  switch (cat) {
    case 'Developer & Builds': return '🔨';
    case 'Caches & Temporary': return '🗑️';
    case 'Media & Videos': return '🎬';
    case 'Documents & Data': return '📄';
    case 'Archives & Disk Images': return '📦';
    case 'System & App Support': return '⚙️';
    case 'Hidden & Dotfiles': return '👁️‍🗨️';
    default: return '📁';
  }
}

function getCategoryGradientClass(cat) {
  switch (cat) {
    case 'Developer & Builds': return 'cat-developer';
    case 'Caches & Temporary': return 'cat-caches';
    case 'Media & Videos': return 'cat-media';
    case 'Documents & Data': return 'cat-documents';
    case 'Archives & Disk Images': return 'cat-archives';
    case 'System & App Support': return 'cat-system';
    case 'Hidden & Dotfiles': return 'cat-hidden';
    default: return 'cat-other';
  }
}
