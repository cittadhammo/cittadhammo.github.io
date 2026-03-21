#!/usr/bin/env python3
import os
import sys
from pathlib import Path
import yaml

svg_dir = Path("assets/svgs")
config_file = Path("data/vectors.yml")

def main():
    svg_files = {p.stem for p in svg_dir.glob("*.svg")}
    
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    existing_names = {entry['name'] for entry in config.get('vectors', [])}
    
    new_entries = []
    for name in sorted(svg_files):
        if name not in existing_names:
            new_entries.append({
                'name': name,
                'formats': ['A1V']
            })
            print(f"Adding: {name} with format A1V")
    
    if new_entries:
        config['vectors'].extend(new_entries)
        with open(config_file, 'w') as f:
            yaml.dump(config, f, default_flow_style=False, sort_keys=False)
        print(f"Added {len(new_entries)} new entries to {config_file}")
    else:
        print("No new SVGs found")

if __name__ == "__main__":
    main()
