;
; 2019-09-16, Greg King
;
; void waitvsync (void);
;
; VERA's vertical sync. causes IRQs which increment the jiffy clock.
;

        .export         _waitvsync

        .include        "cx16.inc"

_waitvsync:
        lda     TIME
:       cmp     TIME
        beq     :-              ; Wait for next jiffy
        rts
