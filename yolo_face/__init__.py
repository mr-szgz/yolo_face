import argparse
import os
import sys
from importlib.metadata import version
from pathlib import Path

import torch
from ultralytics import YOLO


__version__ = version("yolo_face")

# model name -> supported label class ids (cls_id names)
MODELS = [
    ("yolov8n-oiv7.pt", [259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 381, 63, 216, 322, 594])
]

def get_data_dir() -> Path:
    if xdg := os.environ.get("XDG_DATA_HOME"):
        return Path(xdg) / "yolo_face"
    if os.name == "nt":
        return Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local")) / "yolo_face"
    return Path.home() / ".local" / "share" / "yolo_face"


def main():
    parser = argparse.ArgumentParser(
        prog="yolo_face",
        description=(
            f"yolo_face v{__version__} | "
            f"torch {torch.__version__} | "
            f"cuda {torch.cuda.is_available()}"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("source", help="image file, directory, URL, glob, video or any source supported by ultralytics")
    parser.add_argument("--conf", nargs="?", type=float, default=0.25, help="minimum confidence threshold for detections (default: 0.25)")
    parser.add_argument("--check", action="store_true", help="exit 0 if any labels found, exit 1 if none (no other output)")
    parser.add_argument("--check-not", action="store_true", help="exit 0 if no labels found, exit 1 if any (no other output)")
    args = parser.parse_args()
    
    model_name, classes = MODELS[0]

    data_dir = get_data_dir()
    data_dir.mkdir(parents=True, exist_ok=True)
    model_path = data_dir / model_name
    model = YOLO(str(model_path))
    
    # https://docs.ultralytics.com/usage/cfg/#predict-settings
    results = model.predict(
        source=args.source,
        conf=args.conf,
        stream=True,
        verbose=False,
        vid_stride=50,
        classes=classes,
    )
    
    labels = set()
    result = cls_id = None

    # https://docs.ultralytics.com/modes/predict/#boxes
    for result in results:
        if result.boxes is not None and result.boxes.cls is not None:
            for cls_id in result.boxes.cls:
                # get string name from cls_id using result names
                labels.add(result.names[int(cls_id)])

    del results, result, cls_id

    if args.check:
        sys.exit(0 if labels else 1)

    if args.check_not:
        sys.exit(1 if labels else 0)

    for label in sorted(labels):
        print(label)
