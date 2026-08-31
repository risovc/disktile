#!/bin/bash
# ==============================================================================
# storage_scanner.sh — Lightweight High-Performance Storage Scanner for macOS
# ==============================================================================
# Usage:
#   ./storage_scanner.sh [TARGET_DIR] [MAX_DEPTH] [--include-hidden]
# Output:
#   Structured JSON hierarchy containing sizes, item counts, modification dates,
#   and categorized metadata.
# ==============================================================================

set -euo pipefail

TARGET_DIR="${1:-$HOME}"
MAX_DEPTH="${2:-2}"
INCLUDE_HIDDEN=true

# Expand tilde if present
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "{\"error\": \"Target directory does not exist: $TARGET_DIR\"}" >&2
    exit 1
fi

# Run fast Python analyzer (embedded for maximum portability across all macOS versions)
python3 - "$TARGET_DIR" "$MAX_DEPTH" "$INCLUDE_HIDDEN" << 'PYTHON_SCRIPT'
import os
import sys
import json
import time

target_dir = os.path.abspath(sys.argv[1])
max_depth = int(sys.argv[2])
include_hidden = sys.argv[3].lower() == "true"

def categorize(name, path, is_dir):
    lower_name = name.lower()
    lower_path = path.lower()
    
    if name.startswith('.'):
        return "Hidden & Dotfiles"
        
    dev_patterns = ["node_modules", "deriveddata", ".build", "target", "build", ".gradle", ".cargo", ".venv", "venv", "pods"]
    if any(p in lower_name or f"/{p}/" in lower_path for p in dev_patterns):
        return "Developer & Builds"
        
    cache_patterns = ["cache", "caches", "tmp", "temp", "logs"]
    if any(p in lower_name or f"/{p}/" in lower_path for p in cache_patterns):
        return "Caches & Temporary"
        
    ext = os.path.splitext(name)[1].lower().lstrip('.')
    if ext in ["zip", "tar", "gz", "tgz", "bz2", "xz", "7z", "rar", "dmg", "iso", "pkg"]:
        return "Archives & Disk Images"
    if ext in ["mp4", "mov", "mkv", "avi", "mp3", "wav", "flac", "png", "jpg", "jpeg", "heic", "gif", "psd"]:
        return "Media & Videos"
    if ext in ["swift", "js", "ts", "py", "rs", "go", "c", "cpp", "h", "java", "kt", "html", "css", "json", "yaml", "sh"]:
        return "Developer & Builds"
    if ext in ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md", "csv", "pages", "numbers"]:
        return "Documents & Data"
    if "/library/" in lower_path or "/system/" in lower_path:
        return "System & App Support"
        
    return "Other" if is_dir else "Documents & Data"

def scan_path(path, current_depth):
    name = os.path.basename(path) or path
    is_hidden = name.startswith('.')
    
    try:
        stat_info = os.lstat(path)
        is_dir = os.path.isdir(path) and not os.path.islink(path)
        size = stat_info.st_size
        mtime = int(stat_info.st_mtime)
    except Exception:
        return None

    if not is_dir:
        return {
            "name": name,
            "path": path,
            "isDirectory": False,
            "isHidden": is_hidden,
            "size": size,
            "itemCount": 1,
            "mtime": mtime,
            "category": categorize(name, path, False),
            "children": []
        }

    children = []
    total_size = 0
    total_items = 1

    try:
        with os.scandir(path) as entries:
            for entry in entries:
                if not include_hidden and entry.name.startswith('.'):
                    continue
                if current_depth < max_depth:
                    child_node = scan_path(entry.path, current_depth + 1)
                    if child_node:
                        children.append(child_node)
                        total_size += child_node["size"]
                        total_items += child_node["itemCount"]
                else:
                    # Quick size estimate for deep leaves
                    try:
                        child_stat = entry.stat(follow_symlinks=False)
                        s = child_stat.st_size
                        total_size += s
                        total_items += 1
                        children.append({
                            "name": entry.name,
                            "path": entry.path,
                            "isDirectory": entry.is_dir(follow_symlinks=False),
                            "isHidden": entry.name.startswith('.'),
                            "size": s,
                            "itemCount": 1,
                            "mtime": int(child_stat.st_mtime),
                            "category": categorize(entry.name, entry.path, entry.is_dir(follow_symlinks=False)),
                            "children": []
                        })
                    except Exception:
                        pass
    except PermissionError:
        pass

    children.sort(key=lambda x: x["size"], reverse=True)

    return {
        "name": name,
        "path": path,
        "isDirectory": True,
        "isHidden": is_hidden,
        "size": max(size, total_size),
        "itemCount": total_items,
        "mtime": mtime,
        "category": categorize(name, path, True),
        "children": children
    }

root = scan_path(target_dir, 0)
print(json.dumps(root, indent=2))
PYTHON_SCRIPT
