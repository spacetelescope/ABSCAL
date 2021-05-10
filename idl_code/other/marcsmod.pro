pro marcsmod,teff,grav,zmetal,wav,flux,wrange=wrange
;+
; PURPOSE
;	interpolate MARCS models in T,G,Z
; INPUT
;	teff-model temperature
;	grav-log g
;	zmetal-log z
; OUTPUT
;	wav,flux-wavelength in Angstroms, flux in erg cm-2 s-1 A-1
; METHOD

;    DJL: Your interpolation for the full resolution models sounds like exactly
;	      what I do in model_int and should be a good check for the routine.
;
;	Select the two models w/ lower Temp, the lower bracketing log g, and 2  
;	bracketing Z. Then interpolate to my Z. Repeat for upper bracketing g
;	and interpolate to my g for the lower temp. Repeat for the upper Temp
;	and I would have then the 2 bracketing temps w/ my g,z. then just
;	interpolate to my Temp... 

;HISTORY
; 2013Mar12-Convert to read whole grid of std compos. See doc.marcs &
;								ck04blanket.pro
; The ranges are: 2500-4000K in 100K steps and from 4-8000K in 250K steps
;	G: -0.5 to 5.5 in 0.5 steps, Z: -5 to 1 for std comp in various steps.
; 2016Aug2-However, the 5.5 G is only up to 3900K. So set ngrav=12 below.
;----> However, the pp only goes down to G=3. 
; The only overlap is at G=3.0,3.5 so I may as well get spher. up to G=3.5 Get
; microturb=2, mass=1, std compos. Download basket seems to have a 100 model
; limit, so just get spher from G=-0.5 to 3.5, & pick up PP at G=4, 4.5, 5.0. 
; Skip Z=+/- 0.25, 0.75. So Z steps are 0.5 from -3. to +1; and -5,-4.

; 2016nov21-pp of G=4,4.5,5 are OK at 5500,5750,7000K
;PROBLEMS #1 at Teff=7000K printout: 
;	at g=3.5 pp at z=-1.5,-4,-5 & also a Spher @-1.5.No Z of 0,.5,1,-4,-5
;		(agrees w/ new website search 2016nov22, except there is a -5)
;		[The two spher & pp match to 0.2,0.4% from 3000A-1,2.5mic]
;	at g=3.0 have only Spher but no Z of -1,-4,-5
;		(agrees w/ new website search 2016nov22)
;	at g=2.5 only Spher but no Z of -4 to -1.5, no -0.5 (only have 5 of 11)
;	at g=2.0 have all 11 Spher - OK
;	at g=1.5, no Z of -3, -4, -5
; 	no G=-0.5 to 1.0 at all for 7000K. Hottest G=-.5 is 4250K.

; However, the pp looks more complete for G=3.0 & 3.5, so replace those spher w/
;	pp on 2016Nov23. Save current marcs_package/ to marcs_package-spher/

;PROBLEMS#2-Chisq jumps at transition from neg to pos Z. OK-see plots/marcseval.ps

;-

nteff=32  &  ngrav=12  &  nz=11		;2016aug2-complete to only logg=5.0
tmin=2500.  &  gmin=-0.5  &  zmin=-5.

teff=teff<8000.				; 2016AUG11 	- TRY
if teff lt tmin or teff gt 8000 or grav lt gmin or grav gt 5.0 or		$
			zmetal lt zmin or zmetal gt 1 then 		$
	if zmetal ge -5 then stop else begin
		print,'***********WARNING: min Z=-5 and requested ',	$
			zmetal, ' is set to -5
		zmetal=-5.
		endelse
st=''
common dummarc,wave,flxarr
   if n_elements(flxarr) gt 0 then goto,skipread
	readcol,'~/models/marcs_package/wavelengths.vac',wave,/silent
	flxarr=fltarr(100724,nteff,ngrav,nz)
	flx=fltarr(100724)
  	files=[file_search('~/models/marcs_package/p*'),		$
			file_search('~/models/marcs_package/s*')]	;allmods
	fdecomp,files,disk,dir,file
	for ifil=0,n_elements(file)-1 do begin
		fil=file(ifil)
		temp=gettok(fil,'_')
		temp=fix(strmid(temp,1,4))
		logg=gettok(fil,'_m')
		logg=float(strmid(logg,1,4))
		if logg ge 5.5 then goto,no55		;2016aug2-5.5 incomplete
		logz=gettok(fil,'_z')
		logz=gettok(fil,'_a')
		logz=float((strmid(logz,1,5)))
		it=fix((temp-tmin)/100.)		; temperature index
		if temp gt 4000 then it=fix((temp-4000.)/250.)+15
		ig=fix((logg-gmin)/0.5)			; gravity index
		iz=fix(logz-zmin)
		if logz gt -4 then iz=fix((logz+4)/0.5)
		if temp eq 5750 then print,'teff=',temp,logg,logz,iz
		close,5  &  openr,5,files(ifil)
		readf,5,flx
		close,5
		flxarr(*,it,ig,iz)=flx
		no55:
		endfor
skipread:

; models that I have
modt=[indgen(16)*100.+tmin,indgen(16)*250.+4250.]
modg=indgen(ngrav)*0.5+gmin
modz=[indgen(2)+zmin,indgen(9)*0.5-3.]

ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
ind=where(modg ge grav)  &  gind=ind(0)-1>0  &  glow=modg(gind) ; lower grav
ind=where(modz ge zmetal) & zind=ind(0)-1>0  &  zlow=modz(zind) ; lower metals
;print,'Interpolating for ',tind,modt(tind:tind+1),gind,modg(gind:gind+1),  $
;					zind,modz(zind:zind+1)
delz=1  &  if zmetal ge -3 then delz=0.5	; 2016nov29 - 3 --> -3 !!!!

; Interpolate for specified T,G,Z
fluxg=fltarr(100724,2)		; 2 models bracketing in log g
fluxt=fltarr(100724,2)		; 2 models bracketing in Teff

for it=0,1 do begin						; 2 temps
  for ig=0,1 do begin						; 2 gravities
  	flxlo=flxarr(*,it+tind,ig+gind,zind)
	flxhi=flxarr(*,it+tind,ig+gind,zind+1)
	fluxg(*,ig)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/delz	; interp in z
;stop
	if max(flxlo) le 0 or max(flxhi) le 0 then begin
;		print,'Hole in flxarr at:',it+tind,ig+gind,zind,' or',	$
;			it+tind,ig+gind,zind+1,' [i.e. teff,logg,logz]',$
;			modt(it+tind),modg(ig+gind),modz(zind:zind+1)
;		print,teff,grav,zmetal,' Out of range in marcsmod'
; 2016nov28-No Giants, supergiants or Z>.11 or Z<-1
; 2016dec21-stops for hd14943 prefind 8000k,g=4.5,z=-1 missing:
;?	if modg(ig+gind) ge 3 and modz(zind+1) gt -1.5 then stop
		endif
 	endfor
  fluxt(*,it)=fluxg(*,0)+(fluxg(*,1)-fluxg(*,0))*(grav-glow)/0.5  ; interp in g
  endfor
delteff=100.
if teff gt 4000 then delteff=250.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
;good=where(flux gt 0,ngood)
;if ngood lt 100 then begin
;	print,teff,grav,zmetal,' Out of range in marcsmod'
; ###change to make prefind work - 2016aug11:
;;	return			
;	stop
;	end
wav=wave
if keyword_set(wrange) then begin
	good=where(wav ge wrange(0) and wav le wrange(1))
	wav=wav(good)
	flux=flux(good)
	endif
return

end
