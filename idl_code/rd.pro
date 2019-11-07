PRO rd,FILE,ID,DATA
;+
;
; Routine to read ralphs text files of iue spectra
;
; Input: file - file name
;	 id - id of spectra (if 0 then the first one is read)
; output:
;	 data - 2-d array,  data(i,j) is jth column of record i
;
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,'rd,FILE,ID,DATA'
	RETALL
	ENDIF
; 94mar25-note this is old format. use rdf to read data written after 94feb11
; this format works for both old and new, as i TRANSFERRED one space from the 
;	f10 to e11 to make f9.2,e12.2 IN ABPRINT AND MERGE.IBM.
; Putting a blank at end of dn/sec field and reading w/ f10.2 causES no problem!
; 94dec30-gross and bkg need another blank for swp hd60753 co-adds, so change
;	ABPRINT AND MERGE.IBM to omit decimal pt (and make rdf [and rd] work.)
form='(F7.1,F7.0,2F9.0,F10.2,E11.3,F10.2,F10.2,F6.0)'   
;
; open file
;
	on_ioerror,try_again
	close,1 & openr,1,file
	goto,got_it
try_again:
	on_ioerror,null
	fdecomp,file,disk,dir,name,ext
	fname=disk+dir+name+strtrim(id,2)+'.'+ext
	close,1 & openr,1,fname
got_it: on_ioerror,null
;
; read correct position (until you hit '###<id>')
;
	if id eq 0 then begin
		nchar=3
		testst='###'
	    end else begin
		nchar=8
		testst='###'+string(id,'(i5)')
	end
	st='         '
	while strmid(st,1,nchar) ne testst do begin
		readf,1,st
	end
	print,st
; RCB addition
        object='            '
        readf,1,object
        !mtitle=strtrim(object,2)
        print,!mtitle             
;
; set up output data array
;
	data=fltarr(9,2000)
	d=fltarr(9)			;single record buffer
	ON_IOERROR,IOERR
;
; loop on records
;
	nrec=0
	readf,1,format=FORM,d
tryagain:
	while d(0) ne 0 do begin
		DATA(0,NREC)=D
		nrec=nrec+1
		readf,1,format=form,d
        	endwhile
	GOTO, NOERR
;91AUG24 MOD:
IOERR:
		if ((strpos(!err_string,'End of input record') lt 0) and  $
                 (strpos(!err_string,'Input conversion error') lt 0))then begin
                        PRINT,!ERR,!ERR_STRING 
			PRINT,'RD INPUT LINE=',D
			STOP
			ENDIF
;90OCT11-FIX FOR V2 ERR ON SHORT RECORDS-RCB
		if nrec eq 0 then begin
			d = d(0:7)
			data = data(0:7,*)
			goto,tryagain			;switched to 8 column
			endif
;		D(0)=0 		;comment out 93sep3...needed??????
NOERR:	
	data=data(*,0:nrec-1)		;extract filled portion
	data=transpose(data)

	close,1
	return
	end
