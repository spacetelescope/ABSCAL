PRO rdF,FILE,ID,DATA,silent=silent
;+
;
; Routine to read ANY ASCII TEXT FILES
; 	- Data contained between " ###" (with optional 5-element ID)
;         and zero entries in each columnn at end of file.
;       - First line following " ###" is a string (not data)
;
; CALLING SEQUENCE:  rdf,file,id,data
;
; INPUT: file - file name
;	 id - id of spectra (if 0 then the first one is read)
; OUTPUT:
;	 data - 2-d array,  data(i,j) is jth column of record i
;	!mtitle is set for plotting
;
; EXAMPLES:
;	rdf,'stis.mrg',11,d  - reads spectrum No. 11 from a file of spectra
;       rdf,'ellip54.mrg',0,d  reads the first spectrum, regardless of its No.
;	to plot IUE flux, eg:  plot,d(*,0),d(*,5),yr=[0,1e-13]
;
; 91MAY3 - djl
; 92nov10-****WARNING**** lines missing blank delimiters between data are lost
; 93mar17-increase to 10000 max pts from 2000 for lcb
; 93JUL29-increase to 26000 max pts from 10000 for COPERNICUS
; 93dec20-increase to 30000 max pts for COPERNICUS V1
; 93Dec06-increase max columns from 12 to 20	-exv
; 02jul26-increase to 600000 max pts for g191.hub-metals
; 04jan23-add silent optional keyword
; 07jan23-increase to 5Mill max pts to read Kurucz R=500000 model
; 2014mar18 - make output dbl prec. for fine WL scale of models per rdfhdr.pro
;-
;-------------------------------------------------------
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,'USAGE:  rdf,FILE,ID,DATA,silent=silent'
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
	while strmid(st,1,nchar) ne testst do begin
		readf,1,st
		end
	if not keyword_set(silent) then print,st
; RCB addition
        object='            '
        readf,1,object
        !mtitle=strtrim(object,2)
        if not keyword_set(silent) then print,!mtitle             
;91MAY3-READ FIRST LINE AS A STRING AND COUNT NON-BLANK TOKENS
	READF,1,ST
;single record buffer. max 20 columns. 2016feb25-make dbl:
	d=dblarr(20)
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
	if not keyword_set(silent) then PRINT,N+1,' COLUMNS OF DATA FOUND

;
; set up output data array
;
	data=dblarr(N+1,5000000)
	DATA(0,0)=D(0:N)
	d=dblarr(N+1)			;single record buffer
	ON_IOERROR,IOERR
;
; loop on records
;

	nrec=0L				; long word integer
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
