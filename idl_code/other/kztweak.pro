function kztweak,teff,wl
;+
; INPUT
;	teff - Temp for adjustment computation. Must be in range 5650-6000,
;		as the 5750,6000K models are used to compute smooth gradient.
;	wl - wavelengths at which corr are computed. 
; OUTPUT
;	delta - correction vector to multiply the 5777K (2004) model by. For
;		WLs out of range delta=0.
; HISTORY
; 06mar16 - make small adjustments to the solar flux for small del-Teff
; both Kz 1993 & 2004 solar models have Teff=5777, log g=4.4377, log z=0
; see calib/kurucz.doc for list of avail 1993 models
; see calib/kztweak-test.pro for testing this method
;-

if teff lt 5650 or teff gt 6100 then begin
	print,'Teff out of range in kztweak'
	stop
	endif

; closest models in the grid from kurucz.doc are Teff=5750 & 6000K, logg=4.5
;	to the sun_1993 model at logg=4.44... all log z=0
; even tho kurucz interpol to any grid, use the native 1221 pts 4 smo,med filter
kurucz,wlorig,f57,5750,4.5,0
; elim out of range, undefined values to make median and smooth work right.
good=where(f57 gt 0)
wltmp=wlorig(good)  &  f57=f57(good)
old75=tin(wltmp,f57,7000,8000)			; norm to zero corr @ 7-8000K
kurucz,wltmp,flx,6000,4.5,0			;'interpolates' to specified WLs
flx=flx*old75/tin(wltmp,flx,7000,8000)
rat=(flx/f57-1)/250				; frac/K from 250K model grid
; make a smooth ratio (for correcting the good 2004 Kz solar model):
delta=wlorig*0
delta(good)=smooth(smooth(median(rat,31),11),11)*(teff-5777)+1
linterp,wlorig,delta,wl,delta
return,delta
end
