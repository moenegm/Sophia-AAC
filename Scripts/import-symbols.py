#!/usr/bin/env python3
"""Import pinned Mulberry SVGs as 256px thumbnails. Requires rsvg-convert."""
import csv,json,subprocess,concurrent.futures,sys
from pathlib import Path
source=Path(sys.argv[1]); root=Path(sys.argv[2]); dest=root/'Resources/Pictures';dest.mkdir(parents=True,exist_ok=True)
revision=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
if revision != '9cbab9f400c5de44e2bc58839cca07294aadb086':
 raise RuntimeError('Check out the documented Mulberry revision before importing')
rows=list(csv.DictReader((source/'scripts/data/symbol-info-en.csv').open()))
def convert(row):
 name=row['symbol'];key='mulberry-'+row['symbol-id']; src=source/'EN'/(name+'.svg')
 if not src.exists(): raise RuntimeError('Missing '+name)
 subprocess.run(['rsvg-convert','-w','256','-h','256','-o',str(dest/(key+'.png')),str(src)],check=True,capture_output=True)
 return dict(name=name.replace('_',' ').replace(' - ', ' — ').strip(),emoji='💬',keywords=row['tags']+' '+row['category']+' '+name.replace('_',' '),sourceID=key)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool: catalog=list(pool.map(convert,rows))
custom=root/'Scripts/Artwork/chicken-wings.svg'
subprocess.run(['rsvg-convert','-w','256','-h','256','-o',str(dest/'sophia-chicken-wings.png'),str(custom)],check=True)
catalog.insert(0,dict(name='Chicken wings',emoji='💬',keywords='chicken wing wings buffalo hot wings poultry food meat dinner أجنحة دجاج',sourceID='sophia-chicken-wings'))
(dest/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,separators=(',',':')))
(root/'Resources/Mulberry-LICENSE.txt').write_text('\n'.join(line.rstrip() for line in (source/'LICENSE.txt').read_text().splitlines())+'\n')
(root/'Resources/Mulberry-ATTRIBUTION.txt').write_text('Mulberry Symbols by Steve Lee are licensed under Creative Commons Attribution-ShareAlike 4.0.\nhttps://mulberrysymbols.org\nhttps://creativecommons.org/licenses/by-sa/4.0/\nSource: https://github.com/mulberrysymbols/mulberry-symbols\nRevision: 9cbab9f400c5de44e2bc58839cca07294aadb086\nChanges: SVG originals rendered to 256 × 256 PNG thumbnails; symbol names normalized for display.\nThe symbol artwork and derived thumbnails remain available under CC BY-SA 4.0, independently of app source licensing.\n')
print('Imported',len(catalog),'symbols; PNG bytes:',sum(p.stat().st_size for p in dest.glob('*.png')))
