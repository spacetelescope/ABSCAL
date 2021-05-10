pro ck04blanket,teff,grav,zmetal,wav,blanket,contwl,flam,wrange=wrange
;+
; PURPOSE
;	interpolate ck04 models in T,G,Z to get the line blanketing
; INPUT
;	teff-model temperature
;	grav-log g
;	zmetal-log z
;	wrange-2 element vector for first & last WL trimming
; OUTPUT
;	wav-WL
;	blanket-line blanketing as flux/contin (F/C). {F,C are in freq. units.}
;	contwl - continuum converted to WL units
;	flam - flux converted to WL units
;HISTORY
; 2012Jan3-Read & interpolate the continuum line blanketing for CK04 models
; 2012nov30-add cont in WL units to  output
; See marcsmod.pro for the method.
;fetched from http://wwwuser.oat.ts.astro.it/castelli/grids.html just the normal
;	models for log Z=0.5, 0, -.5 and -1.0 (0.2 and more neg Z also exists).
; 2013Feb22- expand the gravity to 1 and the Z to -2.5 for Schmidt 12813
;	Also replace all old models w/ old H2O opacity.
; 2013Feb23 - Add flam to output for cf old & new H2O.
; 2013Feb25 - Expand Teff to do all Teff to 50000K & fix bugs. Add keyword
; 2013Feb26 - Interpol flux,cont & compute blanket @ end
; fetched from http://wwwuser.oat.ts.astro.it/castelli/grids/ just the 7 normal
;	models for log Z=-2.5 to 0.5, step=0.5 (0.2 and more neg Z also exists).
; Trim the models used to log G 1-5 (9 steps of 0.5) and do all Teff 3500-50000,
;	ie 39 steps of 250K to 13000K & then 37 steps of 1000K to 50,000K. 
;	ie use 76*9*7=4788 models. See chifit/doc/doc.fitting for grav range.
;	And cf. CK04 table 1, which is the same as doc.fitting.
; 2014June10 - add flag & use next higher log g blanketing for Lanz model
;-

nteff=76  &  ngrav=9  &  nz=7
tmin=3500.  &  gmin=1.  &  zmin=-2.5

if teff lt tmin or teff gt 50000. or grav lt gmin or grav gt 5 or		$
			zmetal lt zmin or zmetal gt 0.5 then 		$
	if zmetal lt -2.5 then begin
		print,'***********WARNING: min Z=-2.5 and requested ',	$
			zmetal, ' is set to -2.5 in ck04blanket'
		zmetal=-2.5
		endif
	if grav gt 5 then begin
		print,'***********WARNING: max grav=5 and requested ',	$
			grav, ' is set to 5 in ck04blanket'
		grav=5.
		endif
st=''
common dumdum,wave,flxarr,contarr

if n_elements(flxarr) gt 0 then goto,skipread

  get_castkur04_wave,wave		      ;Ang. Same as from Fiorella's site
  flxarr=dblarr(1221,nteff,ngrav,nz)
  contarr=flxarr
  hnu=dblarr(1221)  &  cont=hnu		; for one model
  file=file_search('~/models/ck04full/*pck')
; sort in increasing Z order:
  file=[reverse(file(0:4)),file(5:6)]
  for iz=0,nz-1 do begin				; 4 diff Z loop
	close,5  &  openr,5,file(iz)
loop:	while strmid(st,0,4) ne 'TEFF' do begin
		readf,5,st
		endwhile
	temp=long(strmid(st,6,5))
if temp lt 3500 then stop
	for i=0,2 do dum=gettok(st,' ')			; st changed
	logg=float(gettok(st,' '))
	if logg lt  0.99 then goto,loop				; keep Max G=5
	readf,5,hnu,format='(8e10.4)'
	readf,5,cont,format='(8e10.4)'
	it=fix((temp-tmin)/250.)			; temperature index
	if temp gt 13000 then it=fix((temp-13000.)/1000.)+38
	ig=fix((logg-gmin)/0.5)				; gravity index
	flxarr(*,it,ig,iz)=hnu
	contarr(*,it,ig,iz)=cont
;if temp eq 8000. and iz eq 5 then begin
;  print,temp,logg,st
;  read,st
;  endif
	if temp eq 50000 then goto,skip else readf,5,st	; only 1 50000K model
	goto,loop
skip:
	st=''
	endfor						; 4 step Z loop
skipread:

; Interpolate for specified T,G,Z per marcsmod.pro

fluxg=dblarr(1221,2)			; 2 models bracketing in log g
fluxt=dblarr(1221,2)			; 2 models bracketing in Teff
contg=dblarr(1221,2)			; 2 models bracketing in log g
contt=dblarr(1221,2)			; 2 models bracketing in Teff

; models that I have:
modt=[indgen(39)*250.+tmin,indgen(37)*1000.+14000.]
modg=indgen(ngrav)*0.5+gmin
modz=indgen(nz)*0.5+zmin
ind=where(modt ge teff)  &  tind=ind(0)-1>0  &  tlow=modt(tind) ; lower temp
ind=where(modz ge zmetal) & zind=ind(0)-1>0 & zlow=modz(zind)	; lower z
ind=where(modg ge grav)  &  gind=ind(0)-1>0			; lower grav
; keep higher ind for exact grav cases, eg 3.5 interp 3.5-4, NOT 3-3.5:
if grav eq modg(gind+1) then gind=(gind+1)<(ngrav-2)
; 2016july12-extrap in grav, instead of just the next higher grav approx (see;;) 
if max(flxarr(*,tind+1,gind,zind)) le 0 then begin
	!extrapflg=1
;	print,'Requesting logg=',grav
	gind=gind+1
	if max(flxarr(*,tind+1,gind,zind)) le 0 then gind=gind+1
;	print,'Extrapolating in ck04blanket for ',			$
;		modt(tind:tind+1),modg(gind:gind+1),modz(zind:zind+1)
	if gind gt ngrav-2 then stop				; & punt
	endif
glow=modg(gind)
for it=0,1 do begin						; 2 temps
  for ig=0,1 do begin						; 2 gravities
  	flxlo=flxarr(*,it+tind,ig+gind,zind)
	flxhi=flxarr(*,it+tind,ig+gind,zind+1)
	fluxg(*,ig)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/.5	; interp in z
  	cntlo=contarr(*,it+tind,ig+gind,zind)
; g out of range. But OK for Lanz (n_params=5) contin approx fix below
	if max(cntlo) le 0 and n_params() ne 5 then stop
	cnthi=contarr(*,it+tind,ig+gind,zind+1)
	contg(*,ig)=cntlo+(cnthi-cntlo)*(zmetal-zlow)/.5	; interp in z
	endfor							; end ig loop
  fluxt(*,it)=fluxg(*,0)+(fluxg(*,1)-fluxg(*,0))*(grav-glow)/0.5  ; interp in g
  contt(*,it)=contg(*,0)+(contg(*,1)-contg(*,0))*(grav-glow)/0.5  ; interp in g
  endfor							; end it loop
delteff=250.
if teff gt 13000 then delteff=1000.
flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff	; interp in Teff
contwl=contt(*,0)+(contt(*,1)-contt(*,0))*(teff-tlow)/delteff	; interp in Teff
good=where(contwl gt 0,ngood)
if ngood lt 100 then begin
	print,teff,grav,zmetal,' Out of range in ck04blanket'
;;; Lanz goes to lower log g, so need a contin estimate here. Use the next higher
;;		grav that exists & skip interp in g
;;	if n_params() eq 5 and max(contarr(*,tind+1,gind,zind)) le 0	$
;;		 and max(contarr(*,tind+1,gind+1,zind)) gt 0 then begin
;;		flxlo=flxarr(*,tind,gind+1,zind)	;=higher logg only
;;		flxhi=flxarr(*,tind,gind+1,zind+1)		
;;		fluxt(*,0)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/.5  ; interp in z
;;		flxlo=flxarr(*,tind+1,gind+1,zind)
;;		flxhi=flxarr(*,tind+1,gind+1,zind+1)		
;;		fluxt(*,1)=flxlo+(flxhi-flxlo)*(zmetal-zlow)/.5
;;		cntlo=contarr(*,tind,gind+1,zind)	;=higher logg only
;;		cnthi=contarr(*,tind,gind+1,zind+1)		
;;		contt(*,0)=cntlo+(cnthi-cntlo)*(zmetal-zlow)/.5  ; interp in z
;;		cntlo=contarr(*,tind+1,gind+1,zind)
;;		cnthi=contarr(*,tind+1,gind+1,zind+1)		
;;		contt(*,1)=cntlo+(cnthi-cntlo)*(zmetal-zlow)/.5
;;; interp in Teff:		
;;		flux=fluxt(*,0)+(fluxt(*,1)-fluxt(*,0))*(teff-tlow)/delteff
;;		contwl=contt(*,0)+(contt(*,1)-contt(*,0))*(teff-tlow)/delteff
;;		good=where(contwl gt 0,ngood)
;;		if ngood gt 100 then goto,continue
;;		endif
	stop
	endif
continue:
wav=wave(good)
blanket=flux(good)/contwl(good)
contwl=contwl(good)*3e19/wav^2					; WL units
flam=flux(good)*3e19/wav^2
if keyword_set(wrange) then begin
	good=where(wav ge wrange(0) and wav le wrange(1))
	wav=wav(good)
	blanket=blanket(good)
	contwl=contwl(good)
	flam=flam(good)
	endif

end
