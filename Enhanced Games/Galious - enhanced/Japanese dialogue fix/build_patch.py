"""Build a hash-checked add-on IPS for Galious Enhanced V1.04 Japanese dialogs.

Standard-library-only; no emulator, capture, assembler or network input.
The original game and upstream Enhanced ROM are never modified in place.
"""
import argparse
import hashlib
import json
from pathlib import Path

ORIGINAL_SHA1='4d51d3c5036311392b173a576bc7d91dc9fed6cb'
ENHANCED_SHA256='cdeaa916d198a3ca9891076eb79e05709876fa7ce18dcd929e76f1cf25403f53'
STEM='Galious Enhanced V1.04 JP fix'
SYMBOL_FIRST=117

def sha(data,algorithm='sha256'):
    return hashlib.new(algorithm,data).hexdigest()

def offset(bank,address):return bank*8192+(address&8191)
def word(data,bank,address):
    at=offset(bank,address);return int.from_bytes(data[at:at+2],'little')

def decode(data,at):
    """One Enhanced/original byte-RLE segment, before a VRAM address change."""
    out=bytearray()
    while True:
        value=data[at];at+=1
        if value in(0,128):return bytes(out),at
        if value<128:out.extend(bytes((data[at],))*value);at+=1
        else:
            count=value&127;out.extend(data[at:at+count]);at+=count
        if len(out)>65536:raise ValueError('RLE output exceeds a VRAM bank')

def encode(data):
    """Optimal byte-RLE, including the original address-reset/return suffix."""
    n=len(data);cost=[0]*(n+1);steps=[None]*n
    for i in range(n-1,-1,-1):
        best=10**9
        for k in range(1,min(127,n-i)+1):
            score=k+1+cost[i+k]
            if score<best:best=score;steps[i]=(False,k)
        k=1
        while k<127 and i+k<n and data[i+k]==data[i]:k+=1
        for count in range(1,k+1):
            score=2+cost[i+count]
            if score<best:best=score;steps[i]=(True,count)
        cost[i]=best
    out=bytearray();i=0
    while i<n:
        repeat,k=steps[i]
        out.extend(bytes((k,data[i]))if repeat else bytes((128+k,))+data[i:i+k]);i+=k
    return bytes(out)+b'\x80\0\0\0'

def resource_glyphs(original):
    bits,_=decode(original,offset(10,0x6399));colors,_=decode(original,offset(10,0x6563))
    assert len(bits)==len(colors)==568
    glyphs=[]
    for code in range(0x54,0x5a):
        tile=bytearray()
        for y in range(8):
            at=(code-0x25)*8+y;v=bits[at];color=colors[at]
            pixels=[(color>>4)if v&(128>>x)else color&15 for x in range(8)]
            tile.extend(pixels[x]<<4|pixels[x+1]for x in range(0,8,2))
        glyphs.append(bytes(tile))
    return glyphs

def correct(original,enhanced):
    if sha(original,'sha1')!=ORIGINAL_SHA1:raise ValueError('Wrong original ROM SHA-1')
    if sha(enhanced)!=ENHANCED_SHA256:raise ValueError('Wrong Enhanced V1.04 SHA-256')
    if len(enhanced)!=524288:raise ValueError('Enhanced must be 512 KiB')
    result=bytearray(enhanced)
    # Bank 12 is entirely unused FF in the pinned release. Relocate only the
    # font stream: the other streams in bank 22 keep their original addresses.
    assert enhanced[offset(12,0x6000):offset(12,0x6000)+8192]==b'\xff'*8192
    font,end=decode(enhanced,offset(22,0x6000));assert len(font)==4096
    assert enhanced[end-1:end+3]==b'\x80\0\0\0'
    font=bytearray(font);glyphs=resource_glyphs(original)
    for n,tile in enumerate(glyphs):
        code=SYMBOL_FIRST+n
        for y in range(8):
            at=((code>>5)*8+y)*128+(code&31)*4
            assert font[at:at+4]==b'\xee'*4,'Private glyph slot is not blank'
            font[at:at+4]=tile[y*4:y*4+4]
    stream=encode(font);assert len(stream)<8192
    assert decode(stream,0)[0]==font
    result[offset(12,0x6000):offset(12,0x6000)+len(stream)]=stream
    load=0x22000+0x0951
    assert enhanced[load:load+5]==bytes.fromhex('3e16cd2a42')
    result[load+1]=12
    sites=[]
    for number in(0,2):
        p=offset(15,word(enhanced,15,0xb09e+number*2))+2
        while enhanced[p]!=255:
            value=enhanced[p]
            if 0x54<=value<=0x59:
                result[p]=SYMBOL_FIRST+value-0x54;sites.append(p)
            p+=1
    assert len(sites)==12
    choice=offset(15,word(enhanced,15,0xb09e+13*2))
    assert enhanced[choice:choice+2]==b'\xa9\xee'
    result[choice]=0xe9
    return bytes(result),{'font_bank':12,'font_rle_bytes':len(stream),'private_glyphs':list(range(SYMBOL_FIRST,SYMBOL_FIRST+6)),
        'dialogue_code_offsets':sites,'choice_destination_offset':choice,'fixed_dialogues':[0,2,13]}

def ips(source,result):
    if len(source)!=len(result):raise ValueError('This patch must preserve ROM size')
    output=bytearray(b'PATCH');i=0
    while i<len(source):
        if source[i]==result[i]:i+=1;continue
        start=i
        while i<len(source)and source[i]!=result[i]and i-start<65535:i+=1
        output.extend(start.to_bytes(3,'big')+(i-start).to_bytes(2,'big')+result[start:i])
    return bytes(output)+b'EOF'

def generate(original_path,enhanced_path,output_dir):
    original_path,enhanced_path,output_dir=map(Path,(original_path,enhanced_path,output_dir))
    rom_path=output_dir/(STEM+'[KonamiSCC].rom');patch_path=output_dir/(STEM+'.ips')
    for target in(rom_path,patch_path):
        if target.resolve()in(original_path.resolve(),enhanced_path.resolve()):raise ValueError('Output would overwrite an input')
    original=original_path.read_bytes();source=enhanced_path.read_bytes();fixed,details=correct(original,source);patch=ips(source,fixed)
    output_dir.mkdir(parents=True,exist_ok=True);rom_path.write_bytes(fixed);patch_path.write_bytes(patch)
    report={'original_sha1':ORIGINAL_SHA1,'enhanced_sha256':ENHANCED_SHA256,'output_sha256':sha(fixed),'ips_sha256':sha(patch),
        'rom_bytes':len(fixed),'ips_bytes':len(patch),'input_files_preserved':original_path.read_bytes()==original and enhanced_path.read_bytes()==source,**details}
    (output_dir/(STEM+'.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2));return report

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('original');parser.add_argument('enhanced');parser.add_argument('--output-dir',required=True)
    args=parser.parse_args();generate(args.original,args.enhanced,args.output_dir)
