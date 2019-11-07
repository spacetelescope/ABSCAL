PRO wfcflx,file,hdr,wave,flux,net,gross,back,blower,bupper,eps,err,	$
		exptm,tcor=tcor,noflux=noflux,notime=notime
;
; PURPOSE:
;	calibrate WFC3 grism data to flux & corr for time var.
;	USED by wfcadd.pro
; INPUT
;	- file-extracted spectral fits data file, eg spec_ic5v41b0qpn.fits
;KEYWORDS
;	- /tcor, if present make the time correction and the non-linearity corr.
;		Otherwise just return w/ same result as mrdfits.
;	- /noflux to avoid double interpolation in wfcadd.pro
;	- /notime, if present along with /tcor make only linearity correction
; OUTPUT - hdr=header
;	 - wave=wavelengths
;	 - FLUX If /tcor: corr for time change
;	 - NET counts/s corr for time change & non-linearity if /tcor.
;	 - GROSS counts/s - NOT corr
;	 - back total ct/s - NOT corr
;	 - BLOWER lower bkg - NOT corr
;	 - BUPPER upper bkg - NOT corr
;	 - eps  quality flags
;	 - Statistical err - uncertainties in flux units - Corrected
;	 - exptm exp time array (sec)
;
; AUTHOR-R.C.BOHLIN
; HISTORY:
; 2015may12 - adopted from stisflx & nicflx
; 2018oct16 - add the non-linearity corr. & /notime for tchang measures
;-
st=''
; 
; ###change to pop. /nolin dir of files uncorr for CRNL 2018oct22
;file=replace_char(file,'nolin/','')

z=mrdfits(file,1,hdr,/silent)
wave=z.wave
net=z.net
gross=z.gross
back=z.back
; X, Y, Xback???
eps=z.eps
err=z.err
blower=z.blower
bupper=z.bupper
exptm=z.time
flux=net*0

grat=strtrim(sxpar(hdr,'filter'),2)
tmp='sens.'+strlowcase(grat)
sfile=findfile('~/wfc3/ref/'+tmp)
sfile=sfile(0)
if sfile eq '' then begin
	print,'WFCFLX: No sensitivity file for ',grat
	stop
	endif	
;print,'SENSITIVITY FILE=',sfile
if keyword_set(tcor) then begin
; corr for non-linearity per avg of bohlin & riess:
;19mar4	lincor=1.0074^alog10((abs(net)>1e-4)/1000)	; corr neg. net symmet.
; the ff change made per the paper & HLSP remade 2019mar18:
	lincor=1.0072^alog10((abs(net)>1e-4)/1000)	; corr neg. net symmet.
; ###change to pop /nolin dir of files uncorr for CRNL 2018oct22
;	lincor=1.
	net=net/lincor
	err=err/lincor
; corr for time change
	if not keyword_set(notime) then begin
	    time=absdate(sxpar(hdr,'pstrtime'))  &  time=time(0)
	    if time le 2009.4 then stop			; idiot ck
	    lossrate=0.00169		;G102 frac loss per year +/-.00015
; 2019mar18 - only change per change on CRNL corr to 0.72 %/dex
;	    if grat eq 'G141' then lossrate=0.00084		;G141 +/-.00014
	    if grat eq 'G141' then lossrate=0.00085		;G141 +/-.00014
	    tmcorr=1.-lossrate*(time-2009.4)
	    net=net/tmcorr
	    err=err/tmcorr
	    print,'Net corr for loss rate & time=',lossrate,time,' by',	$
	     tmcorr,' Linearity corr=',lincor,form='(a,f8.5,f7.1,a,f7.4,a,f6.3)'
	    endif
	endif

; option to avoid interpol to data WLs & then back to sens grid WLs in wfcadd
if not keyword_set(noflux) then begin		; calib flux to phys units
	readcol,sfile,wgrid,gravg				; sensitivity
	good=where(wave ge min(wgrid) and wave le max(wgrid))
	w1st=wave(good)
	n1st=net(good)
	e1st=err(good)
	linterp,wgrid,gravg,w1st,sens		; interp sens to obs WLs
	f1st=n1st/sens
	e1st=err/sens
	flux(good)=f1st
	err(good)=e1st
	endif

RETURN
END
