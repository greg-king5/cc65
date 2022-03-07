;
; Constants and variables that are shared by many of the DIO functions.
;
; 2022-01-05, Greg King
;

	.export		_dioNumTracks, _dioMaxSector, _dioForMap_l, _dioForMap_h
        .include        "diovals.inc"
        .include        "filedes.inc"


.bss

; Currently active device file number; used internally (reduces code size).

dhandle:
        .res    1

; These tables are indexed by dhandle.

_dioNumTracks:
dioNumTracks:
        .res    MAX_FDS         ; number of tracks on discoverred disks
_dioMaxSector:
dioMaxSector:
        .res    MAX_FDS         ; maximum sector number, 0 -> use format map

_dioForMap_l:
dioForMap_l:
        .res    MAX_FDS         ; pointers to format maps
_dioForMap_h:
dioForMap_h:
        .res    MAX_FDS

dioSectCount_l:
        .res    MAX_FDS         ; number of sectors on discoverred disks
dioSectCount_h:
        .res    MAX_FDS
