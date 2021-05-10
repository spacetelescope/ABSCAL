pro bosz3e5,teff,grav,zmetal,wav,flux,cont,wrange=wrange
;+
; PURPOSE
;	interpolate Mz flux & continuum in T,G,Z for R=300,000, 1 samp/resel
; INPUT
;	teff-model temperature
;	grav-log g
;	zmetal-log z
; OUTPUT
;	wav,flux-wavelength in Angstroms, flux in erg cm-2 s-1 A-1
;	cont - continuum
;HISTORY
; 2016dec27-implement for  cp00: [C/M]=0, carbon abundance of model
;		 op00: [A/M]=0, alpha abundance of model
; Adopted from mzmod.pro
; GRID SUMMARY - see  absfluxcal1/doc.
; Common wl grid from 1000.8525A to 32 microns
; Including hot model & lower grav for Solar comp ONLY:
; Teff:3500-12000 by 250K (35), 12500-20,000 by 500K (16), 21,000-35,000 by 
;	1000K (15), total 66 temps.
; Log g: 0-5 by 0.5 3500-6000K (11), 1-5 by 0.5 6250-8000K (9), 2-5 by 0.5 8250-
;	12000K (7), 3-5 12500-20,000K (5), 3-5 by 0.5 21000-28,000K (5),
;	3.5-5 29000-34000K (4), 4-5 @ 35000 (3)
; Log Z=[M/H]: -2.5 to 0.5 (0.25 dex steps) (13)
; 130 GB arr is too big to allocate for all the models, so read them, as needed.
;-

nteff=66  &  ngrav=11  &  nz=13
tmin=3500.  &  gmin=0.  &  zmin=-2.5

if teff lt tmin or teff gt 35000. or grav lt gmin or grav gt 5 or	$
			zmetal lt zmin or zmetal gt 0.5 then 		$
	if zmetal lt -2.5 then begin
		print,'***********WARNING: min Z=-2.5 and requested ',	$
			zmetal, ' is set to -2.5 in mzmod.pro'
		zmetal=-2.5
		endif
	if grav gt 5 then begin
		print,'***********WARNING: max grav=5 and requested ',	$
			grav, ' is set to 5 in mzmod.pro'
		grav=5.
		endif
; models that I have:
modt=[indgen(35)*250.+tmin,indgen(16)*500.+12500.,indgen(15)*1000.+21000.]
modg=indgen(ngrav)*0.5+gmin
modz=indgen(nz)*.25+zmin

ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
ind=where(modg ge grav)  &  gind=ind(0)-1>0  &  glow=modg(gind) ; lower grav
; lower metals 2016Jul14 mod:
ind=where(modz ge (zmetal<modz(nz-2))) & zind=ind(0)-1>0  &  zlow=modz(zind) 
print,'Interpolating for ',modt(tind:tind+1),modg(gind:gind+1),modz(zind:zind+1)
delz=0.25

fluxg=fltarr(1730499,2)		     ; 2 models bracketing in log g
fluxt=fltarr(1730499,2)		     ; 2 models bracketing in Teff
contg=dblarr(1730499,2)		     ; 2 models bracketing in log g
contt=dblarr(1730499,2)		     ; 2 models bracketing in Teff

; Interpolate for specified T,G,Z
for it=0,1 do begin						; 2 temps
  for ig=0,1 do begin						; 2 gravities
  	two3e5,modt(it+tind),modg(ig+gind),modz(zind),wave,		$
						flxlo,flxhi,cntlo,cnthi
;	if ig eq 0 and it eq 0 then plot,wave,flxlo,xr=[4830,4900] else	$
;				    oplot,wave,flxlo
;	oplot,wave,flxhi
	fluxg(*,ig)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/delz	; interp in z
 	contg(*,ig)=cntlo+(cnthi-cntlo)*(zmetal-zlow)/delz	; interp in z
 	endfor
  fluxt(*,it)=fluxg(*,0)+(fluxg(*,1)-fluxg(*,0))*(grav-glow)/0.5 ; interp in g
  contt(*,it)=contg(*,0)+(contg(*,1)-contg(*,0))*(grav-glow)/0.5 ; interp in g
  endfor
delteff=250.
if teff gt 12000 then delteff=500.
if teff gt 20000 then delteff=1000.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
cont=contt(*,0)+(contt(*,1)-contt(*,0))*(teff-tlow)/delteff	; interp in Teff
; 2016mar14-15000k,logg=3,uses out of range glow=2.5, where flxarr=0; BUT is OK.
good=where(flux gt 0,ngood)
wav=wave
if keyword_set(wrange) then begin
	good=where(wav ge wrange(0) and wav le wrange(1))
	wav=wav(good)
	flux=flux(good)
	cont=cont(good)
	endif
;oplot,wav,flux,th=3,lin=2
return

end
