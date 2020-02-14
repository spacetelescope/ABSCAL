PRO wfcMRG,F1,F2,FOUT,number,TITLE=TITLE
;+
;
; MERGE TWO SPECTRA IN ASCII FILES INTO A SINGLE ASCII FILE.
;
; wfcMRG,F1,F2,FOUT,number,TITLE=TITLE
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
; 18jun13-MODIFIED FROM stismrg.PRO
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
	X2=X1
	IF F2 NE '' THEN rdf,f2,0,x2
	siz=size(x2)  &  npts=siz(1)

; TRIM to 1st order for now. Iterate for -1,+2 orders and concatenate w/ 1st,
;	as needed.
GOOD=WHERE(X1(*,0) ge 7600 and X1(*,0) le 11750) & X1=X1(MIN(GOOD):MAX(GOOD),*)
GOOD=WHERE(X2(*,0) ge 8300 and X2(*,0) le 17200) & X2=X2(MIN(GOOD):MAX(GOOD),*)

;
; EXTRACT WAVELENGTHS FROM X1 AND X2
;
S1=SIZE(X1) & S2=SIZE(X2)			;SIZE ARRAYS
np1 = s1(1) & np2 = s2(1)			;number of data pts
ncol1=S1(2) & ncol2=S2(2)			;SECOND DIMENSION OF X1 AND X2
W1=X1(*,0)  & W2=X2(*,0)			;WAVELENGTH VECTORS
flux1=x1(*,2)  &  flux2=x2(*,2)			;flux vectors

IF F2 EQ '' THEN BEGIN				;SINGLE SPECTRUM
	if strpos(f1,'g102') gt 0 then XOUT= X1 else XOUT= X2
	WMERGE=0. & GOTO,SKIP
	ENDIF	

; Set const merge pts, so that i can do transm by div by different merged spec.
wmerge=11250					; per mrgall plots of overlap
if strpos(target,'2m055914') ge 0 then wmerge=11100
if strpos(target,'gaia593_1968') ge 0 then wmerge=11075.
if strpos(target,'gaia593_9680') ge 0 then wmerge=11015.
print,'Wmerge = ',wmerge
; ck plot:
if f1 ne '' and f2 ne'' then begin
	!y.style=1
	!mtitle=!mtitle+' diamonds'
	ind=where(w1 ge wmerge-500 and w1 le wmerge+500)
	yrang=minmax(flux1(ind))
	yrang=[0.8*yrang(0),1.25*yrang(1)]
	plot,w1(ind),flux1(ind),yr=yrang,psym=-4,xr=[wmerge-500,wmerge+500]
	oplot,w2,flux2,psym=-6
	oplot,[wmerge,wmerge],[0,!y.crange(1)]
	plotdate,'nidl/wfcmrg'
	if !d.name eq 'X' then read,st
	endif

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
PRINTF,1,'FILE WRITTEN BY wfcmrg.PRO AT ',!STIME
for i=0,nheader-1 do printf,1,header(i)
printf,1,'MERGE POINT ='+STRING(WMERGE,'(F7.1)')
printf,1,' ###'+string(number,'(I5)')
IF KEYWORD_SET(TITLE) THEN PRINTF,1,TITLE ELSE			$
		printf,1,GETTOK(target,' ')	;TARGET ASSUMED TO BE FIRST ITEM
form='(F8.1,4E12.4,I4,F10.1,I4)'
printf,1,transpose(xout),format=form
printf,1,fltarr(ncol1),format=form	;record of zeroes for EOF delim.
close,1
RETURN
END
