import argparse
import os
from pathlib import Path

from ultralytics import YOLO

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
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("conf", type=float, default=None)
    args = parser.parse_args()
    
    model_spec = MODELS[0]

    data_dir = get_data_dir()
    data_dir.mkdir(parents=True, exist_ok=True)
    model_path = data_dir / model_spec[0]
    model = YOLO(str(model_path))
    
    # https://docs.ultralytics.com/usage/cfg/#predict-settings
    results = model.predict(
        source=args.source,
        conf=args.conf,
        stream=True,
        verbose=False,
        vid_stride=50,
        # device="cuda:0",
        classes=model_spec[1],
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

    for label in sorted(labels):
        print(label)

if __name__ == "__main__":
    main()
