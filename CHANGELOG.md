# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
