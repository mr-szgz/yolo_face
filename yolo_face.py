#!/usr/bin/env python3

import argparse
from ultralytics import YOLO


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("--conf", type=float, default=None)
    args = parser.parse_args()
    model = YOLO("yolov8n-oiv7.pt")
    
    # https://docs.ultralytics.com/usage/cfg/#predict-settings
    results = model.predict(
        source=args.source,
        conf=args.conf,
        stream=True,
        verbose=False,
        vid_stride=50,
        # device="cuda:0",
        classes=[259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 381, 63, 216, 322, 594],
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
