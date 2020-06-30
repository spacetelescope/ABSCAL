function synwfc,filter,chip,wave,flux,effwav,pivwl,efflux
;? compile_opt idl2
;+
;
; PURPOSE:
;	Compute synthetic photometry for WFC3 filters
;
;	computed count rate = synwfc(wave,flux) in e-/sec
;
; INPUT
;	fllter-WFC filter name
;	chip - UVIS chip number (ie. 1 or 2). Ignore for IR.
;	wave - vac wavelength array of spectral flux distribution in ANG.
;	flux - spectral flux distribution
; OUTPUT
;	the result of the function in electrons/sec
;	effwav - effective wavelength optional output (optional)
;	efflux - effective flux optional output (optional)
; HISTORY
;	2012May10 - rcb/Jeff Dandoy  (cf. synspz, synacs.pro)
;	2020mar11-out of date filters deleted & replace by ~/calib/photom/wfc3/*
;	2020apr17-WL scales now differ.. Forget Common block idea. RE-VAMP
;-
st=''
filter=strupcase(filter)
nfilts=n_elements(filter)
countrate=fltarr(nfilts) & effwav=countrate & pivwl=countrate & efflux=countrate
for ifilt=0,nfilts-1 do begin
	fil=findfile('~/wfc3/bp2018sep/'+filter(ifilt)+'*')
	if strpos(fil(0),'IR') gt 0 then				$
		readcol,fil(0),dum,wfilt,tfilt,/silent else begin
		readcol,fil(0),dum,wfilt,tfilt,w2,th2,/sil  ;UVIS has both chips
		if chip eq 2 then begin  &  wfilt=w2  &  tfilt=th2  &  endif
		endelse
; rm all but 1 leading & trailing zeroes in tfilt
	good=where(tfilt gt 0)
	good=[good(0)-1,good,good(-1)+1]
	wfilt=wfilt(good)  &  tfilt=tfilt(good)

; A(OTA)=45,239 cm2 from ACS Instr Handbook 6.2.1
; hc=6.626e-27*3e18

; use WL of filter for integral & if wave does not cover wfilt, set missing=0
	linterp,wave,flux,wfilt,fstar,missing=0
	integr=wfilt*fstar*tfilt
	countrate(ifilt)=45239.*integral(wfilt,integr,wfilt(0),		$
  			max(wfilt))/(6.626e-27*2.998e18)
	effwav(ifilt)=integral(wfilt,wfilt*integr,wfilt(0),max(wfilt))/ $
		integral(wfilt,integr,wfilt(0),max(wfilt))
	pivwl(ifilt)=sqrt(integral(wfilt,wfilt*tfilt,wfilt(0),max(wfilt))/ $
			integral(wfilt,tfilt/wfilt,wfilt(0),max(wfilt)))
	efflux(ifilt)=integral(wfilt,integr,wfilt(0),max(wfilt))/ 	$
			integral(wfilt,wfilt*tfilt,wfilt(0),max(wfilt))

; check to see if spectrum covers max of filter:
indx=where(tfilt eq max(tfilt))  &  indx=indx[0]
if wfilt[indx] le min(wave) or wfilt[indx] ge max(wave) then begin
	print,'*synwfc-WARNING***',filter,			$
			' Out of range. ***SYNWFC e-/s set to -'
	effwav=0  &  efflux=0
	countrate=-countrate	; lower lim to count rate
	stop			; and consider a fix
	endif

; check that the spectrum covers enough of the filter:
	frst=ws(wfilt,wave(0))		;index of first SED WL
	last=ws(wfilt,max(wave))	;index of last SED WL
	if tfilt(frst) gt 0.02*max(tfilt) then begin
		print,'***synwfc-WARNING***First wavelength of spec. too big:',$
							filt(ifilt),wfilt(frst)
		effwav=0
		countate=-countrate
		endif
	if tfilt(last) gt 0.01*max(tfilt) then begin
		print,'***synwfc-WARNING*** last WL of spec. too small for ', $
						filt(ifilt),' at ',max(wave)
		countrate=-countrate
		endif
	endfor	
return,countrate
end
