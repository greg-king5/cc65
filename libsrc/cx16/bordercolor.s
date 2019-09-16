;
; 2019-09-15, Greg King
;
; unsigned char __fastcall__ bordercolor (unsigned char color);
;


        .export         _bordercolor

        .include        "cx16.inc"

_bordercolor:
        php
        pha

        ; Point to the border color register.

        sei                             ; Don't let interrupts interfere
        stz     VERA::CTRL              ; Use port 1
        lda     #<VERA::COMPOSER::FRAME
        ldx     #>VERA::COMPOSER::FRAME
        ldy     #^VERA::COMPOSER::FRAME ; (Address mustn't increment)
.ifdef VERA8
        sta     VERA::ADDR
        stx     VERA::ADDR+1
        sty     VERA::ADDR+2
.else
        sta     VERA::ADDR_LO
        stx     VERA::ADDR_MID
        sty     VERA::ADDR_HI
.endif

        plx
        lda     VERA::DATA1             ; get old value
        stx     VERA::DATA1             ; set new value
        plp                             ; Re-enable interrupts
        rts
