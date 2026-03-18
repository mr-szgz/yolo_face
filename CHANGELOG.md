# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Setup/Store-Binary.ps1` and `Setup/Make-GitHubRelease.ps1` to publish Windows release archives to a Hugging Face bucket and create GitHub releases from those stored binaries.
- `Setup/Bundle-PortablePython.ps1`, `Setup/INSTALL_PORTABLE.md`, `Setup/Release-InstallSnippet.md`, and `Setup/Validate-Gpu.ps1` to support the portable Windows distribution and keep release notes consistent.

### Changed

- Reorganized packaging assets and release helpers under `Setup/`.
- Updated `Install.ps1`, `mise.toml`, `pyproject.toml`, and GitHub workflows for the portable Python and bucket-backed release flow.
- Updated GitHub release notes to include download links, human-readable archive sizes, and a reusable ZIP install snippet.

### Removed

- Root-level `Bundle.ps1`, `Doctor.ps1`, `Make-Binary.ps1`, and `Make-Release.ps1` in favor of the `Setup/` variants.

## [0.3.3] - 2026-03-17

### Added

- `CHANGELOG.md` to keep release notes curated and human-readable.
- A local copy of the Keep a Changelog reference in `developers/keepachangelog_com.md`.

### Changed

- Reworked `Make-Release.ps1` into a PowerShell 7.4 advanced script with native confirmation prompts, progress reporting, and direct `git` and `gh` release automation.
- Renamed the Ultralytics configuration reference to `Developers/docs_ultralytics_cfg.md`.
- Bumped the package version from `0.2.1` to `0.3.3`.

### Removed

- Custom fallback and compatibility handling from `Make-Release.ps1` in favor of a straight PowerShell 7.4 release flow.

## [0.2.1] - 2026-03-17

### Added

- The `Faceless` PowerShell module with `Move-Faceless` for organizing media based on face detection results.
- StashApp plugin metadata for the `faceless` integration.
- `Make-Release.ps1` to automate local release preparation and publishing.

### Changed

- Renamed `Make.ps1` to `Make-Binary.ps1` and refined the binary build workflow.
- Changed the default `Move-Faceless` destination directory to `noface`.
- Renamed the developer Ultralytics configuration document to `YoloUltralyticsConfiguration.md`.

## [0.2.0] - 2026-03-17

### Added

- The initial `yolo_face` Python package and CLI entry point for YOLO-based face detection and classification.
- PyInstaller packaging support, including the project spec file and one-dir binary builds.
- `Install.ps1`, `Bundle.ps1`, and `Doctor.ps1` to bootstrap, package, and validate the portable Python environment.
- GitHub Actions workflows for release publishing and portable Python preparation.
- The original PowerShell module packaging for `YoloFace`.
- Developer documentation for Ultralytics configuration and local build tooling such as `mise.toml`, `freeze.txt`, and embedded Python path configuration files.

### Changed

- Replaced the standalone `yolo_face.py` script with a package-based layout under `yolo_face/`.
- Updated the build flow to clear previous output before packaging release artifacts.

[unreleased]: https://github.com/mr-szgz/yolo_face/compare/v0.3.3...HEAD
[0.3.3]: https://github.com/mr-szgz/yolo_face/compare/d27ef04...v0.3.3
[0.2.1]: https://github.com/mr-szgz/yolo_face/compare/v0.2.0...d27ef04
[0.2.0]: https://github.com/mr-szgz/yolo_face/releases/tag/v0.2.0
