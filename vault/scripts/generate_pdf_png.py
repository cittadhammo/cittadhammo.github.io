import os
import sys
import argparse
import subprocess
from pathlib import Path
import fitz  # PyMuPDF
import xml.etree.ElementTree as ET
import re
import yaml

parser = argparse.ArgumentParser(description="Generate PDF and PNG from SVG files")
parser.add_argument("-c", "--compression", choices=["none", "lossless", "lossy"], default="none", help="PNG compression mode")
args = parser.parse_args()

DPI = 300
MM_PER_INCH = 25.4

COMPRESSION = args.compression

BLEED_MM = 0.5

A_SIZES = {
    '2A0V': (1189, 1682),
    '2A0H': (1682, 1189),
    '2A0S': (1189, 1189),
    'A0V': (841, 1189),
    'A0H': (1189, 841),
    'A0S': (841, 841),
    'A1V': (594, 841),
    'A1H': (841, 594),
    'A1S': (594, 594),
    'A2V': (420, 594),
    'A2H': (594, 420),
    'A2S': (420, 420),
}

base_dir = Path("assets")
svg_dir = base_dir / "svgs"
pdf_dir = base_dir / "pdfs"
png_dir = base_dir / "images"
wrapper_dir = base_dir / "wrappers"
config_file = Path("data/vectors.yml")

for folder in [pdf_dir, png_dir, wrapper_dir]:
    folder.mkdir(parents=True, exist_ok=True)

HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    @page {{
      size: {page_width_mm}mm {page_height_mm}mm;
      margin: 0;
    }}
    html, body {{
      margin: 0;
      padding: 0;
      width: {page_width_mm}mm;
      height: {page_height_mm}mm;
      overflow: hidden;
      background: {background_color};
    }}
    object {{
      display: block;
      width: {svg_width_mm}mm;
      height: {svg_height_mm}mm;
      margin: {margin_top_mm}mm {margin_right_mm}mm {margin_bottom_mm}mm {margin_left_mm}mm;
      border: none;
    }}
    {license_css}
  </style>
</head>
<body>
  <object data="../svgs/{svg_name}" type="image/svg+xml"></object>
  {license_html}
</body>
</html>
"""

def svg_units_to_mm(units):
    return units * 0.2646

def mm_to_px(mm, dpi=DPI):
    return int((mm / MM_PER_INCH) * dpi)

def get_svg_size(svg_path):
    tree = ET.parse(svg_path)
    root = tree.getroot()
    viewBox = root.attrib.get("viewBox")
    width = root.attrib.get("width")
    height = root.attrib.get("height")

    if viewBox:
        parts = re.split(r"[,\s]+", viewBox.strip())
        if len(parts) == 4:
            _, _, w, h = map(float, parts)
        else:
            raise ValueError(f"Invalid viewBox format: {viewBox}")
    elif width and height:
        w = float(''.join(filter(lambda c: c.isdigit() or c == '.', width)))
        h = float(''.join(filter(lambda c: c.isdigit() or c == '.', height)))
    else:
        w, h = 1000.0, 1000.0

    return w, h

def has_black_background(label):
    return 'B' in label

def has_margin(label):
    return 'M' in label

def parse_format_from_label(label):
    match = re.match(r"((2A0|A[0-2])[VHS])", label)
    return match.group(1) if match else "A1V"

def create_wrapper(svg_path, wrapper_path, page_w_mm, page_h_mm,
                   svg_w_mm, svg_h_mm,
                   margin_left_mm, margin_right_mm, margin_top_mm, margin_bottom_mm,
                   background_color,
                   license_config=None):
    
    license_html = ""
    license_css = ""
    
    if license_config:
        logo = license_config.get('logo')
        text = license_config.get('text', [])
        scale = license_config.get('scale', 1.0)
        padding = license_config.get('padding', 10)
        
        if isinstance(text, str):
            text = [text]
        
        text_html = "".join([f"<div>{t}</div>" for t in text])
        
        license_html = f"""
  <div class="license-container">
    <div class="license-text">
      {{text_html}}
    </div>
    <img class="license-logo" src="../icons/{{logo}}.svg">
  </div>
""".format(text_html=text_html, logo=logo)
        
        license_css = f"""
    .license-container {{
      position: absolute;
      bottom: {padding}mm;
      right: {padding}mm;
      display: flex;
      flex-direction: row;
      align-items: center;
      opacity: 1.0;
      color: #333333;
      font-family: 'Poppins', sans-serif;
      z-index: 100;
      transform: scale({scale});
      transform-origin: bottom right;
    }}
    .license-text {{
      text-align: right;
      font-weight: 500;
      font-size: 8pt;
      line-height: 1.2;
      margin-right: 2mm;
    }}

    .license-logo {{
      height: 8mm;
    }}
"""

    html_content = HTML_TEMPLATE.format(
        svg_name=svg_path.name,
        page_width_mm=page_w_mm,
        page_height_mm=page_h_mm,
        svg_width_mm=svg_w_mm,
        svg_height_mm=svg_h_mm,
        margin_left_mm=margin_left_mm,
        margin_right_mm=margin_right_mm,
        margin_top_mm=margin_top_mm,
        margin_bottom_mm=margin_bottom_mm,
        background_color=background_color,
        license_html=license_html,
        license_css=license_css
    )
    with open(wrapper_path, 'w', encoding='utf-8') as f:
        f.write(html_content)

def generate_pdf(wrapper_file, pdf_file):
    subprocess.run([
        "chromium",
        "--headless",
        "--disable-gpu",
        "--no-margins",
        "--disable-gcm",
        "--disable-component-update",
        f"--print-to-pdf={pdf_file}",
        f"file://{wrapper_file.resolve()}"
    ], check=True)

def convert_pdf_to_png(pdf_file, png_output_path, output_w_mm, output_h_mm):
    doc = fitz.open(str(pdf_file))
    page = doc.load_page(0)

    # Compute the content area in PDF points, removing the bleed margin
    margin_pt = BLEED_MM / MM_PER_INCH * 72
    clip = fitz.Rect(margin_pt, margin_pt, page.rect.width - margin_pt, page.rect.height - margin_pt)

    # Render only the clipped area at the target output resolution
    target_px_w = mm_to_px(output_w_mm)
    target_px_h = mm_to_px(output_h_mm)
    zoom_x = target_px_w / clip.width
    zoom_y = target_px_h / clip.height
    mat = fitz.Matrix(zoom_x, zoom_y)

    pix = page.get_pixmap(matrix=mat, alpha=False, clip=clip)
    pix.save(str(png_output_path))
    doc.close()

def compress_png(png_path):
    if COMPRESSION == "none":
        return
    
    quality = "100" if COMPRESSION == "lossless" else "70-90"
    
    try:
        subprocess.run([
            "pngquant",
            "--force",
            "--ext", ".png",
            f"--quality={quality}",
            "--strip",
            str(png_path)
        ], check=True)
        print(f"Compressed PNG ({COMPRESSION}): {png_path.name}")
    except subprocess.CalledProcessError as e:
        print(f"Warning: pngquant failed for {png_path.name}: {e}")
    except FileNotFoundError:
        print(f"Warning: pngquant not found. Skipping compression.")

def load_vectors_config():
    config_path = config_file
    if not config_path.exists():
        print(f"Error: vectors config not found at {config_path.resolve()}")
        sys.exit(1)
    
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    return config.get('defaults', {}), config.get('vectors', [])

def process_vector(name, label, license_config=None):
    source_svg = svg_dir / f"{name}.svg"
    if not source_svg.exists():
        print(f"Warning: source SVG not found: {source_svg}")
        return
    
    base_name = f"{name}-{label}"
    prefix = parse_format_from_label(label)
    black_bg = has_black_background(label)
    add_margin = has_margin(label)

    pdf_path = pdf_dir / f"{base_name}.pdf"
    png_path = png_dir / f"{base_name}.png"
    wrapper_path = wrapper_dir / f"{base_name}.html"

    if pdf_path.exists() and png_path.exists():
        print(f"Skipping existing outputs: {base_name}")
        return

    if pdf_path.exists() and not png_path.exists():
        print(f"PNG missing for {base_name}, regenerating all outputs...")
    elif not pdf_path.exists() and png_path.exists():
        print(f"PDF missing for {base_name}, regenerating all outputs...")
    else:
        print(f"Processing: {base_name}")

    try:
        w_units, h_units = get_svg_size(source_svg)
        w_mm = svg_units_to_mm(w_units)
        h_mm = svg_units_to_mm(h_units)

        margin_cm = 1.0 if add_margin else 0.0
        margin_mm = margin_cm * 10

        if prefix in A_SIZES:
            paper_w, paper_h = A_SIZES[prefix]

            avail_w = paper_w - 2 * margin_mm
            avail_h = paper_h - 2 * margin_mm

            scale = min(avail_w / w_mm, avail_h / h_mm)
            svg_w_scaled = w_mm * scale
            svg_h_scaled = h_mm * scale

            margin_left = margin_mm + (avail_w - svg_w_scaled) / 2
            margin_right = margin_mm + (avail_w - svg_w_scaled) / 2
            margin_top = margin_mm + (avail_h - svg_h_scaled) / 2
            margin_bottom = margin_mm + (avail_h - svg_h_scaled) / 2

            page_w_mm = paper_w
            page_h_mm = paper_h
            svg_w_mm = svg_w_scaled
            svg_h_mm = svg_h_scaled
        else:
            page_w_mm = w_mm + 2 * margin_mm
            page_h_mm = h_mm + 2 * margin_mm
            svg_w_mm = w_mm
            svg_h_mm = h_mm
            margin_left = margin_right = margin_top = margin_bottom = margin_mm

        background_color = "black" if black_bg else "white"

        output_w_mm = page_w_mm
        output_h_mm = page_h_mm

        # Add bleed around page to give Chromium a rendering buffer
        page_w_mm += BLEED_MM * 2
        page_h_mm += BLEED_MM * 2
        margin_left += BLEED_MM
        margin_right += BLEED_MM
        margin_top += BLEED_MM
        margin_bottom += BLEED_MM

        create_wrapper(source_svg, wrapper_path,
                       page_w_mm, page_h_mm,
                       svg_w_mm, svg_h_mm,
                       margin_left, margin_right, margin_top, margin_bottom,
                       background_color,
                       license_config=license_config)

        generate_pdf(wrapper_path, pdf_path)
        print(f"Generated PDF: {pdf_path}")

        convert_pdf_to_png(pdf_path, png_path, output_w_mm, output_h_mm)
        print(f"Generated PNG: {png_path}")

        compress_png(png_path)

    except Exception as e:
        print(f"Error processing {base_name}: {e}")

def main():
    defaults, vectors = load_vectors_config()
    default_license = defaults.get('license')
    
    for entry in vectors:
        name = entry.get('name')
        formats = entry.get('formats', [])
        
        vector_license = entry.get('license')
        
        # License is opt-in. Only add wrapper overlay if explicitly configured.
        # 1. If license is True, use the default config.
        # 2. If license is a dict, merge with default.
        # 3. Otherwise (False or absent), no overlay.
        license_config = None
        if vector_license is True:
            license_config = (default_license or {}).copy()
        elif isinstance(vector_license, dict):
            license_config = (default_license or {}).copy()
            license_config.update(vector_license)
        
        for label in formats:
            process_vector(name, label, license_config=license_config)

if __name__ == "__main__":
    main()
