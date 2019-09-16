;
; 2002-12-03, Ullrich von Bassewitz
; 2019-09-09, Greg King
;
; unsigned char get_tv (void);
; /* Return the video mode the machine is using */
;

        .include        "get_tv.inc"

.proc   _get_tv

        lda     #<TV::OTHER
        ldx     #>TV::OTHER
        rts

.endproc
