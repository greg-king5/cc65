;
; This is a helper function for the CBM DIO implementation.
;
; /* Go to a sector.  Move its data between a disk and a drive buffer.
; ** Return the drive status.
; */
; unsigned char fastcall "seek_sector"(unsigned track, unsigned sector,
;                                      char direction);
;
; 2018-04-26, Greg King
;

        .export         seek_sector

        .import         pushax, _utoa
        .import         writediskcmd, readdiskerror
        .import         ptr1:zp, ptr2:zp

        .include        "diovals.inc"
        .include        "filedes.inc"
        .include        "errno.inc"


;--------------------------------------------------------------------------
.data

; (We use .proc here because it defines both a label and a scope.)

.proc   sectCmd
        .byte   'u'
direction:
        .byte   "1 "
channel:
        .byte   "10 "
drive:  .byte   "0 "
track:  .byte   "255 "
sector: .asciiz "255"
.endproc


;--------------------------------------------------------------------------
.code

seek_sector:
        sta     sectCmd::direction
        ldx     #'0'
        stx     sectCmd::channel
        lda     dhandle
        clc
        adc     #LFN_OFFS       ; file # as channel
        cmp     #10
        bcc     @L0             ;(blt)
        ;sec
        sbc     #10
        inc     sectCmd::channel; '1'
        clc
@L0:    adc     #'0'
        sta     sectCmd::channel + 1

; Pad the track and sector fields with spaces.

        ldy     #sectCmd::sector+3 - sectCmd::track+2
        lda     #' '
@L1:    sta     sectCmd::track+2,y
        dey
        bpl     @L1

; utoa (sector, sectCmd.sector, 10);
; sector already is on the C stack.  Put sectCmd.sector on the stack; and, load the radix.
; utoa() will pop sector off the stack.

        lda     #<(sectCmd::sector)
        ldx     #>(sectCmd::sector)
        jsr     pushax
        lda     #<10
        ldx     #>10
        jsr     _utoa

; utoa (track, sectCmd.track, 10);
; track already is on the C stack.  Put sectCmd.track on the stack; and, load the radix.
; utoa() will pop track off the stack.

        lda     #<(sectCmd::track)
        ldx     #>(sectCmd::track)
        jsr     pushax
        lda     #<10
        ldx     #>10
        jsr     _utoa

; Replace the string terminator with a space.
; NOTE!  This code assumes that it knows how utoa() works internally.

        lda     #' '
        sta     (ptr2),y

; Send the command to the drive unit.

        lda     #<sectCmd
        ldx     #>sectCmd
        sta     ptr1
        stx     ptr1+1
        ldy     dhandle
        lda     unittab,y
        tax
        pha
        lda     #.sizeof(sectCmd) - 1
        jsr     writediskcmd

; Get the drive status, set oserror, and return.  The
; CPU's zero-flag is set/reset according to the status.

        pla
        tax                     ; unit #
        jsr     readdiskerror
        sta     __oserror
        rts
