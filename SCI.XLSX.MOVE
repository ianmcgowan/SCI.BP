********************************************************************************
* Program: SCI.XLSX.MOVE
* Author : Ian McGowan
* Date   : 2017-09-12
* Version: 1.0
* Comment: Move a completed excel file to a new location
********************************************************************************
* E.g. SPREAD SCI.XLSX.MOVE _XML_/MEOP.SIN.M.NBV /info/OUTPUT/
S=@SENTENCE
FILE.FROM=FIELD(S,' ',2)
FILE.TO=FIELD(S,' ',3)
IF FILE.FROM='' OR FILE.TO='' THEN STOP 'Usage: SCI.MOVE.FILE <from> <to>'
*
EXECUTE \!mv \:FILE.FROM:\.TMP/*.xlsx \:FILE.TO
