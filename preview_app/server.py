#!/usr/bin/env python3
"""
DiskTile Live Preview Server
----------------------------
Zero-dependency HTTP server providing live Mac storage visualization,
treemap layout calculations, real and simulated filesystem scanning,
and interactive drag-and-drop Trash / Quick Clean simulation.
"""

import os
import sys
import json
import time
import urllib.parse
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
TEMPLATES_DIR = os.path.join(BASE_DIR, "templates")

def get_demo_tree(preset_type="developer"):
    now = int(time.time())
    day = 86400

    if preset_type == "media":
        return {
            "name": "MacBook Pro — Media Studio",
            "path": "/Users/alex",
            "isDirectory": True,
            "isHidden": False,
            "size": 420_500_000_000,
            "itemCount": 48920,
            "mtime": now - 3600,
            "category": "Other",
            "children": [
                {
                    "name": "Final Cut Projects",
                    "path": "/Users/alex/Movies/Final Cut Projects",
                    "isDirectory": True,
                    "isHidden": False,
                    "size": 182_400_000_000,
                    "itemCount": 4200,
                    "mtime": now - 7200,
                    "category": "Media & Videos",
                    "children": [
                        {
                            "name": "Commercial_4K_ProRes.mov",
                            "path": "/Users/alex/Movies/Final Cut Projects/Commercial_4K_ProRes.mov",
                            "isDirectory": False,
                            "isHidden": False,
                            "size": 78_200_000_000,
                            "itemCount": 1,
                            "mtime": now - 3 * day,
                            "category": "Media & Videos",
                            "children": []
                        },
                        {
                            "name": "Render Files (Proxy & Optical)",
                            "path": "/Users/alex/Movies/Final Cut Projects/Render Files",
                            "isDirectory": True,
                            "isHidden": False,
                            "size": 64_500_000_000,
                            "itemCount": 1420,
                            "mtime": now - 2 * day,
                            "category": "Caches & Temporary",
                            "children": []
                        },
                        {
                            "name": "B-Roll Footage 120fps",
                            "path": "/Users/alex/Movies/Final Cut Projects/B-Roll Footage 120fps",
                            "isDirectory": True,
                            "isHidden": False,
                            "size": 39_700_000_000,
                            "itemCount": 2780,
                            "mtime": now - 5 * day,
                            "category": "Media & Videos",
                            "children": []
                        }
                    ]
                },
                {
                    "name": "Lightroom Catalog & RAWs",
                    "path": "/Users/alex/Pictures/Lightroom",
                    "isDirectory": True,
                    "isHidden": False,
                    "size": 115_000_000_000,
                    "itemCount": 14200,
                    "mtime": now - 4 * day,
                    "category": "Media & Videos",
                    "children": [
                        {
                            "name": "Previews.lrdata",
                            "path": "/Users/alex/Pictures/Lightroom/Previews.lrdata",
                            "isDirectory": True,
                            "isHidden": False,
                            "size": 42_000_000_000,
                            "itemCount": 8500,
                            "mtime": now - 4 * day,
                            "category": "Caches & Temporary",
                            "children": []
                        },
                        {
                            "name": "2026_Studio_Shoots",
                            "path": "/Users/alex/Pictures/Lightroom/2026_Studio_Shoots",
                            "isDirectory": True,
                            "isHidden": False,
                            "size": 73_000_000_000,
                            "itemCount": 5700,
                            "mtime": now - 10 * day,
                            "category": "Media & Videos",
                            "children": []
                        }
                    ]
                },
                {
                    "name": "Downloads",
                    "path": "/Users/alex/Downloads",
                    "isDirectory": True,
                    "isHidden": False,
                    "size": 58_600_000_000,
                    "itemCount": 120,
                    "mtime": now - 1800,
                    "category": "Archives & Disk Images",
                    "children": [
                        {
                            "name": "DaVinci_Resolve_Studio_19.dmg",
                            "path": "/Users/alex/Downloads/DaVinci_Resolve_Studio_19.dmg",
                            "isDirectory": False,
                            "isHidden": False,
                            "size": 14_800_000_000,
                            "itemCount": 1,
                            "mtime": now - 12 * day,
                            "category": "Archives & Disk Images",
                            "children": []
                        },
                        {
                            "name": "Sound_Effects_Library_Uncompressed.zip",
                            "path": "/Users/alex/Downloads/Sound_Effects_Library_Uncompressed.zip",
                            "isDirectory": False,
                            "isHidden": False,
                            "size": 28_400_000_000,
                            "itemCount": 1,
                            "mtime": now - 15 * day,
                            "category": "Archives & Disk Images",
                            "children": []
                        },
                        {
                            "name": "Sony_FX3_Firmware_v4.pkg",
                            "path": "/Users/alex/Downloads/Sony_FX3_Firmware_v4.pkg",
                            "isDirectory": False,
                            "isHidden": False,
                            "size": 1_200_000_000,
                            "itemCount": 1,
                            "mtime": now - 20 * day,
                            "category": "Archives & Disk Images",
                            "children": []
                        },
                        {
                            "name": ".DS_Store",
                            "path": "/Users/alex/Downloads/.DS_Store",
                            "isDirectory": False,
                            "isHidden": True,
                            "size": 24576,
                            "itemCount": 1,
                            "mtime": now - 600,
                            "category": "Hidden & Dotfiles",
                            "children": []
                        }
                    ]
                },
                {
                    "name": "Library",
                    "path": "/Users/alex/Library",
                    "isDirectory": True,
                    "isHidden": False,
                    "size": 48_500_000_000,
                    "itemCount": 28500,
                    "mtime": now - 3600,
                    "category": "System & App Support",
                    "children": [
                        {
                            "name": "Caches",
                            "path": "/Users/alex/Library/Caches",
                            "isDirectory": True,
                            "isHidden": False,
                            "size": 32_100_000_000,
                            "itemCount": 18400,
                            "mtime": now - 1200,
                            "category": "Caches & Temporary",
                            "children": []
                        },
                        {
                            "name": "Application Support",
                            "path": "/Users/alex/Library/Application Support",
                            "isDirectory": True,
                            "isHidden": False,
                            "size": 16_400_000_000,
                            "itemCount": 10100,
                            "mtime": now - 7200,
                            "category": "System & App Support",
                            "children": []
                        }
                    ]
                },
                {
                    "name": ".Trash",
                    "path": "/Users/alex/.Trash",
                    "isDirectory": True,
                    "isHidden": True,
                    "size": 16_000_000_000,
                    "itemCount": 180,
                    "mtime": now - 3600,
                    "category": "Hidden & Dotfiles",
                    "children": []
                }
            ]
        }

    # Default Developer MacBook Pro Storage Tree
    return {
        "name": "MacBook Pro — Developer Disk (~)",
        "path": "/Users/developer",
        "isDirectory": True,
        "isHidden": False,
        "size": 348_200_000_000,
        "itemCount": 624100,
        "mtime": now - 1200,
        "category": "Other",
        "children": [
            {
                "name": "Library",
                "path": "/Users/developer/Library",
                "isDirectory": True,
                "isHidden": False,
                "size": 138_400_000_000,
                "itemCount": 312000,
                "mtime": now - 600,
                "category": "System & App Support",
                "children": [
                    {
                        "name": "Developer",
                        "path": "/Users/developer/Library/Developer",
                        "isDirectory": True,
                        "isHidden": False,
                        "size": 78_200_000_000,
                        "itemCount": 194000,
                        "mtime": now - 900,
                        "category": "Developer & Builds",
                        "children": [
                            {
                                "name": "Xcode",
                                "path": "/Users/developer/Library/Developer/Xcode",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 64_100_000_000,
                                "itemCount": 165000,
                                "mtime": now - 900,
                                "category": "Developer & Builds",
                                "children": [
                                    {
                                        "name": "DerivedData",
                                        "path": "/Users/developer/Library/Developer/Xcode/DerivedData",
                                        "isDirectory": True,
                                        "isHidden": False,
                                        "size": 48_600_000_000,
                                        "itemCount": 132000,
                                        "mtime": now - 1200,
                                        "category": "Developer & Builds",
                                        "children": [
                                            {
                                                "name": "SuperApp-cgzkjbfue",
                                                "path": "/Users/developer/Library/Developer/Xcode/DerivedData/SuperApp-cgzkjbfue",
                                                "isDirectory": True,
                                                "isHidden": False,
                                                "size": 26_400_000_000,
                                                "itemCount": 78000,
                                                "mtime": now - 1800,
                                                "category": "Developer & Builds",
                                                "children": []
                                            },
                                            {
                                                "name": "BackendGateway-dhweudw",
                                                "path": "/Users/developer/Library/Developer/Xcode/DerivedData/BackendGateway-dhweudw",
                                                "isDirectory": True,
                                                "isHidden": False,
                                                "size": 14_800_000_000,
                                                "itemCount": 38000,
                                                "mtime": now - 3 * day,
                                                "category": "Developer & Builds",
                                                "children": []
                                            },
                                            {
                                                "name": "LegacyClient-polmqwe",
                                                "path": "/Users/developer/Library/Developer/Xcode/DerivedData/LegacyClient-polmqwe",
                                                "isDirectory": True,
                                                "isHidden": False,
                                                "size": 7_400_000_000,
                                                "itemCount": 16000,
                                                "mtime": now - 45 * day,
                                                "category": "Developer & Builds",
                                                "children": []
                                            }
                                        ]
                                    },
                                    {
                                        "name": "Archives",
                                        "path": "/Users/developer/Library/Developer/Xcode/Archives",
                                        "isDirectory": True,
                                        "isHidden": False,
                                        "size": 15_500_000_000,
                                        "itemCount": 33000,
                                        "mtime": now - 10 * day,
                                        "category": "Archives & Disk Images",
                                        "children": []
                                    }
                                ]
                            },
                            {
                                "name": "CoreSimulator",
                                "path": "/Users/developer/Library/Developer/CoreSimulator",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 14_100_000_000,
                                "itemCount": 29000,
                                "mtime": now - 5 * day,
                                "category": "System & App Support",
                                "children": []
                            }
                        ]
                    },
                    {
                        "name": "Caches",
                        "path": "/Users/developer/Library/Caches",
                        "isDirectory": True,
                        "isHidden": False,
                        "size": 36_400_000_000,
                        "itemCount": 78000,
                        "mtime": now - 300,
                        "category": "Caches & Temporary",
                        "children": [
                            {
                                "name": "com.apple.dt.Xcode",
                                "path": "/Users/developer/Library/Caches/com.apple.dt.Xcode",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 14_200_000_000,
                                "itemCount": 28000,
                                "mtime": now - 300,
                                "category": "Caches & Temporary",
                                "children": []
                            },
                            {
                                "name": "Google/Chrome",
                                "path": "/Users/developer/Library/Caches/Google/Chrome",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 9_800_000_000,
                                "itemCount": 32000,
                                "mtime": now - 600,
                                "category": "Caches & Temporary",
                                "children": []
                            },
                            {
                                "name": "Homebrew",
                                "path": "/Users/developer/Library/Caches/Homebrew",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 7_500_000_000,
                                "itemCount": 1200,
                                "mtime": now - 2 * day,
                                "category": "Caches & Temporary",
                                "children": []
                            },
                            {
                                "name": "CocoaPods",
                                "path": "/Users/developer/Library/Caches/CocoaPods",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 4_900_000_000,
                                "itemCount": 16800,
                                "mtime": now - 7 * day,
                                "category": "Caches & Temporary",
                                "children": []
                            }
                        ]
                    },
                    {
                        "name": "Application Support",
                        "path": "/Users/developer/Library/Application Support",
                        "isDirectory": True,
                        "isHidden": False,
                        "size": 23_800_000_000,
                        "itemCount": 40000,
                        "mtime": now - 1800,
                        "category": "System & App Support",
                        "children": [
                            {
                                "name": "Docker Desktop",
                                "path": "/Users/developer/Library/Application Support/Docker Desktop",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 16_200_000_000,
                                "itemCount": 14000,
                                "mtime": now - 3600,
                                "category": "Developer & Builds",
                                "children": []
                            },
                            {
                                "name": "Code",
                                "path": "/Users/developer/Library/Application Support/Code",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 4_800_000_000,
                                "itemCount": 18000,
                                "mtime": now - 1800,
                                "category": "Developer & Builds",
                                "children": []
                            }
                        ]
                    }
                ]
            },
            {
                "name": "Projects",
                "path": "/Users/developer/Projects",
                "isDirectory": True,
                "isHidden": False,
                "size": 94_500_000_000,
                "itemCount": 240000,
                "mtime": now - 1800,
                "category": "Developer & Builds",
                "children": [
                    {
                        "name": "Enterprise-Platform",
                        "path": "/Users/developer/Projects/Enterprise-Platform",
                        "isDirectory": True,
                        "isHidden": False,
                        "size": 42_300_000_000,
                        "itemCount": 120000,
                        "mtime": now - 1800,
                        "category": "Developer & Builds",
                        "children": [
                            {
                                "name": "node_modules",
                                "path": "/Users/developer/Projects/Enterprise-Platform/node_modules",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 24_600_000_000,
                                "itemCount": 86000,
                                "mtime": now - 3600,
                                "category": "Developer & Builds",
                                "children": []
                            },
                            {
                                "name": ".git",
                                "path": "/Users/developer/Projects/Enterprise-Platform/.git",
                                "isDirectory": True,
                                "isHidden": True,
                                "size": 9_400_000_000,
                                "itemCount": 14000,
                                "mtime": now - 1800,
                                "category": "Hidden & Dotfiles",
                                "children": []
                            },
                            {
                                "name": "dist & build",
                                "path": "/Users/developer/Projects/Enterprise-Platform/dist",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 8_300_000_000,
                                "itemCount": 20000,
                                "mtime": now - 1800,
                                "category": "Developer & Builds",
                                "children": []
                            }
                        ]
                    },
                    {
                        "name": "AI-Agent-Core",
                        "path": "/Users/developer/Projects/AI-Agent-Core",
                        "isDirectory": True,
                        "isHidden": False,
                        "size": 31_200_000_000,
                        "itemCount": 85000,
                        "mtime": now - 7200,
                        "category": "Developer & Builds",
                        "children": [
                            {
                                "name": ".venv (PyTorch & CUDA)",
                                "path": "/Users/developer/Projects/AI-Agent-Core/.venv",
                                "isDirectory": True,
                                "isHidden": True,
                                "size": 18_400_000_000,
                                "itemCount": 45000,
                                "mtime": now - 2 * day,
                                "category": "Hidden & Dotfiles",
                                "children": []
                            },
                            {
                                "name": "checkpoints & models",
                                "path": "/Users/developer/Projects/AI-Agent-Core/checkpoints",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 11_200_000_000,
                                "itemCount": 24,
                                "mtime": now - 3 * day,
                                "category": "Developer & Builds",
                                "children": []
                            },
                            {
                                "name": "src",
                                "path": "/Users/developer/Projects/AI-Agent-Core/src",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 1_600_000_000,
                                "itemCount": 40000,
                                "mtime": now - 7200,
                                "category": "Developer & Builds",
                                "children": []
                            }
                        ]
                    },
                    {
                        "name": "Rust-HighPerf-Engine",
                        "path": "/Users/developer/Projects/Rust-HighPerf-Engine",
                        "isDirectory": True,
                        "isHidden": False,
                        "size": 21_000_000_000,
                        "itemCount": 35000,
                        "mtime": now - 4 * day,
                        "category": "Developer & Builds",
                        "children": [
                            {
                                "name": "target (debug & release builds)",
                                "path": "/Users/developer/Projects/Rust-HighPerf-Engine/target",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 19_800_000_000,
                                "itemCount": 32000,
                                "mtime": now - 4 * day,
                                "category": "Developer & Builds",
                                "children": []
                            },
                            {
                                "name": "src",
                                "path": "/Users/developer/Projects/Rust-HighPerf-Engine/src",
                                "isDirectory": True,
                                "isHidden": False,
                                "size": 1_200_000_000,
                                "itemCount": 3000,
                                "mtime": now - 4 * day,
                                "category": "Developer & Builds",
                                "children": []
                            }
                        ]
                    }
                ]
            },
            {
                "name": ".cache & Package Managers",
                "path": "/Users/developer/.cache",
                "isDirectory": True,
                "isHidden": True,
                "size": 46_200_000_000,
                "itemCount": 48000,
                "mtime": now - 3600,
                "category": "Hidden & Dotfiles",
                "children": [
                    {
                        "name": ".npm (_cacache)",
                        "path": "/Users/developer/.npm/_cacache",
                        "isDirectory": True,
                        "isHidden": True,
                        "size": 18_200_000_000,
                        "itemCount": 22000,
                        "mtime": now - 3600,
                        "category": "Caches & Temporary",
                        "children": []
                    },
                    {
                        "name": ".cargo (registry cache)",
                        "path": "/Users/developer/.cargo/registry",
                        "isDirectory": True,
                        "isHidden": True,
                        "size": 14_600_000_000,
                        "itemCount": 16000,
                        "mtime": now - 2 * day,
                        "category": "Caches & Temporary",
                        "children": []
                    },
                    {
                        "name": ".gradle (caches)",
                        "path": "/Users/developer/.gradle/caches",
                        "isDirectory": True,
                        "isHidden": True,
                        "size": 13_400_000_000,
                        "itemCount": 10000,
                        "mtime": now - 5 * day,
                        "category": "Caches & Temporary",
                        "children": []
                    }
                ]
            },
            {
                "name": "Downloads",
                "path": "/Users/developer/Downloads",
                "isDirectory": True,
                "isHidden": False,
                "size": 42_800_000_000,
                "itemCount": 180,
                "mtime": now - 7200,
                "category": "Archives & Disk Images",
                "children": [
                    {
                        "name": "Xcode_16_Beta_4.xip",
                        "path": "/Users/developer/Downloads/Xcode_16_Beta_4.xip",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 16_800_000_000,
                        "itemCount": 1,
                        "mtime": now - 15 * day,
                        "category": "Archives & Disk Images",
                        "children": []
                    },
                    {
                        "name": "macOS_Sequoia_Installer.dmg",
                        "path": "/Users/developer/Downloads/macOS_Sequoia_Installer.dmg",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 14_200_000_000,
                        "itemCount": 1,
                        "mtime": now - 8 * day,
                        "category": "Archives & Disk Images",
                        "children": []
                    },
                    {
                        "name": "Ubuntu_24_04_ARM64.iso",
                        "path": "/Users/developer/Downloads/Ubuntu_24_04_ARM64.iso",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 5_600_000_000,
                        "itemCount": 1,
                        "mtime": now - 25 * day,
                        "category": "Archives & Disk Images",
                        "children": []
                    },
                    {
                        "name": "Android_Studio_Giraffe.dmg",
                        "path": "/Users/developer/Downloads/Android_Studio_Giraffe.dmg",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 6_200_000_000,
                        "itemCount": 1,
                        "mtime": now - 30 * day,
                        "category": "Archives & Disk Images",
                        "children": []
                    }
                ]
            },
            {
                "name": "Documents & Work",
                "path": "/Users/developer/Documents",
                "isDirectory": True,
                "isHidden": False,
                "size": 16_200_000_000,
                "itemCount": 8500,
                "mtime": now - 14400,
                "category": "Documents & Data",
                "children": [
                    {
                        "name": "Architecture_Design_v3.pdf",
                        "path": "/Users/developer/Documents/Architecture_Design_v3.pdf",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 480_000_000,
                        "itemCount": 1,
                        "mtime": now - 3 * day,
                        "category": "Documents & Data",
                        "children": []
                    },
                    {
                        "name": "Production_Database_Dump.sql.gz",
                        "path": "/Users/developer/Documents/Production_Database_Dump.sql.gz",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 12_400_000_000,
                        "itemCount": 1,
                        "mtime": now - 6 * day,
                        "category": "Archives & Disk Images",
                        "children": []
                    },
                    {
                        "name": "Quarterly_Financials.xlsx",
                        "path": "/Users/developer/Documents/Quarterly_Financials.xlsx",
                        "isDirectory": False,
                        "isHidden": False,
                        "size": 24_000_000,
                        "itemCount": 1,
                        "mtime": now - 1 * day,
                        "category": "Documents & Data",
                        "children": []
                    }
                ]
            },
            {
                "name": ".Trash",
                "path": "/Users/developer/.Trash",
                "isDirectory": True,
                "isHidden": True,
                "size": 10_100_000_000,
                "itemCount": 1420,
                "mtime": now - 1800,
                "category": "Hidden & Dotfiles",
                "children": []
            }
        ]
    }

# In-memory storage state for live trash / clean updates
current_storage_tree = get_demo_tree("developer")
trash_bin_items = []

class DiskTileHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Serve from static or templates directory
        clean_path = path.split('?')[0].split('#')[0]
        if clean_path.startswith('/static/'):
            rel_path = clean_path[len('/static/'):]
            return os.path.join(STATIC_DIR, rel_path)
        return os.path.join(TEMPLATES_DIR, "index.html")

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query)

        if parsed.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            with open(os.path.join(TEMPLATES_DIR, "index.html"), "rb") as f:
                self.wfile.write(f.read())
            return

        if parsed.path == "/api/scan":
            scope = query.get("scope", ["developer"])[0]
            include_hidden = query.get("include_hidden", ["true"])[0].lower() == "true"
            global current_storage_tree

            if scope in ["developer", "media"]:
                current_storage_tree = get_demo_tree(scope)
                result = current_storage_tree
            elif scope == "local":
                # Scan actual local workspace / home directory
                target = query.get("path", [os.path.expanduser("~")])[0]
                result = self.scan_real_dir(target, include_hidden=include_hidden, max_depth=3)
                current_storage_tree = result
            else:
                current_storage_tree = get_demo_tree("developer")
                result = current_storage_tree

            self.send_json_response(result)
            return

        if parsed.path == "/api/system-info":
            info = {
                "volumeName": "Macintosh HD",
                "totalBytes": 512_000_000_000,
                "freeBytes": 163_800_000_000,
                "usedBytes": 348_200_000_000,
                "userHome": "/Users/developer",
                "osVersion": "macOS 15.1 Sequoia (24B83)",
                "chip": "Apple M3 Max (36 GB Unified Memory)"
            }
            self.send_json_response(info)
            return

        if parsed.path == "/api/quick-clean":
            candidates = [
                {
                    "id": "xcode_derived",
                    "title": "Xcode DerivedData & Module Caches",
                    "subtitle": "~/Library/Developer/Xcode/DerivedData",
                    "icon": "hammer.fill",
                    "size": 48_600_000_000,
                    "paths": ["/Users/developer/Library/Developer/Xcode/DerivedData"],
                    "category": "Developer & Builds",
                    "recommended": True
                },
                {
                    "id": "node_modules",
                    "title": "Projects node_modules",
                    "subtitle": "~/Projects/**/node_modules",
                    "icon": "shippingbox.fill",
                    "size": 24_600_000_000,
                    "paths": ["/Users/developer/Projects/Enterprise-Platform/node_modules"],
                    "category": "Developer & Builds",
                    "recommended": True
                },
                {
                    "id": "npm_yarn_cache",
                    "title": "NPM & Cargo Registry Caches",
                    "subtitle": "~/.npm/_cacache, ~/.cargo/registry",
                    "icon": "cylinder.split.1x2.fill",
                    "size": 32_800_000_000,
                    "paths": ["/Users/developer/.npm/_cacache", "/Users/developer/.cargo/registry"],
                    "category": "Caches & Temporary",
                    "recommended": True
                },
                {
                    "id": "app_caches",
                    "title": "User Application Caches",
                    "subtitle": "~/Library/Caches (Xcode, Chrome, CocoaPods)",
                    "icon": "trash.circle.fill",
                    "size": 36_400_000_000,
                    "paths": ["/Users/developer/Library/Caches"],
                    "category": "Caches & Temporary",
                    "recommended": False
                },
                {
                    "id": "xcode_archives",
                    "title": "Old Xcode IPA / App Archives",
                    "subtitle": "~/Library/Developer/Xcode/Archives",
                    "icon": "archivebox.fill",
                    "size": 15_500_000_000,
                    "paths": ["/Users/developer/Library/Developer/Xcode/Archives"],
                    "category": "Archives & Disk Images",
                    "recommended": False
                },
                {
                    "id": "old_installers",
                    "title": "Downloaded Disk Images & Installers",
                    "subtitle": "~/Downloads (*.dmg, *.xip, *.iso)",
                    "icon": "arrow.down.doc.fill",
                    "size": 42_800_000_000,
                    "paths": ["/Users/developer/Downloads/Xcode_16_Beta_4.xip", "/Users/developer/Downloads/macOS_Sequoia_Installer.dmg"],
                    "category": "Archives & Disk Images",
                    "recommended": False
                }
            ]
            self.send_json_response(candidates)
            return

        # Serve static assets
        if parsed.path.startswith("/static/"):
            super().do_GET()
            return

        self.send_error(404, "File Not Found")

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        content_len = int(self.headers.get('Content-Length', 0))
        post_body = self.rfile.read(content_len) if content_len > 0 else b'{}'
        
        try:
            data = json.loads(post_body.decode('utf-8'))
        except Exception:
            data = {}

        if parsed.path == "/api/trash":
            target_path = data.get("path", "")
            freed_bytes = self.remove_node_by_path(current_storage_tree, target_path)
            trash_bin_items.append({"path": target_path, "size": freed_bytes, "time": int(time.time())})
            self.send_json_response({
                "success": True,
                "path": target_path,
                "freedBytes": freed_bytes,
                "updatedTree": current_storage_tree,
                "trashCount": len(trash_bin_items)
            })
            return

        if parsed.path == "/api/quick-clean/clean":
            preset_ids = data.get("presetIds", [])
            total_freed = 0
            # Remove presets from current tree
            if "xcode_derived" in preset_ids:
                total_freed += self.remove_node_by_path(current_storage_tree, "/Users/developer/Library/Developer/Xcode/DerivedData")
            if "node_modules" in preset_ids:
                total_freed += self.remove_node_by_path(current_storage_tree, "/Users/developer/Projects/Enterprise-Platform/node_modules")
            if "npm_yarn_cache" in preset_ids:
                total_freed += self.remove_node_by_path(current_storage_tree, "/Users/developer/.cache")
            if "old_installers" in preset_ids:
                total_freed += self.remove_node_by_path(current_storage_tree, "/Users/developer/Downloads/Xcode_16_Beta_4.xip")
                total_freed += self.remove_node_by_path(current_storage_tree, "/Users/developer/Downloads/macOS_Sequoia_Installer.dmg")
            if "xcode_archives" in preset_ids:
                total_freed += self.remove_node_by_path(current_storage_tree, "/Users/developer/Library/Developer/Xcode/Archives")

            self.send_json_response({
                "success": True,
                "freedBytes": total_freed,
                "updatedTree": current_storage_tree
            })
            return

        self.send_error(404, "Endpoint not found")

    def remove_node_by_path(self, parent_node, target_path):
        if not parent_node or "children" not in parent_node:
            return 0

        for i, child in enumerate(parent_node["children"]):
            if child["path"] == target_path:
                freed = child["size"]
                parent_node["children"].pop(i)
                parent_node["size"] = max(0, parent_node["size"] - freed)
                return freed
            
            if target_path.startswith(child["path"] + "/") or child["path"].startswith(target_path):
                freed = self.remove_node_by_path(child, target_path)
                if freed > 0:
                    parent_node["size"] = max(0, parent_node["size"] - freed)
                    return freed
        return 0

    def scan_real_dir(self, root_dir, include_hidden=True, max_depth=3):
        def categorize(name, path, is_dir):
            lower_name = name.lower()
            lower_path = path.lower()
            if name.startswith('.'): return "Hidden & Dotfiles"
            if any(p in lower_name or f"/{p}/" in lower_path for p in ["node_modules", "deriveddata", ".build", "target", ".gradle", ".cargo"]):
                return "Developer & Builds"
            if any(p in lower_name or f"/{p}/" in lower_path for p in ["cache", "caches", "tmp", "temp", "logs"]):
                return "Caches & Temporary"
            ext = os.path.splitext(name)[1].lower().lstrip('.')
            if ext in ["zip", "tar", "gz", "dmg", "iso", "pkg"]: return "Archives & Disk Images"
            if ext in ["mp4", "mov", "mkv", "png", "jpg", "jpeg", "heic", "gif"]: return "Media & Videos"
            if ext in ["swift", "py", "js", "ts", "rs", "go", "c", "cpp", "java", "json", "sh"]: return "Developer & Builds"
            if ext in ["pdf", "doc", "docx", "txt", "md", "csv"]: return "Documents & Data"
            return "Other" if is_dir else "Documents & Data"

        def traverse(path, depth):
            name = os.path.basename(path) or path
            try:
                st = os.lstat(path)
                is_dir = os.path.isdir(path) and not os.path.islink(path)
                size = st.st_size
                mtime = int(st.st_mtime)
            except Exception:
                return None

            if not is_dir:
                return {
                    "name": name, "path": path, "isDirectory": False, "isHidden": name.startswith('.'),
                    "size": size, "itemCount": 1, "mtime": mtime, "category": categorize(name, path, False), "children": []
                }

            children = []
            total_size = 0
            total_items = 1

            if depth < max_depth:
                try:
                    with os.scandir(path) as it:
                        for entry in it:
                            if not include_hidden and entry.name.startswith('.'):
                                continue
                            c = traverse(entry.path, depth + 1)
                            if c:
                                children.append(c)
                                total_size += c["size"]
                                total_items += c["itemCount"]
                except PermissionError:
                    pass

            children.sort(key=lambda x: x["size"], reverse=True)
            return {
                "name": name, "path": path, "isDirectory": True, "isHidden": name.startswith('.'),
                "size": max(size, total_size), "itemCount": total_items, "mtime": mtime,
                "category": categorize(name, path, True), "children": children
            }

        return traverse(root_dir, 0) or get_demo_tree("developer")

    def send_json_response(self, data):
        response_bytes = json.dumps(data).encode('utf-8')
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(response_bytes)

    def log_message(self, format, *args):
        # Concise logging
        pass

def run_server(port=8888):
    server_address = ('0.0.0.0', port)
    httpd = ThreadingHTTPServer(server_address, DiskTileHandler)
    print(f"🌟 DiskTile Live Preview Server running at http://0.0.0.0:{port}")
    httpd.serve_forever()

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8888
    run_server(port)
