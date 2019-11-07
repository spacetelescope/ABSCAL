PRO rdtbl,FILE,DATA
;
; Routine to read ANY ASCII TEXT table
; 91sep16
;
; Input: file - file name
; output:
;	 data - 2-d array,  data(i,j) is jth column of record i
;
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,'rdtbl,FILE,DATA'
	RETALL
	ENDIF
form='(1X,A12,A9,A3,A9,A2,A3,A7,A6,2(2A6,2A8))'   
;
; open file
;
	close,1 & openr,1,file
;
; set up output data array
;
	data=STRarr(16,2000)
	d=STRarr(16)			;single record buffer
	ON_IOERROR,IOERR
;
; loop on records
;
	nrec=-1
	WHILE (NOT EOF(1)) DO BEGIN
		readf,1,d,FORMAT=FORM
		nrec=nrec+1
		DATA(0,NREC)=D
		ENDWHILE
	GOTO, NOERR
;91AUG24 MOD:
IOERR:  if ((strpos(!err_string,'End of input record') lt 0) and  $
           (strpos(!err_string,'Input conversion error') lt 0))then begin
                        PRINT,!ERR,!ERR_STRING 
			PRINT,'INPUT LINE=',D
			STOP
			endif
NOERR:	
	data=data(*,0:nrec)		;extract filled portion
	data=transpose(data)

	close,1		
	return
	end
