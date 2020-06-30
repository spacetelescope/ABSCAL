pro raumod,teff,grav,wav,flux,blanket,cont,wrange=wrange
;+
; PURPOSE
;	interpolate Rauch pure HI WD models & continuum in T,G
; INPUT
;	teff-model temperature
;	grav-log g
; OUTPUT
;	wav,flux-wavelength in Angstroms, flux in erg cm-2 s-1 A-1
;	blanket-line blanketing as flux/contin (F/C).
;	cont - continuum
;HISTORY
; 2019may24-rcb
; GRID SUMMARY - see /astro/absfluxcal2/rauch/doc.
; Common wl grid from 900A to 30 microns w/ higher sampling in lines, but varies
;	wildly from R=10,0000 up to 5e7 even in the continuum!?
; Grid is 20,000--95,000K, by 2000K to 40,000, then by 5000k. 
; 	log g=7--9.5 by 0.5 (132 files) w/ vacuum WLs. 900A--30mic
;       Rauch suggests that convection is not incl by Hubeny
;	& that detlev Koester has better LTE cool (Teff<20,000K) models
;-

nteff=22  &  ngrav=6		; skip the 0.25 log g increments at <=18000K
tmin=20000.  &  gmin=7.

if teff gt 95000. then begin
	print,'***********WARNING: max Teff=95,000K and requested ',$
			teff, ' is set to 95000K in raumod.pro'
	teff=95000.
	endif
if grav gt 9.5 then begin
	print,'***********WARNING: max grav=9.5 and requested ',$
			grav, ' is set to 9.5 in raumod.pro'
	grav=9.5
	endif
st=''
common dummrau,wave,flxarr,contarr
if n_elements(flxarr) gt 0 then goto,skipread
	flxarr=dblarr(144795,nteff,ngrav)
	contarr=flxarr
  	files=file_search('/astro/absfluxcal2/rauch/grid/*')
	fdecomp,files,disk,dir,file
	for ifil=0,n_elements(file)-1 do begin
		fil=file(ifil)
		rdfloat,files(ifil),wave,flx,blank,cont,/silent,skipl=38,/double
;print,'model #=',ifil,' of',n_elements(file)
		siz=size(wave)
		if siz(1) ne 144795 then stop	; idiot ck
		temp=float(strmid(fil,2,5))
		logg=float(strmid(fil,8,4))
		it=fix((temp-tmin)/2000.)		; temperature index
		if temp gt 40000 then it=fix((temp-40000.)/5000.)+10
		ig=fix((logg-gmin)/0.5)		; gravity index
		flxarr(*,it,ig)=flx
		contarr(*,it,ig)=cont
; if ig eq 5 then begin print,it,ig,temp,logg   &  read,st  & endif
		endfor				; end common block filling
skipread:

; models that I have:
modt=[indgen(10)*2000.+20000.,indgen(12)*5000.+40000.]
modg=indgen(ngrav)*0.5+gmin

ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
ind=where(modg ge grav)  &  gind=ind(0)-1>0  &  glow=modg(gind) ; lower grav
;print,'Interpolating for ',modt(tind:tind+1),modg(gind:gind+1)

fluxg=dblarr(144795,2)	    ; 2 models bracketing in log g
fluxt=dblarr(144795,2)	    ; 2 models bracketing in Teff
contg=dblarr(144795,2)	    ; 2 models bracketing in log g
contt=dblarr(144795,2)	    ; 2 models bracketing in Teff

; Interpolate for specified T,G
for it=0,1 do begin						; 2 temps
  	flxlo=flxarr(*,it+tind,gind)
	flxhi=flxarr(*,it+tind,gind+1)
 	cntlo=contarr(*,it+tind,gind)
	cnthi=contarr(*,it+tind,gind+1)
; trap missing models
	if max(flxlo) le 0 or max(flxhi) le 0 then stop
;?	if max(flxlo) le 0 and round(2*(grav-glow)) ne 1 then begin
;?		fluxg(*,ig)=fluxg(*,ig)+1e20		; 2017Jan14
;?		contg(*,ig)=contg(*,ig)+5e20		;  -make big chisq
;?		endif
	fluxt(*,it)=flxlo+(flxhi-flxlo)*(grav-glow)/0.5	; interpol in g
	contt(*,it)=cntlo+(cnthi-cntlo)*(grav-glow)/0.5	; interpol in g
	endfor
delteff=2000.
if teff gt 40000 then delteff=5000.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
cont=contt(*,0)+(contt(*,1)-contt(*,0))*(teff-tlow)/delteff	; interp in Teff
wav=wave
; catch out of range:
good=where(flux gt 0,ngood)
if ngood lt 100 then begin
	print,'REQUESTED model IS OUT OF Rauch GRID'
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
