/**
 * DiskTile — Squarified Treemap Layout & Interactive Controller
 */

class DiskTileApp {
  constructor() {
    this.rootData = null;
    this.currentScopeNode = null;
    this.selectedNode = null;
    this.historyStack = [];
    this.showHiddenFiles = true;
    this.currentScopePreset = 'developer';
    this.inspectorVisible = true;
    this.stagedTrashItems = [];
    
    this.container = document.getElementById('treemapContainer');
    this.breadcrumbBar = document.getElementById('breadcrumbBar');
    this.inspectorSidebar = document.getElementById('inspectorSidebar');
    this.trashDropZone = document.getElementById('trashDropZone');
    this.contextMenu = document.getElementById('contextMenu');
    this.quickCleanModal = document.getElementById('quickCleanModal');
    this.toast = document.getElementById('toastNotification');
    this.contextTargetNode = null;

    this.initEventListeners();
    this.loadStorageData('developer');
  }

  // MARK: - Event Listeners
  initEventListeners() {
    window.addEventListener('resize', () => this.renderTreemap());

    // Scope / Target selector buttons
    document.querySelectorAll('.segment-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        document.querySelectorAll('.segment-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const scope = btn.dataset.scope;
        this.currentScopePreset = scope;
        this.loadStorageData(scope);
      });
    });

    // Hidden files toggle
    const hiddenToggle = document.getElementById('toggleHiddenBtn');
    if (hiddenToggle) {
      hiddenToggle.addEventListener('click', () => {
        this.showHiddenFiles = !this.showHiddenFiles;
        hiddenToggle.classList.toggle('active', this.showHiddenFiles);
        this.showToast(this.showHiddenFiles ? "Showing hidden files and dotfolders" : "Hiding hidden files");
        this.renderTreemap();
      });
    }

    // Inspector toggle
    const inspectorToggle = document.getElementById('toggleInspectorBtn');
    if (inspectorToggle) {
      inspectorToggle.addEventListener('click', () => {
        this.inspectorVisible = !this.inspectorVisible;
        this.inspectorSidebar.classList.toggle('hidden', !this.inspectorVisible);
        setTimeout(() => this.renderTreemap(), 50);
      });
    }

    // Rescan button
    const rescanBtn = document.getElementById('rescanBtn');
    if (rescanBtn) {
      rescanBtn.addEventListener('click', () => {
        this.showToast("Rescanning storage hierarchy...");
        this.loadStorageData(this.currentScopePreset);
      });
    }

    // Quick Clean modal trigger
    const quickCleanBtn = document.getElementById('quickCleanBtn');
    if (quickCleanBtn) {
      quickCleanBtn.addEventListener('click', () => this.openQuickCleanModal());
    }

    // Search input
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase().trim();
        this.highlightMatchingTiles(query);
      });
    }

    // Drag and Drop to Trash Zone
    this.trashDropZone.addEventListener('dragover', (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      this.trashDropZone.classList.add('dragover');
    });

    this.trashDropZone.addEventListener('dragleave', () => {
      this.trashDropZone.classList.remove('dragover');
    });

    this.trashDropZone.addEventListener('drop', (e) => {
      e.preventDefault();
      this.trashDropZone.classList.remove('dragover');
      const nodePath = e.dataTransfer.getData('text/plain');
      if (nodePath) {
        this.moveToTrash(nodePath);
      }
    });

    // Close context menu on outside click
    document.addEventListener('click', (e) => {
      if (!this.contextMenu.contains(e.target)) {
        this.contextMenu.classList.remove('visible');
      }
    });
  }

  // MARK: - Data Loading
  async loadStorageData(scope = 'developer') {
    try {
      const url = `/api/scan?scope=${encodeURIComponent(scope)}&include_hidden=${this.showHiddenFiles}`;
      const res = await fetch(url);
      const data = await res.json();
      this.rootData = data;
      this.currentScopeNode = data;
      this.selectedNode = data.children && data.children.length > 0 ? data.children[0] : data;
      this.historyStack = [];

      this.updateBreadcrumbs();
      this.renderTreemap();
      this.updateInspector();
      this.updateDiskMeter();
    } catch (err) {
      console.error("Failed to load storage data:", err);
      this.showToast("Failed to load storage metrics");
    }
  }

  // MARK: - Treemap Layout Algorithm (Squarified)
  computeSquarifiedTreemap(items, bounds) {
    if (!items || items.length === 0 || bounds.width <= 4 || bounds.height <= 4) {
      return [];
    }

    const filtered = items.filter(n => {
      if (!this.showHiddenFiles && n.isHidden) return false;
      return n.size > 0;
    });

    if (filtered.length === 0) return [];

    const totalSize = filtered.reduce((acc, curr) => acc + curr.size, 0);
    if (totalSize <= 0) return [];

    const totalArea = bounds.width * bounds.height;
    const elements = filtered.map(node => ({
      node,
      area: (node.size / totalSize) * totalArea
    }));

    const tiles = [];
    let remaining = { x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height };
    let currentRow = [];

    const worstRatio = (row, length) => {
      if (!row.length || length <= 0) return Infinity;
      const rowArea = row.reduce((sum, item) => sum + item.area, 0);
      const rowWidth = rowArea / length;
      if (rowWidth <= 0) return Infinity;

      let worst = 0;
      for (const item of row) {
        const itemHeight = item.area / rowWidth;
        if (itemHeight <= 0) continue;
        const ratio = Math.max(rowWidth / itemHeight, itemHeight / rowWidth);
        if (ratio > worst) worst = ratio;
      }
      return worst;
    };

    const layoutRow = (row, boundingBox) => {
      if (!row.length) return;
      const rowArea = row.reduce((sum, item) => sum + item.area, 0);
      const isHorizontal = boundingBox.width >= boundingBox.height;

      if (isHorizontal) {
        const rowWidth = rowArea / boundingBox.height;
        let currentY = boundingBox.y;

        for (const item of row) {
          const itemHeight = item.area / rowWidth;
          tiles.push({
            node: item.node,
            x: boundingBox.x + 2,
            y: currentY + 2,
            width: Math.max(2, rowWidth - 4),
            height: Math.max(2, itemHeight - 4)
          });
          currentY += itemHeight;
        }

        boundingBox.x += rowWidth;
        boundingBox.width = Math.max(0, boundingBox.width - rowWidth);
      } else {
        const rowHeight = rowArea / boundingBox.width;
        let currentX = boundingBox.x;

        for (const item of row) {
          const itemWidth = item.area / rowHeight;
          tiles.push({
            node: item.node,
            x: currentX + 2,
            y: boundingBox.y + 2,
            width: Math.max(2, itemWidth - 4),
            height: Math.max(2, rowHeight - 4)
          });
          currentX += itemWidth;
        }

        boundingBox.y += rowHeight;
        boundingBox.height = Math.max(0, boundingBox.height - rowHeight);
      }
    };

    for (const item of elements) {
      const shortest = Math.min(remaining.width, remaining.height);
      if (currentRow.length === 0) {
        currentRow.push(item);
      } else {
        const currentWorst = worstRatio(currentRow, shortest);
        const candidate = [...currentRow, item];
        const nextWorst = worstRatio(candidate, shortest);

        if (nextWorst <= currentWorst) {
          currentRow.push(item);
        } else {
          layoutRow(currentRow, remaining);
          currentRow = [item];
        }
      }
    }

    if (currentRow.length > 0) {
      layoutRow(currentRow, remaining);
    }

    return tiles;
  }

  // MARK: - Render Treemap
  renderTreemap() {
    this.container.innerHTML = '';
    const rect = this.container.getBoundingClientRect();
    const bounds = { x: 0, y: 0, width: rect.width - 12, height: rect.height - 12 };

    const items = this.currentScopeNode ? (this.currentScopeNode.children || []) : [];
    const tiles = this.computeSquarifiedTreemap(items, bounds);

    if (!tiles.length) {
      const empty = document.createElement('div');
      empty.style.cssText = 'display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;color:var(--text-muted);gap:10px;';
      empty.innerHTML = `
        <span style="font-size:40px;">📁</span>
        <div style="font-size:14px;font-weight:600;color:var(--text-secondary)">No items found in this directory</div>
        <div style="font-size:12px;">The folder is empty or hidden files are filtered out.</div>
      `;
      this.container.appendChild(empty);
      return;
    }

    tiles.forEach(tile => {
      const el = document.createElement('div');
      el.className = `treemap-tile ${this.getCategoryClass(tile.node.category)}`;
      el.style.left = `${tile.x}px`;
      el.style.top = `${tile.y}px`;
      el.style.width = `${tile.width}px`;
      el.style.height = `${tile.height}px`;

      if (this.selectedNode && this.selectedNode.path === tile.node.path) {
        el.classList.add('selected');
      }

      el.draggable = true;
      el.dataset.path = tile.node.path;

      const isLarge = tile.width > 75 && tile.height > 50;
      const isMedium = tile.width > 45 && tile.height > 30;

      let innerHTML = '';
      if (isLarge) {
        innerHTML = `
          <div class="tile-header">
            <span class="tile-icon">${this.getCategoryEmoji(tile.node.category)}</span>
            <span class="tile-name" title="${this.escapeHtml(tile.node.name)}">${this.escapeHtml(tile.node.name)}</span>
            ${tile.node.isHidden ? '<span class="tile-badge-hidden">HIDDEN</span>' : ''}
          </div>
          <div class="tile-footer">
            <div class="tile-size">${this.formatBytes(tile.node.size)}</div>
            <div class="tile-meta">
              <span>${this.formatRelativeTime(tile.node.mtime)}</span>
              ${tile.node.isDirectory ? `<span>${tile.node.itemCount.toLocaleString()} items</span>` : ''}
            </div>
          </div>
        `;
      } else if (isMedium) {
        innerHTML = `
          <div class="tile-header">
            <span class="tile-name" style="font-size:10px;">${this.escapeHtml(tile.node.name)}</span>
          </div>
          <div class="tile-footer">
            <div class="tile-size" style="font-size:10px;">${this.formatBytes(tile.node.size)}</div>
          </div>
        `;
      }

      el.innerHTML = innerHTML;

      // Click: Select
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        this.selectNode(tile.node);
      });

      // Double Click: Drill Down
      el.addEventListener('dblclick', (e) => {
        e.stopPropagation();
        if (tile.node.isDirectory && tile.node.children && tile.node.children.length > 0) {
          this.drillDown(tile.node);
        } else {
          this.showToast(`Selected file: ${tile.node.name} (${this.formatBytes(tile.node.size)})`);
        }
      });

      // Right Click: Context Menu
      el.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        this.showContextMenu(e.clientX, e.clientY, tile.node);
      });

      // Drag Source
      el.addEventListener('dragstart', (e) => {
        el.classList.add('dragging');
        e.dataTransfer.setData('text/plain', tile.node.path);
        e.dataTransfer.effectAllowed = 'move';
      });

      el.addEventListener('dragend', () => {
        el.classList.remove('dragging');
      });

      this.container.appendChild(el);
    });
  }

  // MARK: - Navigation & Drilldown
  drillDown(node) {
    if (this.currentScopeNode) {
      this.historyStack.push(this.currentScopeNode);
    }
    this.currentScopeNode = node;
    this.selectedNode = node.children && node.children.length > 0 ? node.children[0] : node;
    this.updateBreadcrumbs();
    this.renderTreemap();
    this.updateInspector();
  }

  drillUp() {
    if (this.historyStack.length > 0) {
      this.currentScopeNode = this.historyStack.pop();
      this.selectedNode = this.currentScopeNode;
      this.updateBreadcrumbs();
      this.renderTreemap();
      this.updateInspector();
    }
  }

  navigateToNode(targetNode) {
    this.currentScopeNode = targetNode;
    this.selectedNode = targetNode;
    this.updateBreadcrumbs();
    this.renderTreemap();
    this.updateInspector();
  }

  selectNode(node) {
    this.selectedNode = node;
    document.querySelectorAll('.treemap-tile').forEach(tile => {
      tile.classList.toggle('selected', tile.dataset.path === node.path);
    });
    this.updateInspector();
  }

  updateBreadcrumbs() {
    this.breadcrumbBar.innerHTML = '';
    const trail = [];
    let curr = this.currentScopeNode;

    // Build hierarchy backwards
    while (curr) {
      trail.unshift(curr);
      // Find parent in rootData
      curr = this.findParent(this.rootData, curr.path);
    }

    trail.forEach((item, index) => {
      const isLast = index === trail.length - 1;
      const el = document.createElement('div');
      el.className = `breadcrumb-item ${isLast ? 'current' : ''}`;
      el.innerHTML = `
        <span>${this.getCategoryEmoji(item.category)}</span>
        <span>${this.escapeHtml(item.name || item.path)}</span>
      `;
      el.addEventListener('click', () => {
        this.navigateToNode(item);
      });
      this.breadcrumbBar.appendChild(el);

      if (!isLast) {
        const sep = document.createElement('span');
        sep.className = 'breadcrumb-sep';
        sep.innerText = '›';
        this.breadcrumbBar.appendChild(sep);
      }
    });
  }

  findParent(root, targetPath) {
    if (!root || !root.children) return null;
    for (const child of root.children) {
      if (child.path === targetPath) return root;
      const found = this.findParent(child, targetPath);
      if (found) return found;
    }
    return null;
  }

  // MARK: - Inspector Panel
  updateInspector() {
    if (!this.selectedNode) {
      this.inspectorSidebar.innerHTML = `
        <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;color:var(--text-muted);gap:8px;text-align:center;">
          <span style="font-size:32px;">👆</span>
          <div style="font-size:13px;font-weight:500;color:var(--text-secondary);">Select a Tile</div>
          <div style="font-size:11px;">Click on any tile to inspect file details and options.</div>
        </div>
      `;
      return;
    }

    const node = this.selectedNode;
    const scopeSize = this.currentScopeNode ? this.currentScopeNode.size : 1;
    const percentOfScope = Math.min(100, Math.max(0, (node.size / (scopeSize || 1)) * 100));

    this.inspectorSidebar.innerHTML = `
      <div class="inspector-header">
        <div class="inspector-avatar ${this.getCategoryClass(node.category)}">
          ${this.getCategoryEmoji(node.category)}
        </div>
        <div>
          <div class="inspector-title">${this.escapeHtml(node.name)}</div>
          <div class="inspector-category">${this.escapeHtml(node.category)}</div>
        </div>
      </div>

      <div class="metric-group">
        <div class="metric-row">
          <span class="metric-label">Size</span>
          <span class="metric-value" style="color:var(--accent-teal);font-size:14px;">${this.formatBytes(node.size)}</span>
        </div>
        <div class="progress-bar-container">
          <div style="display:flex;justify-content:space-between;font-size:10px;color:var(--text-muted);">
            <span>% of current view</span>
            <span>${percentOfScope.toFixed(1)}%</span>
          </div>
          <div class="progress-track">
            <div class="progress-fill" style="width:${percentOfScope}%"></div>
          </div>
        </div>
        ${node.isDirectory ? `
        <div class="metric-row">
          <span class="metric-label">Items Contained</span>
          <span class="metric-value">${node.itemCount.toLocaleString()}</span>
        </div>` : ''}
        <div class="metric-row">
          <span class="metric-label">Last Modified</span>
          <span class="metric-value">${new Date(node.mtime * 1000).toLocaleDateString()} ${new Date(node.mtime * 1000).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}</span>
        </div>
        <div class="metric-row">
          <span class="metric-label">Relative Age</span>
          <span class="metric-value">${this.formatRelativeTime(node.mtime)}</span>
        </div>
        <div class="metric-row">
          <span class="metric-label">Type</span>
          <span class="metric-value">${node.isDirectory ? 'Directory Folder' : 'File'}</span>
        </div>
        ${node.isHidden ? `
        <div class="metric-row">
          <span class="metric-label">Visibility</span>
          <span class="metric-value" style="color:var(--accent-orange);">Hidden (.dotfile)</span>
        </div>` : ''}
      </div>

      <div>
        <div style="font-size:11px;color:var(--text-secondary);margin-bottom:4px;">Full POSIX Path</div>
        <div class="path-box">${this.escapeHtml(node.path)}</div>
      </div>

      <div class="inspector-actions">
        ${node.isDirectory ? `
        <button class="btn-inspector secondary" id="inspectorDrillBtn">
          <span>🔍 Drill Down</span>
        </button>` : ''}
        <button class="btn-inspector secondary" id="inspectorCopyBtn">
          <span>📋 Copy Full Path</span>
        </button>
        <button class="btn-inspector danger" id="inspectorTrashBtn">
          <span>🗑️ Move to Trash</span>
        </button>
      </div>
    `;

    // Bind inspector buttons
    const drillBtn = document.getElementById('inspectorDrillBtn');
    if (drillBtn) {
      drillBtn.addEventListener('click', () => this.drillDown(node));
    }

    const copyBtn = document.getElementById('inspectorCopyBtn');
    if (copyBtn) {
      copyBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(node.path);
        this.showToast("Path copied to clipboard");
      });
    }

    const trashBtn = document.getElementById('inspectorTrashBtn');
    if (trashBtn) {
      trashBtn.addEventListener('click', () => {
        this.moveToTrash(node.path);
      });
    }
  }

  // MARK: - Trash & Cleanup Operations
  async moveToTrash(path) {
    try {
      const res = await fetch('/api/trash', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path })
      });
      const data = await res.json();
      if (data.success) {
        this.showToast(`🗑️ Moved to Trash! Reclaimed ${this.formatBytes(data.freedBytes)}`);
        this.rootData = data.updatedTree;
        
        // Find current scope in updated tree
        this.currentScopeNode = this.findNodeByPath(this.rootData, this.currentScopeNode.path) || this.rootData;
        this.selectedNode = this.currentScopeNode.children && this.currentScopeNode.children.length > 0 ? this.currentScopeNode.children[0] : this.currentScopeNode;
        
        this.updateBreadcrumbs();
        this.renderTreemap();
        this.updateInspector();
        this.updateDiskMeter();
      }
    } catch (err) {
      console.error("Trash error:", err);
      this.showToast("Failed to move item to trash");
    }
  }

  findNodeByPath(root, path) {
    if (!root) return null;
    if (root.path === path) return root;
    if (!root.children) return null;
    for (const c of root.children) {
      const found = this.findNodeByPath(c, path);
      if (found) return found;
    }
    return null;
  }

  // MARK: - Quick Clean Modal
  async openQuickCleanModal() {
    this.quickCleanModal.classList.add('active');
    const body = document.getElementById('quickCleanBody');
    body.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:center;height:140px;color:var(--text-secondary);gap:8px;">
        <span>⏳ Analyzing developer and system caches...</span>
      </div>
    `;

    try {
      const res = await fetch('/api/quick-clean');
      const candidates = await res.json();
      
      body.innerHTML = '';
      candidates.forEach(preset => {
        const card = document.createElement('div');
        card.className = 'preset-card';
        card.innerHTML = `
          <input type="checkbox" class="preset-checkbox" data-id="${preset.id}" data-size="${preset.size}" ${preset.recommended ? 'checked' : ''}>
          <div class="preset-info">
            <div class="preset-name">${this.escapeHtml(preset.title)}</div>
            <div class="preset-path">${this.escapeHtml(preset.subtitle)}</div>
          </div>
          <div class="preset-size">${this.formatBytes(preset.size)}</div>
        `;
        card.addEventListener('click', (e) => {
          if (e.target.type !== 'checkbox') {
            const cb = card.querySelector('.preset-checkbox');
            cb.checked = !cb.checked;
          }
          this.updateQuickCleanTotal();
        });
        body.appendChild(card);
      });

      this.updateQuickCleanTotal();

      // Bind modal clean button
      const cleanBtn = document.getElementById('confirmCleanBtn');
      cleanBtn.onclick = () => this.executeQuickClean();
      
      const cancelBtn = document.getElementById('cancelCleanBtn');
      cancelBtn.onclick = () => this.quickCleanModal.classList.remove('active');
    } catch (err) {
      body.innerHTML = `<div style="color:var(--accent-red);">Failed to analyze caches.</div>`;
    }
  }

  updateQuickCleanTotal() {
    let total = 0;
    document.querySelectorAll('.preset-checkbox:checked').forEach(cb => {
      total += parseInt(cb.dataset.size || '0', 10);
    });
    const totalEl = document.getElementById('quickCleanTotalSize');
    if (totalEl) {
      totalEl.innerText = this.formatBytes(total);
    }
  }

  async executeQuickClean() {
    const selectedIds = [];
    document.querySelectorAll('.preset-checkbox:checked').forEach(cb => {
      selectedIds.push(cb.dataset.id);
    });

    if (selectedIds.length === 0) {
      this.quickCleanModal.classList.remove('active');
      return;
    }

    const cleanBtn = document.getElementById('confirmCleanBtn');
    cleanBtn.innerText = "Cleaning...";
    cleanBtn.disabled = true;

    try {
      const res = await fetch('/api/quick-clean/clean', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ presetIds: selectedIds })
      });
      const data = await res.json();
      
      this.quickCleanModal.classList.remove('active');
      cleanBtn.innerText = "Move to Trash";
      cleanBtn.disabled = false;

      this.showToast(`✨ Successfully reclaimed ${this.formatBytes(data.freedBytes)}!`);
      this.rootData = data.updatedTree;
      this.currentScopeNode = this.rootData;
      this.selectedNode = this.rootData.children && this.rootData.children.length > 0 ? this.rootData.children[0] : this.rootData;
      
      this.updateBreadcrumbs();
      this.renderTreemap();
      this.updateInspector();
      this.updateDiskMeter();
    } catch (err) {
      console.error("Clean error:", err);
      this.showToast("Cleanup encountered an error.");
    }
  }

  // MARK: - Context Menu
  showContextMenu(x, y, node) {
    this.contextTargetNode = node;
    this.contextMenu.style.left = `${x}px`;
    this.contextMenu.style.top = `${y}px`;
    this.contextMenu.classList.add('visible');

    this.contextMenu.innerHTML = `
      ${node.isDirectory ? `<div class="context-menu-item" id="ctxDrill"><span>🔍</span> Drill Down</div>` : ''}
      <div class="context-menu-item" id="ctxCopy"><span>📋</span> Copy Path</div>
      <div class="context-menu-item" id="ctxInspect"><span>ℹ️</span> Inspect Info</div>
      <div class="context-divider"></div>
      <div class="context-menu-item danger" id="ctxTrash"><span>🗑️</span> Move to Trash</div>
    `;

    const ctxDrill = document.getElementById('ctxDrill');
    if (ctxDrill) {
      ctxDrill.addEventListener('click', () => {
        this.contextMenu.classList.remove('visible');
        this.drillDown(node);
      });
    }

    document.getElementById('ctxCopy').addEventListener('click', () => {
      this.contextMenu.classList.remove('visible');
      navigator.clipboard.writeText(node.path);
      this.showToast("Path copied to clipboard");
    });

    document.getElementById('ctxInspect').addEventListener('click', () => {
      this.contextMenu.classList.remove('visible');
      this.selectNode(node);
    });

    document.getElementById('ctxTrash').addEventListener('click', () => {
      this.contextMenu.classList.remove('visible');
      this.moveToTrash(node.path);
    });
  }

  // MARK: - Search Filtering
  highlightMatchingTiles(query) {
    document.querySelectorAll('.treemap-tile').forEach(tile => {
      const name = (tile.querySelector('.tile-name')?.innerText || '').toLowerCase();
      if (!query) {
        tile.style.opacity = '1';
        tile.style.filter = 'none';
      } else if (name.includes(query)) {
        tile.style.opacity = '1';
        tile.style.filter = 'brightness(1.3) drop-shadow(0 0 8px #ffffff)';
      } else {
        tile.style.opacity = '0.2';
        tile.style.filter = 'grayscale(80%)';
      }
    });
  }

  // MARK: - Helpers & Formatters
  updateDiskMeter() {
    if (!this.rootData) return;
    const totalCapacity = 512_000_000_000;
    const currentUsed = this.rootData.size;
    const free = Math.max(0, totalCapacity - currentUsed);
    const percent = Math.min(100, Math.max(0, (currentUsed / totalCapacity) * 100));

    const meterFill = document.getElementById('diskMeterFill');
    const label = document.getElementById('diskMeterLabel');
    if (meterFill) meterFill.style.width = `${percent}%`;
    if (label) {
      label.innerText = `Macintosh HD: ${this.formatBytes(free)} Free of ${this.formatBytes(totalCapacity)}`;
    }
  }

  showToast(message) {
    if (!this.toast) return;
    this.toast.innerText = message;
    this.toast.classList.add('show');
    clearTimeout(this.toastTimeout);
    this.toastTimeout = setTimeout(() => {
      this.toast.classList.remove('show');
    }, 2800);
  }

  formatBytes(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1000;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${(bytes / Math.pow(k, i)).toFixed(1)} ${sizes[i]}`;
  }

  formatRelativeTime(timestamp) {
    if (!timestamp) return '';
    const now = Date.now() / 1000;
    const diff = now - timestamp;
    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 86400 * 30) return `${Math.floor(diff / 86400)}d ago`;
    return `${Math.floor(diff / (86400 * 30))}mo ago`;
  }

  getCategoryClass(category) {
    switch (category) {
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

  getCategoryEmoji(category) {
    switch (category) {
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

  escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
}

// Instantiate on DOM load
window.addEventListener('DOMContentLoaded', () => {
  window.app = new DiskTileApp();
});
