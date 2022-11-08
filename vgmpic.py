#!/usr/bin/env python3
"""
vgm+png-to-md converter by insane/rabenauge^tscc 2022.11

supports tracker generated pcm samples - no vgm rips dac support
"""

try:
    import sys
    import struct
    import zlib
    import gzip
    import png
    import base64
    import audioop

except ImportError as impErr:
    print(f"[Import Error]: {impErr.args[0]}")
    exit(-1)

# color divisor
coldiv=32

# pcm sample rate, middle between PAL/NTSC
samplerate=15628


#-----------------------------------------------------------------------------


def convertvgm(vgmfile):
    opt_vgm=0   #remove duplicate writes

    vgmid=struct.unpack("<I",b'Vgm ')[0]
    HDR_VGMOFS=0x34

    CMD_DLY=0x00
    CMD_YMW=0x30
    CMD_PSG=0xFE
    CMD_DAC=0xFF

    vgm=bytes()
    out=bytearray()
    idx=0

    ymshadow=[0]*512

    delays={}
    samples={}
    smpcnt=0
    pcmfreqs={}

    timerbctrl=0b00101010

    class sample:
        pcmusage=0
        pcmrates=set()
        pcmdata=[]
        pcmdataconv=[]

    ymallregs=[
      0x022, 0x024, 0x025, 0x026, 0x027, 0x028, 0x02A, 0x02B,
      0x030, 0x031, 0x032, 0x034, 0x035, 0x036, 0x038, 0x039, 0x03A, 0x03C, 0x03D, 0x03E,
      0x040, 0x041, 0x042, 0x044, 0x045, 0x046, 0x048, 0x049, 0x04A, 0x04C, 0x04D, 0x04E,
      0x050, 0x051, 0x052, 0x054, 0x055, 0x056, 0x058, 0x059, 0x05A, 0x05C, 0x05D, 0x05E,
      0x060, 0x061, 0x062, 0x064, 0x065, 0x066, 0x068, 0x069, 0x06A, 0x06C, 0x06D, 0x06E,
      0x070, 0x071, 0x072, 0x074, 0x075, 0x076, 0x078, 0x079, 0x07A, 0x07C, 0x07D, 0x07E,
      0x080, 0x081, 0x082, 0x084, 0x085, 0x086, 0x088, 0x089, 0x08A, 0x08C, 0x08D, 0x08E,
      0x090, 0x091, 0x092, 0x094, 0x095, 0x096, 0x098, 0x099, 0x09A, 0x09C, 0x09D, 0x09E,
      0x0A0, 0x0A1, 0x0A2, 0x0A4, 0x0A5, 0x0A6, 0x0A8, 0x0A9, 0x0AA, 0x0AC, 0x0AD, 0x0AE,
      0x0B0, 0x0B1, 0x0B2, 0x0B4, 0x0B5, 0x0B6,
      0x130, 0x131, 0x132, 0x134, 0x135, 0x136, 0x138, 0x139, 0x13A, 0x13C, 0x13D, 0x13E,
      0x140, 0x141, 0x142, 0x144, 0x145, 0x146, 0x148, 0x149, 0x14A, 0x14C, 0x14D, 0x14E,
      0x150, 0x151, 0x152, 0x154, 0x155, 0x156, 0x158, 0x159, 0x15A, 0x15C, 0x15D, 0x15E,
      0x160, 0x161, 0x162, 0x164, 0x165, 0x166, 0x168, 0x169, 0x16A, 0x16C, 0x16D, 0x16E,
      0x170, 0x171, 0x172, 0x174, 0x175, 0x176, 0x178, 0x179, 0x17A, 0x17C, 0x17D, 0x17E,
      0x180, 0x181, 0x182, 0x184, 0x185, 0x186, 0x188, 0x189, 0x18A, 0x18C, 0x18D, 0x18E,
      0x190, 0x191, 0x192, 0x194, 0x195, 0x196, 0x198, 0x199, 0x19A, 0x19C, 0x19D, 0x19E,
      0x1A0, 0x1A1, 0x1A2, 0x1A4, 0x1A5, 0x1A6,
      0x1B0, 0x1B1, 0x1B2, 0x1B4, 0x1B5, 0x1B6,
    ]

    def read4(*args):
        nonlocal idx
        if len(args)==1: idx=args[0]
        idx+=4
        return struct.unpack("<I",vgm[idx-4:idx])[0]
    
    def read2(*args):
        nonlocal idx
        if len(args)==1: idx=args[0]
        idx+=2
        return struct.unpack("<H",vgm[idx-2:idx])[0]
    
    def read1(*args):
        nonlocal idx
        if len(args)==1: idx=args[0]
        idx+=1
        return struct.unpack("<B",vgm[idx-1:idx])[0]
    
    def seek(ofs):
        nonlocal idx
        idx=ofs
    
    def adddelay(dly):
        if dly in delays:
            delays[dly]+=1
        else:
            delays[dly]=1
   
    def gentimerb():
        MCLK50=7600489
        # Timer B
        timerbs=[]
        for i in range(256):
            timerbs.append(MCLK50/(2304*(256-i)))
        return(timerbs)

    def mdout(port,val):
        out.append(port)
        out.append(val)

    def putdly(samp):
        dlyval=samp//delayrate
        if (dlyval>255):
            putdly(dlyval-255)
            dlyval=255
        if(out[-2]==CMD_DLY):
            dlymod=out[-1]+dlyval
            if dlymod<256:
                out[-1]=dlymod
                return
        out.append(CMD_DLY)
        out.append(dlyval)

    def checkreg(ymreg,ymdat):
        if ymreg==0x00: #should not happen
            ymreg=0xE000 #show error
        elif ymreg==0x26: #timer-b freq
            ymreg=0xE026 #show error
        elif ymreg==0x27: #timer ctrl
            ymdat|=timerbctrl # force timer-b active
        elif ymreg==0x28: #key-on
            ymshadow[0x10|(ymdat&7)]=ymdat&0xf0
        elif ymreg==0x2A: #dac output
            ymreg=0xE02A #show error
        elif ymreg==0x2B: #dac enable
            ymreg=0x00 #force skip
            if ymdat&0x80==0: mdout(CMD_DAC,0x00) #furnace PCM stop
        return ymreg,ymdat

    def ymout(ymreg,ymdat):
        ymshadow[ymreg]=ymdat
        regcode=ymallregs.index(ymreg)
        mdout(CMD_YMW+regcode,ymdat)

    def vgm_ym2612write(ymreg,ymdat):
        ymreg,ymdat=checkreg(ymreg,ymdat)
        if ymreg in ymallregs:
            ymout(ymreg,ymdat)

#TODO: ym2612 write opt reg 0x30..0x9f, 0xb0..0xb6, 0x130..0x19f, 0x1b0..0x1b6
#TODO: ym2612 write opt reg 0x28 keyon/off
#TODO: ym2612 channel + timer-a freq write opt (latched writes)
#TODO: psg write opt

            """
            if 0x20<=ymreg<=0x9f:
                if ymshadow[ymreg]!=ymdat:
                    ymout(ymreg,ymdat)
            else:
                ymout(ymreg,ymdat)
            """
        else:
            if ymreg: print(f"{idx:08X}:YM {ymreg:03X}={ymdat:02X}")

       
    if vgmfile=="": #no sound support
        return(bytearray(6))

    try:
        with gzip.open(vgmfile,"rb") as f:
            vgm=f.read()
    except gzip.BadGzipFile:
        with open(vgmfile,"rb") as f:
            vgm=f.read()
   
    if (read4()!=vgmid):
        print("Not an VGM file")
        exit()
    
    eofpos=read4()+4
    vgmver=read4()
    
    if vgmver<0x150:
        seek(0x40)
    else:
        seek(read4(HDR_VGMOFS)+HDR_VGMOFS)
    
    vgmstart=idx
    #scan for delays
    while idx<eofpos:
        dat=read1()
        if dat==0x50: #SN76489 WRITE
            idx+=1
        elif dat==0x52: #YM2612 PORT 0 WRITE
            idx+=2
        elif dat==0x53: #YM2612 PORT 1 WRITE
            idx+=2
        elif dat==0x61: #SAMPLE DELAY
            sdly=read2()
            dlyms=int(sdly/44.100)
            adddelay(sdly)
        elif dat==0x62: #60hz DELAY
            adddelay(735)
        elif dat==0x63: #50hz DELAY
            adddelay(882)
        elif dat==0x66: #END OF STREAM
            break
        elif dat==0x67: #DATA BLOCK
            if read1()!=0x66:
                print("?MALFORMED DATA BLOCK")
                exit()
            dattyp=read1()
            datsiz=read4()
            idx+=datsiz
        elif dat==0x90: #DAC STREAM CTRL
            idx+=4
        elif dat==0x91: #DAC STREAM DATA
            idx+=4
        elif dat==0x92: #DAC STREAM FREQ
            idx+=5
        elif dat==0x94: #DAC STREAM STOP
            idx+=1
        elif dat==0x95: #DAC STREAM START FAST
            idx+=4
        else:
            print(f"?UNSUPPORTED COMMAND: {dat:02X}")
            exit()

    delayrate=sorted(delays.keys())[0]
    #delayrate=sorted(delays.items(),key=lambda x:x[1],reverse=True)[0][0]
    delayhz=44100/delayrate

    timerbs=gentimerb()
    timerbval=min(enumerate(timerbs), key=lambda x:abs(x[1]-delayhz))

    print(f"Using {delayhz:.2f}hz audio refresh rate - YM2612 timer: {timerbval[1]:.2f}hz")
    if delayhz>1000:
        print("can't convert vgm - audio refresh rate too high")
        exit(-1)

    seek(vgmstart)

    ymout(0x26,timerbval[0])
    ymout(0x27,timerbctrl)

    while idx<eofpos:
        dat=read1()
        if dat==0x50: #SN76489 WRITE
            psgdat=read1()
            mdout(CMD_PSG,psgdat)
        elif dat==0x52: #YM2612 PORT 0 WRITE
            ymreg=read1()
            ymdat=read1()
            vgm_ym2612write(ymreg,ymdat)
        elif dat==0x53: #YM2612 PORT 1 WRITE
            ymreg=read1()|0x100
            ymdat=read1()
            vgm_ym2612write(ymreg,ymdat)
        elif dat==0x61: #SAMPLE DELAY
            sdly=read2()
            putdly(sdly)
        elif dat==0x62: #60hz DELAY
            putdly(735)
        elif dat==0x63: #50hz DELAY
            putdly(882)
        elif dat==0x66: #END OF STREAM
            mdout(CMD_DLY,0x00)
            break
        elif dat==0x67: #DATA BLOCK
            if read1()!=0x66:
                print("?MALFORMED DATA BLOCK")
                exit()
            dattyp=read1()
            datsiz=read4()
            if dattyp==0x00:
                #print(f"{idx:08X}:PCM DATA BLOCK {dattyp:02X} {datsiz} bytes")
                newsamp=sample()
                newsamp.pcmusage=0
                newsamp.pcmrates=set()
                newsamp.pcmdata=vgm[idx:idx+datsiz]
                newsamp.pcmdataconv=[]
                samples[smpcnt]=newsamp
                smpcnt+=1
            elif dattyp==0xFE:
                oldidx=idx
                fid=read1()
                ford=read1()
                frow=read1()
                idx=oldidx
                print(f"{idx:08X}:TRACKER PATTERN START {ford:02X}:{frow:02X}")
            else:
                print(f"{idx:08X}?UNSUPPORTED DATA BLOCK: {dattyp:02X}")
                exit()
            idx+=datsiz
        elif dat==0x90: #DAC STREAM CTRL
            streamid=read1()
            chiptype=read1()
            streamport=read1()
            streamdata=read1()
            #print(f"{idx:08X}:PCM CTRL {streamid:02X} CHIP {chiptype:02X} YMSEL-{streamport:02X}={streamdata:02X}")
        elif dat==0x91: #DAC STREAM DATA
            streamid=read1()
            streambank=read1()
            stepsize=read1()
            stepbase=read1()
            #print(f"{idx:08X}:PCM DATA {streamid:02X} {streambank:02X} {stepsize:02X} {stepbase:02X}")
        elif dat==0x92: #DAC STREAM FREQ
            streamid=read1()
            streamfreq=read4()
            #print(f"{idx:08X}:PCM FREQ {streamid:02X}={streamfreq}HZ")
            pcmfreqs[streamid]=streamfreq
        elif dat==0x94: #DAC STREAM STOP
            streamid=read1()
            mdout(CMD_DAC,0x00)
            #print(f"{idx:08X}:PCM STOP {streamid:02X}")
        elif dat==0x95: #DAC STREAM START FAST
            streamid=read1()
            streamblock=read2() #sample
            streamflags=read1()
            nextdat=read1()
            if nextdat==0x92: #DAC FREQ AFTER START, FURNACE BUG(?)
                streamid=read1()
                streamfreq=read4()
                pcmfreqs[streamid]=streamfreq
            else:
                idx-=1
            samples[streamblock].pcmusage+=1 
            samples[streamblock].pcmrates.add(pcmfreqs[streamid])
            mdout(CMD_DAC,streamblock+1)
            #print(f"{idx:08X}:PCM PLAY: {streamid:02X} {streamblock:04X} {streamflags:02X} {pcmfreqs[streamid]}")
        else:
            print(f"{idx:08X}?UNSUPPORTED COMMAND: {dat:02X}")
            exit()
    if 0:
        for y in range(16):
            for chip in range(2):
                for x in range(16):
                    print(f"{ymshadow[(y*16)+x+(chip*0x100)]:02X} ",end="")
                print("   ",end="")
            print()

#new_frames = audioop.bias(new_frames, 1, 128) #unsigned to signed
#converted = audioop.ratecv(data, 1, 1, inrate, outrate, None)
#new_frames = audioop.bias(new_frames, 1, 128) #signed to unsigned

    smpram=bytearray()
    smpramhdr=bytearray(smpcnt*4)
    smpramlen=len(smpramhdr)
    smpramdat=bytearray()
    for smp in range(smpcnt):
        print(f"SAMPLE {smp+1:02X}, {len(samples[smp].pcmdata):5d} bytes, used {samples[smp].pcmusage:5d} times",end="")
        if samples[smp].pcmusage:
            srchz=list(samples[smp].pcmrates)[0]
            print(", freq: ",end="")
            for hz in samples[smp].pcmrates:
                print(f"{hz}hz ",end="")
            if(len(samples[smp].pcmrates)>1):
                print(f": using {srchz}hz ",end="")
            wav_sb=audioop.bias(samples[smp].pcmdata,1,128)
            wav_md=audioop.ratecv(wav_sb,1,1,srchz,samplerate,None)[0]
            wav_ub=bytearray(audioop.bias(wav_md,1,128)).replace(b'\x00',b'\x01') #0x00=stop sample
            wav_ub.append(0)
            if (len(wav_ub)&1): #force alignment
                wav_ub.append(0)
            samples[smp].pcmdataconv=wav_ub
        else:
            samples[smp].pcmdataconv=bytearray(2)
        smpramdat.extend(samples[smp].pcmdataconv)
        cursmplen=len(samples[smp].pcmdataconv)
        ramofs=smp*4
        smpramhdr[ramofs:ramofs+4]=struct.pack(">I",smpramlen)
        smpramlen+=cursmplen
        print()
    smpram.extend(struct.pack(">I",smpramlen))
    smpram.extend(smpramhdr)
    smpram.extend(smpramdat)
    return(smpram+out)


#-----------------------------------------------------------------------------


def convertpic(fnam):
    # supported maximum res
    res=(320,224)

    if fnam=="": #no screen support
        return(bytearray(0))
        
    out=bytearray()
    picdat=bytearray()
    
    picobj=png.Reader(fnam)
    pic=picobj.read()
    
    sizex=pic[0]
    sizey=pic[1]
    pixdat=list(pic[2])
    
    print(f"Loaded PNG: {sizex}*{sizey} Pixels")
    
    if (sizex!=res[0]):
        print(f"Picture width is not {res[0]} pixels!")
        exit(-1)
    
    if (sizey>res[1]):
        print(f"Picture height is bigger than {res[1]} lines!")
        exit(-1)
    
    center=(res[1]-sizey)//2
    
    # convert palette
    mdcol=[0]*16

    if not 'palette' in pic[3]:
        print("PNG picture must have a palette!")
        exit(-1)

    if len(pic[3]['palette'])>16:
        print("Warning: PNG palette has more than 16 colors!")

    for idx,col in enumerate(pic[3]['palette']):
        r=col[0]//coldiv
        g=col[1]//coldiv
        b=col[2]//coldiv
        if idx<16:
            mdcol[idx]=(b<<9)|(g<<5)|(r<<1)

    out.extend(struct.pack(">16H",*mdcol))
    
    # convert to centered chunky pixel data
    # empty lines before pic
    for row in range(center):
        picdat.extend([0]*res[0])
    
    # center
    for row in pixdat:
        for cnt in range(sizex):
            picdat.extend(struct.pack("B",row[cnt]&15))
    
    # empty lines after pic
    for row in range(center):
        picdat.extend([0]*res[0])
    
    # reorder, convert to packed pixel pattern data
    for cy in range(res[1]//8):
        for cx in range(res[0]//8):
            for py in range(8):
                for px in range(0,8,2):
                    pix= picdat[((py+(cy*8))*sizex)+(cx*8)+px+0]<<4
                    pix|=picdat[((py+(cy*8))*sizex)+(cx*8)+px+1]
                    out.extend(struct.pack("B",pix))
    return out



#-----------------------------------------------------------------------------


# md rom file start
viewerrom="eNrt1F1MW2UYB/D/+a9KxSnla+LnjmwDBk4PpSBgGS1wgFbaQPkQlm0pC6Pbsi0MgbClIxRhDgYTEHCQfQDZFjVq2LItMzmJeKUmM9kSL/Rq3hg12YVXBgnJ8WmZF7s0xit9mt/75Hnfp+/peU9bBdEgKTYIi3hMPC7ihFU8IeLFk2KjeEo8LRKETSSKJJEsUkSq2CSeEWniWfGceF7ItfDiw7xZsipeFulii9gqtokMkSmyxHaRLXLEK2KHeFW8JjSRK+wiTzhEvigQr4tCUSSKxRvCKUrETlEq6vUqt+qLDhUBT5OuZpVvD7jLVNWu2e25uVqhFLrf3Vilq74KtdZT3tAY0NUmj/6WHlDd/gq1qcqn1ta4W6SMxd/tl7L5Yexobh5e9aqPRuzxIM6EKck0TfUfhrdRf6T2v125lglbERagLDuREIrfshY9Eyy4UP4HlgH3r7B4azWj36IZkRTNGNA0YzBOM4Z6NeNdaMaIqRlnJI9GNGOsVDPeo2aMK5oxIXOT0KN7JKYYuCS+EPeFmbemAAuJWM9JsBYhVrf/nreG2Ez1z+ZvNfcTzL86OqEaLlnSnKVmeqTua3MtVts6kter6HVVIwhscDgV2J3YrDlRmkH7O4FyWV/9Loysum/MB97bVoQc691Tle/LrjOW6STN+EA+bRClTvRrl/QVq0U15NbRkWCfW9890uWW2XsrVrz5Cyz37jZXp1f7VizR+5t3YfZOH1qBkQ7Y0jqRlHbXpRUAIW0pDCVUISNDXhnVNga/d+BH75ITme3cpKT2q0iNqIo1CXHtq0HDq4Reai2TSgmtyDllppZDqVfaHwQXk7+MnmNwTvUEZ6QrrV6R9ZzUMPqh/OTJ6rbhh2+DMMOt6TL2yPNchvU2Qklp+Pyr0EbbC6F46c9OdUHxd8feWQVl9o6/G0gw/80X0rEV25CBTGQhGznQkAs7HMhHAQpRhGI4UYKdcMGNMlRARyWq4YEXNfDBj1rUIYAGNKIJzWjBLuzGHuxFUA58H9qwH+04gIM4hMM4gqPowDH5snShGz3oxXGcQBgn0SfnFMEABjGEUziNYYxgFGM4i3FMYBJTmMYMzmEWcziPC7iIeflFLOIyruAqPsRH+Bif4FN8hiVcw3XcwE3cosZc2ulgPgtYyCIW08kS7qSLbpaxgjorWU0Pvayhj37Wso4BNrCRTWxmC3dxN/dwL4Ns5T62cT/beYAHeYiHeYRH2cFj7GQXu9nDXh7nCYZ5kn3sZ4QDHOQQT/E0hznCUY7xLMc5wUlOcZozPMdZzvE8L/Ai57nARV7mFV7lEq/xOm/wJm9BkT/h/+M/HX8C+QxyPQ=="
# md rom file end


if __name__ == "__main__":
    print("VGM+PNG to MD v1.0 by insane/rabenauge^tscc")
    if (len(sys.argv)==1):
        print("Converts VGM and/or PNG file to a Sega MegaDrive/Genesis ROM\n")
        print("Usage:\n  vgmpic.py [infile.vgm] [infile.png] [outfile.md]\n")
        print("Examples:")
        print("$ vgmpic.py title.png music.vgm intro1.md")
        print('  Creates "intro1.md" which shows "title.png" and plays "music.vgm".\n')
        print("$ vgmpic.py title.png")
        print('  Creates "title.md" which only shows "title.png".\n')
        print("$ vgmpic.py music.vgm music.md")
        print('  Creates "music.md" which only plays "music.vgm".\n')
        print("Notes:")
        print("  PNG file must use palletized/indexed 16 color mode.")
        print("  VGM Drums are resampled to ~15khz sample rate.")
        print("  Only Tracker Style Sample Commands are supported!")
        exit()

    fnamvgm=""
    fnampng=""
    fnamrom=""

    for arg in sys.argv:
        if arg.upper().endswith('.VGM'):   fnamvgm=arg
        elif arg.upper().endswith('.PNG'): fnampng=arg
        elif arg.upper().endswith('.MD'):  fnamrom=arg
        elif arg.upper().endswith('.BIN'): fnamrom=arg
        elif arg.upper().endswith('.ROM'): fnamrom=arg

    if fnamvgm=="" and fnampng=="":
        print("Error: no VGM and/or PNG files found in arguments")
        exit()

    if fnamrom=="":
        if fnamvgm!="":
            fnamrom=fnamvgm[:-4]+".md"
        elif fnampng!="":
            fnamrom=fnampng[:-4]+".md"

    picdat=convertpic(fnampng)
    vgmdat=convertvgm(fnamvgm)

    with open(fnamrom,"wb") as f:
        f.write(zlib.decompress(base64.b64decode(viewerrom)))
        f.write(struct.pack(">I",len(picdat)))
        f.write(picdat)
        f.write(vgmdat)
    
# vim:list:listchars=tab\:>-:set ts=4 sw=4 sws=4 et:
