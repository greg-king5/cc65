;
; 2017-07-07, Greg King
;
; void scrollscr (void);
;

        .export         _scrollscr

        .import         pushax, _memcpy
        .importzp       ptr1

        .include        "atmos.inc"

; Number of characters to move, for scrolling by one line
ScrollLength    = (SCREEN_YSIZE - 1) * SCREEN_XSIZE


_scrollscr:
        dec     CURS_Y          ; Cursor position, also, goes up
        bpl     nottop
        inc     CURS_Y          ; But, it must stay on the screen

        ; Scroll destination address
nottop: lda     #<SCREEN
        ldx     #>SCREEN
        jsr     pushax

        ; Scroll source address
        lda     #<(SCREEN + SCREEN_XSIZE)
        ldx     #>(SCREEN + SCREEN_XSIZE)
        jsr     pushax

        ; Number of characters to move
        lda     #<ScrollLength
        ldx     #>ScrollLength
        jsr     _memcpy

        ; Address of first character in last line of screen
        lda     #<(SCREEN + ScrollLength)
        ldx     #>(SCREEN + ScrollLength)
        sta     ptr1
        stx     ptr1+1

        ldy     #SCREEN_XSIZE   ; Fill last line with blanks
        lda     #' '
clrln:  sta     (ptr1),y
        dey
        bpl     clrln
        rts
