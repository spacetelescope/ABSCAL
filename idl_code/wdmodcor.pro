pro wdmodcor,head,nam,wstar,fstar,wmod,fmod,cont,ebv,teff,logg,type=type
;+
;
; PURPOSE:
;	create a reddened pure hyd Rauch model flux & continuum
;		normalize to the wstar,fstar input flux @ 68-7700A
;
; INPUT
;	nam - star name
;	wstar - vac wavelength array of obs. spectral flux distribution in ANG.
;		if not an array, then do not normalize.
;	fstar - observed spectral flux distribution
; INPUT/output
;	head  - header
; OUTPUT
;	wmod - wavelengths w/ minmax=900A-30mic
;	fmod - flux, reddened
;	cont - continuum, reddened
;	ebv - E(B-V)
;	teff - effective temperature
;	logg - surface gravity
; HISTORY
;	2020feb8 - rcb
;	2020mar12 - add keyword for Hubeny option
;	2020mar31 - add header to .pro arguments & write normalizing WLs & value
;-

vmg=vmag(nam,ebv,spty,bvri,teff,logg,logz,model='rauch')	; ok for grw
if type eq 'hub' then							$
    hubmod,teff,logg,wmod,fmod,blanket,cont,wrange=[900,320000] else	$
    raumod,teff,logg,wmod,fmod,blanket,cont,wrange=[900,300000]
chiar_red,wmod,fmod,-(ebv),fmod
chiar_red,wmod,cont,-(ebv),cont
; 2020feb10 - Match norm range to make_stis_calspec:
if nam eq 'wd1657_343' then begin			; wd1650 BAD at 68-7700A
	mnwl=1730  &  mxwl=3020
     end else begin
	mnwl=6800  &  mxwl=7700
	endelse
norm=tin(wstar,fstar,mnwl,mxwl)/tin(wmod,fmod,mnwl,mxwl)
sxaddhist,'Model Normalized to obs. by'+string(norm,'(e12.5)')+' at '+     $
		string([mnwl,mxwl],"(f6.1,'-',f6.1,' Ang')"),head
fmod=fmod*norm
cont=cont*norm

end
