PRO IUEMERGEASC,F1,F2,FOUT,number
;
; PROCEDURE TO MERGE A SHORT AND A LONG WAVELENTH SPECTRUM INTO
; A SINGLE FITS FILE.
;
; It works only with files ascii files containing single spectra.
; (I.E. those split up by IUEBREAK)
;
; VERSION 1  BY D. LINDLER  April 11, 1991
;
; INPUT:
;	F1 - FILE NAME OF SHORT WAVELENGTH SPECTRUM (Ascii file)
;	F2 - FILE NAME OF LONG WAVELENGTH SPECTRUM  (Ascii file)
; 	FOUT - FILE NAME OF OUTPUT MERGED SPECTRUM  (Ascii file)
;	number - output file number
; HISTORY:
;	93sep5-change output format from E10.3 to E11.3 to match merge.ibm,
;		(which was changed 91apr25!!!!!!!!)
;	94mar25-change output format from to match merge.ibm and abprint.ibm,
;		(which was changed 94feb11-see history in those programs)
;	95jan19-change output format to i9 for gross and bkg AND BACK TO
;		F10.2 AND E11.3 FOR FN/SEC AND FLUX (FROM STUPID F9.2,E12.3!!)
;	95apr - djl added special merge point cases
;	95may1- rcb add g191b2b to special case list and set max mrgpt=1994,
; 			based on NGC246
;	95jun19-rcb add alpha-leo
;	95juL21-rcb add AGK+81D266
;-------------------------------------------------------------------------
;
; GET INPUT DATA
;
	rd,f1,0,x1
	rd,f2,0,x2
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
	close,1 & openr,1,f2
	readf,1,st
	while strmid(st,1,3) ne '###' do begin
		header(nheader) = st
		nheader=nheader+1
		readf,1,st
 	end
	target='' & readf,1,target		;target name
	close,1
;
; EXTRACT WAVELENGTHS FROM X1 AND X2
;
ITER:	S1=SIZE(X1) & S2=SIZE(X2)		;SIZE ARRAYS
	np1 = s1(1) & np2 = s2(1)
	NREC1=S1(2) & NREC2=S2(2)		;SECOND DIMENSION OF X1 AND X2
; 93MAY18-TRIM 9 COL DATA FROM MERGE.IBM TO 8 COLUMNS
	IF NREC1 GT 8 THEN BEGIN
		X1=X1(*,0:7)
		GOTO,ITER
		ENDIF
	IF NREC2 GT 8 THEN BEGIN
		X2=X2(*,0:7)
		GOTO,ITER
		ENDIF
	W1=X1(*,0) & W2=X2(*,0)			;WAVELENGTH VECTORS
	sig2=x2(*,7)
	sig1=x1(*,7)
	flux2=x2(*,5)
;
; merge at 1970 A except for cool stars and HZ2 which uses
; the hairy code below. (30 mar 89)
;
; OCT 15, 1990 - Changed condition below to work for opt. ext. and IUESIPS
;		IUESIPS coadds. BAD changed from 20% error to err-LW/err-SW = 3
; NOV 21, 1991 - Changed factor of 3 to 5 to make VEGA work.
;92OCT21-FIXED TCHANG TO WORK BEYOND 1970, SO TRY A FACTOR OF 1
;
	err_sw = total(sig1(np1-20:np1-10))/11.0
	BAD = where( ((sig2/err_sw gt 1.0) or (flux2 lt 0)) $
				and (w2 lt max(w1)) )
	if !err gt 0 then wmerge=W2(BAD(!err-1)+1) else wmerge=min(w2)
;92MAR27-SEE 0121-590 DEGRADING FROM 1975.6 TO 1980, SO NEVER GO BEYOND 1980!
;92OCT21-FIXED TCHANG TO WORK BEYOND 1970, SO COMMENT OUT NEXT LINE
;93JUL7- PUT VERSION OF THIS .PRO IN [.CALIB] W/1970 BELOW FOR OLD F311 SPECTRA
	if wmerge GT 1994 then wmerge=1994
	if wmerge lt 1970 then wmerge=1970
;
; special merge points
;
	case strtrim(!p.title,2) of
		'AU-MIC' : wmerge = 1981
		'ALPHA-LEO' : wmerge = 1972
		'AGK+81D266' : wmerge = 1970
		'BETA-HYI' : wmerge = 1987
		'HD27836' : wmerge = 1989
		'HZ2' : wmerge = 1975
		'LB227' : wmerge = 1985
		'LDS749B' : wmerge = 1989
		'NGC6752-2128' : wmerge = 1982
		'16CYGB' : wmerge = 1983
		'G191B2B' : wmerge = 1980
		else:
	end	


	print,'Wmerge = ',wmerge
	good1=where(w1 lt wmerge)
	n1=!err
	good2=where(w2 ge wmerge)
	n2=!err
	first=good2(0)
;
; merge spectra
;
	NPOUT=N1+N2			;NUMBER OF POINTS IN OUTPUT SPECTRUM
	XOUT=FLTARR(NPOUT,NREC1)	;OUTPUT ARRAY
	XOUT(0,0) = X1			;INSERT FIRST SPECTRUM
	XOUT(n1,0) =X2(FIRST:first+N2-1,0:NREC2-1)  ;INSERT GOOD PART OF SECOND
;
; WRITE OUTPUT SPECTRUM
;
	openw,1,fout
	for i=0,nheader-1 do printf,1,header(i)
	printf,1,'MERGE POINT ='+STRING(WMERGE,'(F7.1)')
	printf,1,' ###'+string(number,'(I5)')
	printf,1,target
	if nrec1 eq 9 then 			$
			form='(F7.1,F7.0,2i9,F10.2,E11.3,F10.2,F10.4,F6.0)' $
	           else form='(F7.1,F7.0,2i9,F10.2,E11.3,F10.2,F10.4)'

	printf,1,transpose(xout),format=form
	printf,1,fltarr(nrec1),format=form
	close,1
RETURN
END
