function synnic,wave,flux,effwav,plt=plt
;+
;
; PURPOSE:
;	Compute synthetic photometry for Nicmos filters
;
;	computed count rate = synwfc(wave,flux) in e-/sec
;
; INPUT
;	wave - vac wavelength array of spectral flux distribution in ANG.
;	flux - spectral flux distribution
; OPTIONAL INPUT
;	plt - keyword to make plots
; OUTPUT
;	the result of the function in ADU for Nic2 Gain=5.4. (NIC1,3 G=5.4,6.5)
;	effwav - effective wavelength optional output (optional)
; HISTORY
;	2012May11 - rcb/Emilia Gold  (cf. synwfc, synspz, synacs.pro)
; COMMON means recompiling may not work. Exit idl and return to implmnt changes!
;-
st=''
common filtbp,wfilt,tfilt,nfil
; works for only one camera (nic2)
if n_elements(wfilt) eq 0 then begin
;	dir=				; runs only in calib/photom
	fil=findfile('total*.fits')
	nfil=n_elements(fil)
	wfilt=fltarr(10000,nfil)
	tfilt=wfilt
	for i=0,nfil-1 do begin
		z=mrdfits(fil(i),1,hd)
		wfilt(*,i)=z.wavelength
		tfilt(*,i)=z.throughput
		endfor
	endif

countrate=fltarr(nfil)  &  effwav=countrate
filt=['f110w','f160w','f205w']
nfilt=n_elements(filt)
for ifilt=0,nfilt-1 do begin
;	A(OTA)=45,239 cm2 from ACS Instr Handbook 6.2.1
;	hc=6.626e-27*3e18
	wfil=wfilt(*,ifilt)
	tfil=tfilt(*,ifilt)
; use WL of filter for integral & if wave does not cover wfil, set missing=0
	linterp,wave,flux,wfil,fstar,missing=0
	integr=wfil*fstar*tfil
	countrate(ifilt)=45239.*integral(wfil,integr,wfil(0),	$
  			max(wfil))/(6.626e-27*2.998e18)/5.4	; ADU for G=5.4
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
		xyouts,.2,.15,'Filter Max='+string(max(tfil),'(f5.3)'),/norm
		plotdate,'synwfc'
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
