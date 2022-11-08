	        dc.b	"SEGA MEGA DRIVE "                                 ; Console name - "SEGA MEGA DRIVE ","SEGA GENESIS    ","SEGA SSF        "
;	        dc.b	"SEGA GENESIS    "                                 ; Console name - "SEGA MEGA DRIVE ","SEGA GENESIS    ","SEGA SSF        "
;		dc.b	"SEGA SSF        "                                 ; Console name - "SEGA MEGA DRIVE ","SEGA GENESIS    ","SEGA SSF        "

	        dc.b	"(C)RAB  "                                         ; Copyright holder and release date

;		dc.b	"2021.DEC"                                         ; Standard Date: 2021.DEC
		include	"mdrelease.inc"                                    ; Or use makefile generated YYYYMMDD

	        dc.b	"RABENAUGE MD PICTURE VIEWER AND VGM PLAYER      " ; Domestic name
	        dc.b	"RABENAUGE MD PICTURE VIEWER AND VGM PLAYER      " ; International name

	        dc.b	"GM XXXXXXXX-XX"                                   ; Version number
	        dc.w	$0000                                              ; Checksum
	        dc.b	"J               "                                 ; I/O support
	        dc.l	$00000000                                          ; Start address of ROM
	        dc.l	ROM_End-1                                          ; End address of ROM
	        dc.l	$00FF0000                                          ; Start address of RAM
	        dc.l	$00FFFFFF                                          ; End address of RAM
	        dc.l	$20202020                                          ; SRAM enabled when 'RA'
	        dc.l	$20202020                                          ; Start address of SRAM
	        dc.l	$20202020                                          ; End address of SRAM
	        dc.l	$20202020                                          ; Unused
	        dc.l	$20202020                                          ; Unused
	        dc.l	$20202020                                          ; Unused
	        dc.b	"                                        "         ; Notes (unused)
	        dc.b	"JUE             "                                 ; Country codes
