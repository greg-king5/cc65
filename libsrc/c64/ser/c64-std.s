; A serial driver for the C64, using the user-port.
;
; (c) 2014, Johan Van den Brande
; 2019-02-16, Greg King
;
; Based on George Hug's 'Towards 2400' article in the Transactor Magazine, volume 9, issue 3.
; <https://archive.org/details/transactor-magazines-v9-i03>
;
; This version works on only NTSC C64s.  PAL C64s need different speed tables.

        .include        "zeropage.inc"
        .include        "ser-kernel.inc"
        .include        "ser-error.inc"
        .include        "cbm_kernal.inc"
        .include        "c64.inc"

        .macpack        module
        .macpack        generic

; ------------------------------------------------------------------------
; Routines that are buried in the Kernal ROM

findfn  :=      $F30F
devnum  :=      $F31F
nofile  :=      $F701

rstkey  :=      $FE56
norest  :=      $FE72

; ------------------------------------------------------------------------
; Header. Includes jump table

        module_header   _c64_std_ser

; Driver signature

        .byte   $73, $65, $72   ; ASCII "ser"
        .byte   SER_API_VERSION ; serial API version number

; Library reference

        .addr   $0000

; Jump table

        .addr   SER_INSTALL
        .addr   SER_UNINSTALL
        .addr   SER_OPEN
        .addr   SER_CLOSE
        .addr   SER_GET
        .addr   SER_PUT
        .addr   SER_STATUS
        .addr   SER_IOCTL
        .addr   SER_IRQ

.bss

oldnmi: .res    2
inbuf:  .res    $0100           ; note: these buffers aren't aligned
outbuf: .res    $0100           ;   on page boundaries

.rodata

; NTSC Speed tables

strt24: .word   $01CB           ; 459   start-bit times
strt12: .word   $0442           ; 1090
strt03: .word   $1333           ; 4915

full24: .word   $01A5           ; 421   full-bit times
full12: .word   $034D           ; 845
full03: .word   $0D52           ; 3410

.data

; Default RS-232 parameters

baudrate = SER_BAUD_2400
databits = %00000000            ; SER_BITS_8
stopbit  = %00000000            ; SER_STOP_1

wire   = %00000000              ; SER_HS_NONE
duplex = %00000000              ; full duplex
parity = %00000000              ; SER_PAR_NONE

serial_config:
  .byte stopbit | databits | baudrate
  .byte parity | duplex | wire

.code

;----------------------------------------------------------------------------
; SER_INSTALL routine. Is called after the driver is loaded into memory. If
; possible, check if the hardware is present.
; Must return an SER_ERR_xx code in a/x.

SER_INSTALL:
        lda     #<SER_ERR_OK
        tax                     ; #>SER_ERR_OK
        rts

;----------------------------------------------------------------------------
; PARAMS routine. A pointer to a ser_params structure is passed in ptr1.
; Must return a SER_ERR_xx code in a/x.

; The requested BPS rate isn't available.

InvBPS: lda     #<SER_ERR_BAUD_UNAVAIL
        .byte   $2C             ;(bit $xxxx)

; A parameter is invalid.

InvParam:
        lda     #<SER_ERR_INIT_FAILED
        ldx     #>SER_ERR_COUNT
        rts

SER_OPEN:
        lda     NMIVec
        ldx     NMIVec+1
        sta     oldnmi
        stx     oldnmi+1

        ldx     ptr1+1          ; ptr1 == NULL?
        bze     noparams        ; yes, keep old settings

; Set the value for the control register, which tells the BPS rate,
; the character length, and the number of stop bits.  Only 8N1 is supported.

        ldy     #SER_PARAMS::BAUDRATE
        lda     (ptr1),y        ; get BPS code
        cmp     #SER_BAUD_300
        blt     InvBPS          ; branch if rate not supported
        cmp     #SER_BAUD_600
        beq     InvBPS
        cmp     #SER_BAUD_1800
        beq     InvBPS
        cmp     #SER_BAUD_3600
        bge     InvBPS
        tax

        iny                     ;ldy #SER_PARAMS::DATABITS
        lda     (ptr1),y
        cmp     #SER_BITS_8
        bne     InvParam        ; only eight bit-characters supported

        iny                     ;ldy #SER_PARAMS::STOPBITS
        lda     (ptr1),y
        cmp     #SER_STOP_1
        bne     InvParam        ; no idle bit support
        stx     serial_config + 0

; Set the value for the command register.

        iny                     ;ldy #SER_PARAMS::PARITY
        lda     (ptr1),y
        cmp     #SER_PAR_NONE
        bne     InvParam        ; no parity support

; Ignore the HandShake setting, so that this driver can co-exist
; with the SwiftLink driver (which demands a different setting).

.if 0
        iny                     ;ldy #SER_PARAMS::HANDSHAKE
        lda     (ptr1),y
        cmp     #SER_HS_NONE
        bne     InvParam        ; handshaking not supported
        sta     serial_config + 1       ; (.A is zero)
.endif

noparams:
; Assign the driver's buffers because the Kernal's
; buffers would overwrite other parts of RAM.

        lda     #<inbuf
        ldx     #>inbuf
        sta     RIBUF
        stx     RIBUF+1
        lda     #<outbuf
        ldx     #>outbuf
        sta     ROBUF
        stx     ROBUF+1

        lda     #2              ; a file-number not used by POSIX file system
        tax
        ;tay                    ; (C64 driver doesn't use a second address)
        jsr     SETLFS          ; set logical, first, and second addresses

        ;lda    #2              ; (SETLFS doesn't change the registers)
        ldx     #<serial_config
        ldy     #>serial_config
        jsr     SETNAM          ; set "file-name"

        jsr     OPEN            ; (RS-232 open always returns error code)
        cmp     #$F0            ; is it fake code (used by BASIC ROM)?
        bne     badopen

        lda     #<nmi64
        ldx     #>nmi64
        sta     NMIVec
        stx     NMIVec+1

        lda     BAUDOF          ; full tx bit-time to ta
        ldx     BAUDOF+1
        sta     CIA2_TA
        stx     CIA2_TA+1

        lda     BAUDOF+1        ; set receive to same
        and     #%00000110      ;   BPS rate as xmit
        tay
        lda     strt24,y
        sta     strtlo+1        ; overwrite values in NMI handler
        lda     strt24+1,y
        sta     strthi+1
        lda     full24,y
        sta     fulllo+1
        lda     full24+1,y
        sta     fullhi+1
        jsr     inable          ; start listenning for traffic

        lda     #<SER_ERR_OK
        tax
        rts

badopen:
        cmp     #2
        beq     already_open
        lda     #<SER_ERR_NO_DEVICE
        .byte   $2C             ;(bit $xxxx)
already_open:
        lda     #<SER_ERR_INSTALLED
        ldx     #>SER_ERR_COUNT
        rts

;----------------------------------------------------------------------------
; SER_UNINSTALL routine. Is called before the driver is removed from memory.
; Must return a SER_ERR_xx code in a/x.

SER_UNINSTALL:
        ; Make sure that the device is closed before the driver is abandoned.

;----------------------------------------------------------------------------
; SER_CLOSE: Flush the send buffer, disable interrupts, and close the device.
; Called without parameters. Must return an error code in a/x.

SER_CLOSE:
        jsr     disabl

        lda     #2
        jsr     CLOSE
        bcs     @notopn

; Disconnect the modem.

        lda     #%00000010      ; lower DTR line
        sta     CIA2_PRB
        lda     #%00000110
        sta     CIA2_PRB

        lda     oldnmi
        ldx     oldnmi+1
        sta     NMIVec
        stx     NMIVec+1

@notopn:
        lda     #<SER_ERR_OK
        tax
        rts

;----------------------------------------------------------------------------
; SER_GET: Will fetch a character from the receive buffer; and, store it into
; the variable pointed to by ptr1. If no data is available, SER_ERR_NO_DATA is
; returned.

SER_GET:
        ldy     RIDBS
        cpy     RIDBE           ; buffer empty?
        beq     get_no_data

        ldx     #2
        jsr     nchkin
        bcs     notopen
        jsr     GETIN
        ldx     #$00
        sta     (ptr1,x)
        jsr     CLRCH

        lda     #<SER_ERR_OK
        tax
        rts

notopen:
        lda     #<SER_ERR_NOT_OPEN
        .byte   $2C             ;(bit $xxxx)
get_no_data:
        lda     #<SER_ERR_NO_DATA
        ldx     #>SER_ERR_COUNT
        rts

;----------------------------------------------------------------------------
; SER_PUT: Output the character in A.  This function will be blocked
; while the send buffer is full.  Must return an error code in a/x.

SER_PUT:
        pha
        ldx     #2
        jsr     CKOUT
        pla
        bcs     notopen
        jsr     rsout
        jsr     CLRCH

        lda     #<SER_ERR_OK
        tax
        rts

;----------------------------------------------------------------------------
; SER_STATUS: Return the status in the variable pointed to by ptr1.
; Must return an error code in a/x.
;
; This version of the driver doesn't detect RS-232 character errors.

SER_STATUS:
        lda     #<SER_ERR_INV_IOCTL
        ldx     #>SER_ERR_INV_IOCTL
        rts

;----------------------------------------------------------------------------
; SER_IOCTL: Driver-defined entry point. The wrapper will pass a pointer
; to ioctl-specific data in ptr1, and the ioctl code in A.
; Must return an error code in a/x.
;
; SER_IOCTL can be used to prevent NMIs from interfering with IEC bus
; operations and RAM expansion DMA.

SER_IOCTL:
        tax
        bze     @disable
@ENABLe:
        jsr     inable
        jmp     @exit

@disable:
        jsr     disabl
@exit:  lda     #<SER_ERR_OK
        tax
        rts

;----------------------------------------------------------------------------
; SER_IRQ: Non-Maskable Interrupts are used instead.
;

SER_IRQ := $0000

;--------------------------------------
; New NMI handler.
; Some operands are changed in-place; that helps to make this routine fast.
; But, it means that this driver can't run from a ROM!

nmi64:  pha
        txa
        pha
        tya
        pha
nmi128: cld
        ldx     CIA2_TB+1       ; sample timer b hi byte
        lda     #%01111111      ; disable CIA NMIs
        sta     CIA2_ICR
        lda     CIA2_ICR        ; read/clear flags
        bpl     notcia          ; (restore key)
        cpx     CIA2_TB+1       ; tb timeout since timer b sampled?
        ldy     CIA2_PRB        ; (sample user port pin C, for later)
        bge     mask            ; no
        ora     #%00000010      ; yes, work around CIA bug
        ora     CIA2_ICR        ; read/clear flags again
mask:   and     ENABL           ; mask out non-ENABLed
        tax                     ; these must be serviced
        lsr     a               ; timer a? (bit 0)
        bcc     ckflag          ; no
        lda     CIA2_PRA        ; yes, put output bit on pin M
        and     #<~%00000100    ; replace old bit
        ora     NXTBIT          ;   with next bit
        sta     CIA2_PRA

ckflag: txa
        and     #%00010000      ; *flag NMI (bit 4)?
        bze     nmion           ; no
strtlo: lda     #<$01CB         ; yes, start-bit time to tb (self-modified)
        sta     CIA2_TB
strthi: lda     #>$01CB         ; (self-modified)
        sta     CIA2_TB+1
        lda     #%00010001      ; start tb counting
        sta     CIA2_CRB
        lda     #%00010010      ; *flag NMI off, tb on
        eor     ENABL           ; update mask
        sta     ENABL
        sta     CIA2_ICR        ; ENABLe new config
fulllo: lda     #<$01A5         ; change reload latch (self-modified)
        sta     CIA2_TB         ;   to full-bit time
fullhi: lda     #>$01A5         ; (self-modified)
        sta     CIA2_TB+1
        lda     #8              ; # of bits to receive
        sta     BITCI
        bnz     chktxd          ; branch always (carry still has ta's NMI)

notcia: ldy     #$00
        jmp     rstkey          ; or jmp norest

nmion:  lda     ENABL           ; re-ENABLe NMIs
        sta     CIA2_ICR
        txa
        and     #%00000010      ; timer b? (bit 1)
        bze     chktxd          ; no
        tya                     ; yes, get sample of pin C
        lsr     a
        ror     RIDATA          ; RS232 is LSB first
        dec     BITCI           ; byte finished?
        bnz     txd             ; no
        ldy     RIDBE           ; yes, byte to buffer
        lda     RIDATA
        sta     (RIBUF),y       ; (no overrun test)
        inc     RIDBE
        lda     #%00000000      ; stop timer b
        sta     CIA2_CRB
        lda     #%00010010      ; *flag on, tb NMI off

switch: ldy     #%01111111      ; disable all NMIs
        sty     CIA2_ICR
        sty     CIA2_ICR        ;   twice
        eor     ENABL           ; update mask
        sta     ENABL
        sta     CIA2_ICR        ; ENABLe new config.

txd:    txa
        lsr     a               ; timer a?
chktxd: bcc     exit            ; no
        dec     BITTS           ; byte finished?
        bmi     char            ; yes
        lda     #%00000100      ; no, prep. next bit
        ror     RODATA          ; (fill with set stop & idle bits)
        bcs     store

low:    lda     #%00000000      ; clear bit 2
store:  sta     NXTBIT

exit:   jmp     NMIEXIT         ; restore registers, rti

char:   ldy     RODBS
        cpy     RODBE           ; buffer empty?
        beq     txoff           ; yes
getbuf: lda     (ROBUF),y       ; no, prep next byte
        inc     RODBS
        sta     RODATA
        lda     BITNUM          ; # bits to send (e.g., 8+1)
        sta     BITTS
        bnz     low             ; branch always -- do start bit

txoff:  ldx     #%00000000      ; stop timer a
        stx     CIA2_CRA
        lda     #%00000001      ; disable ta NMI
        bnz     switch          ; branch always

;--------------------------------------
; Stops the serial device's Non-Maskable Interrupts.

disabl: ldx     #%00010000
        lda     #%00000011
test:   bit     ENABL           ; any current activity?
        bnz     test            ; yes, keep waiting
        stx     CIA2_ICR        ; no, disable *flag NMI
        and     ENABL           ; newly receiving?
        bnz     test            ; yes, start over
        sta     ENABL           ; all off, update mask
        rts

;--------------------------------------
; Output to RS-232.

rsout:  sta     KPTR1
        sty     XSAV

point:  ldy     RODBE
        sta     (ROBUF),y       ; not official 'till pointer bumped
        iny
        cpy     RODBS           ; buffer full?
        beq     fulbuf          ; yes
        sty     RODBE           ; no, bump pointer

strtup: lda     ENABL
        and     #%00000001      ; transmitting now?
        bnz     ret3            ; yes
        sta     NXTBIT          ; no, prep start bit,
        lda     BITNUM
        sta     BITTS           ;   # bits to send,
        ldy     RODBS
        lda     (ROBUF),y
        sta     RODATA          ;   and next byte
        inc     RODBS
        lda     #%00010001      ; start timer a
        sta     CIA2_CRA
        lda     #%10000001      ; ENABLe ta NMI
change: sta     CIA2_ICR        ; NMI clears flag if set
        ldy     #%01111111
        php                     ; save IRQ status
        sei                     ; disable IRQs because this must happen quickly
        sty     CIA2_ICR        ; temporarily disable all NMIs
        sty     CIA2_ICR        ;   twice
        ora     ENABL           ; update mask
        sta     ENABL
        sta     CIA2_ICR        ; ENABLe new config.
        plp                     ; restore IRQ status

ret3:   clc
        ldy     XSAV
        lda     KPTR1
        rts

; The send buffer is full.  Make sure that it will be emptied.  Keep trying
; to store the current output character until there is space for it.

fulbuf: jsr     strtup
        jmp     point

;--------------------------------------
nchkin:                 ; new CHKIN
        jsr     findfn
        bne     nosuch
        jsr     devnum
        lda     DEVNUM
        sta     DFLTN

; ENABLe RS-232 input.

inable: sta     KPTR1
        sty     XSAV
        lda     ENABL
        and     #%00010010      ; *flag or tb on?
        bnz     ret3            ; yes
        sta     CIA2_CRB        ; no, stop tb (.A is zero)
        lda     #%10010000      ; turn on flag NMI
        jmp     change

nosuch: jmp     nofile
