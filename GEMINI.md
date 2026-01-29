# Project Context for Gemini CLI

This document outlines key information about the Dhammacharts project for the Gemini CLI agent.

## General Project Overview
*   This website is built with **Jekyll** and uses **Bundler** for Ruby dependency management.
*   Content is managed via an **Obsidian vault**, which is synced from another repository.
*   The primary goal is displaying and storing Dhamma Charts and Art.

## Development Workflow
*   When Gemini CLI is running, the `make local-serve` command has already been launched. Therefore, there is no need to rebuild the site.
*   Any code modifications I make should be **instantaneously visible** to the user without needing to rebuild or restart the server.
*   Live reloading is handled via `jekyll serve --livereload --config _config.yml,_config_local.yml` or the `make serve-local` command.

## Content Structure & Organization
*   Content can be organized into "areas." To add a new area:
    *   Create an `area_name.md` file in the root (with title and area frontmatter).
    *   Add a collection to the `_config.yml` file.
    *   Adjust the `areas.yml` file in the `content/_data/` folder.
*   Pages within a collection need a frontmatter `type: page` to be displayed at the top right of an area.
*   Categories of items are extracted via their path.

## Asset Management & Generation
*   **Charts are primarily SVG files.** These are converted into **PNG tiles** via a script located in `vault/script`.
*   A `generate assets` script in the root `scripts` folder is also involved in asset processing.
*   The **`searchAndMap.sh`** script (`make assets`) is crucial for asset generation:
    *   Scans markdown files for images listed in their frontmatter.
    *   Copies original images and creates three resized thumbnails.
    *   For images marked as maps, it generates map tiles and records dimensions in `maps.yml`.
*   A Python script handles general image processing and can be run via `make images`.
*   To optimize live reloads and avoid excessive copying, a "clever trick" is used: `keep_files` in the Jekyll config combined with a relative symlink to assets.
*   **Generated tiles are served and displayed using special HTML map files that utilize the OpenLayers library.**

## Key Makefile Commands
*   `make serve`: Starts Jekyll with livereload.
*   `make assets`: Runs the `searchAndMap.sh` script.
*   `make images`: Runs the Python script inside the vault directory.
*   `make clean`: Cleans up the build folder.

## Script Dependencies
*   Required dependencies for asset generation scripts: `vips` (libvips), `go-yq` (mikefarah/yq), `gawk` (awk), `findutils` (find), `openslide`.

## Configuration Notes
*   The `baseurl` in `_config.yml` might need to be set to `''` if the website is deployed to the root folder of a domain.