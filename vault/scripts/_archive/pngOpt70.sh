find ./assets/images2 -type f -name "*.png" -exec pngquant --force --ext .png --quality=70-90 {} \;
