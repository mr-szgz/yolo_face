## Install and run (ZIP release)

1. Download `yolo_face-<version>-windows-amd64-cu128.zip`.
2. Extract it, then open a terminal in the extracted `yolo_face` folder.
3. Run:

```powershell
.\yolo_face.exe <image-or-folder-or-video>
```

Optional checks:

```powershell
.\yolo_face.exe <source> --check
.\yolo_face.exe <source> --check-not
```

The first run downloads model files to `%LOCALAPPDATA%\yolo_face`.
