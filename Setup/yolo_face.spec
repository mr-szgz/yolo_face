# -*- mode: python ; coding: utf-8 -*-
import os

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(SPEC), ".."))

a = Analysis(
    [os.path.join(REPO_ROOT, "yolo_face", "__main__.py")],
    pathex=[REPO_ROOT],
    binaries=[],
    datas=[(os.path.join(REPO_ROOT, "pyproject.toml"), ".")],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="yolo_face",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="yolo_face",
)
