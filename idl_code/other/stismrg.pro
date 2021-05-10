PRO stisMRG,F1,F2,FOUT,number,TITLE=TITLE
;+
;
; MERGE TWO SPECTRA IN ASCII FILES INTO A SINGLE ASCII FILE.
;
; stisMRG,F1,F2,FOUT,number,TITLE=TITLE
;
; INPUT:
;	F1 - FILE NAME OF SHORT WAVELENGTH SPECTRUM (Ascii file)
;	F2 - FILE NAME OF LONG WAVELENGTH SPECTRUM  (Ascii file)
; 	FOUT - FILE NAME OF OUTPUT MERGED SPECTRUM  (Ascii file)
;	number - OPTIONAL output file number (DEFAULT=1)
;	TITLE  - OPTIONAL OUTPUT TITLE FOR LINE after ### IN ASCII OUTPUT FILE
;
;HISTORY:
; 98feb27-MODIFIED FROM fosmrg.PRO BY R.C.BOHLIN
; 00jan4 -keep bad data w/ bad flag, instead of data gaps
;-------------------------------------------------------------------------
;
IF N_PARAMS(0) LT 4 THEN NUMBER=1
;
; get headers
;
	st = ''
	header = strarr(10000)
	nheader = 0
	close,1 & openr,1,f1
	readf,1,st
	while strmid(st,1,3) ne '###' do begin
		header(nheader) = st
		nheader=nheader+1
		readf,1,st
 	end
	target='' & readf,1,target		;target name
IF F2 EQ '' THEN GOTO,ONEFIL
	close,1 & openr,1,f2
	readf,1,st
	while strmid(st,1,3) ne '###' do begin
		header(nheader) = st
		nheader=nheader+1
		readf,1,st
 	end
	close,1
; GET INPUT DATA
ONEFIL: 			;data order: W,C,F,staterr,syserr,NPTS,TIME,QUAL
	rdf,f1,0,x1
	mtit1=!mtitle
; trim first and last 5 points that are usually bad
;	siz=size(x1)  &  npts=siz(1)
;	x1=x1(5:npts-6,*)	; NO good... each iter keeps trimming beginning
	X2=X1
	IF F2 NE '' THEN rdf,f2,0,x2
	siz=size(x2)  &  npts=siz(1)
	IF F2 NE '' THEN x2=x2(5:npts-6,*)
; delete parts of arrays w/ bad quality(=0), i.e. w/DATA QUALITY FLAG GE 200.
;
;	qual1=x1(*,7)
;	qual2=x2(*,7)
;good=where(qual1 eq 1)  & x1=x1(good,*)		
;good=where(qual2 eq 1)  & x2=x2(good,*)

; trim below 1140A. was 1155 before 98jul10... need 1140 to make std *
GOOD=WHERE(X1(*,0) ge 1140) & X1=X1(GOOD,*)

; TRIM OFF ZERO FLUX AT ENDS
;
GOOD=WHERE(X1(*,2) NE 0) & X1=X1(MIN(GOOD):MAX(GOOD),*)
GOOD=WHERE(X2(*,2) NE 0) & X2=X2(MIN(GOOD):MAX(GOOD),*)

;
; EXTRACT WAVELENGTHS FROM X1 AND X2
;
	S1=SIZE(X1) & S2=SIZE(X2)		;SIZE ARRAYS
	np1 = s1(1) & np2 = s2(1)		;number of data pts
	ncol1=S1(2) & ncol2=S2(2)		;SECOND DIMENSION OF X1 AND X2
	W1=X1(*,0)  & W2=X2(*,0)		;WAVELENGTH VECTORS
IF F2 EQ '' THEN BEGIN		;SINGLE SPECTRUM
	XOUT= X1 & WMERGE=0. & GOTO,SKIP
	ENDIF	

	sig1=x1(*,3) & sig2=x2(*,3)
	flux1=x1(*,2)				;flux vectors
	flux2=x2(*,2)
;	fosovrlap,w1,w2,flux1,flux2,flux1,flux2	;correct overlap region smoothly
;	x1(*,2)=flux1  &  x2(*,2)=flux2

; determine merge point

wmerge=min(w2)
if max(w1) gt min(w2) then begin
	ovrlap=max(w1)-min(w2)
        nbeg=fix(ws(w2,min(w2)+.25*ovrlap))   ;keep 25% of ovrlap away from ends
        nend=fix(ws(w2,max(w1)-.25*ovrlap))+1
        wmerge=w2(nbeg)
        if nbeg ge nend then begin		; should never be True
                wmerge=w2((nbeg+nend)/2)
              endif else begin
                err_sw=smooth(sig1,5)           ;smooth short wl errors
                err_sw=smooth(err_sw,5)
                for i=nbeg,nend do begin
                        npt1=fix(ws(w1,w2(i))+.5)  ;find w1 pt corresp. to w2(i)
                        if((err_sw(npt1) le sig2(i)) or (flux2(i) lt 0)) then  $
                                                        wmerge=w2(i+1)
                        endfor
                endelse
; Set const merge pts, so that i can do transm by div by different merged spec.
	if strpos(mtit1,'G140L' ) ge 0 then wmerge=1678 ;98jul21 for gr+70
	if strpos(target,'BPM16274') ge 0 then wmerge=1655 ;early bpm on repellr
	if strpos(mtit1,'G230L') ge 0 then wmerge=3065
	if strpos(mtit1,'G230MRG') ge 0 then wmerge=3065
	if strpos(mtit1,'G230L') ge 0 and strpos(target,'132811') ge 0	$
				then wmerge=3150	;2018jun - Avila SDSS
	if strpos(mtit1,'G230L') ge 0 and strpos(target,'GRW_70D5824') ge 0 $
				then wmerge=3130	;2019feb G230L monitor
; 06june - 3065 is OK for G230LB. There are 5 more (bad) pts & sens is a max.
	if strpos(mtit1,'G430L' ) ge 0 then wmerge=5450	;99oct8 - avoid g750 dip
	if strpos(mtit1,'G430L') ge 0 and strpos(target,'WD1657') ge 0	$
						 then wmerge=5690	;06may1
	if strpos(mtit1,'G430L') ge 0 and strpos(target,'281159') ge 0	$
						then wmerge=5690
	if strpos(mtit1,'G430L') ge 0 and strpos(target,'132811') ge 0	$
				then wmerge=5280	;2018jun - Avila SDSS
	if strpos(mtit1,'G430L') ge 0 and strpos(target,'73882') ge 0	$
						 then wmerge=5610	;2015apr
	if strpos(mtit1,'G430L') ge 0 and strpos(target,'11d3759') ge 0	$
				then wmerge=5625    ;2018aug-M star better resol
	if strpos(mtit1,'G430L') ge 0 and strpos(target,'HZ4') ge 0	$
			then wmerge=5310	;2019feb G750L - much better S/N
        endif
print,'Wmerge = ',wmerge
good1=where(w1 lt wmerge,icount)
n1=icount
good2=where(w2 ge wmerge,icount)
n2=icount
first=good2(0)
;
; merge spectra
;
NPOUT=N1+N2			;NUMBER OF POINTS IN OUTPUT SPECTRUM
XOUT=FLTARR(NPOUT,ncol1)	;OUTPUT ARRAY
XOUT(0,0) = X1(good1,0:ncol1-1)	;INSERT FIRST SPECTRUM
XOUT(n1,0) =X2(FIRST:first+N2-1,0:ncol2-1)  ;INSERT GOOD PART OF SECOND
;
; WRITE OUTPUT SPECTRUM
;
SKIP:	close,1 & openw,1,fout
PRINTF,1,'FILE WRITTEN BY stismrg.PRO ON ',!STIME
for i=0,nheader-1 do printf,1,header(i)
printf,1,'MERGE POINT ='+STRING(WMERGE,'(F7.1)')
printf,1,' ###'+string(number,'(I5)')
IF KEYWORD_SET(TITLE) THEN PRINTF,1,TITLE ELSE			$
		printf,1,GETTOK(target,' ')	;TARGET ASSUMED TO BE FIRST ITEM
form='(F12.6,4E12.4,I4,F10.1,I4)'

printf,1,transpose(xout),format=form
printf,1,fltarr(ncol1),format=form	;record of zeroes for EOF delim.
close,1
RETURN
END
