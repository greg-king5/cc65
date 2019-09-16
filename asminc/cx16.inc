;
; CX16 definitions
;

; ---------------------------------------------------------------------------
; Zero page

VARTAB          := $2D          ; Pointer to start of BASIC variables
MEMSIZE         := $37          ; Pointer to highest BASIC RAM location (+1)
TXTPTR          := $7A          ; Pointer into BASIC source code

TIME            := $A0          ; 60 Hz. clock
FNAM_LEN        := $B7          ; Length of filename
SECADR          := $B9          ; Secondary address
DEVNUM          := $BA          ; Device number
FNAM            := $BB          ; Pointer to filename
KEY_COUNT       := $C6          ; Number of keys in input buffer
RVS             := $C7          ; Reverse flag
CURS_FLAG       := $CC          ; 1 = cursor off
CURS_BLINK      := $CD          ; Blink counter
CURS_CHAR       := $CE          ; Character under the cursor
CURS_STATE      := $CF          ; Cursor blink state
SCREEN_PTR      := $D1          ; Pointer to current char in text screen
CURS_X          := $D3          ; Cursor column
CURS_Y          := $D6          ; Cursor row
LLEN		:= $D9		; Line length
NLINES		:= $DA		; Number of screen lines
JOY1		:= $EF		; 3 bytes of NES/SNES gamepad data, ...
JOY2		:= $F2		; ... interrupt-driven
CRAM_PTR        := $F3          ; Pointer to current char in color RAM (not in CX16)
FREKZP          := $FB          ; Five unused bytes

; Page two

BASIC_BUF       := $200         ; Location of command-line
BASIC_BUF_LEN   = 89            ; Maximum length of command-line

CHARCOLOR       := $286
CURS_COLOR      := $287         ; Color under the cursor

KBDREPEAT       := $28a
KBDREPEATRATE   := $28b
KBDREPEATDELAY  := $28c

PALFLAG         := $2A6         ; $01 = PAL, $00 = NTSC

; ---------------------------------------------------------------------------
; Vector and other locations

IRQVec          := $0314
BRKVec          := $0316
NMIVec          := $0318

; ---------------------------------------------------------------------------
; I/O locations

; Sound

; Video Enhanced Retro Adapter
.scope VERA
.ifdef VERA8
  ; External registers
  .struct
		.org	$9F20
  ADDR		.faraddr	; Address for data port access
  DATA1		.byte		; First data port
  DATA2		.byte		; Second data port
  CTRL		.byte		; Control register
  IEN		.byte		; Interrupt enable bits
  ISR		.byte		; Interrupt flags
  .endstruct
  .enum				; Address automatic increment
  INCR0		=	0 << 4
  INCR1		=	1 << 4
  INCR2		=	2 << 4
  INCR4		=	3 << 4
  INCR8		=	4 << 4
  INCR16	=	5 << 4
  INCR32	=	6 << 4
  INCR64	=	7 << 4
  INCR128	=	8 << 4
  INCR256	=	9 << 4
  INCR512	=	10 << 4
  INCR1024	=	11 << 4
  INCR2048	=	12 << 4
  INCR4096	=	13 << 4
  INCR8192	=	14 << 4
  INCR16384	=	15 << 4
  .endenum
  ; Internal RAM and registers
  VRAM		:=	$000000
  .scope	COMPOSER	; Display composer
    .struct
		.org	$0F0000
    VIDEO	.byte
    HSCALE	.byte
    VSCALE	.byte
    FRAME	.byte
    HSTART_LO	.byte
    HSTOP_LO	.byte
    VSTART_LO	.byte
    VSTOP_LO	.byte
    STRTSTOP_HI	.byte
    IRQ_LINE	.word
    .endstruct
    .enum	MODE		; Output mode
      DISABLE	=	0
      VGA
      NTSC
      RGB			; Interlaced, composite sync
    .endenum
    .enum
    ENABLE_COLOR	= 	0 << 2
    DISABLE_COLOR	= 	1 << 2	; NTSC monochrome
    .endenum
  .endscope
  PALETTE	:=	$0F1000
  .struct	L1		; Layer 1 registers
		.org	$0F2000
    CTRL0	.byte		; Display mode control
    CTRL1	.byte		; Geometry control
    MAP_BASE	.addr
    TILE_BASE	.addr
    HSCROLL	.word		; Horizontal scroll
    VSCROLL	.word		; Vertical scroll
  .endstruct
  .struct	L2		; Layer 2 registers (same as layer 1)
		.org	$0F3000
    CTRL0	.byte
    CTRL1	.byte
    MAP_BASE	.addr
    TILE_BASE	.addr
    HSCROLL	.word
    VSCROLL	.word
  .endstruct
  .enum		MAP		; Map geometry
    WIDTH32	=	0
    WIDTH64
    WIDTH128
    WIDTH256
    HEIGHT32	=	0 << 2
    HEIGHT64	=	1 << 2
    HEIGHT128	=	2 << 2
    HEIGHT256	=	3 << 2
  .endenum
  .scope	TILE		; Tile geometry
    .enum
    WIDTH8	=	0 << 4
    WIDTH16	=	1 << 4
    WIDTH320	=	WIDTH8
    WIDTH640	=	WIDTH16
    HEIGHT8	=	0 << 5
    HEIGHT16	=	1 << 5
    .endenum
    .enum	FLIP
      NONE	=	0 << 2
      HORIZ	=	1 << 2
      VERT	=	2 << 2
      BOTH	=	3 << 2
    .endenum
  .endscope
  .enum		DMODE		; Display modes
    TEXT16	=	0 << 5
    TEXT256	=	1 << 5
    TILE4	=	2 << 5
    TILE16	=	3 << 5
    TILE256	=	4 << 5
    BITMAP4	=	5 << 5
    BITMAP16	=	6 << 5
    BITMAP256	=	7 << 5
  .endenum
  .scope	SPRITE
    .struct
		.org	$0F4000
    CTRL	.byte		; Enables sprites
    COLLISION	.byte
    .endstruct
    .enum	FLIP
      NONE	=	0
      HORIZ
      VERT
      BOTH
    .endenum
    .enum			; Sprite geometry
    WIDTH8	=	0 << 4
    WIDTH16	=	1 << 4
    WIDTH32	=	2 << 4
    WIDTH64	=	3 << 4
    HEIGHT8	=	0 << 6
    HEIGHT16	=	1 << 6
    HEIGHT32	=	2 << 6
    HEIGHT64	=	3 << 6
    COLORS16	=	0 << 7
    COLORS256	=	1 << 7
    .endenum
    .enum	DEPTH
      DISABLE	=	0 << 2
      CANVAS	=	1 << 2
      LAYER1	=	2 << 2
      LAYER2	=	3 << 2
    .endenum
    DATA	:=	$0F5000
  .endscope
.else
; Emulator has VERA 0.7
  ; External registers
  .struct
		.org	$9F20
  ADDR_HI	.byte
  ADDR_MID	.byte
  ADDR_LO	.byte
  DATA1		.byte		; First data port
  DATA2		.byte		; Second data port
  CTRL		.byte		; Control register
  IEN		.byte		; Interrupt enable bits
  ISR		.byte		; Interrupt flags
  .endstruct
  ; Internal RAM and registers
  VRAM		:=	$000000
  FONT1		:=	$020000
  FONT2		:=	$020800
  .struct	L1		; Layer 1 registers
		.org	$040000
    CTRL0	.byte		; Display mode control
    CTRL1	.byte		; Geometry control
    MAP_BASE	.addr
    TILE_BASE	.addr
    HSCROLL	.word		; Horizontal scroll
    VSCROLL	.word		; Vertical scroll
  .endstruct
  .struct	L2		; Layer 2 registers (same as layer 1)
		.org	$040010
    CTRL0	.byte
    CTRL1	.byte
    MAP_BASE	.addr
    TILE_BASE	.addr
    HSCROLL	.word
    VSCROLL	.word
  .endstruct
  .enum		MAP		; Map geometry
    WIDTH32	=	0
    WIDTH64
    WIDTH128
    WIDTH256
    HEIGHT32	=	0 << 2
    HEIGHT64	=	1 << 2
    HEIGHT128	=	2 << 2
    HEIGHT256	=	3 << 2
  .endenum
  .scope	TILE		; Tile geometry
    .enum
    WIDTH8	=	0 << 4
    WIDTH16	=	1 << 4
    WIDTH320	=	WIDTH8
    WIDTH640	=	WIDTH16
    HEIGHT8	=	0 << 5
    HEIGHT16	=	1 << 5
    .endenum
    .enum	FLIP
      NONE	=	0 << 2
      HORIZ	=	1 << 2
      VERT	=	2 << 2
      BOTH	=	3 << 2
    .endenum
  .endscope
  .enum		DMODE		; Display modes
    TEXT16	=	0 << 5
    TEXT256	=	1 << 5
    TILE4	=	2 << 5
    TILE16	=	3 << 5
    TILE256	=	4 << 5
    BITMAP4	=	5 << 5
    BITMAP16	=	6 << 5
    BITMAP256	=	7 << 5
  .endenum
  .scope	SPRITE
    .struct
		.org	$040020
    CTRL	.byte		; Enables sprites
    COLLISION	.byte
    .endstruct
    .enum	FLIP
      NONE	=	0
      HORIZ
      VERT
      BOTH
    .endenum
    .enum			; Sprite geometry
    WIDTH8	=	0 << 4
    WIDTH16	=	1 << 4
    WIDTH32	=	2 << 4
    WIDTH64	=	3 << 4
    HEIGHT8	=	0 << 6
    HEIGHT16	=	1 << 6
    HEIGHT32	=	2 << 6
    HEIGHT64	=	3 << 6
    COLORS16	=	0 << 7
    COLORS256	=	1 << 7
    .endenum
    .enum	DEPTH
      DISABLE	=	0 << 2
      CANVAS	=	1 << 2
      LAYER1	=	2 << 2
      LAYER2	=	3 << 2
    .endenum
    DATA	:=	$040800
  .endscope
  .scope	COMPOSER	; Display composer
    .struct
		.org	$040040
    VIDEO	.byte
    HSCALE	.byte
    VSCALE	.byte
    FRAME	.byte
    HSTART_LO	.byte
    HSTOP_LO	.byte
    VSTART_LO	.byte
    VSTOP_LO	.byte
    STRTSTOP_HI	.byte
    IRQ_LINE	.word
    .endstruct
    .enum	MODE		; Output mode
      DISABLE	=	0
      VGA
      NTSC
      RGB			; Interlaced, composite sync
    .endenum
    .enum
    ENABLE_COLOR	= 	0 << 2
    DISABLE_COLOR	= 	1 << 2	; NTSC monochrome
    .endenum
  .endscope
  PALETTE	:=	$040200
.endif
.endscope

; 65c22
.struct VIA1                    ; Versatile Interface Adapter
        .org    $9F60
PRB     .byte                   ; Port Register B
PRA     .byte                   ; Port Register A
DDRB    .byte                   ; Data Direction Register B
DDRA    .byte                   ; Data Direction Register A
T1      .word                   ; Timer 1
T1L     .word                   ; Timer 1 Latch
T2      .word                   ; Timer 2
SR      .byte                   ; Shift Register
ACR     .byte                   ; Auxiliary Control Register
PCR     .byte                   ; Peripheral Control Register
IFR     .byte                   ; Interrupt Flags Register
IER     .byte                   ; Interrupt Enable Register
PRA2    .byte                   ; Port Register A without handshaking
.endstruct

; 65c22
.struct VIA2
        .org    $9F70
PRB     .byte
PRA     .byte
DDRB    .byte
DDRA    .byte
T1      .word
T1L     .word
T2      .word
SR      .byte
ACR     .byte
PCR     .byte
IFR     .byte
IER     .byte
PRA2    .byte
.endstruct

; Real-Time Clock

; X16 Emulator device
; This device doesn't exist on the real machine.
.struct EMULATOR
		.org	$9FB0
DEBUG		.byte
VIDACCESSLOG	.byte
KEYBOARDLOG	.byte
ECHO		.byte
SAVEXIT		.byte
.endstruct
