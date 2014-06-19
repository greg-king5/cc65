;
; Oliver Schmidt, 2012-10-17
;

        .export         diskinit
        .import         opencmdchannel, closecmdchannel
        .import         writefncmd, readdiskerror
        .import         isdisk, fnunit, fnlen

;------------------------------------------------------------------------------
; diskinit

.proc   diskinit

; Save device

        sta     fnunit

; Check for disk device

        tax
        jsr     isdisk
        bcc     open
        lda     #9              ; "Illegal device"
        rts

; Open channel

open:   jsr     opencmdchannel
        bne     done

; Write command

        ldx     #0
        stx     fnlen
        lda     #'i'            ; the Initiate command
        jsr     writefncmd
        bne     close

; Read error

        ldx     fnunit
        jsr     readdiskerror

; Close channel

close:  pha
        ldx     fnunit
        jsr     closecmdchannel
        pla

done:   rts

.endproc
