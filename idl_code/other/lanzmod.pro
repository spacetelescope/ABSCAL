pro lanzmod,teff,grav,zmetal,wav,flux,wrange=wrange
;+
; PURPOSE
;	interpolate Lanz & Hubeny OB models in T,G,Z
; INPUT
;	teff-model temperature
;	grav-log g
;	zmetal-log z
; OUTPUT
;	wav,flux-wavelength in Angstroms, flux in erg cm-2 s-1 A-1
; METHOD
;	Select the two models w/ lower Temp, the lower bracketing log g, and 2  
;	bracketing Z. Then interpolate to my Z. Repeat for upper bracketing g
;	and interpolate to my g for the lower temp. Repeat for the upper Temp
;	and I would have then the 2 bracketing temps w/ my g,z. then just
;	interpolate to my Temp... {Adaptation of marcsmod.pro}

;	See doc.lanzOB
; The ranges are: 15-30000K in 1000 K steps and from 32500-55000K in 2500K steps
;	Z/Zsun = 2,1,0.5,0.2,0.1 for Cloudy format
;	Z/Zsun = to -3 for Ostars also available but not implemented. 
;	alog10(Z/Zsun)= 0.301  0.000 -0.301 -0.70 -1.00 (5)
;	logg from 1.75 to 4.75 in 0,25 steps (13)
;HISTORY
;	2014Jun9 - RCB 
;-

nteff=26  &  ngrav=13  &  nz=5			; Cloudy uses  5 Z subset
tmin=15000.  &  gmin=1.75  &  zmin=-1.

if teff lt tmin or teff gt 55000 or grav lt gmin or grav gt 4.75 or		$
			zmetal lt zmin or zmetal gt 0.3 then begin
	if zmetal lt zmin then begin		; z OK but Teff or log g
		print,'***********WARNING: min Z=-1 or -3 and requested T,z',  $
			zmetal, ' is set to zmin for ',teff
		zmetal=-1.  &  if teff gt 30000. then zmetal=-3.
		endif
	if zmetal gt 0.3 then begin		; z OK but Teff or log g
		print,'***********WARNING: max Z=0.3 and requested T,z',  $
			zmetal, ' is set to zmax for ',teff
		zmetal=0.3
		endif
	endif
st=''
common dumlanz,wave,flxarr,modt,modg,modz
;  Read in the Cloudy format merged Lanz & Hubeny file for NLTE OB stars
   if n_elements(flxarr) gt 0 then goto,skipread
; models that I have
	modt=[indgen(16)*1000.+tmin,indgen(10)*2500.+32500.]
	modg=indgen(ngrav)*0.25+gmin
	modz=[-1,-0.7,-0.3,0,0.3]	; Cloudy subset of log Z/Zsun
	st=''
	close,5  &  openr,5,'~/models/lanzOB/umd-cloudy.mrg'
	for i=0,11 do readf,5,st			; skip 12 intro lines
	modlst=fltarr(3246)				;1082 models * 3 param
	readf,5,modlst
	freq=dblarr(19998)
	readf,5,freq
	mods=dblarr(19998,1082)				; freq units
	readf,5,mods
	print,'Lanz & Hubeny OB models read'
	wave=2.99792458d18/freq				; convert to WL units
	flam=mods					; WL units
	for i=0,1081 do flam(*,i)=2.99792458d18*mods(*,i)/wave^2
	flxarr=fltarr(19998,nteff,ngrav,nz)
	close,5
	for ifil=0,1081 do begin			; 1082 SEDs
		indx=ifil*3				; triplets of Teff, g, z
		temp=modlst(indx)
		logg=modlst(indx+1)
		z=modlst(indx+2)
		it=fix((temp-tmin)/1000.)		; temperature index
		if temp gt 30000 then it=fix((temp-32500.)/2500.)+16
		ig=fix((logg-gmin)/0.25)		; gravity index
		iz=where(z eq modz)
		iz=iz(0)				; possible models
		flxarr(*,it,ig,iz)=flam(*,ifil)
;if temp eq 32500 then print,temp,logg,z,it,ig,iz
		endfor
skipread:
; keep higher ind for exact grav cases, eg 3.5 intrp 3.5-3.75, NOT 3.25-3.5:
ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
ind=where(modg ge grav)  &  gind=ind(0)-1>0
; keep higher ind for exact grav cases, eg 3.5 intrp 3.5-4, NOT 3-3.5:
if grav eq modg(gind+1) then gind=(gind+1)<(ngrav-2)  &  glow=modg(gind)	; lower grav
ind=where(modz ge zmetal) & zind=ind(0)-1>0 & zlow=modz(zind)	; lower z

; trap common problem of grav out of lower range
if max(flxarr(*,tind+1,gind,zind)) le 0 then begin
	print,'Gravity out of range for',teff,grav,zmetal,' in Lanz',	$
		modt(tind:tind+1),modg(gind:gind+1),modz(zind:zind+1),	$
		form='(a,i6,2f6.3,a,2i6,4f6.3)'
	stop
	endif
;print,'Interpolating for ',teff,grav,zmetal,' in ',modt(tind:tind+1),	$
;	modg(gind:gind+1),modz(zind:zind+1),form='(a,i6,2f6.3,a,2i6,4f6.3)'
delz=modz(zind+1)-modz(zind)

; Interpolate for specified T,G,Z
fluxg=fltarr(19998,2)		; 2 models bracketing in log g
fluxt=fltarr(19998,2)		; 2 models bracketing in Teff

for it=0,1 do begin						; 2 temps
  for ig=0,1 do begin						; 2 gravities
  	flxlo=flxarr(*,it+tind,ig+gind,zind)
	if max(flxlo) le 0 then stop
	flxhi=flxarr(*,it+tind,ig+gind,zind+1)
	fluxg(*,ig)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/delz	; interp in z
 	endfor
  fluxt(*,it)=fluxg(*,0)+(fluxg(*,1)-fluxg(*,0))*(grav-glow)/0.25  ; interp in g
  endfor
delteff=1000.
if teff gt 30000 then delteff=2500.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
good=where(flux gt 0,ngood)
if ngood lt 1000 then begin
	print,teff,grav,zmetal,' Out of range in lanzmod'
	stop
	end
wav=wave
if keyword_set(wrange) then begin
	good=where(wav ge wrange(0) and wav le wrange(1))
	wav=wav(good)
	flux=flux(good)
	endif
return

end
