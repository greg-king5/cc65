/*
** Copies a broken-down time into the CIA time-of-day
** registers that exist on some Commodore models.
**
** Copies a broken-down date into an internal structure
** that is used by time() on those platforms.
**
** 2014-07-14, Greg King
*/


#include <time.h>


#if defined(__C128__) || defined(__C64__) || defined(__CBM510__) || defined(__CBM610__)

#include <cbm.h>

/* These definitions choose the chip at $DC00 on all four models.
** The choice is arbitrary for the C128 and the C64;
** but, the CBM510 and CBM610 mainboards have only that one chip.
*/

#if defined(__CBM510__) || defined(__CBM610__)
#  define CIA CIA2
#  define setb(addr,val) pokebsys ((unsigned)(addr), val)
#else
#  define CIA CIA1
#  define setb(addr,val) (*(unsigned char*)(addr) = (val))
#endif


/* Convert a binary number into a Binary-Coded Decimal number. */

static unsigned char __fastcall__ bin_to_bcd (unsigned char n)
{
    /* return ((n / 10u) << 4) | (n % 10u);     ( bigger and slower on CC65 platforms) */
    return n + (unsigned char)(n / 10u * 6u);   /* (smaller and faster) */
}


void __fastcall__ _cbm_settime (register struct tm* tm)
{
    /* Reduce the time-of-day, so that it fits within a day. */
    tm->tm_mday += tm->tm_hour / 24u;
    tm->tm_hour %= 24u;

    setb (&CIA.tod_hour,
         /* Convert from the 24-hour format to the 12-hour format. */

         /* Set the PM flag here because a CIA bug will
         ** toggle it when $12 is put into the chip.
         */
         ((unsigned char)tm->tm_hour ==  0u) ? 0x12 | 0x80 :  /* 12 AM */
         ((unsigned char)tm->tm_hour <= 12u) ?
         bin_to_bcd (tm->tm_hour) :                           /* AM, 12 PM */
         bin_to_bcd (tm->tm_hour - 12u) | 0x80                /* PM */
         );
    setb (&CIA.tod_min, bin_to_bcd (tm->tm_min));
    setb (&CIA.tod_sec, bin_to_bcd (tm->tm_sec));
    setb (&CIA.tod_10, 0);                       /* restart the TOD clock */

    _cbm_setdate (tm);
}

#else

void __fastcall__ _cbm_settime (struct tm*)
{
}

#endif /* defined(__C128__) || defined(__C64__) || defined(__CBM510__) || defined(__CBM610__) */
