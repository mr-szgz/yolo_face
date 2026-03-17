# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added this changelog to keep release notes curated and human-readable.

### Changed

- Reworked `Make-Release.ps1` into a PowerShell 7.4 advanced script with native confirmation prompts, progress reporting, and direct `git` and `gh` release automation.

### Removed

- Removed custom fallback and compatibility handling from `Make-Release.ps1` in favor of a straight PowerShell 7.4 release flow.

## [0.2.1] - 2026-03-17

### Added

- Added the `Faceless` PowerShell module with `Move-Faceless` for organizing media based on face detection results.
- Added StashApp plugin metadata for the `faceless` integration.
- Added `Make-Release.ps1` to automate local release preparation and publishing.

### Changed

- Renamed `Make.ps1` to `Make-Binary.ps1` and refined the binary build workflow.
- Changed the default `Move-Faceless` destination directory to `noface`.
- Renamed the developer Ultralytics configuration document to `YoloUltralyticsConfiguration.md`.

## [0.2.0] - 2026-03-17

### Added

- Added the initial `yolo_face` Python package and CLI entry point for YOLO-based face detection and classification.
- Added PyInstaller packaging support, including the project spec file and one-dir binary builds.
- Added `Install.ps1`, `Bundle.ps1`, and `Doctor.ps1` to bootstrap, package, and validate the portable Python environment.
- Added GitHub Actions workflows for release publishing and portable Python preparation.
- Added the original PowerShell module packaging for `YoloFace`.
- Added developer documentation for Ultralytics configuration and local build tooling files such as `mise.toml`, `freeze.txt`, and embedded Python path configuration files.

### Changed

- Replaced the standalone `yolo_face.py` script with a package-based layout under `yolo_face/`.
- Updated the build flow to clear previous output before packaging release artifacts.

[unreleased]: https://github.com/mr-szgz/yolo_face/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/mr-szgz/yolo_face/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/mr-szgz/yolo_face/releases/tag/v0.2.0
