***************************************************************************
* Program: RECALL.CLUSTER
* Author : Ian McGowan
* Date   : 01/14/2015
* Checkin: $*Id: $
* Comment: Analyse recalls to find ones that are similar
***************************************************************************
* $*Log: $
OPEN "RECALLS" TO RECALLS ELSE STOP "CANNOT OPEN RECALLS"
RECALL.LIST=""
FINGERPRINTS=""
ATB.LIST=""

PRINT "GENERATING FINGERPRINTS"
EXECUTE \SELECT RECALLS = "I]"\
LOOP
    READNEXT ID ELSE EXIT
    PRINT "Fingerprinting ":ID
    GOSUB FINGERPRINT.RECALL
REPEAT
PRINT "DONE WITH FINGERPRINTS"

PRINT "ANALYSING FINGERPRINTS"
FOR R.CTR=1 TO DCOUNT(RECALL.LIST<1>,@VM)
    ID=RECALL.LIST<1,R.CTR>
    FINGERPRINT=FINGERPRINTS<R.CTR>
    GOSUB ANALYSE.RECALL
    PRINT ID'L#20':' ':
    IF BEST.MATCH # 0 THEN
        MATCH.PCT=MAX.SCORE
        PRINT RECALL.LIST<1,BEST.MATCH>'L#20':' ':MATCH.PCT
    END ELSE
        PRINT "NO MATCHES"
    END
NEXT R.CTR
PRINT "DONE"
STOP

FINGERPRINT.RECALL:
    * Create a fingerprint for each recall, such that two exact copies
    * will have the same fingerprint
    READ R FROM RECALLS, ID THEN
        RECALL.LIST<1,-1>=ID
        RECALL.POS=DCOUNT(RECALL.LIST<1>,@VM)
        FINGERPRINT=""
        * We just need a flat list of tokens
        CONVERT @AM TO @VM IN R
        CONVERT " " TO @VM IN R
        GOT.FILE=0
        FOR W.CTR = 1 TO DCOUNT(R<1>,@VM)
            WORD=R<1,W.CTR>
            * See if we have already assigned this word a number
            * This ends up assigning every "token" in every recall
            * a unique number
            LOCATE WORD IN ATB.LIST<1> SETTING POS THEN
                FINGERPRINT<1,POS>=1
            END ELSE
                * Not!  Assign it one now
                ATB.LIST<1,-1>=WORD
                POS=DCOUNT(ATB.LIST<1>,@VM)
                FINGERPRINT<1,POS>=1
            END
        NEXT W.CTR
        FINGERPRINTS<RECALL.POS>=FINGERPRINT
    END
RETURN

ANALYSE.RECALL:
    * Given the current recall, loop thru all the others looking for matches,
    * For each, generate a score of how similar this recall is to the target
    * as well as how similar the target is to this.  Average those two scores.
    MAX.SCORE=0 ; BEST.MATCH=0
    FOR F=1 TO DCOUNT(FINGERPRINTS,@AM)
        * Don't compare to ourselves - that will be 100% match ;-)
        IF F # R.CTR THEN
            COMP.FINGERPRINT=FINGERPRINTS<F>
            SCORE=0
            TOT.CUR.POINTS=0
            TOT.TARGET.POINTS=0
            * Compare current to target
            FOR POS=1 TO DCOUNT(FINGERPRINT<1>,@VM)
                * Too bad no bitwise-and...
                IF FINGERPRINT<1,POS> = 1 AND COMP.FINGERPRINT<1,POS>=1 THEN
                    SCORE+=1
                END
                IF FINGERPRINT<1,POS> = 1 THEN TOT.CUR.POINTS+=1
            NEXT POS
            FOR POS=1 TO DCOUNT(COMP.FINGERPRINT<1>,@VM)
                * We don't need to keep score any more
                IF COMP.FINGERPRINT<1,POS> = 1 THEN TOT.TARGET.POINTS+=1
            NEXT POS

            IF TOT.CUR.POINTS # 0 THEN CUR.SCORE = SCORE / TOT.CUR.POINTS
            IF TOT.TARGET.POINTS # 0 THEN TARGET.SCORE = SCORE / TOT.TARGET.POI
            SCORE = (CUR.SCORE + TARGET.SCORE) / 2 * 100
            IF SCORE > MAX.SCORE THEN
                MAX.SCORE=SCORE
                BEST.MATCH=F
            END
        END
    NEXT F
RETURN
