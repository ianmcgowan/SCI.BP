PROGRAM TB.LOCATION.BASH
*
* AUTHOR: Ian McGowan
* DATE  : 2015-10-01
* PROG  : Update location codes
*
OPEN 'TB.LOCATION' TO TB.LOCATION ELSE STOP 201,'TB.LOCATION'
OPEN 'TB.TAX' TO TB.TAX ELSE STOP 201,'TB.TAX'
OPEN 'V' TO V ELSE STOP 201,'V'
*
E=\SELECT V\
PRINT E
EXECUTE E
*
LOOP
  READNEXT ID ELSE EXIT
  PRINT ID
  READ REC FROM V, ID THEN
    NEW.REC=''
    FOR F=1 TO DCOUNT(REC<3>,@VM)
      IF REC<3,F> = '001' OR REC<3,F> = '100' OR REC<3,F> = '150' THEN
      	 C=COUNT(ID,"*")
	 BEGIN CASE
	   CASE C=1 ;* State, no transit
	     NEW.REC<2,-1>=REC<2,F>
	   CASE C=2 ;* County, include transit
	     NEW.REC<2,-1>=REC<2,F>+REC<8,F>
	   CASE C=3 ;* City, include transit
	     NEW.REC<2,-1>=REC<2,F>+REC<9,F>
           CASE 1
	     NEW.REC<2,-1>=REC<2,F>
         END CASE
         NEW.REC<8,-1>=REC<3,F>
      END
    NEXT F
    NEW.REC<1>=REC<1>
    NEW.REC<7>='C'
    WRITE NEW.REC ON TB.LOCATION, ID
  END
REPEAT
