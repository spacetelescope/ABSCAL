pro mzmod,teff,grav,zmetal,wav,flux,blanket,cont,wrange=wrange
;+
; PURPOSE
;	interpolate Meszaros models & continuum in T,G,Z
; INPUT
;	teff-model temperature
;	grav-log g
;	zmetal-log z
; OUTPUT
;	wav,flux-wavelength in Angstroms, flux in erg cm-2 s-1 A-1
;	blanket-line blanketing as flux/contin (F/C).
;	cont - continuum
;HISTORY
; 2014Mar4-Initial implementation for  cp00: [C/M]=0, carbon abundance of model
;		 op00: [A/M]=0, alpha abundance of model
; GRID SUMMARY - see  absfluxcal1/doc.
; Common wl grid from 1000.8525A to 40 microns
; Log Z=[M/H]: -2.5 to 0.5 (0.25 dex steps) (13) + 0.75(amp08)* -->14
; Including hot model & lower grav for Solar comp ONLY:
; Teff:3500-12000 by 250K (35), 12500-20,000 by 500K (16), 21,000-35,000 by 
;	1000K (15), total 66 temps.
; Log g: 0-5 3500-6000K (11), 1-5 6250-8000K (9), 2-5 8250-12000K (7),
;	3-5 12500-20,000K (5), 3-5 21000-28,000K (5),
;	3.5-5 29000-34000K (4), 4-5 @ 35000 (3). All have steps of 0.5
; 2014Mar7 - Fully cked w/ hand interpol. for 8125K, G=3.75, Z=-.125
; 2016dec19-Sw from single to double samp/resel models.
; 2018nov15-Add the 'new' hi-metal amp08* files, which are missing the hotter
;	>30000K models.
; 2020apr2-Several 3500K models are missing, eg amm20cp00op00t3500g30* to 40*,
;	so avoid the teff=3500k region
; 2020apr3 - upgrade out of limit checks
;-

nteff=66  &  ngrav=11  &  nz=14			;2018nov15 13-->14
tmin=3500.  &  gmin=0.  &  zmin=-2.5
;2018nov15 - zmax .5-->.75
if teff lt tmin or teff gt 35000. then begin				;2020apr
	print,'***********WARNING:',teff,'=requested Teff is out '+	$
		'of 3500-35000K range & is set to limit in mzmod.pro'
	if teff lt 3500 then teff=3500. else teff=35000.
	endif
if zmetal lt -2.5 or zmetal gt 0.75 then begin
	print,'***********WARNING:',zmetal,'=requested zmetal is out '+	$
		'of -2.5 to 0.75 range & is set to limit in mzmod.pro'
	if zmetal lt -2.5 then zmetal=-2.5 else zmetal=0.75
	endif
gmn=0.
if teff gt 6000 then gmn=1.
if teff gt 8000 then gmn=2.
if teff gt 12000 then gmn=3.
if teff gt 28000 then gmn=3.5
if teff gt 34000 then gmn=4.
if grav lt gmn or grav gt 5 then begin
	print,'***********WARNING:',string(grav,'(f5.2)')+		$
		'=requested grav is out of '+				$
		string(gmn,'(f3.1)')+' to 5 range & is set to limit in mzmod'
		if grav lt gmn then grav=gmn else grav=5.
		endif
; ff fails. Avoid low Teff near 3500K & do not use prefind w/ cool stars.
;if teff lt 3750 then begin			; several 3500K models missing
;	print,'Missing models at 3500K, set teff=4000' ; i use the lower 3750
;	teff=3750.
;	endif
st=''
common dummz,wave,flxarr,contarr
if n_elements(flxarr) gt 0 then goto,skipread
	flxarr=fltarr(5769,nteff,ngrav,nz)			; v2-double  "
	contarr=flxarr
;obsolete  	files=findfile('~/models/mzgrid-solar/am*')
  	files=file_search('~/models/mzgrid-solar/am*')
	fdecomp,files,disk,dir,file
	for ifil=0,n_elements(file)-1 do begin
		fil=file(ifil)
		rdfloat,files(ifil),wave,flx,cont,/silent
		siz=size(wave)
; ###change to be tidy when I get all of v2:
		if siz(1) ne 5769 then stop	; ck for bad old-v1 to 40mic
		zst=strmid(fil,3,2)
		logz=float(zst)/10
		if strmid(zst,1,1) eq '3' or strmid(zst,1,1) eq '8'	$
							then logz=logz-.05
		minus=strmid(fil,2,1)
		if minus eq 'm' then logz=-logz
		dum=gettok(fil,'t')
		temp=float(gettok(fil,'g'))
		logg=float(strmid(fil,0,2))/10
		it=fix((temp-tmin)/250.)		; temperature index
		if temp gt 12000 then it=fix((temp-12000.)/500.)+34
		if temp gt 20000 then it=fix((temp-20000.)/1000.)+50
		ig=fix((logg-gmin)/0.5)			; gravity index
		iz=fix((logz-zmin)/.25)
		flxarr(*,it,ig,iz)=flx
		contarr(*,it,ig,iz)=cont
		endfor				; end common filling
; a missing model is teff,logg,logz=12000.0 (34)   4.50000 (9)  -1.25000 (5)
;	i.e. amm13cp00op00t12000g45v20modrt0b500rs.asc
;approx,single interpol:
	flxarr(*,34,9,5)=(flxarr(*,34,9,4)+flxarr(*,34,9,6))/2
	contarr(*,34,9,5)=(contarr(*,34,9,4)+contarr(*,34,9,6))/2
skipread:

; models that I have:
modt=[indgen(35)*250.+tmin,indgen(16)*500.+12500.,indgen(15)*1000.+21000.]
modg=indgen(ngrav)*0.5+gmin
modz=indgen(nz)*.25+zmin

ind=where(modg ge grav)  &  gind=ind(0)-1>0  &  glow=modg(gind) ; lower grav
if glow lt gmn then begin			; keep grav in range:
	glow=gmn  &  ind=where(modg ge glow)  &  gind=ind(0)  &  endif
ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
; lower metals 2016Jul14 mod:
ind=where(modz ge (zmetal<modz(nz-2))) & zind=ind(0)-1>0  &  zlow=modz(zind) 
;print,'Interpolating for',modt(tind:tind+1),modg(gind:gind+1),modz(zind:zind+1)
delz=0.25

fluxg=fltarr(5769,2)		     ; 2 models bracketing in log g
fluxt=fltarr(5769,2)		     ; 2 models bracketing in Teff
contg=dblarr(5769,2)		     ; 2 models bracketing in log g
contt=dblarr(5769,2)		     ; 2 models bracketing in Teff

; Interpolate for specified T,G,Z
for it=0,1 do begin						; 2 temps
  for ig=0,1 do begin						; 2 gravities
  	flxlo=flxarr(*,it+tind,ig+gind,zind)
	flxhi=flxarr(*,it+tind,ig+gind,zind+1)
; Trap bad models:
	if max(flxlo) le 0 or max(flxhi) le 0 then begin
		if max(flxlo) le 0 then zbad=zind else zbad=zind+1
 		print,'Zero flux for Teff,log g, log z=',		$
			modt(it+tind),modg(ig+gind),modz(zbad)
; a missing model is teff,logg,logz=12000.0 (34)   4.50000 (9)  -1.25000 (5)
;	i.e. amm13cp00op00t12000g45v20modrt0b500rs.asc

		stop
		endif
	fluxg(*,ig)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/delz	; interp in z
 	cntlo=contarr(*,it+tind,ig+gind,zind)
	cnthi=contarr(*,it+tind,ig+gind,zind+1)
	contg(*,ig)=cntlo+(cnthi-cntlo)*(zmetal-zlow)/delz	; interp in z
	if max(flxlo) le 0 and round(2*(grav-glow)) ne 1 then begin
		fluxg(*,ig)=fluxg(*,ig)+1e20		;2017Jan14
		contg(*,ig)=contg(*,ig)+5e20		;  -make big chisq
		endif
 	endfor						; end ig=0,1
  fluxt(*,it)=fluxg(*,0)+(fluxg(*,1)-fluxg(*,0))*(grav-glow)/0.5 ; interp in g
  contt(*,it)=contg(*,0)+(contg(*,1)-contg(*,0))*(grav-glow)/0.5 ; interp in g
  endfor						; end it=0,1
delteff=250.
if teff gt 12000 then delteff=500.
if teff gt 20000 then delteff=1000.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
cont=contt(*,0)+(contt(*,1)-contt(*,0))*(teff-tlow)/delteff	; interp in Teff
; 2014mar-catch out of range:
;good=where(flux gt 0 and flxarr(*,tind,gind,zind) gt 0,ngood)
; 2016mar14-15000k,logg=3,uses out of range glow=2.5, where flxarr=0; BUT is OK.
good=where(flux gt 0,ngood)
wav=wave
if ngood lt 100 then begin
	print,'REQUESTED MZMOD IS OUT OF GRID'
	print,teff,grav,zmetal,' mzmod low interp mods=',tlow,glow,zlow
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
