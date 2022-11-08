font_addr=$0000
bmp_addr=$2000
planea_addr=$c000       ;foreground/text
planeb_addr=$e000       ;background/pic
sprite_addr=$f000
hscr_addr=$fc00
picsiz=320*224
md_init_exception_handler=ROM_Init

		include	"mdmacros.asm"

		rsset	0
		rs.b	ROM_End
datastart:	rs.b	0		
piclen:		rs.l	1
picpal:		rs.w	16
picdat:		rs.b	picsiz/2

		org	0
ROM_Start:
		dc.l	$01000000                  	; Initial stack pointer value
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

ROM_HInt:
ROM_VInt:
		rte

ROM_Init:	
		md_int_off
		move.b	md_reg_version,d0
		and.b	#$f,d0
		beq	.skiptmss
		move.l	#'SEGA',md_reg_tmss
.skiptmss:
		lea	vdp_data,a1
		lea	4(a1),a0
		tst.w	(a0)		; dummy read from vdp

initvdp:
		md_set_vdp_mode1	vdp_m1_default,(a0)
		md_set_vdp_mode2	vdp_m2_dma,(a0)
		md_set_vdp_planea_addr	planea_addr,(a0)
		md_set_vdp_planeb_addr	planeb_addr,(a0)
		md_set_vdp_sprite_addr	sprite_addr,(a0)
		md_set_vdp_bgcol	$00,(a0)
		md_set_vdp_hblrate	$ff,(a0)
		md_set_vdp_mode3	vdp_m3_default,(a0)
		md_set_vdp_mode4	vdp_m4_320,(a0)
		md_set_vdp_hscroll_addr	hscr_addr,(a0)
		md_set_vdp_incr 	2,(a0)
		md_set_vdp_mapsize	vdp_map_64x32,(a0)
		md_set_vdp_winx 	vdp_win_default,(a0)
		md_set_vdp_winy 	vdp_win_default,(a0)

		;md_dma_wait	; should need dma enabled

		lea	vdp_psg,a2
		move.b	#$9f,(a2)
		move.b	#$bf,(a2)
		move.b	#$df,(a2)
		move.b	#$ff,(a2)	; movep is too fast for the psg

		md_z80_reset

; clear vdp ram
		moveq	#0,d1

		md_set_vram_addr 0,(a0)
		move.w	#$3FFF,d0	;64kB
.vram_clrloop:
		move.l	d1,(a1)
		dbra	d0,.vram_clrloop

;		md_set_cram_addr 0,(a0)
;		moveq	#32-1,d0	;64 words/128b
;.cram_clrloop:
;		move.l	d1,(a1)
;		dbra	d0,.cram_clrloop

		md_set_vsram_addr 0,(a0)
		moveq	#20-1,d0	;40 words/80b
.vsram_clrloop:
		move.l	d1,(a1)
		dbra	d0,.vsram_clrloop

prepbitmap:	;prepare vdp plane-b for bitmap mode
		md_set_vdp_incr 2,(a0)
		md_set_vram_addr planeb_addr,(a0)	;B!

		move.w	#bmp_addr>>5,d2
		move.w	#32-1,d1	; rows
.ylp:		move.w	#64-1,d0	; chars
		move.l	d2,d3		; save tile
.lp:		move.w	d3,(a1)
		addq	#1,d3		; add to tile
		dbra	d0,.lp
		add.w	#40,d2		; add row
		dbra	d1,.ylp

showpic:
		tst.l	piclen
		beq	vgm_main
		md_dma_ram_to_vram_a0	picdat,bmp_addr,picsiz>>1
		lea	picpal,a2
		move.l	#$C0000000|((0&$3f)<<17),(a0)
		moveq	#16-1,d0
.lp:		move.w	(a2)+,(a1)	
		dbra	d0,.lp

		md_set_vdp_mode2	vdp_m2_disp|vdp_m2_vbl|vdp_m2_dma,(a0)

vgm_main:
;a0: VGM data pointer
;a1: VGM data restart
;a2: YM2612
;a4: current sample pointer
;a5: sample rom start
;a6: Port Code Array
;a7: stack

;d0: port, both coded and decoded
;d1: data/delay
;d2: ym2612 port select
;d3: timer-control value
;d4: vdp vcnt, initial vcount is not important
;d7: zero
		lea	datastart+4,a0
		add.l	piclen,a0
		lea.l	4(a0),a5	;data for sample #1
		add.l	(a0),a0		;digi size
		add.w	#4,a0		;add size longint

		move.l	a0,a1		;for restart
		lea	ports,a6
		lea	reg_ym2612,a2
		sub.l	a4,a4
		moveq	#0,d7

vgm_playloop:
		bsr	digicheck	;68c altogether

		moveq	#0,d0
		move.b	(a0)+,d0	;port
		moveq	#0,d1
		move.b	(a0)+,d1	;dat

		add.w	d0,d0
		move.w	(a6,d0),d0	;depack port

		;cmp.w	#$0000,d0	;delay
		beq	vgm_dodly

		cmp.w	#$0001,d0	;psg
		beq	vgm_dopsg

		cmp.w	#$0002,d0	;dac
		beq	vgm_dodigi

		cmp.w	#$0020,d0	;ym
		bcc	vgm_doym

		bra	vgm_playloop

vgm_doym:
		move.w	d0,d2
		lsr.w	#8,d2

		cmp.b	#$27,d0		;YM TIMER CONTROL
		bne	.skipstore
		move.b	d1,d3
.skipstore:
		move.b	d0,0(a2,d2)
		move.b	d1,1(a2,d2)
.wait:	
		btst.b	#7,(a2)		;BUSY?, 90 Z80c / 192 68kC, 70 Z80c needed
	        bne.s	.wait

		bra	vgm_playloop

vgm_dodly:		
		tst.b	d1		;end?
		beq	vgm_dostop
.wait:
		bsr	digicheck
		btst.b	#1,(a2)		;TIMER-B?
		beq.s	.wait
	
		move.b	#$27,0(a2)	;YM TIMER CONTROL
		move.b	d3,1(a2)

		sub.b	#1,d1
		bne	.wait

		bra	vgm_playloop

vgm_dopsg:
		move.b	d1,vdp_psg
		bra	vgm_playloop

vgm_dostop:
		move.l	a1,a0
		bra	vgm_playloop

vgm_dodigi:
		tst.b	d1
		beq	.digistop
.digistart:
		subq.b	#1,d1
		move.b	#$2b,0(a2)	;DAC CONTROL
		move.b	#$80,1(a2)	;DAC ENABLE
		lsl.w	#2,d1
		move.l	(a5,d1),a4	;LOAD SAMPLE OFFSET
		add.l	a5,a4		;ADD ROM ADDRESS
		bra	vgm_playloop
	
.digistop:
		bsr	digistop
		bra	vgm_playloop

digicheck:
		move.b	vdp_vcnt,d0	;16
		cmp.b	d0,d4		; 4
		beq	.chkdone	;12
		move.b	d0,d4
		cmp.l	d7,a4
		beq	.chkdone
		move.b	(a4)+,d0
		beq	digistop
		move.b	#$2a,(a2)
		move.b	d0,1(a2)
.chkdone:		
		rts			;16

digistop:
		move.b	#$2b,0(a2)	;DAC CONTROL
		move.b	d7,1(a2)	;DAC DISABLE
		sub.l	a4,a4		;NO SAMPLE
		rts

ports:
		dc.w	$000,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
		dc.w	$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
		dc.w	$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
		dc.w	$022,$024,$025,$026,$027,$028,$02A,$02B,$030,$031,$032,$034,$035,$036,$038,$039
		dc.w	$03A,$03C,$03D,$03E,$040,$041,$042,$044,$045,$046,$048,$049,$04A,$04C,$04D,$04E
		dc.w	$050,$051,$052,$054,$055,$056,$058,$059,$05A,$05C,$05D,$05E,$060,$061,$062,$064
		dc.w	$065,$066,$068,$069,$06A,$06C,$06D,$06E,$070,$071,$072,$074,$075,$076,$078,$079
		dc.w	$07A,$07C,$07D,$07E,$080,$081,$082,$084,$085,$086,$088,$089,$08A,$08C,$08D,$08E
		dc.w	$090,$091,$092,$094,$095,$096,$098,$099,$09A,$09C,$09D,$09E,$0A0,$0A1,$0A2,$0A4
		dc.w	$0A5,$0A6,$0A8,$0A9,$0AA,$0AC,$0AD,$0AE,$0B0,$0B1,$0B2,$0B4,$0B5,$0B6,$230,$231
		dc.w	$232,$234,$235,$236,$238,$239,$23A,$23C,$23D,$23E,$240,$241,$242,$244,$245,$246
		dc.w	$248,$249,$24A,$24C,$24D,$24E,$250,$251,$252,$254,$255,$256,$258,$259,$25A,$25C
		dc.w	$25D,$25E,$260,$261,$262,$264,$265,$266,$268,$269,$26A,$26C,$26D,$26E,$270,$271
		dc.w	$272,$274,$275,$276,$278,$279,$27A,$27C,$27D,$27E,$280,$281,$282,$284,$285,$286
		dc.w	$288,$289,$28A,$28C,$28D,$28E,$290,$291,$292,$294,$295,$296,$298,$299,$29A,$29C
		dc.w	$29D,$29E,$2A0,$2A1,$2A2,$2A4,$2A5,$2A6,$2B0,$2B1,$2B2,$2B4,$2B5,$2B6,$001,$002

		align	10
ROM_End:	
		end
