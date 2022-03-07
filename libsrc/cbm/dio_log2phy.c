/*
** 2022-01-12, Greg King
*/

#include <dio.h>
#include <stdlib.h>
#include <errno.h>

extern const unsigned char dioNumTracks[];
extern const unsigned char dioMaxSector[];
extern const unsigned char dioForMap_h[], dioForMap_l[];

static div_t track_sect;
static const unsigned int (*format)[];
static unsigned int sectnum;
static unsigned char track, t;

unsigned char __fastcall__ dio_log_to_phys (dhandle_t handle,
                                            const unsigned *psectnum, /* input */
                                            dio_phys_pos *physpos)   /* output */
/* convert logical sector number to physical sector address (head/track/sector) */
/* return _oserror (0 for success) */
{
    if (dio_query_sectcount(handle) <= (sectnum = *psectnum)) {
        return _oserror = 66;           /* "bad track or sector" */
    }

/* Note:  dhandle_t is declared as a pointer.  But, it's opaque; it can be
** anything, as long as it isn't zero.  The CBM version is a POSIX file
** descriptor.
*/
#define handle (unsigned int)handle

    if (dioMaxSector[handle] != 0) {
        track_sect = div (sectnum, dioMaxSector[handle] + 1);
        physpos->sector = track_sect.rem;
        physpos->track = track_sect.quot + 1;
        return _oserror = physpos->head = 0;
    }

    /* The disk's tracks have different lengths.
    ** Use a format map to decompose the sector number.
    */
    format = (void *)(((unsigned int)dioForMap_h[handle] << 8) | dioForMap_l[handle]);
    track = 1;
    t = dioNumTracks[handle];

    /* Single-sided disks have an odd number of tracks,
    ** double-sided ones have an even number.
    */
    if ((t & 0b00000001) == 0b00000000) {
        t /= 2u;
        if ((*format)[t] <= sectnum) {
            /* The wanted sector is on the second side.  Use its first-side
            ** mirror to decompose the number.
            */
            sectnum -= (*format)[t];
            track = t + 1;
        }
    }

    do ; while ((*format)[--t] > sectnum);
    physpos->sector = sectnum - (*format)[t];
    physpos->track = track + t;
    return _oserror = physpos->head = 0;
}
