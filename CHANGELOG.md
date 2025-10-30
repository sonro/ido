# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-10-30

### Changed

- **BREAKING** Updated to zig version 0.15.1

## [0.1.0] - 2024-08-07

### Added

#### Library

`ido` library module for serializing, parsing, loading and saving todo lists
in different formats.

- `ido.Format` simple "TODO: task" format.
- `ido.Manager` todo list manager.
- `ido.TaskStore` interface for saving and loading todo lists.
- `ido.FileStore` file-based todo list `TaskStore`, generic over formats.

#### CLI

`ido` cli app for displaying an `ido.Format` file on the command line.

[Unreleased]: https://github.com/sonro/ido/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/sonro/ido/releases/tag/v0.2.0
[0.1.0]: https://github.com/sonro/ido/releases/tag/v0.1.0
