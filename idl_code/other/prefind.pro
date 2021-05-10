pro prefind,dbase,origt,origg,origz,orige,smonum,smosigobs,bwide,ewide,	$
			starwl,wbeg,wend,teff,logg,logz,ebv

; 2016mar8 - Front end to findmin to search a whole grid for the min chisq
;INPUT
;	dbase - which set of models to use, ck04,mz,marcs, etc.
;	origt - first guess teff
;	origg - first guess gravity
;	origz - first guess metalicity
;	orige - first guess E(B-V)
;	smonum - star binned in bwide,ewide
;	smosigobs - uncert of star in bwide,ewide
;	bwide,ewide - begin,end WLs of broad bins used for chisq
;	starwl - WL array of star to be fit
;	wbeg,wend - begin,end WLs of 2px star resol for smoothing model
; OUTPUT
;	teff,logg,logz,ebv - best fitting results
;-
;Compile_opt idl2-- causes syntax errors ?????
common dumdum,waveck,flxarrck,contarrck		; common for ck04 grid
common dummz,wavemz,flxarrmz,contarrmz		; common for meszaros grid
common dummarc,wavemc,flxarrmc			; common for marcs grid
blankfrac=.1					; fractional uncert per 1743045
nbins=n_elements(bwide)				; # of broad WL bins

if dbase eq 'castelli' then begin
	nteff=76  &  ngrav=9  &  nz=7
	tmin=3500.  &  gmin=1.  &  zmin=-2.5
	modt=[indgen(39)*250.+3500,indgen(37)*1000.+14000.]	; 3500-50000K
	modg=indgen(ngrav)*0.5+gmin				; 1-5
	modz=indgen(nz)*0.5+zmin				; -2.5-+.5
; to try speeding up by omitting all the subr. calls in inner loup:
;;	wave=waveck & flxarr=flxarrck*3e19/wav^2 & contarr=contarrck*3e19/wav^2
	endif
if dbase eq 'mz' then begin
	nteff=66  &  ngrav=11  &  nz=13
	tmin=3500.  &  gmin=0.  &  zmin=-2.5
	modt=[indgen(35)*250.+3500,indgen(16)*500.+12500.,		$
		indgen(15)*1000.+21000.]			; 3500-35000K
	modg=indgen(ngrav)*0.5+gmin				; 0-5
	modz=indgen(nz)*.25+zmin				; -2.5-+.5
;;	wave=wavemz  &  flxarr=flxarrmz  &  contarr=contarrmz
	endif
if dbase eq 'marcs' then begin
	nteff=32  &  ngrav=12  &  nz=11
	tmin=2500.  &  gmin=-0.5  &  zmin=-5.
	modt=[indgen(16)*100.+tmin,indgen(16)*250.+4250.]	; 2500-8000K
	modg=indgen(ngrav)*0.5+gmin				; -.5-5.0
	modz=[indgen(2)+zmin,indgen(9)*0.5-3.]			; -5-+1
;;	wave=wavemc  &  flxarr=flxarrmc
	endif
if dbase eq 'lanz' then begin
	nteff=26  &  ngrav=13  &  nz=5			; Cloudy uses 5 Z subset
	tmin=15000.  &  gmin=1.75  &  zmin=-1.
	modt=[indgen(16)*1000.+tmin,indgen(10)*2500.+32500.]	; 15,000-55,000K
	modg=indgen(ngrav)*0.25+gmin				; -.5-5.5
	modz=[-1,-0.7,-0.3,0,0.3]		; Cloudy subset of log Z/Zsun
	endif

; find the steps to do

tabinv,modt,origt,indx
indx=round(indx)
itmin=(indx-3)>0						; do 7 steps
itmax=itmin+6							; do 7 steps
if itmax gt nteff-1 then begin
	itmax=nteff-1  &  itmin=itmax-6  &  endif

tabinv,modg,origg,indx
indx=round(indx)
igmin=(indx-3)>0						; do 7 steps
igmax=igmin+6							; do 7 steps
if igmax gt (ngrav-1) then begin
	igmax=ngrav-1  &  igmin=igmax-6  &  endif

; ck logg range that varies w/ Teff, eg. MZ:
tmax=modt(itmax)
if dbase eq 'mz' then begin		;gmin=0,del-g=0.5 chifit/pub mods paper
	if tmax gt 6000 and igmin lt 2 then begin
		igmin=2  &  igmax=8  &  endif
	if tmax gt 8000 and igmin lt 4 then begin
		igmin=4  &  igmax=10  &  endif
	if tmax gt 12000 then begin
		igmin=6  &  igmax=10  &  endif
	if tmax gt 28000 then begin
		igmin=7  &  igmax=10  &  endif
	if tmax gt 34000 then begin
		igmin=8  &  igmax=10  &  endif
	endif
if dbase eq 'castelli' then begin	;gmin=1,del-g=0.5 chifit/doc/doc.fitting
	if tmax gt 8250 and igmin lt 1 then begin 
		igmin=1  &  igmax=7  &  endif
	if tmax gt 9000 then begin
		igmin=2  &  igmax=8  &  endif
	if tmax gt 11750 then begin
		igmin=3  &  igmax=8  &  endif
	if tmax gt 19000 then begin
		igmin=4  &  igmax=8  &  endif
	if tmax gt 26000 then begin
		igmin=5  &  igmax=8  &  endif
	if tmax gt 31000 then begin
		igmin=6  &  igmax=8  &  endif	; eg grav range= 4-5
	if tmax gt 39000 then begin
		igmin=7  &  igmax=8  &  endif
	if tmax gt 49000 then begin
		igmin=8  &  igmax=8  &  endif
	endif
if dbase eq 'lanz' then begin	; gmin=1.75, del-g=0.25, ngrav=13 models/doc.lanzOB
	if tmax ge 16000 and igmin lt 1 then begin 
		igmin=1  &  igmax=7  &  endif
	if tmax ge 19000 and igmin lt 2 then begin
		igmin=2  &  igmax=8  &  endif
	if tmax ge 21000 and igmin lt 3 then begin
		igmin=3  &  igmax=9  &  endif
	if tmax ge 25000 and igmin lt 4 then begin
		igmin=4  &  igmax=10  &  endif
	if tmax ge 29000 and igmin lt 5 then begin
		igmin=5  &  igmax=11  &  endif
	if tmax ge 32500 then begin
		igmin=6  &  igmax=12  &  endif
	if tmax ge 37500 then begin
		igmin=7  &  igmax=12  &  endif
	if tmax ge 42500 then begin
		igmin=8  &  igmax=12  &  endif
	if tmax ge 47500 then begin
		igmin=9  &  igmax=12  &  endif
	endif
tabinv,modz,origz,indx
indx=round(indx)
izmin=(indx-3)>0						; do 7 steps
izmax=izmin+6							; do 7 steps
if izmax gt nz-1 then begin
	izmax=nz-1  &  izmin=(izmax-6)>0  &  endif

doteff=modt(itmin:itmax)
dologg=modg(igmin:igmax)
dologz=modz(izmin:izmax)
doebv=orige
print,'PREFIND starting T,g,z,e=',origt,origg,origz,orige
print,'PREFIND search ranges in teff, logg, logz=',dbase,		$
	minmax(doteff),minmax(dologg),minmax(dologz)
;stop
chisq=fltarr(7,7,7)  &  earr=chisq			; do 7 steps in ea param
for it=0,6 do begin
   for ig=0,n_elements(dologg)-1 do begin
   	for iz=0,n_elements(dologz)-1 do begin
;	    print,'PREFIND teff, logg, logz=',dbase,doteff(it),		$
;	    					dologg(ig),dologz(iz)
; Use the subroutines, rather than the models in common, if not too slow

	if (dbase eq 'castelli') then 					$
	     ck04blanket,doteff(it),dologg(ig),dologz(iz),bwave,blank,dumco,bflx
; ff needed for Marcs & Lanz models that have NO continuum.
	if (dbase ne 'castelli') then 					$
	       mzmod,doteff(it),dologg(ig),dologz(iz),bwave,bflx,blank
	    if dbase eq 'lanz' or dbase eq 'marcs' then 		$
	    	ck04blanket,doteff(it),dologg(ig),dologz(iz),bwave,blank
	    wmod=bwave					; For blanketing.
	    if dbase eq 'marcs' then marcsmod,doteff(it),		$
				dologg(ig),dologz(iz),bwave,bflx
	    if dbase eq 'lanz' then lanzmod,doteff(it),			$
				dologg(ig),dologz(iz),bwave,bflx
	    if min(bflx) le 0 then begin	; trap missing  Marcs logg's
	    	print,dbase,doteff(it),dologg(ig),dologz(iz),' MISSING'
		ebmvlast=99
		chisqlast=9999
;		goto,done
		endif
; fractional line blanketing * weighting factor in broad bins:
	    smofrac=(1-tin(wmod,blank,bwide,ewide))*blankfrac
	    ebmvlast=-1.  &  posneg=0
; INNER LOOP	 Find Min E(B-V)
iter:
	    chiar_red,bwave,bflx,-(doebv),redflx
;smo denom by 2px to match STIS flux numer w/ starwl WL array:
	    smoflx=tin(bwave,redflx,wbeg,wend)
	    smoden=tin(starwl,smoflx,bwide,ewide)	; broadband bins
; 2012May17-Try proper "avg" norm. See paper derivation in G-star folder:
	    normfac=total(smonum*smoden)/total(smoden^2)
	    smoden=smoden*normfac
	    smoblank=smofrac*smoden			; blanketing uncertainty
	    sigtot2=smosigobs^2+smoblank^2
	    chi=total((smonum-smoden)^2/sigtot2)	; total chisq
; find E(B-V) to minimize chisq for ea model:
	    if ebmvlast eq -1 then begin		;first time, do one iteration
		ebmvlast=doebv
		chisqlast=chi
		doebv=doebv+.001		; known +step to determ posneg
		goto,iter
		endif
	    if posneg eq 0 then begin		; 2nd time find +/- for E(B-V)
		if chisqlast ge chi then posneg=+1 else posneg=-1
		ebmvlast=doebv
		chisqlast=chi
		doebv=(doebv+posneg*.001)>0
		goto,iter
		endif
	    if chi ge chisqlast then goto,done
	    ebmvlast=doebv
	    chisqlast=chi
	    doebv=(doebv+posneg*.001)>0
	    goto,iter
; END INNER LOOP
done:	    earr(it,ig,iz)=ebmvlast			;extinction result array
; if doteff(it) eq 16000. and dologg(ig) eq 3 then stop
	    chisq(it,ig,iz)=chisqlast
	    endfor
	endfor
   endfor
good=where(chisq gt 0)
imin=where(chisq eq min(chisq(good)))  &  imin=imin(0)
iz=imin/49
ig=(imin-iz*49)/7
it=(imin-iz*49-ig*7)
chisq=chisq/(nbins-4)				; avg chisq. fix -4 2017jan14
print,chisq(it,ig,iz),' Min PREFIND chisq at teff,logg,logz,E(B-V)=',	$
				doteff(it),dologg(ig),dologz(iz),earr(it,ig,iz)
teff=doteff(it)						; output
logg=dologg(ig)
logz=dologz(iz)
ebv=earr(it,ig,iz)
print,dologz(iz),doteff,form='("Z=",f5.2,i7,8i8)'	;Temperature header line
for i=0,7<(n_elements(dologg)-1) do 					$
			print,dologg(i),chisq(*,i,iz),form='(f4.2,2x,7f8.3)'
; 2016jul14 - add print of chisq of Z closest to origz:
print,''
print,'CHISQ matrix closest to orig Z of ',origz,':'
tabinv,dologz,origz,indx
indx=round(indx)
print,dologz(indx),doteff,form='("Z=",f5.2,i7,8i8)'	;Temperature header line
for i=0,7<(n_elements(dologg)-1) do 					$
			print,dologg(i),chisq(*,i,indx),form='(f4.2,2x,7f8.3)'


if it eq 0 or ig eq 0 or iz eq 0 then begin
	print,'On an edge of the search area'
	print,'Model grid and teff,logg,logz ranges=',dbase,		$
		minmax(modt),minmax(modg),minmax(modz)
	endif
;if it eq 8 or ig eq 8 or iz eq 8<(nz-1) then begin
;if it eq 8 or iz eq 8<(nz-1) then begin		;ck04 snap2 @ g=5
if it eq 6 then begin					;ck04 hd159222 @ z=5
	print,'On an edge of the search area'
	print,'Model grid and teff,logg,logz ranges=',dbase,		$
		minmax(modt),minmax(modg),minmax(modz)
	teff=teff-40	; keep away from edge (Marcs 8000K)
	endif
print,'END PREFIND'
return
end
