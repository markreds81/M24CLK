page      60,132
          title     M24CLK - CLOCK$ Driver for Olivetti M24
;
;         ------------------------------------------------------------------
;         |                                                                |
;         |         Copyright (c) 1986, H.M. The Queen                     |
;         |                             in Right of Canada                 |
;         |                                                                |
;         |         Unauthorized commercial use of this computer program   |
;         |         is prohibited.                                         |
;         |                                                                |
;         |         This program is the property of the People of Canada,  |
;         |         and as such, may be freely distributed.  No charge,    |
;         |         other than for materials, may be made for any copy     |
;         |         of this program.  All copies must, however, include    |
;         |         this Notice.                                           |
;         |                                                                |
;         |         This program is distributed in the following form:     |
;         |                                                                |
;         |         Media:    3.5" diskette, MS-DOS format                 |
;         |         Contents: M24CLK.ASM   MASM source code                |
;         |                   M24CLK.LST   MASM source listing             |
;         |                   M24CLK.OBJ   object code                     |
;         |                   M24CLK.COM   executable program              |
;         |                                                                |
;         |                                                                |
;         |         Author:   G. Kroll,                                    |
;         |                   Manager, Special Projects                    |
;         |                   PGWGSC Network Engineering Directorate,      |
;         |                   Public Works & Government Services Canada,   |
;         |                   11 Laurier St.,                              |
;         |                   HULL, Quebec,                                |
;         |                   Canada                                       |
;         |                   K1A 0S5                                      |
;         |                                                                |
;         |                   (819) 956-2773                               |
;         |                                                                |
;         ------------------------------------------------------------------
;
          subttl    Documentation
          page      +
;
;
;         Name:     M24CLK.SYS
;
;
;         Type:     device driver (CLOCK$)
;
;
;         Purpose:
;
;                   As a device driver, this program is intended to remain
;                   resident.  It will handle all DOS requests to set or read
;                   the clock, and will re-direct these calls to the hardware
;                   clock.
;
;
;         Usage:
;
;                   The CONFIG.SYS file must include the statement
;
;                         DEVICE=M24CLK.SYS
;
;                   All interfacing with this routine is the responsibility of
;                   DOS.  The interfacing information is contained in the DOS
;                   Technical Reference Manual.
;
;
;
;         Description:
;
;                   This program uses non-standard extensions of the INT 1A
;                   routines, provided by Olivetti as part of the resident ROM
;                   BIOS, to interface directly with the hardware clock.
;
;                   Since the calling parameters of these INT 1A extensions are
;                   almost identical with those of the CLOCK$ driver, only a
;                   small amount of processing is actually necessary here.
;
          subttl    Resident Data Declarations, etc.
          page      +
M24CLK    segment   byte public 'code'
          assume    cs:M24CLK, ds:M24CLK, es:NOTHING, ss:NOTHING
          org       0h
;
;         *************************************************************
;         *                                                           *
;         *   Device Driver Header.                                   *
;         *                                                           *
;         *   This set of declarations must be kept at location 0     *
;         *   in order for this routine to be a device driver.        *
;         *                                                           *
;         *************************************************************
;
          dw        -1,-1               ; Pointer to next device driver
H_ATTRIB  dw        8000h+8h            ; Attributes
H_STRATGY dw        STRATEGY            ; Pointer to device strategy rtne
H_INTRPT  dw        INTERRUPT           ; Pointer to device interrupt rtne
H_NAME    db        'CLOCK$  '          ; Device Name
;
;
;
;         DOS Device Request Description
;
DOS_REQST struc
R_LENGTH     db     ?                   ; Request length
R_UNIT       db     ?                   ; Unit code
R_COMMAND    db     ?                   ; Command code
R_STATUS     dw     ?                   ; Status return field
             dw     4 dup (?)           ; Reserved for DOS
R_UNIT_CT    db     ?                   ; # units/media descriptor
R_BUFFER     dw     ?,?                 ; Buffer pointer
             dw     ?                   ; Byte/sector count
             dw     ?                   ; Starting sector #
             dw     ?,?                 ; Volume id pointer 
DOS_REQST ends
;
;
;         Data declarations, etc.
;
;
REQST_PTR dw        ?,?                 ; Pointer to DOS request block
;
;
VECTOR    dw        INIT                ; 00: Initialization
          dw        CMD_ERR             ; 01: Media check
          dw        CMD_ERR             ; 02: Build BPB
          dw        CMD_ERR             ; 03: IOCTL (input)
          dw        INPUT               ; 04: Read
          dw        CMD_ERR             ; 05: Non-destructive read
          dw        CMD_ERR             ; 06: Input status
          dw        CMD_ERR             ; 07: Input flush
          dw        OUTPUT              ; 08: Write
          dw        OUTPUT              ; 09: Write with verify
          dw        CMD_ERR             ; 10: Output status
          dw        CMD_ERR             ; 11: Output flush
          dw        CMD_ERR             ; 12: IOCTL (output)
          dw        CMD_ERR             ; 13: Device open
          dw        CMD_ERR             ; 14: Device close
          dw        CMD_ERR             ; 15: Removable media
;
;
BIAS      dw        (366+3*365)*3       ; # days between 1980.01.01
                                        ;            and 1992.01.01
;
;
          subttl    Device Strategy Routine
          page      +
;
;
;         STRATEGY:
;
;                   This routine saves the pointer to the DOS request block, and
;                   does nothing else.
;
STRATEGY  proc      far
;
          mov       cs:REQST_PTR,bx     ; Save pointer to the request block
          mov       cs:REQST_PTR+2,es   ;   provided by DOS
          ret                           ; Exit, that's all here
;
STRATEGY  endp

;
;
          subttl    Device Interrupt Routine
          page      +
;
;
;         INTERRUPT:
;
;                   This routine processes the DOS request whose address was
;                   saved by the STRATEGY routine.
;
;                   The request is validated.  If an error is found, an immedi-
;                   ate exit is made.
;
;                   Valid requests are re-directed to the ROM BIOS routines via
;                   non-standard function codes in INT 1A.
;
INTERRUPT proc      far
          push      ds
          push      dx
          push      cx
          push      bx
          push      ax
          push      di
          push      si
; Validate DOS-supplied request block
          lds       di,dword ptr cs:REQST_PTR ; ds:di addr of request block
          mov       al,[di+R_COMMAND]
          xor       ah,ah               ; ax: 16-bit command code
          lds       di,dword ptr [di+R_BUFFER] ; ds:di addr of request buffer
          cmp       ax,+15              ; If command code > 15,
          jg        CMD_ERR             ;   there's something wrong
          mov       si,offset VECTOR
          add       si,ax               ; Develop proper pointer
          add       si,ax               ;   into vector table
          jmp       cs:[si]             ;     before jumping to correct rtne
          page
;
;
;         Reject this request:  Unsupported function code
;
CMD_ERR:
          mov       ax,8000h+100h+3h
          jmp       EXIT
;
;
;         Request is completed:  Exit normally
;
CMD_OK:
          mov       ax,100h
EXIT:
          lds       di,dword ptr cs:REQST_PTR ; ds:di addr of request block
          mov       [di+R_STATUS],ax    ; Set status into request block
          pop       si
          pop       di
          pop       ax
          pop       bx
          pop       cx
          pop       dx
          pop       ds
          ret
          page
;
;
;         Function 08, 09:  Write to clock
;
;                   This routine uses INT 1A.FF to write the current date & time
;                   to the hardware clock.  This will work only on an Olivetti
;                   M24.
;
OUTPUT:
          mov       bx,[di]             ; bx: # days since 80.01.01
          sub       bx,cs:BIAS          ; bx: # days since 92.01.01
          mov       cx,[di+2]           ; ch: hours, cl: minutes
          mov       dx,[di+4]           ; dh: sec., dl: centisec. (ignored)
          mov       ah,-1               ; Use INT 1A.FF
          int       1ah                 ;   to write to hardware clock
          jmp       CMD_OK
          page
;
;
;         Function 04:  Read from clock
;
;                   This routine uses INT 1A.FE to read the current date & time
;                   from the hardware clock.  This will work only on an Olivetti
;                   M24.
;
INPUT:
          mov       ah,-2               ; Use INT 1A.FE
          int       1ah                 ;   to read from hardware clock
          add       bx,cs:BIAS
          mov       [di],bx             ; bx: # days since 80.01.01
          mov       [di+2],cx           ; ch: hours, cl: minutes
          mov       [di+4],dx           ; dh: seconds, dl: centiseconds
          jmp       CMD_OK
          page
;
;
;         Function 00:  Initialization
;
;                   This routine issues an INT 1A.FE to test for execution on an
;                   Olivetti M24.  The initial conditions are such that a NOP
;                   exit from BIOS can be detected.
;
;                   If the t.o.d. returned is illegal, we can assume that the
;                   current machine is not an Olivetti M24.  In this case, the
;                   exit is taken such that this routine will NOT remain 
;                   resident.
;
INIT:
          mov       di,offset COPYRIGHT
          call      DISPLAY             ; Produce sign-on message
          lds       di,dword ptr cs:REQST_PTR ; ds:di addr of request block
          mov       ax,offset INIT
          mov       [di+R_BUFFER],ax    ; Set next avail addr
          mov       [di+R_BUFFER+2],cs  ;   into request block
          mov       ch,-1               ; Pre-load 'hours' reg. to illegal val.
          mov       ah,-2
          int       1ah                 ; Issue that trial INT 1A.FE
          cmp       ch,-1               ; If t.o.d. returned is now legal,
          jnz       CMD_OK              ;   assume it's an Olivetti M24
          mov       di,offset MSG0
          call      DISPLAY             ; Display an informative message
          lds       di,dword ptr cs:REQST_PTR ; ds:di addr of request block
          mov       ax,offset H_NAME+8  ; Set next available addr
          mov       [di+R_BUFFER],ax    ;   to the minimum necessary
; Modify device header to indicate a 'do nothing' device
          push      cs
          pop       ds
          xor       ax,ax
          mov       word ptr H_NAME,ax  ; Make device name illegal
          mov       H_INTRPT,ax         ; Zero device interrupt pointer
          mov       H_STRATGY,ax        ;   as well as device strategy pointer
          mov       byte ptr H_ATTRIB,al ; Erase 'CLOCK$' bit
          jmp       CMD_OK              ; Exit, that's all
;
;
INTERRUPT endp
          subttl    Non-resident Subroutines
          page      +
;
;
;         DISPLAY:
;
;                   This routine will display a message.
;
;
;         Usage:
;
;                        lds   di,offset MESSAGE
;                        call  DISPLAY
;
;                   MESSAGE is an ASCII string terminated by a '$'.
;
;
;         Description:
;
;                   The string, whose address is relative to the CS register,
;                   will be displayed using BIOS routine 10.0E.
;
;
DISPLAY   proc      near
D_TAG0:
          mov       bl,7h               ; bl: foreground colour
          mov       ah,0eh              ; ah:  function code
          mov       al,cs:[di]          ; Fetch that byte
          inc       di                  ;   and step to next one
          cmp       al,'$'
          je        D_TAG1              ; If it's not "$",
          int       10h                 ;   display it using INT 10.0E,
          jmp       D_TAG0              ;     and go around again
; Exit: we're done now
D_TAG1:
          ret
DISPLAY   endp
;
          subttl    Non-resident Data Declarations
          page      +
;
;
;         Data areas
;
COPYRIGHT db        13,10,'M24CLK v. 1.1 (c) '
          db        '1986,1993,1995'
          db        ' by H.M. the Queen in Right of Canada, ',13,10
          db        '     Written by G. Kroll '
          db        '(95.07.28)'
          db        13,10,'$'
;
MSG0      db        '     This is NOT an Olivetti M24.  M24CLK will NOT '
          db        'remain resident.',13,10,'$'
;
M24CLK    ends
;
          end
