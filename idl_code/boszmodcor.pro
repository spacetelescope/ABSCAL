pro boszmodcor,nam,wstar,fstar,wmod,fmod,cont,ebv,teff,logg,logz,hires=hires
;+
;
; PURPOSE:
;	create a dereddened BOSZ model w/ param as pub in BOSZ paper 
;		and normalize to the wstar,fstar input flux @ 6-9000A
;
; INPUT
;	nam - star name
;	wstar - vac wavelength array of obs. spectral flux distribution in ANG.
;		if not an array, then do not normalize.
;	fstar - observed spectral flux distribution
;	/hires-get R=300,000 model.
; OUTPUT
;	wmod - wavelengths w/ min WL=2002A for R=500 & min=1000A for R=300,000
;	fmod - flux
;	cont - continuum
;	ebv - E(B-V)
;	teff - effective temperature
;	logg - surface gravity
;	logz - metallicity
; HISTORY
;	2017jan31 - rcb
;	2017mar21 - add continuum
;-

vmg=vmag(nam,ebv,spty,bvri,teff,logg,logz,model='mz')
if keyword_set(hires) then bosz3e5,teff,logg,logz,wmod,fmod,cont,	$
						wrange=[1000,3.2e5]	$
	 else mzmod,teff,logg,logz,wmod,fmod,bldum,cont,wrange=[2002,3.2e5]
chiar_red,wmod,fmod,-(ebv),fmod
if n_elements(wstar) gt 1 then begin
	norm=tin(wstar,fstar,6000,9000)/tin(wmod,fmod,6000,9000)
	fmod=fmod*norm
	cont=cont*norm
	endif
good=where(wmod le 319000.)	; 2019aug - elim bad pts
wmod=wmod(good)  &  fmod=fmod(good)
end
