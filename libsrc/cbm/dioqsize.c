/*
** 2015-08-24, Greg King
*/

#include <dio.h>
#include <errno.h>

unsigned __fastcall__ dio_query_sectsize (dhandle_t)
/* Return the DIO sector size. */
{
    _oserror = 0;

    /* All CBM-compatible sectors have the same size. */
    return 0x0100;
}
