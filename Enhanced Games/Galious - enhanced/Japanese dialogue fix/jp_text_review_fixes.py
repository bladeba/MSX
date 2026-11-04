"""User-approved Japanese review changes; standard library only.

Menu entry starts and all code/pointer tables remain fixed. Each JP/EN/ES
triple is repacked inside its original allocation, with unused FF after ES.
The actual Enhanced locale routine skips FF-delimited strings from JP.
"""
import unicodedata
from build_patch import decode,encode,offset

MENU_STARTS=(0x7e36d,0x7e4d4,0x7e5eb,0x7e64c,0x7e70a,0x7e7d2,0x7e88a,0x7e991)
MENU_END=0x7ea66
# User-edited8x8 glyph, approved on2026-11-04. Values are source palette
# indices, copied exactly; the standalone upstream generator needs no PNG.
SMALL_YA=bytes.fromhex(
    'eeeeeeee'
    'eeeeeeee'
    'efefeeee'
    'fffffeee'
    'e42424ee'
    'e422422e'
    'ed2e22ee'
    'ee2eeeee')
SMALL_YA_PNG_SHA256='3f440b55ecfcde9602ed5422b7f7ecceb9c6f24ad274bb96bfe8835d5403205c'
RULES=(
 (5,'ほのう','ほのお','ユーザー指定'),
 (6,'し ゆ じんこう','しゅじんこう','ユーザー指定'),
 (0,'じらいを3つおける。。。','じらいを3つおける。','ユーザー指定'),
 (3,'CERAMICでできだや。','CERAMICでできた、や。','ユーザー指定（前回の濁点補正も含む）'),
 (4,'しゅじんこうの たつているFLOOR','しゅじんこうの たっているFLOOR','ユーザー指定'),
 (7,'しゅじんこうのぶきとなるもの。WORLDないせきひにきざまれて いる',
    'WORLDないのせきひにきざまれている','ユーザー指定'),
 (5,'FLOORへ とおりていく','FLOORへと おりていく','語の区切りの空白を修正'),
)


def encoded(text):
    kana='あいうえおかきくけこさしすせそ'
    codes={c:0x91+i for i,c in enumerate(kana)}
    kana='たちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわん'
    codes.update({c:0xe0+i for i,c in enumerate(kana)})
    codes.update({'を':0x86,'っ':0x8f,'ぃ':0x88,'ゃ':0x8c,'ゅ':0x8d,'ょ':0x8e,
                  '\u3099':0xde,'\u309a':0xdf,'。':0xa1,'、':0xa4})
    return bytes(codes[c]if c in codes else ord(c)for c in unicodedata.normalize('NFD',text))


def menu_description(text,number):
    for n,before,after,_ in RULES:
        if n!=number:continue
        needle=encoded(before)
        if text.count(needle)!=1:raise ValueError(('Unexpected menu text',number,before))
        text=text.replace(needle,encoded(after))
    return text


def menu_streams(data,number):
    p=MENU_STARTS[number];end=MENU_STARTS[number+1]if number<7 else MENU_END
    rows=[]
    for _ in range(3):
        stop=data.index(255,p,end);rows.append(data[p:stop]);p=stop+1
    return rows


def small_ya(data):
    """Install the user's exact missing8Ch glyph in blank slot123."""
    packed,_=decode(data,offset(12,0x6000));font=bytearray(packed)
    def pixel(n,x,y):
        at=((n>>5)*8+y)*128+(n&31)*4+x//2
        return (font[at]>>(0 if x&1 else 4))&15
    assert all(pixel(123,x,y)==14 for y in range(8)for x in range(8))
    for y in range(8):
        at=((123>>5)*8+y)*128+(123&31)*4
        font[at:at+4]=SMALL_YA[y*4:y*4+4]
    stream=encode(font);assert len(stream)<8192
    return stream,dict(glyph_slot=123,input_code=0x8c,previous_glyph=79,
                       user_png_sha256=SMALL_YA_PNG_SHA256,font_rle_bytes=len(stream),missing_small_ya=True)


def reviewed(data):
    """Apply on canonical menu bytes plus the existing dialogue/font fix."""
    result=bytearray(data);details=[]
    assert result[0x24751+0x8c]==79 and result[0x24751+0x8d:0x24751+0x8f]==bytes((92,93))
    stream,glyph_details=small_ya(data)
    result[offset(12,0x6000):offset(12,0x6000)+8192]=stream+b'\xff'*(8192-len(stream))
    result[0x24751+0x8c]=123;details.append(glyph_details)
    for number,start in enumerate(MENU_STARTS):
        end=MENU_STARTS[number+1]if number<7 else MENU_END
        rows=menu_streams(data,number);corrected=menu_description(rows[0],number)
        payload=corrected+b'\xff'+rows[1]+b'\xff'+rows[2]+b'\xff'
        if len(payload)>end-start:raise ValueError('Menu triple exceeds its original allocation')
        result[start:end]=payload+b'\xff'*(end-start-len(payload))
        if corrected!=rows[0]:details.append(dict(menu=number,old_bytes=len(rows[0]),new_bytes=len(corrected)))
    # Slots30 and31 alias the same old direct-glyph English revival text.
    pointers=[int.from_bytes(data[15*8192+(0xb09e+n*2&8191):15*8192+(0xb09e+n*2&8191)+2],'little')for n in(30,31)]
    assert pointers[0]==pointers[1]
    at=15*8192+(pointers[0]&8191)+2;sites=[]
    while result[at]!=255:
        if 0x54<=result[at]<=0x59:result[at]+=117-0x54;sites.append(at)
        at+=1
    assert len(sites)==6,'Expected one shared English resource-icon string'
    ptr=int.from_bytes(data[15*8192+(0xb09e+16*2&8191):15*8192+(0xb09e+16*2&8191)+2],'little')
    at=15*8192+(ptr&8191)+2;stop=result.index(255,at)
    # The direct-glyph Japanese message16 has one word-separating blank.
    original=bytes(result[at:stop]);normalized=bytes(v-142 if v>=170 else v for v in original)
    assert normalized==bytes((74,59,0,44,48,46,97))
    result[at+2]=96+142
    details.append(dict(english_alias_slots=[30,31],resource_code_sites=sites,
                        farewell_message=16,farewell_comma_offset=at+2))
    assert len(result)==len(data)
    return bytes(result),details
