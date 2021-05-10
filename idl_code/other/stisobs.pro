PRO stisobs,FILE,obs,grat,aper,star,selgrt,selapr,selstr
;+
;
; Routine to read output of stisDIR.PRO ASCII FILES
; 97jul24-rcb. adapted from fosobs
; ****WARNING**** lines missing blank delimiters between data are lost
;
; Input: 
;	file - name of file output by stisdir w/ list of obs to process
; OPTIONAL INPUT:
;	selgrt,selapr,selstr - Strings to restrict search for
;	grating, aperture, and star name to select. Use '' for all of any mode.
;		ONLY SELAPR CAN BE A VECTOR.
;	Restrict any grating mode to one cenwave by eg. selgrt of G750L-7751
;	To include more that one aperture, use '' for all apertures or eg. 
;							'6X6 52X2' for a subset.
; OUTPUT:
;	OBS-1D array of observations: dat/spec_* (max of 1000)
; OPTIONAL OUTPUT:
;	grat, aper, and STAR name- 1D arrays of corresponding config
;
; EXAMPLE: stisobs,FILE,obs,grat,aper,star,selgrt,selapr,selstr
; HISTORY: 04Feb5 - add nicmos capability
;	07feb6 - increase  obs array from 2000 to 5000 for nicmos
;	08sep10- pick up P330-E w/ P330E for the 
;	13jun10- ...... G-191B2B crap for G191B2B
;	08sep16- Fix above fix to pick up P330-E w/ P330-E for the selstr
;	13aug14 - assume lst is always ~/stiscal/dat, eg stisci/mrgall.pro
;	13sep17 -........ unless nam='nical' at bottom
;-------------------------------------------------------
selgrt=strupcase([selgrt])				; add 06jun27
selapr=strupcase([selapr])				; belt AND suspenders
selstr=strupcase([selstr])				; 04aug30
;
; open file
;
	close,1 & openr,1,file
	ON_IOERROR,IOERR
;
; read until hitting O or N as first character
;
	obs=strarr(5000)
	GRAT=OBS
	APER=OBS
	star=obs
	st=''
	while strupcase(strmid(st,0,1)) ne 'O' and 			$
		strupcase(strmid(st,0,1)) ne 'N' do readf,1,st
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
		if strupcase(strmid(st,0,1)) ne 'O' and			$
		    strupcase(strmid(st,0,1)) ne 'N' then goto,skipit ; skip BAD
		firstflag=1
		obs(n)=strmid(st,0,9)		; 02dec2 to account for # flags
		dum=gettok(st,' ')
		GRAT(N)=gettok(st,' ')
		APER(N)=STRTRIM(gettok(st,' '),2)
	   	cenwav=strtrim(gettok(st,' '),2)
		dum=gettok(st,' ')			;skip detector
		star(N)=gettok(st,' ')
		if star(n) eq 'P330-E' and selstr ne 'P330-E' 		$
							then star(n)='P330E'
		if star(n) eq 'G-191B2B' and selstr ne 'G-191B2B' 		$
							then star(n)='G191B2B'
		if n_params(0) gt 6 then begin
		   if strpos(selgrt(0),'-') gt 0 then grat(n)=grat(n)+'-'+cenwav
		   dum=where(selgrt(0) eq grat(n))  &  dum=dum(0)
		   if ((selgrt(0) ne '') and (dum eq -1)) then goto, skipit
; 07apr3-NG for >1 STIS aper		   selindx=where(selapr(0) eq aper(n),nselap)
		   selindx=where(selapr eq aper(n),nselap)	;07apr3-fix STIS 
		   if ((selapr(0) ne '') and (nselap le 0)) then goto,skipit
		   if ((selstr(0) ne '') and (selstr(0) ne star(n))) 	$
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
			print,'stop in stisobs'
			STOP
			endif
NOERR:	

close,1

; CK FOR NO MATCHES
IF N EQ -1 THEN BEGIN
	PRINT,'*****WARNING***** NO MATCHES FOR REQUEST IN stisobs for '+   $
			selgrt+' '+selapr+' '+selstr+' In:',file
	N=0
	return
	ENDIF
;trim to number of obs in table.
obs=strlowcase(obs(0:n))
grat=grat(0:n)			; 02mar27 - in case last obs is a reject.
aper=aper(0:n)
star=star(0:n)
; 2012Oct - ff line for Rauch testing, but fails in preproc! rm:
; 2013aug - ?? abovr?? try again
cd,current=dir
fdecomp,dir,disk,drct,nam,ext
; lv obs w/o directory for nicmos nictemp.pro
; different Input dir (indir), eg in make-tchang.pro done 'manually'
; 2015jan14-ff fix works for stiskarl dir work:
if nam ne 'nical' then 	obs='dat/spec_'+obs+'.fits'
; 2015Jan16-stisci obs reduced and kept at stiscal/dat:
if nam eq 'stisci' then obs='../stiscal/'+obs
return
end
