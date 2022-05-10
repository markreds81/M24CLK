# M24CLK
Clock driver for Olivetti M24 and AT&T 6300, written by G. Kroll and updated by me to be compatible with the last decade.

## Purpose
Lets any version of MS-DOS access the on-board clock of the Olivetti M24 and AT&T 6300 XT-compatible computers, using the usual TIME and DATE commands.

These old PC XT models had a RTC chip able to keep only 4095 days from the epoch, after that it rolls over again. So the original driver provided by Olivetti doesn't work anymore.
I found this alternative implementation with sources somewhere from Internet and published in this repository available to anyone. The last version from the original author was 1.1. Here I've updated to version 1.2 to be compatible from 2016 to 2028.

## Usage
Include the following statement in your CONFIG.SYS:

`DEVICE=M24CLK.SYS`

## Restrictions:
MS-DOS version 3.0 or later (no check for this).
Olivetti M24 or AT&T 6300 motherboard (check for this).
Olivetti M240 (check for this).

## History

### Version 1.0 (86.03.06)
Original release

### Version 1.1 (95.07.28)
Corrects a date entry problem for dates after 1995.03.18, caused by the limited hardware of the M24 clock.
The hardware clock only counts up to 4095 days from the "zero" date, which was previously set at 1984.01.01.  This release changes the "zero" date to 1992.01.01.  M24CLK will therefore fail again after 2003.03.18.

### Version 1.2 (22.05.03)
Updated to be compatible until 2028. Compiled with MS Macro Assembler 5.0 on my Olivetti M240 running MS-DOS 5.0.

## Copyright
(C) 1986,1993,1995 by H.M. the Queen, in Right of Canada
Although copyrighted, there are no restrictions on the distribution of this software. The software may not be sold. It is "freeware".

## Author
G. Kroll  
Manager, Special Projects  
PWGSC Network Infrastructure Directorate  
Public Works & Government Services Canada  
2A1, Portage III  
11 Laurier Street  
HULL, PQ  
Canada    K1A 0S5

Voice:  +1 819 956 2773  
FAX:  +1 819 956 7056  
E-mail:  gerry.kroll@hqtsd1.ssc.ssc-asc.x400.gc.ca
