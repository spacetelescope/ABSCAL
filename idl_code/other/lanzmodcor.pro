pro lanzmodcor,nam,wstar,fstar,wmod,fmod,ebv,teff,logg,logz
;+
;
; PURPOSE:
;	create a corrected Lanz model w/ param as pub in BOSZ paper 
;		and norm to the wstar,fstar input flux @ 6800-7700A-2020feb
;
; INPUT
;	nam - star name
;	wstar - vac wavelength array of obs. spectral flux distribution in ANG.
;		if not an array, then do not normalize.
;	fstar - observed spectral flux distribution
; OUTPUT
;	wmod - wavelengths w/ min WL=2002A
;	fmod - flux
;	ebv - E(B-V)
;	teff - effective temperature
;	logg - surface gravity
;	logz - metallicity
; HISTORY
;	17jan31 - rcb
;-

vmg=vmag(nam,ebv,spty,bvri,teff,logg,logz,model='lanz')
lanzmod,teff,logg,logz,wmod,fmod,wrange=[1000,32e4]
chiar_red,wmod,fmod,-(ebv),fmod
if n_elements(wstar) gt 1 then						$
	fmod=fmod*tin(wstar,fstar,6800,7700)/tin(wmod,fmod,6800,7700)
end
