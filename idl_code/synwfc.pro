function synwfc,chip,wave,flux,effwav,plt=plt
;+
;
; PURPOSE:
;	Compute synthetic photometry for WFC3 filters
;
;	computed count rate = synwfc(wave,flux) in e-/sec
;
; INPUT
;	chip - wfc chip number (ie. 1 or 2)
;	wave - vac wavelength array of spectral flux distribution in ANG.
;	flux - spectral flux distribution
; OPTIONAL INPUT
;	plt - keyword to make plots
; OUTPUT
;	the result of the function in electrons/sec
;	effwav - effective wavelength optional output (optional)
; HISTORY
;	2012May10 - rcb/Jeff Dandoy  (cf. synspz, synacs.pro)
; COMMON means recompiling may not work. Exit idl and return to implmnt changes!
;-
st=''
common filtbp,wfilt,tfilt,nfil
if n_elements(wfilt) eq 0 then begin
	dir='~/calib/photom/'
	fil=findfile(dir+'*wfc')		; pairs of chip1, 2 that differ
	nfil=n_elements(fil)
	readcol,fil(0),dum,w,f
;all WFC3 files have the same WL scale from 1700-20000A at 1A spacing:
	tfilt=fltarr(n_elements(w),nfil)	
	for i=0,nfil-1 do begin
		readcol,fil(i),dum,wfilt,f
		tfilt(*,i)=f
		endfor
	endif

countrate=fltarr(nfil/2)  &  effwav=countrate
filt=['f336w','f410m','f467m','f547m']
nfilt=n_elements(filt)
for ifilt=0,nfilt-1 do begin				; do all filters
;	A(OTA)=45,239 cm2 from ACS Instr Handbook 6.2.1
;	hc=6.626e-27*3e18

	tfil=tfilt(*,ifilt*2+chip-1)	;chip 1 is files 0,2,4.. chip2: 1,3,5...
; use WL of filter for integral & if wave does not cover wfilt, set missing=0
	linterp,wave,flux,wfilt,fstar,missing=0
	integr=wfilt*fstar*tfil
	countrate(ifilt)=45239.*integral(wfilt,integr,wfilt(0),	$
  			max(wfilt))/(6.626e-27*2.998e18)
	effwav(ifilt)=integral(wfilt,wfilt^2*fstar*tfil,wfilt(0),max(wfilt))/ $
		integral(wfilt,wfilt*fstar*tfil,wfilt(0),max(wfilt))

	if keyword_set(plt) then begin
		pset
		!xtitle='WL (Ang)'
		!ytitle='FLUX & '+filt(ifilt)+' Throughput'
		good=where(tfil ge .001)
		plot,wfilt(good),fstar(good)>0
		indx=where(tfil eq max(tfil))  &  indx=indx(0)
		oplot,wfilt,tfil*max(fstar[good])/tfil(indx),lines=1
		plotdate,'synwfc'
		if !d.name eq 'X' then read,st
		endif

; check to see if spectrum covers max of filter:
	indx=where(tfil eq max(tfil))  &  indx=indx[0]
	if wfilt[indx] le min(wave) or wfilt[indx] ge max(wave) then begin
		print,'*synwfc-WARNING***',filt(ifilt),			$
			' Out of range. ***SYNWFC e-/s set to -'
		effwav(ifilt)=0
		countrate=-countrate	; lower lim to count rate
		stop			; and consider a fix
		endif

; check that the spectrum covers enough of the filter:
	frst=ws(wfilt,wave(0))		;index of first SED WL (0 for <1700A)
	last=ws(wfilt,max(wave))	;index of last SED WL (18300 @ >20,000A)
	if tfil(frst) gt 0.02*max(tfil) then begin
		print,'***synwfc-WARNING***First wavelength of spec. too big:',$
							filt(ifilt),wfilt(frst)
		effwav(ifilt)=0
		countate=-countrate
		endif
	if tfil(last) gt 0.01*max(tfil) then begin
		print,'***synwfc-WARNING*** last WL of spec. too small for ', $
						filt(ifilt),' at ',max(wave)
; 2e-21 for LDS @ 30Mic:
;?? 2016feb  Why?	if fstar(n_elements(fstar)-1) gt 2e-21 then stop	
		countrate=-countrate
		endif
	endfor	
return,countrate
end
