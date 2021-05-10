PRO fosobs,FILE,obs,det,grat,aper,star,seldet,selgrt,selapr,selstr
;+
;
; Routine to read output of FOSDIR.PRO ASCII FILES
; 93aug14-rcb
; ****WARNING**** lines missing blank delimiters between data are lost
;
; Input: file - name of file output by fosdir w/ list of obs to process
; optional input:	
;	seldet,selgrt,selapr,selstr, which are restrictions of search for
;	detector id, grating, aperture, and star name to select. 
;	Use '' for all of any mode. only selgrt can be a vector.
; output:
;	OBS-1D array of observations (max of 1000)
; optional output:
;	det, grat, aper, and STAR name- 1D arrays of corresponding FOS config
;
; EXAMPLE: fosobs,FILE,obs,det,grat,aper,star,seldet,selgrt,selapr,selstr
; 93oct26-add star and selstr to calling sequence and get dir name from first 
;	line of FILE
; 95feb24-selgrt can be a vector
;-------------------------------------------------------
;
; open file
;
	close,1 & openr,1,file
	ON_IOERROR,IOERR
	DISK=''
	readf,1,disk & disk=strtrim(disk,2)	;disk and dir name in first line
;
; read until hitting Y as first character
;
	obs=strarr(1000)
	DET=OBS
	GRAT=OBS
	APER=OBS
	star=obs
	st=''
	while strmid(st,0,2) ne ' Y' do readf,1,st
;
; loop on records
;
	n=-1
	firstflag=0
	GOTO,STARTIT
	while not eof(1) do begin
STARTIT:
		n=n+1
		if firstflag ne 0 then readf,1,st
		firstflag=1
		obs(N)=gettok(st,' ')
		DET(N)=gettok(st,' ')
		GRAT(N)=gettok(st,' ')
		APER(N)=STRTRIM(gettok(st,' '),2)
		star(N)=gettok(st,' ')
		if n_params(0) gt 6 then begin
		   if ((seldet ne '') and (seldet ne det(n)))  then goto, skipit
		   dum=where(selgrt eq grat(n))  &  dum=dum(0)
		   if ((selgrt(0) ne '') and (dum eQ -1))      then goto, skipit
		   if ((selapr ne '') and (selapr ne aper(n))) then goto, skipit
		   if ((selstr ne '') and (selstr ne star(n))) then goto, skipit
		   endif
		goto, gotit
skipit:		obs(n)=''
		n=n-1
gotit:		
		ENDWHILE
	GOTO, NOERR
IOERR:  if ((strpos(!err_string,'End of input record') lt 0) and  $
           (strpos(!err_string,'Input conversion error') lt 0))then begin
                        PRINT,!ERR,!ERR_STRING 
			PRINT,'INPUT LINE=',st
			print,'stop in fosobs'
			STOP
			endif
NOERR:	

close,1

; CK FOR NO MATCHES
IF N EQ -1 THEN BEGIN
	PRINT,'*****WARNING***** NO MATCHES FOR REQUEST IN FOSOBS for ',       $
					seldet,selgrt,selapr
	N=0
	return
	ENDIF
;trim to number of obs in table and add disk.
	obs=disk+obs(0:n)
	return
	end
