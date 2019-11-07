function synspz,wav,flux,effwav,plt=plt,shft=shft
;+
;
; PURPOSE:
;	Compute synthetic photometry for 6 Spitzer filters
;
;	computed count rate = synspz(wav,flux) in e-/sec
;
; INPUT
;	wav - vac wavelength array of spectral flux distribution in ANG.
;	flux - spectral flux distribution
; OPTIONAL INPUT
;	plt - keyword to make plots
;	shft - keyword specifying shift of filter BP in Ang.
; OUTPUT
;	the result of the function in electrons/sec
;	effwav - effective wavelength optional output (optional)
; HISTORY
;	09May19 - rcb  (cf. synacs.pro)
;	10Apr5 - add the corr (fixfdg) per paper for the R transmissions.
; COMMON means recompiling may not work. Exit idl and return to implmnt changes!
;-
st=''
common filtbp,wfilt,tfilt,npts
;mult corr factor per paper - Also put into calpar.pro and iterate.(EXIT IDL !!)
; ###change
fixfdg=[1.4006 ,1.0711 ,1.0505 ,0.9849 ,0.5403 ,0.4853]	; from calpar

if n_elements(wfilt) eq 0 then begin
	npts=intarr(6)					;size of each filter curve
	dir='~/calib/photom/'
	readcol,dir+'36.irac-spitzer',w36,t36,format='d,d'  &  siz=size(w36)
	npts(0)=siz(1)
	readcol,dir+'45.irac-spitzer',w45,t45,format='d,d'  &  siz=size(w45)
	npts(1)=siz(1)
	readcol,dir+'58.irac-spitzer',w58,t58,format='d,d'  &  siz=size(w58)
	npts(2)=siz(1)
	readcol,dir+'80.irac-spitzer',w80,t80,format='d,d'  &  siz=size(w80)
	npts(3)=siz(1)
	readcol,dir+'15.irs-spitzer',w15,t15,format='d,d'  &  siz=size(w15)
	t15=t15/3.58			; correction. See header of this file.
	npts(4)=siz(1)
	readcol,dir+'24.mips-spitzer',w24,t24,format='d,d'  &  siz=size(w24)
	npts(5)=siz(1)
	mx=max(npts)
	wfilt=fltarr(mx,6)  &  tfilt=wfilt
	wfilt(0:npts(0)-1,0)=w36  &  tfilt(0:npts(0)-1,0)=t36*fixfdg(0)
	wfilt(0:npts(1)-1,1)=w45  &  tfilt(0:npts(1)-1,1)=t45*fixfdg(1)
	wfilt(0:npts(2)-1,2)=w58  &  tfilt(0:npts(2)-1,2)=t58*fixfdg(2)
	wfilt(0:npts(3)-1,3)=w80  &  tfilt(0:npts(3)-1,3)=t80*fixfdg(3)
	wfilt(0:npts(4)-1,4)=w15  &  tfilt(0:npts(4)-1,4)=t15*fixfdg(4)
	wfilt(0:npts(5)-1,5)=w24  &  tfilt(0:npts(5)-1,5)=t24*fixfdg(5)
	wfilt=wfilt*1e4
;;;NO	airtovac,wfilt	See doc.help
	endif

wave=wav						; star WL in microns
if not keyword_set(shft) then shft=0
countrate=fltarr(6)  &  effwav=countrate
filt=['3.6','4.5','5.8','8.0','15','24']
for ifilt=0,5 do begin
;	Area of primary=5674.5*0.86 cm2 from 85cm diam primary (& 
; 		obscuration=14.2%, per Werner, 2004)
;	hc=6.626e-27*3e18

	wfil=wfilt(0:npts(ifilt)-1,ifilt)+shft
	tfil=tfilt(0:npts(ifilt)-1,ifilt)
; use WL of filter for integral & if wave does not cover wfilt, set missing=0
	linterp,wave,flux,wfil,fstar,missing=0
	integr=wfil*fstar*tfil				; Eq 2 of Spitzer paper
	countrate(ifilt)=5674.5*0.858*integral(wfil,integr,wfil(0),	$
  			max(wfil))/(6.626e-27*2.998e18)
	effwav(ifilt)=integral(wfil,wfil^2*fstar*tfil,wfil(0),max(wfil))/ $
		integral(wfil,wfil*fstar*tfil,wfil(0),max(wfil))

	if keyword_set(plt) then begin
		pset
		!xtitle='WL (Ang)'
		!ytitle='FLUX & '+filt(ifilt)+' Throughput'
		good=where(tfil ge .001)
		plot,wfil(good),fstar(good)>0
		indx=where(tfil eq max(tfil))  &  indx=indx(0)
		oplot,wfil,tfil*max(fstar[good])/tfil(indx),lines=1
		plotdate,'synspz'
		if !d.name eq 'X' then read,st
		endif

; check to see if spectrum covers max of filter:
	indx=where(tfil eq max(tfil))  &  indx=indx[0]
	if wfil[indx] le min(wave) or wfil[indx] ge max(wave) then begin
		print,'*synspz-WARNING***',filt(ifilt),			$
			' Out of range. ***SYNSPZ e-/s set to -'
		effwav(ifilt)=0
		countrate=-countrate	; lower lim to count rate
		stop
		endif

; check that the spectrum covers enough of the filter:
	frst=ws(wfil,wave(0))
	last=ws(wfil,max(wave))
	if tfil(frst) gt 0.02*max(tfil) then begin
		print,'***synspz-WARNING***First wavelength of spec. too big:',$
							filt(ifilt),wfil(frst)
		effwav(ifilt)=0
		countate=-countrate
		endif
	if tfil(last) gt 0.01*max(tfil) then begin
		print,'***synspz-WARNING*** last WL of spec. too small for ', $
						filt(ifilt),' at ',max(wave)
; 2e-21 for LDS @ 30Mic:
		if fstar(n_elements(fstar)-1) gt 2e-21 then stop	
		countrate=-countrate
		endif
	endfor	
return,countrate
end
