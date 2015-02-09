***************************************************************************
* Program: TRIN.UNIVERSAL.BASH
* Author : Ian McGowan
* Date   : 06/10/2014
* Checkin: $*Id: $
* Comment: Bash any file based on IL.BPI column names and spreadsheet
***************************************************************************
* $*Log: $
PROMPT ""
OPEN "IL.BPI" TO IL.BPI ELSE STOP 201, "IL.BPI"
OPEN "EXCELFILE" TO EF ELSE STOP 201,"EXCELFILE"

FILE.NAME=FIELD(@SENTENCE, " ", 2)
BPI.NAME=FIELD(@SENTENCE, " ", 3)
FNAME=FIELD(@SENTENCE, " ", 4)

OPEN FILE.NAME TO FVAR ELSE STOP 201, FILE.NAME
OPEN "DICT",FILE.NAME TO DVAR ELSE STOP 201, "DICT ":FILE.NAME
OPEN "TRIN.UNIVERSAL.BASH.BACKUP" TO BKUP ELSE STOP 201, "TRIN.UNIVERSAL.BASH.B
READ BPI.REC FROM IL.BPI, BPI.NAME ELSE STOP "Cannot read IL.BPI ":BPI.NAME
READ D FROM EF, FNAME ELSE STOP "Cannot read EXCELFILE ":FNAME
GOSUB GET.COL.HDRS

PRINT "Everything checks out. Press ENTER to do a dry-run:":
INPUT YORN
IF YORN="/" THEN STOP
DRY.RUN=1
GOSUB BASHIT
PRINT "If that looks ok, then enter YES to run the bash:":
INPUT YORN
IF YORN#"YES" THEN STOP
DRY.RUN=0
GOSUB BASHIT
STOP

BASHIT:
    SAVED.LIST=""
    FOR L=2 TO DCOUNT(D,@AM)
        ROW=D<L>
        GOSUB CONVERT.ROW
        ID=ROW<1,1>
        UPD=0
        READ REC FROM FVAR, ID THEN
            IF NOT(DRY.RUN) THEN SAVED.LIST<-1>=ID
            ORIG.REC=REC
            FOR FLD=2 TO DCOUNT(ROW<1>,@VM)
                ATB=ATBS<1,FLD>
                POS=ATBS<2,FLD>
                CNV=ATBS<3,FLD>
                VAL=TRIM(ROW<1,FLD>)
                * Special case for excel money format...
                IF CNV[1,1]="M" AND VAL[1,1]="(" THEN
                    CONVERT "(" TO "" IN VAL
                    CONVERT ")" TO "" IN VAL
                    IVAL=ICONV(VAL, CNV)
                    IVAL=-IVAL
                END ELSE
                    IF CNV # "" THEN IVAL=ICONV(VAL, CNV) ELSE IVAL=VAL
                END
                IF REC<POS> # IVAL THEN
                    PRINT L, ID, ATB"L#20":" ":REC<POS>"L#20":"=>":IVAL:
                    IF DRY.RUN THEN PRINT "" ELSE PRINT " updated"
                    REC<POS>=IVAL
                    UPD=1
                END
            NEXT FLD
        END ELSE
            PRINT "FAILED TO READ ":ID
        END

        IF UPD AND NOT(DRY.RUN) THEN
            BKUP.KEY=FILE.NAME:"*":ID:"*":DATE():"*":TIME()
            WRITE ORIG.REC ON BKUP, BKUP.KEY
            WRITE REC ON FVAR, ID
        END
    NEXT L
    PRINT DCOUNT(SAVED.LIST,@AM):" records to be updated"
    IF NOT(DRY.RUN) THEN
        SELECT SAVED.LIST TO LIST
        EXECUTE \SAVE.LIST UNIVERSAL.BASH\ PASSLIST LIST
    END
RETURN

CONVERT.ROW:
    * For now, let's assume tab-seperated - csv sucks!
    CONVERT CHAR(9) TO @VM IN ROW
    CONVERT CHAR(34) TO "" IN ROW
    CONVERT CHAR(13) TO "" IN ROW
RETURN

GET.COL.HDRS:
    ATBS=""
    ROW=D<1>
    GOSUB CONVERT.ROW
    * Column 1 is reserved for the ID
    FOR C=2 TO DCOUNT(ROW<1>,@VM)
        COL=TRIM(ROW<1,C>)
        PRINT "SEARCHING FOR ":COL
        GOSUB GET.BPI
    NEXT C
RETURN

GET.BPI:
    ATB=""
    POS=""
    CNV=""
    * Loop thru the BPI, looking for the column header
    FOR F=1 TO DCOUNT(BPI.REC,@AM)
        L=BPI.REC<F>
        IF FIELD(L," ",1) = "EQUATE" THEN
            * EQUATE API.WIRE.COVERING.BANK  TO API.FUND(17)
            A=FIELD(L," ",2)
            IF A # COL THEN CONTINUE
            ATB=A
            POS=FIELD(L,"(",2)
            POS=FIELD(POS,")",1)
            * Need to grab the format conversion from DICT, e.g. D4/ MR2,
            READV CNV FROM DVAR, ATB, 3 ELSE CNV=""
            * Stop at the first matching ATB by EXITing the loop
            EXIT
        END
    NEXT F
    IF ATB="" THEN
        PRINT "Column heading ":COL:" not found in IL.BPI ":BPI.NAME
        STOP
    END
    ATBS<1,C>=ATB
    ATBS<2,C>=POS
    ATBS<3,C>=CNV
RETURN
