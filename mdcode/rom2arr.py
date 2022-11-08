#!/usr/bin/env python3
import zlib,base64,struct

def checkmd(rom):   #update MD ROM Checksum
    newchk=0
    for idx in range(0x200,struct.unpack(">I",rom[0x1A4:0x1A8])[0],2):
        newchk=(newchk+struct.unpack(">H",rom[idx:idx+2])[0])&0xffff
    rom[0x18E:0x190]=struct.pack(">H",newchk)
    
with open("main.md","rb") as f:
    rom=bytearray(f.read())

checkmd(rom)

romz=zlib.compress(bytes(rom), 9)

romline='viewerrom="'+base64.b64encode(romz).decode()+'"\n'

with open("../vgmpic.py","r") as f:
    code=f.readlines()

for idx,line in enumerate(code):
    if line.startswith('viewerrom="'):
        code[idx]=romline
        break

with open("../vgmpic.py","w") as f:
    f.writelines(code)

print("viewerrom updated")

# vim:list:listchars=tab\:>-:set ts=4 sw=4 sws=4 et:
