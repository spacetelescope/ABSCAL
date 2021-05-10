PRO wfcobs,FILE,obs,grat,aper,star,selgrt,selapr,selstr
;+
;
; Routine to read output of wfcDIR.PRO ASCII FILES
; 97jul24-rcb. adapted from fosobs, stisobs
; ****WARNING**** lines missing blank delimiters between data are lost
;
; Input: 
;	file - name of file output by wfcdir w/ list of obs to process
; OPTIONAL INPUT:
;	selgrt,selapr,selstr - Strings to restrict search for
;	grating, aperture, and star name to select. Use '' for all of any mode.
;		ONLY SELAPR CAN BE A VECTOR.
;	To include more that one aperture, use '' for all apertures or eg. 
;							'52X2' for a subset.
; OUTPUT:
;	OBS-1D array of observations: dat/spec_* (max of 1000)
; OPTIONAL OUTPUT:
;	grat, aper, and STAR name- 1D arrays of corresponding config
;
; EXAMPLE: wfcobs,FILE,obs,grat,aper,star,selgrt,selapr,selstr
; HISTORY: 04Feb5 - add nicmos capability
;	13apr19-match just the selstr char to elim *-COPY odd names
;-------------------------------------------------------
selgrt=strupcase([selgrt])				; add 06jun27
selapr=strupcase([selapr])				; belt AND suspenders
selstr=strupcase([selstr])
;
; open file
;
	close,1 & openr,1,file
	ON_IOERROR,IOERR
	DISK=''
	readf,1,disk & disk=strtrim(disk,2)	;disk and dir name in first line
;
; read until hitting I as first character
;
	obs=strarr(5000)
	GRAT=OBS
	APER=OBS
	star=obs
	st=''
	while strupcase(strmid(st,0,1)) ne 'I' do readf,1,st
;
; loop on records
;
	n=-1
	firstflag=0
	while not eof(1) do begin
		n=n+1
		if firstflag ne 0 then readf,1,st
		if strupcase(strmid(st,0,1)) ne 'I' then goto,skipit ; skip BAD
		firstflag=1
		obs(n)=strmid(st,0,9)		; 02dec2 to account for # flags
		dum=gettok(st,' ')
		GRAT(N)=gettok(st,' ')
		APER(N)=STRTRIM(gettok(st,' '),2)
		dum=gettok(st,' ')			;skip detector
		star(N)=gettok(st,' ')
		if n_params(0) gt 6 then begin
		   dum=where(selgrt(0) eq grat(n))  &  dum=dum(0)
		   if ((selgrt(0) ne '') and (dum eq -1)) then goto, skipit
		   selindx=where(selapr eq aper(n),nselap) 
		   if ((selapr(0) ne '') and (nselap le 0)) then goto,skipit
		   if (selstr ne '') and (strpos(star(n),selstr) lt 0)	$
		   					then goto, skipit
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
			print,'stop in wfcobs'
			STOP
			endif
NOERR:	

close,1

; CK FOR NO MATCHES
IF N EQ -1 THEN BEGIN
	PRINT,'*****WARNING***** NO MATCHES FOR REQUEST IN wfcobs for '+   $
			selgrt+' '+selapr+' '+selstr+' In:',file
	N=0
	return
	ENDIF
;trim to number of obs in table and add disk.
obs=strlowcase(obs(0:n))
grat=grat(0:n)			; 02mar27 - in case last obs is a reject.
aper=aper(0:n)
star=star(0:n)
return
end
