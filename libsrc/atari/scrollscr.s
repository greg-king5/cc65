;
; 2017-07-06, Greg King
;
; void scrollscr (void);
;

        .export         _scrollscr

        .import         setcursor, __scroll

        .include        "atari.inc"


_scrollscr:
        dec     ROWCRS          ; move cursor up
        bpl     nottop
        inc     ROWCRS          ; but, stay on the screen
nottop: jsr     setcursor       ; (returns with .Y = 0)
        lda     OLDCHR
        sta     (OLDADR),y      ; remove cursor

        lda     #+1
        jsr     __scroll        ; move text up by one line

        ldy     #$00
        lda     (OLDADR),y      ; prepare for next call to setcursor
        sta     OLDCHR
        rts
