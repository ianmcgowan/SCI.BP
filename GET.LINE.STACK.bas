SUBROUTINE GET.LINE(X,XXLENGTH,DISP.LEN,XXDATA,RTN.CHAR)
************************************************************************
* Program: GET.LINE.STACK
* Author : Ian McGowan
* Date   : 6/24/89
* Edited : 16:49:22 Nov 19 1998 By MCGOWAN 
* Comment: Get a line of data with editing keys
************************************************************************
* Date     By   Desc
* -------- ---- ----------------------------------------------------
*10/02/95* IAN  Attempt to fix 'turd' bug -- JIM
*10/02/95  IAN  Add CTRL-B for back -- JIM
*09/14/95  IAN  Add CTRL-W for delete word -- JIM
*01/02/94  IAN  Trap HOME and END key, Also add del word and line -- JIM
*01/25/94  IAN  CTRL-D exits -- JIM
*08/22/97  IAN  Add wyse support, make more emacs like
************************************************************************
* $Id: GET.LINE.STACK 17327 2014-07-15 01:05:38Z mcgowi96 $

* $Log: GET.LINE.STACK,v $
* Revision 1.4  2003/11/03 18:01:23  dsiroot
* mcgowan:Change abort char from ^Y to ^G
*
* Revision 1.3  2003/04/10 02:41:01  dsiroot
* mcgowan:Add CVS id
*
* Revision 1.2  2003/04/10 02:21:06  dsiroot
* mcgowan:Add cvs log comment
*

* X           = X POS
* XXLENGTH    = MAX ALLOWED LENGTH
* DISP.LEN    = MAX DISPLAYED XXLENGTH
* XXDATA      = ON INPUT  VARIABLE XXDATA
*             = ON OUTPUT RETURNED STRING
* RTN.CHAR    = SEQ(CHAR PRESSED TO EXIT)

* Important globals
* CP          = Cursor Position, Y coordinate on the screen 0 -> DISP.LEN
* CH.PTR      = Pointer into string being edited            1 -> XXLENGTH
* POS         = Pointer to first char currently displayed   1 -> XXLENGTH
* ASC.CH      = The numeric value of the key just entered

INIT:
   EQU INSERT TO '1',REPLACE TO '-1',BEEP TO CHAR(7)
   EQU ESC TO CHAR(27),AM TO CHAR(254)
   EQU NUL TO '',TRUE TO 1,FALSE TO 0,SPACE TO ' '
   TERM=UPCASE(GETENV("TERM"))
   IF INDEX(TERM,'WY',1) THEN TERM='W'   
   PROMPT NUL
   ECHO OFF
   MODE = INSERT ; TEMP.XXDATA =XXDATA
   BASE = @(X) ; MASK = 'L#':DISP.LEN
   PRINT BASE:
   CURR.LEN = LEN(XXDATA)
   GOSUB GO.END
   RTN.CHAR=''

MAIN:
   LOOP
      PRINT @(X+CP):
      CH=IN()
      ASC.CH = SEQ(CH)
      EXIT.FLAG=FALSE
      BEGIN CASE
         CASE ASC.CH = 1
            GOSUB GO.BEGIN
         CASE ASC.CH = 2
            GOSUB LEFT
         CASE ASC.CH = 4
            GOSUB DEL
         CASE ASC.CH = 5
            GOSUB GO.END
         CASE ASC.CH = 6
            GOSUB RIGHT
         CASE ASC.CH = 8 AND TERM='W'
            GOSUB LEFT
         CASE ASC.CH = 8
            GOSUB BACK
         CASE ASC.CH = 9
            GOSUB FORWARD.WORD
         CASE ASC.CH = 10 AND TERM='W'
            RTN.CHAR=2
            EXIT.FLAG=TRUE
         CASE ASC.CH = 10
            GOSUB DEL.TO.END
         CASE ASC.CH=11 AND TERM='W'
            RTN.CHAR=1
            EXIT.FLAG=TRUE
         CASE ASC.CH=12 AND TERM='W'
            GOSUB RIGHT
         CASE ASC.CH = 13
            EXIT.FLAG = TRUE
            RTN.CHAR=13
         CASE ASC.CH = 14
            RTN.CHAR=2
            EXIT.FLAG=TRUE
         CASE ASC.CH = 16
            RTN.CHAR=1
            EXIT.FLAG=TRUE
         CASE ASC.CH = 18
            GOSUB INSRT
         CASE ASC.CH = 23
            GOSUB DELETE.WORD
         CASE ASC.CH = 24
            GOSUB FORWARD.WORD
         CASE ASC.CH = 7 OR ASC.CH = 12
            IF ASC.CH = 12 THEN PRINT @(-1):
            XXDATA = ''
            EXIT.FLAG=TRUE
            RTN.CHAR=13
         CASE ASC.CH = 26
            GOSUB BACK.WORD
         CASE ASC.CH = 27
            GOSUB ESC.KEY
         CASE ASC.CH < 27
            PRINT @(0):ASC.CH:
         CASE ASC.CH = 127
            GOSUB BACK
         CASE 1
            GOSUB ORD
      END CASE
      CURR.LEN = LEN(XXDATA)
   UNTIL EXIT.FLAG DO
   REPEAT
   IF XXDATA[CURR.LEN,1] = SPACE THEN XXDATA = XXDATA[1,CURR.LEN-1]
   ECHO ON ; PRINT BASE:XXDATA MASK
RETURN

ORD:
   * Ordinary key pressed
   IF CH.PTR # XXLENGTH+1 THEN
      IF MODE = INSERT THEN
         IF CURR.LEN = XXLENGTH THEN
            PRINT BEEP:
            GOTO SKIP1
         END ELSE
            XXDATA = XXDATA[1,CH.PTR-1]:CH:XXDATA[CH.PTR,CURR.LEN]
         END
      END ELSE
         XXDATA = XXDATA[1,CH.PTR-1]:CH:XXDATA[CH.PTR+1,CURR.LEN]
      END
      CH.PTR = CH.PTR + 1
      IF CP # DISP.LEN THEN
         PRINT @(X+CP):CH:
         IF MODE = INSERT THEN
            PRINT XXDATA[CH.PTR,DISP.LEN-CP-1]:
         END
         CP = CP + 1
      END ELSE
         POS = POS + 1
         PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
      END
   END ELSE
      PRINT BEEP:
   END
SKIP1:
RETURN

RIGHT:
* There are 3 situations here -
* 1 We're pressing the right arrow thru existing text       (CH.PTR = CURR.LEN)
* 2 We've typed text and are at the end when we press right (CH.PTR > CURR.LEN)
* 3 We're in the middle of text, pressing the right arrow   (CH.PTR < CURR.LEN)
   IF CH.PTR < XXLENGTH THEN
      IF CH.PTR > CURR.LEN THEN PRINT BEEP: ; GOTO SKIP2
      IF CH.PTR = CURR.LEN THEN
         * If the last char is not a space make it one
         IF XXDATA[CURR.LEN,1] # SPACE THEN
            XXDATA = XXDATA:SPACE
            IF CP # DISP.LEN THEN PRINT @(X+CP+1):SPACE:
            CURR.LEN = CURR.LEN + 1
         END ELSE
            PRINT BEEP:
            GOTO SKIP2
         END
      END
      CH.PTR = CH.PTR + 1
      IF CP # DISP.LEN THEN
         * We're not at the end of display so just move the cursor
         CP = CP + 1
      END ELSE
         * We are at the end of the display so leave cursor where
         * it is and scroll through line
         POS = POS + 1
         PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
      END
   END ELSE
      PRINT BEEP:
   END
SKIP2:
RETURN

FORWARD.WORD:
   * Tab key pressed - move forwards a word
   IF CH.PTR >= CURR.LEN THEN
      PRINT BEEP:
   END ELSE
      LOOP
         CH.PTR = CH.PTR + 1
         CP = CP + 1
      UNTIL XXDATA[CH.PTR,1] = SPACE OR CH.PTR = CURR.LEN DO
      REPEAT
      IF CH.PTR # CURR.LEN THEN
         LOOP
            CH.PTR = CH.PTR + 1
            CP = CP + 1
         UNTIL XXDATA[CH.PTR,1] # SPACE OR CH.PTR = CURR.LEN DO
         REPEAT
      END
      IF CP > DISP.LEN THEN
         CP = DISP.LEN
         POS = CH.PTR - DISP.LEN
         PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
      END
   END
RETURN

LEFT:
   * If we're not at the start of data, move left
   IF CH.PTR # 1 THEN
      CH.PTR = CH.PTR - 1
      IF CP # 0 THEN
         * We're not at the start of the display so just move the cursor
         CP = CP - 1
      END ELSE
         * We are at the start of the display so leave cursor and scroll
         POS = POS - 1
         PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
      END
   END ELSE
      PRINT BEEP:
   END
RETURN

DEL:
   * Delete the character at the cursor and redisplay from this point
   XXDATA = XXDATA[1,CH.PTR-1]:XXDATA[CH.PTR+1,CURR.LEN]
   CURR.LEN = CURR.LEN - 1
   PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
RETURN

BACK:
   * Backspace key pressed
   IF CH.PTR # 1 THEN
      CH.PTR = CH.PTR - 1
      XXDATA = XXDATA[1,CH.PTR-1]:XXDATA[CH.PTR+1,CURR.LEN]
      CURR.LEN = CURR.LEN - 1
      IF CP # 0 THEN
         CP = CP - 1
      END ELSE
         POS = POS - 1
      END
      PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
   END ELSE
      PRINT BEEP:
   END
RETURN

INSRT:
   * Toggle between insert and replace modes
   MODE = -MODE
RETURN

ESC.KEY:
   * ESC pressed, or extended key
   * Get next char of extended command
   ALLOW = 0
   EXT.KEY=IN()
   EXT = SEQ(EXT.KEY)
   EXT.KEY = OCONV(EXT.KEY,'MCU')
   BEGIN CASE
      CASE EXT.KEY = 'D'
        GOSUB DELETE.WORD
      CASE EXT.KEY = '[' OR EXT.KEY = 'O'
         EXT.KEY=IN()
         BEGIN CASE
            CASE EXT.KEY = 'C'
               GOSUB RIGHT
            CASE EXT.KEY = 'D'
               GOSUB LEFT
            CASE EXT.KEY = 'A'
               RTN.CHAR=1
               EXIT.FLAG=TRUE
            CASE EXT.KEY = 'B'
               RTN.CHAR=2
               EXIT.FLAG=TRUE
         END CASE
   END CASE
RETURN ; * From ESC key

BACK.WORD:
   * Shift tab pressed - go back a word
   IF CH.PTR = 1 THEN
      PRINT BEEP:
   END ELSE
      * 2 situations - either we're in a word already or
      * we're at the start of a word
      * If in a word - loop to the start of the word
      * otherwise skip spaces, and then move to start of word
      IF XXDATA[CH.PTR-1,1] # SPACE THEN
         LOOP
         UNTIL XXDATA[CH.PTR-1,1] = SPACE OR CH.PTR = 1 DO
            CH.PTR = CH.PTR - 1
            CP = CP - 1
         REPEAT
      END ELSE
         * Skip spaces
         LOOP
         UNTIL XXDATA[CH.PTR-1,1] # SPACE OR CH.PTR = 1 DO
            CH.PTR = CH.PTR - 1
            CP = CP - 1
         REPEAT
         IF CH.PTR > 1 THEN
            * At word end - move to start of word
            LOOP
            UNTIL XXDATA[CH.PTR-1,1] = SPACE OR CH.PTR = 1 DO
               CH.PTR = CH.PTR - 1
               CP = CP - 1
            REPEAT
         END
      END
      IF CP < 0 THEN
         CP = 0
         POS = CH.PTR
         PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
      END
   END
RETURN

DEL.TO.END:
   * Delete from cursor to end of line
   IF CH.PTR = 1 THEN
      XXDATA = ''
      CP = 0
      POS = 1
   END ELSE
      XXDATA = XXDATA[1,CH.PTR-1]
   END
   CURR.LEN = LEN(XXDATA)
   PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
RETURN

DELETE.WORD:
   * Delete to space at right of cursor
   IF CH.PTR >= CURR.LEN THEN
      PRINT BEEP:
   END ELSE
      C = CH.PTR
      LOOP
         C = C + 1
      UNTIL XXDATA[C,1] = SPACE OR C = CURR.LEN DO
      REPEAT
      XXDATA = XXDATA[1,CH.PTR-1]:XXDATA[C+1,CURR.LEN]
      CURR.LEN = CURR.LEN - C + CH.PTR - 1
      PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
   END
RETURN

GO.BEGIN:
   * Go to the start of data and redisplay
   CP = 0
   CH.PTR = 1
   POS = 1
   PRINT BASE:XXDATA MASK:
RETURN

GO.END:
   * Move to the end of data and redisplay
   IF XXDATA[CURR.LEN,1] # SPACE THEN
      XXDATA = XXDATA:SPACE
      CURR.LEN = CURR.LEN + 1
   END
   IF CURR.LEN < DISP.LEN THEN
      CP = CURR.LEN - 1
      POS = 1
   END ELSE
      CP = DISP.LEN - 1
      POS = CURR.LEN - DISP.LEN + 1
   END
   CH.PTR = CURR.LEN
   PRINT BASE:XXDATA[POS,DISP.LEN] MASK:
RETURN
