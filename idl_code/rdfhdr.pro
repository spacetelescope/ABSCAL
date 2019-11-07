PRO rdfhdr,FILE,ID,DATA,hdr
;+
;
; Routine to read ANY ASCII TEXT FILES with header
; 	- Data contained between " ###" (with optional 5-element ID)
;         and zero entries in each columnn at end of file.
;       - First line following " ###" is a string (not data)
;
; CALLING SEQUENCE:  rdf,file,id,data,hdr
;
; INPUT: file - file name
;	 id - id of spectra (if 0 then the first one is read)
; OUTPUT:
;	 data - 2-d array,  data(i,j) is jth column of record i
;	 hdr - string array of header info
;
; HISTORY:
; 97dec23- adapted from rdf
; 92nov10-****WARNING**** lines missing blank delimiters between data are lost
; 14mar18-make output dbl precision for better WLs in Rauch Models
;-
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,'USAGE:  rdf,FILE,ID,DATA'
	print,'        use ID=0 for no id'
	RETALL
	ENDIF
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
reinit:
	hdr=strarr(100000)
	ihdr=-1
	while strmid(st,1,nchar) ne testst do begin
		readf,1,st
		if strmid(st,0,4) eq ' 0 0' then goto,reinit
		ihdr=ihdr+1
		hdr(ihdr)=st
		end
	hdr=hdr(0:ihdr-1)
	print,st
; RCB addition
        object='            '
        readf,1,object
        !mtitle=strtrim(object,2)
        print,!mtitle             
;91MAY3-READ FIRST LINE AS A STRING AND COUNT NON-BLANK TOKENS
	READF,1,ST
	d=fltarr(20)			;single record buffer. max 20 columns
	n=-1
	st=strtrim(st,2)
	while st ne '' do begin
		n=n+1
	        if (n eq 20) then begin
		   	print,'Exceeded limit of 20 columns'
			print,'Change size of d array and re-compile'
			stop
		endif
		D(n)=gettok(st,' ')
		endwhile
	PRINT,N+1,' COLUMNS OF DATA FOUND

;
; set up output data array
;
	data=dblarr(N+1,700000L)	; for long rauch metal mod of G191B2B
	DATA(0,0)=D(0:N)
	d=dblarr(N+1)			;single record buffer
	ON_IOERROR,IOERR
;
; loop on records
;

	nrec=0L
	readf,1,d			;READ FIRST DATA LINE
	IND=WHERE(D NE 0,COUNT)		;96MAY9
	while COUNT GT 0 do begin
		nrec=nrec+1
		DATA(0,NREC)=D
		readf,1,d
		IND=WHERE(D NE 0,COUNT)		;96MAY9
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

;	close,1		;KEEP OPEN FOR PLTWID TO WORK
	return
	end
