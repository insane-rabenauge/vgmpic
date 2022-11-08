; md init+header+macro list by insane/tSCc - insane.tscc.de
	nolist

; clears 68k-RAM,VRAM,CRAM,VSRAM

; Macros:
;
; ROM
;   - switches to ROM space
;
; RAM
;   - switches to RAM space
;

; Settings:
;
; md_rom_expand [0/(1)]
;   - aligns ROM to EPROM sizes
;
; md_init_sp [$1000000]
;   - sp to use at system start
;
; eh_enable [0/(1)]
;   - disables (0) or enables (1) the inclusion of the exception handler
;
; eh_font [font-address in rom]
;   - if set uses a custom exception handler font in ROM, NOT a pointer to a font!
;   - if not defined then a default ROM will be linked in
;   - font starts at char 0x20
;
; eh_font_small [0/(1)]
;   - expands 4x8 to 8x8 font
;
; eh_joy_enable [0/(1)]
;   - enables looking through RAM via joypad
;
; eh_col0 [BGR] - background color
; eh_col1 [BGR] - register dump color

; Macros
RAM_Start	equ	$ffff0000
md_RAM_inram	set	0

ROM     macro
		ifne	md_RAM_inram
                popsection
		endif
md_RAM_inram	set	0
        endm

RAM     macro   start
		ifeq	md_RAM_inram
		pushsection
                offset  \1
		endif
md_RAM_inram	set	1
        endm

md_set_vdp:	macro	addr, cmd, dst
		move.l  #((((\1)&$3FFF)<<16))|(((\1)&$C000)>>14)|\2,\3
		endm

md_set_vram_addr_reg:	macro	reg, dst
		lsl.l	#2,\1
		lsr.w	#2,\1
		or.w	#$4000,\1
		swap	\1
	ifne	\#!=2
		move.l	\1,vdp_ctrl
	else
		move.l	\1,\2
	endc
		endm

md_set_vram_addr:	macro	addr (vdp_ctrl)
	ifne	\#!=2
		md_set_vdp \1,vdp_addr_vram,vdp_ctrl
	else
		md_set_vdp \1,vdp_addr_vram,\2
	endc
		endm

md_set_cram_addr:	macro	addr (vdp_ctrl)
	ifne	\#!=2
		md_set_vdp \1,vdp_addr_cram,vdp_ctrl
	else
		md_set_vdp \1,vdp_addr_cram,\2
	endc
		endm

md_set_vsram_addr:	macro	addr (vdp_ctrl)
	ifne	\#!=2
		md_set_vdp \1,vdp_addr_vsram,vdp_ctrl
	else
		md_set_vdp \1,vdp_addr_vsram,\2
	endc
		endm

md_set_vram_read:	macro	addr (vdp_ctrl)
	ifne	\#!=2
		md_set_vdp \1,vdp_read_vram,vdp_ctrl
	else
		md_set_vdp \1,vdp_read_vram,\2
	endc
		endm

md_set_cram_read:	macro	addr (vdp_ctrl)
	ifne	\#!=2
		md_set_vdp \1,vdp_read_cram,vdp_ctrl
	else
		md_set_vdp \1,vdp_read_cram,\2
	endc
		endm

md_set_vsram_read:	macro	addr (vdp_ctrl)
	ifne	\#!=2
		md_set_vdp \1,vdp_read_vsram,vdp_ctrl
	else
		md_set_vdp \1,vdp_read_vsram,\2
	endc
		endm

md_set_psg_freq:	macro	chn freq (vdp_psg)
	ifne	\#!=3
		move.b	#$80|((\1&3)<<5)|(\2&$f),vdp_psg
		move.b	#((\2>>4)&$3f),vdp_psg
	else
		move.b	#$80|((\1&3)<<5)|(\2&$f),\3
		move.b	#((\2>>4)&$3f),\2
	endc
		endm

md_set_psg_tone: 	macro	chn freq (vdp_psg)
	ifne	\#!=3
		move.b	#$80|((\1&3)<<5)|(\2&$f),vdp_psg
	else
		move.b	#$80|((\1&3)<<5)|(\2&$f),\3
	endc
		endm
md_set_psg_vol: 	macro	chn vol (vdp_psg)
	ifne	\#!=3
		move.b	#$90|((\1&3)<<5)|(\2&$f),vdp_psg
	else
		move.b	#$90|((\1&3)<<5)|(\2&$f),\3
	endc
		endm

md_set_psg_freqhi:	macro	freq (vdp_psg)
	ifne	\#!=2
		move.b	#(\1&$3f),vdp_psg
	else
		move.b	#(\1&$3f),\2
	endc
		endm

md_set_vdp_mode1:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_mode1|\1,vdp_ctrl
	else
		move.w	#vdp_reg_mode1|\1,\2
	endc
		endm

md_set_vdp_mode2:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_mode2|\1,vdp_ctrl
	else
		move.w	#vdp_reg_mode2|\1,\2
	endc
		endm

md_set_vdp_mode3:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_mode3|\1,vdp_ctrl
	else
		move.w	#vdp_reg_mode3|\1,\2
	endc
		endm

md_set_vdp_mode4:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_mode4|\1,vdp_ctrl
	else
		move.w	#vdp_reg_mode4|\1,\2
	endc
		endm

md_set_vdp_incr:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_incr|\1,vdp_ctrl
	else
		move.w	#vdp_reg_incr|\1,\2
	endc
		endm

md_set_vdp_bgcol:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_bgcol|\1,vdp_ctrl
	else
		move.w	#vdp_reg_bgcol|\1,\2
	endc
		endm

md_set_vdp_hblrate:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_hblrate|\1,vdp_ctrl
	else
		move.w	#vdp_reg_hblrate|\1,\2
	endc
		endm

md_set_vdp_mapsize:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_mapsize|\1,vdp_ctrl
	else
		move.w	#vdp_reg_mapsize|\1,\2
	endc
		endm

md_set_vdp_winx:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_winx|\1,vdp_ctrl
	else
		move.w	#vdp_reg_winx|\1,\2
	endc
		endm

md_set_vdp_winy:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_winy|\1,vdp_ctrl
	else
		move.w	#vdp_reg_winy|\1,\2
	endc
		endm

md_set_vdp_planea_addr:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_planea|\1>>10,vdp_ctrl
	else
		move.w	#vdp_reg_planea|\1>>10,\2
	endc
		endm

md_set_vdp_planeb_addr:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_planeb|\1>>13,vdp_ctrl
	else
		move.w	#vdp_reg_planeb|\1>>13,\2
	endc
		endm

md_set_vdp_window_addr:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_window|\1>>10,vdp_ctrl
	else
		move.w	#vdp_reg_window|\1>>10,\2
	endc
		endm

md_set_vdp_sprite_addr:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_sprite|\1>>9,vdp_ctrl
	else
		move.w	#vdp_reg_sprite|\1>>9,\2
	endc
		endm

md_set_vdp_hscroll_addr:	macro	(vdp_ctrl)
	ifne	\#!=2
		move.w	#vdp_reg_hscroll|\1>>10,vdp_ctrl
	else
		move.w	#vdp_reg_hscroll|\1>>10,\2
	endc
		endm

md_dma_ram_to_vram:	macro	source,destination,len,strife
		move.l	a0,-(sp)
		lea	(vdp_ctrl).l,a0
	ifne	\#!=4
		move.w	#$8f02,(a0)
	else
		move.w	#$8f00+\4,(a0)
	endc
		move.l	#$94000000+((((\3)>>1)&$FF00)<<8)+$9300+(((\3)>>1)&$FF),(a0)
		move.l	#$96000000+((((\1)>>1)&$FF00)<<8)+$9500+(((\1)>>1)&$FF),(a0)
		move.w	#$9700+(((((\1)>>1)&$FF0000)>>16)&$7F),(a0)
		move.w	#$4000+((\2)&$3FFF),(a0)
		move.w	#$80+(((\2)&$C000)>>14),-(sp)
		move.w	(sp)+,(a0)
		move.l	(sp)+,a0
		endm

md_dma_ram_to_vram_a0:	macro	source,destination,len,strife	;a0 needs to be set to vdp_ctrl
	ifne	\#!=4
		move.w	#$8f02,(a0)
	else
		move.w	#$8f00+\4,(a0)
	endc
		move.l	#$94000000+((((\3)>>1)&$FF00)<<8)+$9300+(((\3)>>1)&$FF),(a0)
		move.l	#$96000000+((((\1)>>1)&$FF00)<<8)+$9500+(((\1)>>1)&$FF),(a0)
		move.w	#$9700+(((((\1)>>1)&$FF0000)>>16)&$7F),(a0)
		move.w	#$4000+((\2)&$3FFF),(a0)
		move.w	#$80+(((\2)&$C000)>>14),-(sp)
		move.w	(sp)+,(a0)
		endm

md_dma_vram_to_vram:	macro	source,destination,len
		move.l	a0,-(sp)
		lea	(vdp_ctrl).l,a0
		move.w	#$8f01,(a0)
		move.l	#$94000000+(((\3)&$FF00)<<8)+$9300+((\3)&$FF),(a0)
		move.l	#$96000000+(((\1)&$FF00)<<8)+$9500+((\1)&$FF),(a0)
		move.w	#$97C0,(a0)
		move.l	#$000000C0+(((\2)&$3FFF)<<16)+(((\2)&$C000)>>14),(a0)
		move.l	(sp)+,a0
		endm

md_dma_fill_vram:	macro	value,destination,len
		move.l	a0,-(sp)
		lea	(vdp_ctrl).l,a0
		move.w	#$8F01,(a0)
		move.l	#$94000000+(((\3)&$FF00)<<8)+$9300+((\3)&$FF),(a0)
		move.w	#$9780,(a0)
		move.l	#$40000080+(((\2)&$3FFF)<<16)+(((\2)&$C000)>>14),(a0)
		move.w	#\1,-4(a0)
		move.l	(sp)+,a0
		endm

md_wait_vbl_on:	macro
.l\@:		btst.b	#3,vdp_status+1
                beq.s	.l\@
        endm
md_wait_vbl_off:	macro
.l\@:		btst.b	#3,vdp_status+1
                bne.s	.l\@
        endm
	
md_poll_vbl_start:	macro
		md_wait_vbl_off
		md_wait_vbl_on
        endm
md_poll_vbl_end:	macro
		md_wait_vbl_on
		md_wait_vbl_off
        endm
md_poll_vbl:	macro
		md_poll_vbl_start
	endm

md_dma_wait:	macro
.loop\@:	btst.b	#1,vdp_status+1
                bne.s	.loop\@
		endm

md_set_col:	macro	col,val
		move.l	#$C0000000|((\1&$3f)<<17),vdp_ctrl
		move.w	\2,vdp_data
		endm

md_int_off:	macro
		move.w	#$2700,sr
		endm

md_int_vbl:	macro
		move.w	#$2500,sr
		endm

md_int_hbl:	macro
		move.w	#$2300,sr
		endm

md_z80_stop:	macro
		move.w	#$100,z80_busreq
		endm

md_z80_wait:	macro
.wait\@:
		btst	#0,z80_busreq
		bne.s	.wait\@
		endm

md_z80_stopwait:	macro
		md_z80_stop
		md_z80_wait
		endm

md_z80_reset_off:	macro
		move.w	#$100,z80_reset
		endm

md_z80_reset_on:	macro
		move.w	#0,z80_reset
		endm

md_z80_start:	macro
		move.w	#0,z80_busreq
		endm

md_z80_reset:	macro	; no need to use ofs(a0), same size
		md_z80_stop
		md_z80_reset_off
		md_z80_wait
		md_z80_reset_on
		movem.l	d0-d7/a0-a3,-(sp)	;at least 192c
		movem.l	(sp)+,d0-d7/a0-a3	;delay for reset
		md_z80_reset_off
		endm

md_z80_reset_run:	macro
		md_z80_reset
		md_z80_start
		endm

; init sections
		org	0
; set up RAM section
		RAM	RAM_Start
; back to ROM
		ROM

	ifnd	eh_enable
eh_enable=1
	endc

	ifnd	md_init_sp
md_init_sp=$1000000
	endc

ROM_Start:
		dc.l	md_init_sp                  	; Initial stack pointer value
		dc.l	ROM_Init                   	; Start of program
		dc.l	$02000000+md_init_exception_handler	; Bus error - NC/connected to VCC on Sega
		dc.l	$03000000+md_init_exception_handler	; Address error
		dc.l	$04000000+md_init_exception_handler	; Illegal instruction
		dc.l	$05000000+md_init_exception_handler	; Division by zero
		dc.l	$06000000+md_init_exception_handler	; CHK CPU_Exception
		dc.l	$07000000+md_init_exception_handler	; TRAPV CPU_Exception
		dc.l	$08000000+md_init_exception_handler	; Privilege violation
		dc.l	$09000000+md_init_exception_handler	; TRACE exception
		dc.l	$0A000000+md_init_exception_handler	; Line-A emulator
		dc.l	$0B000000+md_init_exception_handler	; Line-F emulator
		dc.l	$0C000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$0D000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$0E000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$0F000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$10000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$11000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$12000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$13000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$14000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$15000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$16000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$17000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$18000000+md_init_exception_handler	; Spurious exception
		dc.l	$19000000+md_init_exception_handler	; IRQ level 1,SR $2000
		dc.l	$1A000000+md_init_exception_handler	; IRQ level 2,SR $2100
		dc.l	$1B000000+md_init_exception_handler	; IRQ level 3,SR $2200
		dc.l	ROM_HInt				; IRQ level 4,SR $2300 HBL
		dc.l	$1D000000+md_init_exception_handler	; IRQ level 5,SR $2400
		dc.l	ROM_VInt				; IRQ level 6,SR $2500 VBL
		dc.l	$1F000000+md_init_exception_handler	; IRQ level 7,SR $2600; $2700=off
		dc.l	$20000000+md_init_exception_handler	; TRAP #00 exception
		dc.l	$21000000+md_init_exception_handler	; TRAP #01 exception
		dc.l	$22000000+md_init_exception_handler	; TRAP #02 exception
		dc.l	$23000000+md_init_exception_handler	; TRAP #03 exception
		dc.l	$24000000+md_init_exception_handler	; TRAP #04 exception
		dc.l	$25000000+md_init_exception_handler	; TRAP #05 exception
		dc.l	$26000000+md_init_exception_handler	; TRAP #06 exception
		dc.l	$27000000+md_init_exception_handler	; TRAP #07 exception
		dc.l	$28000000+md_init_exception_handler	; TRAP #08 exception
		dc.l	$29000000+md_init_exception_handler	; TRAP #09 exception
		dc.l	$2A000000+md_init_exception_handler	; TRAP #10 exception
		dc.l	$2B000000+md_init_exception_handler	; TRAP #11 exception
		dc.l	$2C000000+md_init_exception_handler	; TRAP #12 exception
		dc.l	$2D000000+md_init_exception_handler	; TRAP #13 exception
		dc.l	$2E000000+md_init_exception_handler	; TRAP #14 exception
		dc.l	$2F000000+md_init_exception_handler	; TRAP #15 exception
		dc.l	$30000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$31000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$32000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$33000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$34000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$35000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$36000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$37000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$38000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$39000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$3A000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$3B000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$3C000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$3D000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$3E000000+md_init_exception_handler	; Unused (reserved)
		dc.l	$3F000000+md_init_exception_handler	; Unused (reserved)

; SEGA Header here
		include	"mdheader.asm"
		dcb.b   $200-*


; Hardware Initialization here
ROM_Init:
		md_int_off
		move.b	md_reg_version,d0
		and.b	#$f,d0
		beq	.skiptmss
		move.l	#'SEGA',md_reg_tmss
.skiptmss:
		tst.w	vdp_ctrl	; dummy read from vdp

; setup 320x224 with disabled screen +auto increment here (bandwidth!)
		lea     vdp_ctrl,a0
		move.w  #vdp_reg_mode1,(a0)		;mode1, lcb off, hint off, l2 off
		move.w  #vdp_reg_mode2|vdp_m2_dma,(a0) 		;mode2, disp off, vint off, dma off
		move.w  #vdp_reg_mode3,(a0)		;mode3, xint off, full scroll
		move.w  #vdp_reg_mode4|vdp_m4_320,(a0)  ;mode4, 320px
		move.w	#vdp_reg_winx,(a0)		;deactivate window
		move.w	#vdp_reg_winy,(a0)
		move.w  #vdp_reg_incr|$02,(a0)  ;auto increment: 2 bytes per access; long word = 2 accesses

		md_dma_wait	; should need dma enabled - TODO: test

; init joypads
		lea	md_iobase,a0
		moveq	#0,d0
		move.b	d0,joy_sctrl1-md_iobase(a0)
		move.b	d0,joy_sctrl2-md_iobase(a0)
		move.b	d0,joy_sctrl3-md_iobase(a0)
		moveq	#$40,d0
		move.b	d0,joy_ctrl1-md_iobase(a0)
		move.b	d0,joy_ctrl2-md_iobase(a0)
		move.b	d0,joy_ctrl3-md_iobase(a0)
		move.b	d0,joy_data1-md_iobase(a0)
		move.b	d0,joy_data2-md_iobase(a0)
		move.b	d0,joy_data3-md_iobase(a0)
; clear ram:
		lea	RAM_Start,a0
		move.w	#$3FFF,d0
		moveq	#0,d1
.ramclear:
		move.l	d1,(a0)+
		dbra	d0,.ramclear

		bsr.s	md_init_auxram

		jmp	ROM_Main

md_init_auxram:
; reset z80 + ym2612, clear z80 ram
		lea	vdp_psg,a0
		move.b	#$9f,(a0)
		move.b	#$bf,(a0)
		move.b	#$df,(a0)
		move.b	#$ff,(a0)	; movep is too fast for the psg

		md_z80_reset

		moveq	#0,d0
		lea	z80_ram,a0
		move.b	#$18,(a0)+	;jr
		move.b	#$fe,(a0)+	;to 0
		move.w	#$1ffd,d2
.z80_clrloop:
		move.b	d0,(a0)+
		dbra	d2,.z80_clrloop

; clear vdp ram
		moveq	#0,d1
		lea	vdp_data,a1
		lea	4(a1),a0

		md_set_vram_addr 0,(a0)
		move.w	#$3FFF,d0	;64kB
.vram_clrloop:
		move.l	d1,(a1)
		dbra	d0,.vram_clrloop

		md_set_cram_addr 0,(a0)
		moveq	#32-1,d0	;64 words/128b
.cram_clrloop:
		move.l	d1,(a1)
		dbra	d0,.cram_clrloop

		md_set_vsram_addr 0,(a0)
		moveq	#20-1,d0	;40 words/80b
.vsram_clrloop:
		move.l	d1,(a1)
		dbra	d0,.vsram_clrloop
		rts

; Exception Handler code
md_init_exception_handler:
	ifne	eh_enable==0
		stop	#$2700
		bra.s	md_init_exception_handler
	else
	  	include	"mdexception.asm"
	endc
		align	4

; Equates
md_iobase:		equ	$A10000
md_reg_version:		equ	$A10001
md_ver_pal:		equ	%01000000
md_bit_pal:		equ	6
md_reg_tmss:		equ	$A14000
z80_ram:		equ	$A00000
z80_busreq:		equ	$A11100
z80_reset:		equ	$A11200
z80_pause_on:		equ	$100
z80_pause_off:		equ	$000
z80_reset_on:		equ	$000
z80_reset_off:		equ	$100

reg_ym2612:		equ	$A04000
dat_ym2612:		equ	$A04001
reg_ym2612p0:		equ	$A04000
dat_ym2612p0:		equ	$A04001
reg_ym2612p1:		equ	$A04002
dat_ym2612p1:		equ	$A04003

joy_data:		equ	$A10002
joy_data1:		equ	$A10003
joy_data2:		equ	$A10005
joy_data3:		equ	$A10007
joy_ctrl:		equ	$A10008
joy_ctrl1:		equ	$A10009
joy_ctrl2:		equ	$A1000b
joy_ctrl3:		equ	$A1000d
joy_sctrl1:		equ	$A10013
joy_sctrl2:		equ	$A10019
joy_sctrl3:		equ	$A1001f

; VDP port addresses
vdp_ctrl:		equ	$C00004
vdp_control:		equ	$C00004
vdp_status:		equ	$C00004
vdp_data:		equ	$C00000
vdp_hvcnt:		equ	$C00008
vdp_vcnt:		equ	$C00008
vdp_hcnt:		equ	$C00009
vdp_psg:		equ	$C00011
vdp_addr_vram:		equ	$40000000
vdp_addr_cram:		equ	$C0000000
vdp_addr_vsram:		equ	$40000010
vdp_read_vram:		equ	$00000000
vdp_read_cram:		equ	$00000020
vdp_read_vsram:		equ	$00000010

vdp_m1_default:		equ	%00000000
vdp_m1_lcb:		equ	%00100000
vdp_m1_hbl:		equ	%00010000

vdp_m2_off:		equ	%00000000
vdp_m2_disp:		equ	%01000000
vdp_m2_vbl:		equ	%00100000
vdp_m2_dma:		equ	%00010000
vdp_m2_240:		equ	%00001000

vdp_m3_default:		equ	%00000000
vdp_m3_vscr_full:	equ	%00000000
vdp_m3_vscr_strip:	equ	%00000100
vdp_m3_hscr_full:	equ	%00000000
vdp_m3_hscr_strip:	equ	%00000010
vdp_m3_hscr_line:	equ	%00000011

vdp_m4_320:		equ	%10000001
vdp_m4_256:		equ	%00000000
vdp_m4_lace:		equ	%00000110
vdp_m4_s_h:		equ	%00001000

vdp_map_32x32:		equ	%00000000
vdp_map_64x32:		equ	%00000001
vdp_map_128x32:		equ	%00000011
vdp_map_32x64:		equ	%00010000
vdp_map_64x64:		equ	%00010001
vdp_map_32x128:		equ	%00110000

vdp_win_default:	equ	%00000000
vdp_winx_left:		equ	%00000000
vdp_winx_right:		equ	%10000000
vdp_winy_above:		equ	%00000000
vdp_winy_below:		equ	%10000000

vdp_reg_mode1:		equ	$8004  ; Mode register #1
vdp_reg_mode2:		equ	$8104  ; Mode register #2
vdp_reg_planea:		equ	$8200  ; Plane A table address
vdp_reg_window:		equ	$8300  ; Window table address
vdp_reg_planeb:		equ	$8400  ; Plane B table address
vdp_reg_sprite:		equ	$8500  ; Sprite table address
vdp_reg_bgcol:		equ	$8700  ; Background color
vdp_reg_hblrate:	equ	$8A00  ; HBlank interrupt rate
vdp_reg_mode3:		equ	$8B00  ; Mode register #3 - scrolling
vdp_reg_mode4:		equ	$8C00  ; Mode register #4
vdp_reg_hscroll:	equ	$8D00  ; HScroll table address
vdp_reg_incr:		equ	$8F00  ; Autoincrement
vdp_reg_mapsize:	equ	$9000  ; Plane A and B size
vdp_reg_winx:		equ	$9100  ; Window X split position
vdp_reg_winy:		equ	$9200  ; Window Y split position
vdp_reg_dmalen_l:	equ	$9300  ; DMA length (low)
vdp_reg_dmalen_h:	equ	$9400  ; DMA length (high)
vdp_reg_dmasrc_l:	equ	$9500  ; DMA source (low)
vdp_reg_dmasrc_m:	equ	$9600  ; DMA source (mid)
vdp_reg_dmasrc_h:	equ	$9700  ; DMA source (high)
	list
