PRO echladd,files,HEAD,TITLE,wlm,count,FLUX,FLXERR,NPTS,TIME
;+
; NAME:
;       stisADD
; PURPOSE:
;	stis echelle COADD & merge. CORRESPONDs TO stisadd for lo-disp
; CALLING SEQUENCE:
;	echlADD,files,HEAD,TITLE,Wav,count,FLUX,FLXERR,NPTS,TIME
; INPUT:
;	files-ASCII LIST OF ROOTNAMES TO BE COADDED
; OUTPUT: for use in echlreduce.pro
;	HEAD-HEADER FOR LAST OBS SET
;	TITLE-CONSTRUCTED FROM HEAD, incl avg radial vel.
;	wlm-WAVELENGTH
;	count-AVERAGED COUNTRATE weighted by exposure time
;	FLUX-AVERAGE FLUX weighted by exposure time
;	FLXERR-PROGAGATED FLUX STATISTICAL UNCERTAINTY
;	NPTS-ARRAY OF TOTAL POINTS COADDED for flux array
;	TIME-ARRAY OF TOTAL EXP TIME PER POINT in counts array
; HISTORY:
; 2012Jul9-WRITTEN BY R. C. BOHLIN
; Start by using the STScI pipeline output, which has fluxes. Even include
; 	spectra w/ non-zero monthly offsets. See direchl-x1d.log
;-
IF N_PARAMS(0) EQ 0 THEN BEGIN
PRINT,'echlADD,files,HEAD,TITLE,wlm,count,FLUX,FLXERR,NPTS,TIME'
	RETALL
	ENDIF
st=''
num=n_elements(files)

;INITIALIZE COADDED QUANTITIES
; set up master WLM grid covering complete range from 1141-3146A. E140H covers
;	1141-1687.83, while E230H is 1628.89-3146.40 @ ~.007-0.013A/px. R is 
;	~constant @ ~2.3e5 per px (1.15e5 per resel).
; see also rsmooth.pro
; Let wmin=1 & note e^(n/R) ~ (1+n/R)^n, ie wl(i)= (1+i/R)^i = e^(i/R)

indx=findgen(2.3e5*alog(3145.))+1	; indices of new WL vector for 2x sampl.
wlm=exp(indx/(2.3d5))			; R=res*2 wl array for 2x sample
wlm=wlm(where(wlm ge 1145))		; master Merged WL vector
npts=n_elements(wlm)
count=wlm*0.
FLUX=wlm*0.
FLXERR=wlm*0.
NPTS=intarr(npts)
TIME=wlm*0.
flags=(1+2+4+32+64+512)		; bad px. 512 for o5i013010 bad ref file substit
;					for vignetting.

; The longest WL E140H-1598 goes to 1687.8, while the shortest WL E230H-1763
;	overlaps down to 1628; but seems always to be much noisier. 
;	But keep all G230H.
;; For each order, find max exp time & reject spectra w/ < half of max. Or 1st,
;	just try adding the counts for everything to see if all spectra can be
;	retained. Ck,eg w/ & w/o the short obb001060  E140H-1343 686.0s exp.

;MAIN LOOP
FOR ifil=0,NUM-1 DO BEGIN
	print,'Processing ',files(ifil)
	z=mrdfits(files(ifil),1,head,/silent)
	wl=z.wavelength
	flx=z.flux
	ct=z.net
	flxer=z.error
	ql=z.dq
	ql=(ql and flags) eq 0			; =1 for good px
	exptim=sxpar(head,'exptime')
	siz=size(wl)
	if siz(1) ne 1024 then stop		; idiot ck.
	nord=siz(2)				; number of orders
; Remove 1st & last orders:		; fixes 1316 & 1629A glitches; but new
;						one @1632 pops up!
	wl=wl(*,1:nord-2)
	flx=flx(*,1:nord-2)
	ct=ct(*,1:nord-2)
	flxer=flxer(*,1:nord-2)
	ql=ql(*,1:nord-2)
	nord=nord-2
; trim orders to elim lower countrates (WLs decrease for higher orders)
	trimend=wl(1019,*)  &  trimbeg=wl(4,*) ;use all data xcept 4 end pts
	for iord=0,nord-2 do begin
	   if wl(1023,iord+1) gt wl(0,iord) then begin	; some overlap
		n1=ws(wl(*,iord),wl(1023,iord+1)) ;end pt of overlap in iord
		n2=ws(wl(*,iord+1),wl(0,iord))	  ;1st pt of overlap in iord+1
; interpol overlap region in ord+1 to overlap region of ord
		linterp,wl(n2:1019,iord+1),ct(n2:1019,iord+1),wl(4:n1,iord),ctrp
; call everything good down to half the interpol count level of overlap
		good=where(ct(4:n1,iord) ge ctrp/2,ngd1)
		trimbeg(iord)=wl((n1-ngd1)>4,iord)	; skip at least 4 pts
		good=where(ctrp ge ct(4:n1,iord)/2,ngd2)
		trimend(iord+1)=wl((n2+ngd2)<1019,iord+1)
		endif
	   endfor
	for iord=0,nord-1 do begin		; DO Co-adds
		good=where(wl(*,iord) ge trimbeg(iord) and		$
						wl(*,iord) le trimend(iord))
		linterp,wl(good,iord),ct(good,iord),wlm,ctm,missing=0
		linterp,wl(good,iord),flx(good,iord),wlm,flxm,missing=0
		linterp,wl(good,iord),flxer(good,iord),wlm,flxerm,missing=0
		linterp,wl(good,iord),ql(good,iord),wlm,qlm,missing=0
		qlm=qlm ge 1.0		  ; mask is either 0 (bad) or 1 (good)
;The error for 0 counts is set to the sqrt(1) = 1.0.
;An error of 0.0 should only occur at undefined data points. ---Don 
		count=count+ctm*qlm*exptim		;wgt by exp time, ie cts
		time=time+exptim*qlm
		flux=flux+flxm*exptim*qlm
; Plot a sample:
;		if 1632.3 ge wl(good(0),iord) and 1632.3 le wl(max(good),iord)  $
;						then begin
;			!y.style=0
;			plot,wlm,flux,xr=[1629,1635]
;			oplot,wlm,flxm*exptim*qlm,lin=1
;		        xyouts,.7,.15,'iord='+string(iord,'(i2)'),/norm
;			read,st
;			endif
; see Bevington p. 73 for proper formula
		gooderr=where(flxerm gt 0) 
		flxerm(gooderr)=1./flxerm(gooderr)^2		 ;invert
;2013jun10- err. should already incl any exptime factor, ie small cts-->big err
		flxerr=flxerr+flxerm*qlm
;not needed	neg=where(flxerm lt 0,nneg)
;		if nneg gt 0 then stop		;idiot ck oh! missing=0 elim neg
		npts=npts+qlm
		endfor
	ENDFOR			; END MAIN spectrum LOOP

;COMPUTE AVERAGES
; trim outputs to the size of good data, i.e where time>0
INDEX=WHERE(time GT 0)
wlm=wlm(index)
count=count(index)
flux=flux(index)
flxerr=flxerr(index)
time=time(index)
npts=npts(index)
count=count/TIME
FLUX=FLUX/time
FLXERR=1./SQRT(FLXERR)
;MAKE TITLE
z=mrdfits(files(0),0,head)
targnam=strtrim(SXPAR(HEAD,'targname'),2)
TITLE=TARGNAM+' Sum of '+STRING(NUM,'(I3)')+' OBS with STIS E*H Echelles'
print,title
RETURN
END
