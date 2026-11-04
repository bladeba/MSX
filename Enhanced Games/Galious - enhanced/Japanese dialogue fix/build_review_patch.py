"""Build the reviewed Enhanced add-on IPS; original inputs are never edited."""
import argparse,json
from pathlib import Path
from build_patch import correct,ips,sha
from jp_text_review_fixes import reviewed

STEM='Galious Enhanced V1.04 JP review r7'

def generate(original_path,enhanced_path,output_dir):
    original_path,enhanced_path,output_dir=map(Path,(original_path,enhanced_path,output_dir))
    original=original_path.read_bytes();source=enhanced_path.read_bytes()
    previous,prior_details=correct(original,source);fixed,details=reviewed(previous)
    patch=ips(source,fixed)
    rom_path=output_dir/(STEM+'[KonamiSCC].rom');patch_path=output_dir/(STEM+'.ips')
    for p in(rom_path,patch_path):
        if p.resolve()in(original_path.resolve(),enhanced_path.resolve()):raise ValueError('Would overwrite an input')
    output_dir.mkdir(parents=True,exist_ok=False)
    rom_path.write_bytes(fixed);patch_path.write_bytes(patch)
    report=dict(original_sha1=sha(original,'sha1'),enhanced_sha256=sha(source),output_sha256=sha(fixed),
                ips_sha256=sha(patch),rom_bytes=len(fixed),ips_bytes=len(patch),prior_fixes=prior_details,
                review_fixes=details,menu_entry_addresses_preserved=True,english_spanish_menu_text_preserved=True,
                scope='Enhanced Japanese text/font review; no MD extensions',
                input_files_preserved=original_path.read_bytes()==original and enhanced_path.read_bytes()==source)
    (output_dir/(STEM+'.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(json.dumps(report,ensure_ascii=False));return report

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original');p.add_argument('enhanced');p.add_argument('--output-dir',required=True)
    a=p.parse_args();generate(a.original,a.enhanced,a.output_dir)
