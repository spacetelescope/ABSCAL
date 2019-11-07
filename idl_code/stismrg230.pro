PRO stisMRG230,star
;+
;
; combine a G230L and a G230LB ASCII FILE INTO A SINGLE ASCII FILE.
;
; stisMRG,star
;
; INPUT:
;	star - name of files to be combined: star.g230l and star.g230lb
; OUTPUT: Ascii File: 'star.g230mrg'
;
;HISTORY:
; 99oct19-MODIFIED FROM stismrg.PRO BY R.C.BOHLIN
;-------------------------------------------------------------------------
;
; get headers
;
	st = ''
	header = strarr(10000)
	nheader = 0
	close,1 & openr,1,star+'.g230l'
	readf,1,st
	while strmid(st,1,3) ne '###' do begin
		header(nheader) = st
		nheader=nheader+1
		readf,1,st
 	end
	target='' & readf,1,target		;target name
	close,1 & openr,1,star+'.g230lb'
	readf,1,st
	while strmid(st,1,3) ne '###' do begin
		header(nheader) = st
		nheader=nheader+1
		readf,1,st
 	end
	close,1
; GET INPUT DATA
;data order: W,C,F,staterr,syserr,NPTS,TIME,QUAL
	rdf,star+'.g230l',0,x1
; trim first and last 5 points that are usually bad
	siz=size(x1)  &  npts=siz(1)
	x1=x1(5:npts-6,*)
	X2=X1
	rdf,star+'.g230lb',0,x2
	siz=size(x2)  &  npts=siz(1)
	x2=x2(5:npts-6,*)

; TRIM OFF ZERO FLUX AT ENDS
;
GOOD=WHERE(X1(*,2) NE 0) & X1=X1(MIN(GOOD):MAX(GOOD),*)
GOOD=WHERE(X2(*,2) NE 0) & X2=X2(MIN(GOOD):MAX(GOOD),*)

;
; EXTRACT FROM X1 AND X2
;
	S1=SIZE(X1) & S2=SIZE(X2)		;SIZE ARRAYS
	np1 = s1(1) & np2 = s2(1)		;number of data pts
	ncol1=S1(2) & ncol2=S2(2)		;SECOND DIMENSION OF X1 AND X2
	W1=X1(*,0)     &  W2=X2(*,0)		;WAVELENGTH VECTORS
	ct1=x1(*,1)    &  ct2=x2(*,1)
	flux1=x1(*,2)  &  flux2=x2(*,2)		;flux vectors
	sig1=x1(*,3)   &  sig2=x2(*,3)
	npt1=x1(*,5)   &  npt2=x2(*,5)
	tim1=x1(*,6)   &  tim2=x2(*,6)
	qual1=x1(*,7)  &  qual2=x2(*,7)
	
; make merged WL array
inds=where(w1 lt w2(0),ns)	; G230L (w1) always shorter and longer than LB
indl=where(w1 gt w2(np2-1),nl)
NPOUT=ns+nl+np2				;NUMBER OF POINTS IN OUTPUT SPECTRUM
XOUT=FLTARR(NPOUT,ncol1)		;OUTPUT ARRAY
XOUT(0,0) = X1(inds,0:ncol1-1)		;INSERT short end of G230L
XOUT(ns+np2,0) = X1(indl,0:ncol1-1)	;INSERT long end of G230L
XOUT(ns,0) =X2(*,0:ncol2-1)  		;INSERT G230LB

; MERGE in overlap region
for i=0,np2-1 do begin
	wgt2=ct2(i)*tim2(i)*qual2(i)	; use counts as wgt * 0 or 1 for qual
; interpolate G230L:
	wlpt=ws(w1,w2(i))
	ind=fix(wlpt)			; array 1, G230L index
	frac=wlpt-ind
	wgt1a=ct1(ind)*tim1(ind)*qual1(ind)*(1-frac)
	wgt1b=ct1(ind+1)*tim1(ind+1)*qual1(ind+1)*frac
	ii=i+ns				; output array index
	smwgt=wgt1a+wgt1b+wgt2		; total net counts (NG for faint *)
	xout(ii,1)=ct1(ind)*qual1(ind)*(1-frac)+ct1(ind+1)*qual1(ind+1)*frac $
						+ct2(i)*qual2(i)
	xout(ii,2)=(flux1(ind)*wgt1a+flux1(ind+1)*wgt1b+flux2(i)*wgt2)/smwgt
; stat error in LB range is just scaled LB uncert! for good global est.
	xout(ii,3)=xout(ii,2)/sqrt(smwgt)
; 00apr6 - 4th col sys-err reset at 1% of flux
	xout(ii,4)=0.01*xout(ii,2)
	xout(ii,5)=fix((npt1(ind)*qual1(ind)*(1-frac)+			$
			npt1(ind+1)*qual1(ind+1)*frac+npt2(i)*qual2(i))+.5)
	xout(ii,6)=tim1(ind)*qual1(ind)*(1-frac)+			$
			tim1(ind+1)*qual1(ind+1)*frac+tim2(i)*qual2(i)
	xout(ii,7)=fix((qual1(ind)*wgt1a+qual1(ind+1)*wgt1b+qual2(i)*wgt2)<1)
	endfor
;
; WRITE OUTPUT SPECTRUM
;
close,1 & openw,1,star+'.g230mrg'
PRINTF,1,'FILE WRITTEN BY stismrg230.PRO ON ',!STIME
for i=0,nheader-1 do printf,1,header(i)
printf,1,' ###    1'
PRINTF,1,gettok(!mtitle,' ')+string(max(npt1),'(i3)')+' G230L +'+	$
					string(max(npt2),'(i3)')+' G230LB' 
form='(F12.6,4E12.4,I4,F10.1,I4)'
printf,1,transpose(xout),format=form
printf,1,fltarr(ncol1),format=form	;record of zeroes for EOF delim.
close,1
RETURN
END
