# Add a new area

(could be made automatic based on folder structure of content)

- Need an area_name.md file in the root (with title and area frontmatter)
- Add collection to the `_config.yml` file
- Adjust the `areas.yml` file in the `content/_data/` folder

Note: pages are part of the collection and need a frontmatter "type: page" to be displayed
at the top right of an area. (we could consider having a `_pages` collection and layout the pages
in the areas.yml)

Categories of the items are extracted via their path.

## Scripts

```
make serve      # Starts Jekyll with livereload
make assets     # Runs your searchAndMap.sh script
make images     # Runs the Python script inside the vault directory
make clean      # Cleans up the build folder
```

## Generating assets

- Every original images in the assets that are listed in the frontmatter `images` of the pages
    should be processed into thumbnail of different size, map moisaic, lightbox depending
    on the layout chosen.

### searchAndMaps script

This script scans all markdown files in your content folder to find images listed in their frontmatter. For each image, it copies the original and creates three resized thumbnails. If the image is marked as a map, it generates map tiles and records the image’s dimensions in `maps.yml`, updating existing entries or adding new ones.

```bash
bash ./scripts/searchAndMap.sh
```

## Obsidian

THe content folder can be edited via Obsidian. Actually, a vault containing content is stored on another repo that when a commit is pushed it get sync with this one. (not sure this is true)

## install

Pineaple Jekyll template for this website

The following is true with old version of Ruby that had gems preinstalled, please use bundle in that new project. For reference: 

Run: `jekyll serve` no need to `bundle install` or `bundle exec jekyll serve` on this repo.

`jekyll serve --livereload --config _config.yml,_config_local.yml` for live reload.

Change `baseurl` in `_confilg.yml` to: `` if it is the root folder for the website.

## Dhamma Charts

Site for displaying and storing Dhamma Charts and Art.

Using the [Pinaple](https://github.com/DhammaCharts/pineapple) template

## Local mirror

```
wget \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  http://localhost:4000/
```

## Dependencies for script generate_assets

- **vips** (libvips)
- **go-yq** (mikefarah/yq)
- **gawk** (awk)
- **findutils** (find)
- **sed**

## Installation

Run the following command to install all required dependencies on Arch Linux:

make sure to remove yq

```bash
sudo pacman -S libvips go-yq gawk findutils
sudo pacman -S openslide
```

---

## Jekyll Local Development Setup

To ensure consistent Jekyll development across different environments, this project now uses Bundler to manage Ruby dependencies.

### Initial Setup (One-time)

1.  **Install Bundler (if you haven't already):**
    ```bash
    gem install bundler
    ```
2.  **Install Project Dependencies:**
    Navigate to the project root and run:
    ```bash
    bundle install
    ```
    This will install all necessary Ruby gems, including Jekyll, into a local `vendor/bundle` directory within the project. The `vendor/bundle` directory is automatically ignored by Git.

### Running the Jekyll Server

You can now serve the Jekyll site using the following command:

```bash
bundle exec jekyll serve --livereload --config _config.yml,_config_local.yml
```

Alternatively, a new `make` command has been added for convenience:

```bash
make serve-local
```

### Publishing

Add "gh-pages"" or "cf-pages" key words in the commit for the github action to push to the relevant hosting. 

Could use a container in the workflow at some point for more stability, something like :

```
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ruby:3.2-bookworm  # or ruby:3.0-bullseye

    steps:
      - uses: actions/checkout@v4

      - name: Install libvips
        run: apt-get update && apt-get install -y libvips-tools

      - name: Install Bundler (optional but recommended)
        run: gem install bundler

      - name: Build Jekyll site
        run: bundle exec jekyll build --config _config.yml,_config_gh.yml

```
