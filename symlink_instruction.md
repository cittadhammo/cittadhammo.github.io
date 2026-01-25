# Jekyll Local Development: Image Symlinking

To optimize build times and manage large image assets without duplicating files, this project uses a symbolic link for the `assets/images` directory.

## 🛠 Setup Instructions

### 1. Create the Symlink
Run the following command from the project root to link your source images directly into the build folder:

```bash
# Ensure the destination path exists
mkdir -p ./_site/assets/

# Create a relative symlink
ln -sr ./assets/images ./_site/assets/images

# Prevent Jekyll from wiping the symlink during builds
keep_files:
  - assets/images

# (Optional) Prevents Jekyll from processing the source folder 
# since the symlink handles the connection
exclude:
  - assets/images
