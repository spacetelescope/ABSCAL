pro hubmod,teff,grav,wav,flux,blanket,cont,wrange=wrange
;+
; PURPOSE
;	interpolate Hubeny pure HI WD models & continuum in T,G
; INPUT
;	teff-model temperature
;	grav-log g
; OUTPUT
;	wav,flux-wavelength in Angstroms, flux in erg cm-2 s-1 A-1
;	blanket-line blanketing as flux/contin (F/C).
;	cont - continuum
;HISTORY
; 2019may22-rcb
; GRID SUMMARY - see /astro/absfluxcal2/hubeny/doc.
; Common wl grid from 900A to 32 microns at R=5000
; Grid is 10,000--95,000K, by 1000 to 20,000K by 2000 to 40,000, then by 5000k. 
; 	log g=7--9.5 by 0.5 (242 files) w/ vacuum WLs. 900A--32mic
;       At 10000-18000K, log g is 7--9.5 by 0.25) but Rauch suggests that
;	convection is not incl & that detlev Koester has better cool models;
;	AND grid must be uniform in log g, so skip the .25 increments,
;	leaving 242-50 = 192 files (vs. 132 for Rauch, who skips 10-18,000K).
; 2019aug20 - above orig grid moved to /astro/absfluxcal2/hubeny-olddel/
;	new grid see wd/newhub-rau/hubeny/doc.:
; T_eff between 20,000 and 95,000 K, with a step:
;     2,000 K between 20 and 40 kK, and
;     5,000 K between 40 and 95 kK
; log g between 7.0 and 9.5, with a step 0.5.
; All models are NLTE models, computed with tlusty207.
; The spectra cover the wavelength range from 900 A to 32 microns,
;	with a resolution R=5000 (i.e. delta(lambda)/lambda = 1/5000).
; For each pair of (T_eff, log g), there are two files:
;	*.spec - a detailed spectrum at R=5000,
;	*.cont - a theortical continuum (with a lower resolution)
;-

; old nteff=32  &  ngrav=6	; skip the 0.25 log g increments at <=18000K
; old tmin=10000.  &  gmin=7.
nteff=22  &  ngrav=6		; 2019aug20 - new
tmin=20000.  &  gmin=7.

if grav gt 9.5 then begin
	print,'***********WARNING: max grav=9.5 and requested ',$
			grav, ' is set to 9.5 in hubmod.pro'
	grav=9.5
	endif
if teff lt tmin then begin					; 3020mar9
	print,'***********WARNING: min teff=20000 and requested ',$
			teff, ' is set to 20000 in hubmod.pro'
	teff=20000.
	endif
	
st=''
common dummhub,wave,flxarr,contarr
if n_elements(flxarr) gt 0 then goto,skipread
	flxarr=dblarr(29712,nteff,ngrav)
	contarr=flxarr
; old  	files=file_search('/astro/absfluxcal2/hubeny/grid/*.mrgspec')
  	files=file_search('/astro/absfluxcal2/hubeny/grid/*.spec')
; old	good=where(strpos(files,'5n.') lt 0)
; old	help,files,good
; old	files=files(good)		; skip .025 log g increm. at <20000K
	fdecomp,files,disk,dir,file
	for ifil=0,n_elements(file)-1 do begin
		fil=file(ifil)
		rdfloat,files(ifil),wave,flx,/silent
		siz=size(wave)
		if siz(1) ne 29712 then stop	; idiot ck
		temp=float(strmid(fil,1,3))*100
		logg=float(strmid(fil,5,3))/100
; old		it=fix((temp-tmin)/1000.)		; temperature index
		it=fix((temp-tmin)/2000.)		; temperature index
; old		if temp gt 20000 then it=fix((temp-20000.)/2000)+10
; old		if temp gt 40000 then it=fix((temp-40000.)/5000.)+20
		if temp gt 40000 then it=fix((temp-40000.)/5000.)+10
		ig=fix((logg-gmin)/0.5)		; gravity index
		flxarr(*,it,ig)=flx

; old		cfile=replace_char(files(ifil),'mrgspec','mrgcont')
		cfile=replace_char(files(ifil),'spec','cont')
		rdfloat,cfile,cwave,cflx,/silent
		linterp,cwave,cflx,wave,cont
		contarr(*,it,ig)=cont
; if ig eq 5 then begin print,it,ig,temp,logg   &  read,st  & endif
		endfor				; end common block filling
skipread:

; models that I have:
;oldmodt=[indgen(10)*1000.+tmin,indgen(10)*2000.+20000.,indgen(12)*5000.+40000.]
modt=[indgen(10)*2000.+20000.,indgen(12)*5000.+40000.]
modg=indgen(ngrav)*0.5+gmin

ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
ind=where(modg ge grav)  &  gind=ind(0)-1>0  &  glow=modg(gind) ; lower grav
;print,'Interpolating for ',modt(tind:tind+1),modg(gind:gind+1)

fluxg=dblarr(29712,2)		 ; 2 models bracketing in log g
fluxt=dblarr(29712,2)		 ; 2 models bracketing in Teff
contg=dblarr(29712,2)		 ; 2 models bracketing in log g
contt=dblarr(29712,2)		 ; 2 models bracketing in Teff

; Interpolate for specified T,G
for it=0,1 do begin						; 2 temps
  	flxlo=flxarr(*,it+tind,gind)
	flxhi=flxarr(*,it+tind,gind+1)
 	cntlo=contarr(*,it+tind,gind)
	cnthi=contarr(*,it+tind,gind+1)
; trap missing models:
	if max(flxlo) le 0 or max(flxhi) le 0 then stop

	fluxt(*,it)=flxlo+(flxhi-flxlo)*(grav-glow)/0.5	; interpol in g
	contt(*,it)=cntlo+(cnthi-cntlo)*(grav-glow)/0.5	; interpol in g
	endfor
; old delteff=1000.
delteff=2000.
; old if teff gt 20000 then delteff=2000.
if teff gt 40000 then delteff=5000.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
cont=contt(*,0)+(contt(*,1)-contt(*,0))*(teff-tlow)/delteff	; interp in Teff
wav=wave
; catch out of range:
good=where(flux gt 0,ngood)
if ngood lt 100 then begin
	print,'REQUESTED model IS OUT OF Hubeny GRID'
	print,teff,grav,' low limits=',tlow,glow
	stop
	end
if keyword_set(wrange) then begin
	good=where(wav ge wrange(0) and wav le wrange(1))
	wav=wav(good)
	flux=flux(good)
	cont=cont(good)
	endif
blanket=flux/cont
return

end
