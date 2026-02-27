find ./assets/images3 -type f -name "*.png" | while read f; do
  out="${f%.png}.jpg"
  vips copy "$f" "$out[Q=85,optimize_coding]"
done
