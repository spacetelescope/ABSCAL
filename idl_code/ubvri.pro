pro ubvri,wstar,fstar,mags,nozp=nozp,bndpas=bndpas,shft=shft
; +
;
; PURPOSE:
;	Compute Landolt std mags on Johnson-Cousins system, using the
;		Landolt CTIO BP functions, mod for the CTIO atmosph. transmiss.
;		by Cohen(2003), paper XIII for UBVRI and 2003 paper XIV for 
;		2MASS JHK
; INPUT:
;	wstar - Wavelength vector of flux spectrum. If scaler, then load common
;		block and return.
;	fstar - Flux of star
;	nozp  - optional keyword to avoid adding the zero pts (for alphotcf.pro)
;		Do NOT do the intrum mag corr, just return the rawmag integral.
;	bndpas-Name of filter set. Cohen orig. the default. Now required to say.
;	shft - keyword specifying shift of FILTER BPs in Ang. Same dim as mag
; OUTPUT:
;	mags - synthetic UBVRI vector of magnitudes on Johnson-Cousins system
;
; HISTORY:
;	07Nov17 - rcb for use in fitting spectra for A stars & JWST cal.
;	07nov29-old err:mags(ifilt)=-2.5*alog10(integral(wstar,fstar*trans*wstar
;		See end of calib/aktype/doc.cohen for explanation.
;	07dec19-discover CK04 models have coarser sampling than filter, eg in J
;		where the atmosph lines are strong. Go to a 10x finer filter 
;		grid for the master WL scale & ck star for even finer scale.
;	14nov6-add Maiz & Bessell bandpasses. Must exit IDL to change BPs.
;	14nov7-add short wave to long wave ck for mag ne 00 test.
;	14nov10-Fix error in calc of mean flux & mod cohen by div by WL to get 
; 		the std style of filter thruput per calib/aktype/doc.cohen
;	14nov17-Add ubvr from Mann & von Braun, dec4-update R & add I
;	14dec12-Implement Bessell rec. of smooth fit to his BP functions
;	14dec15-Implement BP shift option per synacs.pro
;	15Feb12-Upgrade Bessell spline fitting and endpoints.
;		only diff in pub values is Vega R=0.033 -->0.032 in Table 5
; TEST & VERIFICATION:
;	see alphotcf.pro & ...cohen
;-
; "Zero Points" from alphotcf.cohen & .pro. See Maiz paper for doc. markups.
;zp=[99.99,-13.158,-13.690,-13.535,-14.612,-15.752,-16.347,-17.370]	;07dec19
; 2015jul10-above are old system, before corr error in <F> calc below.
;	new below are from Bohlin & Landolt (2015):
zp=[-20.871,-20.414,-21.059,-21.614,-22.376]	; Cohen JHK??
if bndpas eq 'bessell' then zp=[-20.939,-20.499,-21.092,-21.645,-22.330]
if bndpas eq 'bessell' and keyword_set(shft) then 			$
		zp=[-20.934,-20.485,-21.079,-21.626,-22.317]
if bndpas eq 'maiz' then zp=[-20.932,-20.496,-21.087]

; Load data into common on 1st call only:
common grndbp,wfilt,tfilt,sysname		; 5 filter BP func w/ vac WLs
if n_elements(wfilt) le 1 then begin
    st=''
    sysname=bndpas
    dir='../../calib/photom/'	; 2014jun to make alphotcf work
    if bndpas eq 'cohen' then begin
	rdf,dir+'v.cohen',1,vo  &  siz=size(vo)
		npts=siz(1)
		mx=max(vo(*,0))  &  mn=vo(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		v=fltarr(10*siz(1)+1,2)
		v(*,0)=wl
		linterp,vo(*,0),vo(*,1),wl,tnew  &  v(*,1)=tnew
	rdf,dir+'u.cohen',1,uo  &  siz=size(uo)
		if siz(1) gt npts then npts=siz(1)
		mx=max(uo(*,0))  &  mn=uo(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		u=fltarr(10*siz(1)+1,2)
		u(*,0)=wl
		linterp,uo(*,0),uo(*,1),wl,tnew  &  u(*,1)=tnew
	rdf,dir+'b.cohen',1,bo  &  siz=size(bo)
		if siz(1) gt npts then npts=siz(1)
		mx=max(bo(*,0))  &  mn=bo(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		b=fltarr(10*siz(1)+1,2)
		b(*,0)=wl
		linterp,bo(*,0),bo(*,1),wl,tnew  &  b(*,1)=tnew
	rdf,dir+'r.cohen',1,ro  &  siz=size(ro)
		if siz(1) gt npts then npts=siz(1)
		mx=max(ro(*,0))  &  mn=ro(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		r=fltarr(10*siz(1)+1,2)
		r(*,0)=wl
		linterp,ro(*,0),ro(*,1),wl,tnew  &  r(*,1)=tnew
	rdf,dir+'i.cohen',1,io  &  siz=size(io)
		if siz(1) gt npts then npts=siz(1)
		mx=max(io(*,0))  &  mn=io(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		i=fltarr(10*siz(1)+1,2)
		i(*,0)=wl
		linterp,io(*,0),io(*,1),wl,tnew  &  i(*,1)=tnew
	rdf,dir+'j.cohen',1,jo  &  siz=size(jo)
		if siz(1) gt npts then npts=siz(1)
		mx=max(jo(*,0))  &  mn=jo(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		j=fltarr(10*siz(1)+1,2)
		j(*,0)=wl
		linterp,jo(*,0),jo(*,1),wl,tnew  &  j(*,1)=tnew
	rdf,dir+'h.cohen',1,ho  &  siz=size(ho)
		if siz(1) gt npts then npts=siz(1)
		mx=max(ho(*,0))  &  mn=ho(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		h=fltarr(10*siz(1)+1,2)
		h(*,0)=wl
		linterp,ho(*,0),ho(*,1),wl,tnew  &  h(*,1)=tnew
	rdf,dir+'k.cohen',1,ko  &  siz=size(ko)
		if siz(1) gt npts then npts=siz(1)
		mx=max(ko(*,0))  &  mn=ko(0,0)
		dlam=(mx-mn)/(10*siz(1))
		wl=findgen(10*siz(1)+1)*dlam+mn
		k=fltarr(10*siz(1)+1,2)
		k(*,0)=wl
		linterp,ko(*,0),ko(*,1),wl,tnew  &  k(*,1)=tnew

	npts=10*npts+1
	wfilt=fltarr(npts,8)  &  tfilt=wfilt	; order as U,B,V,R,I
	siz=size(u)  &  wfilt(0:siz(1)-1,0)=u(*,0)  & tfilt(0:siz(1)-1,0)=u(*,1)
	siz=size(b)  &  wfilt(0:siz(1)-1,1)=b(*,0)  & tfilt(0:siz(1)-1,1)=b(*,1)
	siz=size(v)  &  wfilt(0:siz(1)-1,2)=v(*,0)  & tfilt(0:siz(1)-1,2)=v(*,1)
	siz=size(r)  &  wfilt(0:siz(1)-1,3)=r(*,0)  & tfilt(0:siz(1)-1,3)=r(*,1)
	siz=size(i)  &  wfilt(0:siz(1)-1,4)=i(*,0)  & tfilt(0:siz(1)-1,4)=i(*,1)
	siz=size(j)  &  wfilt(0:siz(1)-1,5)=j(*,0)  & tfilt(0:siz(1)-1,5)=j(*,1)
	siz=size(h)  &  wfilt(0:siz(1)-1,6)=h(*,0)  & tfilt(0:siz(1)-1,6)=h(*,1)
	siz=size(k)  &  wfilt(0:siz(1)-1,7)=k(*,0)  & tfilt(0:siz(1)-1,7)=k(*,1)
	wfilt=wfilt*1e4				; microns --> Ang
; 2014nov10-cohen RSRs have been mult by WL, so divide here to standardize:
	good=where(wfilt gt 0)  &  tfilt(good)=tfilt(good)/wfilt(good)
	!mtitle='CTIO bandpass w/ Cohen atmosph corr.'
	endif						; END cohen
    if bndpas eq 'maiz' then begin
    	readcol,'ubv.maiz',wu,pu,wb,pb,wv,pv	   	; filter thruputs
	wfilt=fltarr(47,3)  &  tfilt=wfilt
	wfilt(*,0)=wu  &  tfilt(*,0)=pu
	wfilt(*,1)=wb  &  tfilt(*,1)=pb
	wfilt(*,2)=wv  &  tfilt(*,2)=pv
    	endif						; END Maiz
    if bndpas eq 'bessell' then begin
    	readcol,'ubvri.bessell',wu,pu,wb,pb,wv,pv,wr,pr,wi,pi	;filter thruputs
; 2014dec12-implement spline fits on a 1A WL grid
	wfilt=fltarr(3700,5)  &  tfilt=wfilt
	nnodes=15
	good=where(pu gt 0)
	good=[0,good,max(good)+1]				; restore end 0s
	w=wu(good)  &  t=pu(good)
;	plot,w,t,psym=4,xr=[w(0)-100,w(-1)+100]
	dlam=(w(-1)-w(0))/(nnodes-1)
	wnod=findgen(nnodes)*dlam+w(0)
	ynod=wnod*0+.5
	fit=splinefit(w,t,w*0+1.,wnod,ynod)
	wmin=long(w(0))  &  wmax=long(w(-1)+.999)
	wl=findgen(wmax-wmin+1)+wmin				; 1A d-lam 
	fit=cspline(wnod,ynod,wl)
	good=where(fit ge 0)
	wl=wl(good)  &  fit=fit(good)
	if wl(0) gt w(0) then begin				; 2015FEB12
		wl=[wl(0),wl]  &  fit=[0,fit]
	    end else fit(0)=0					;insure 0 at end
	if wl(-1) lt w(-1) then begin
		wl=[wl,w(-1)]  &  fit=[fit,0]
	    end else fit(-1)=0
;	oplot,wl,fit,th=0
	npts=n_elements(wl)
;read,st
	wfilt(0:npts-1,0)=wl  &  tfilt(0:npts-1,0)=fit
	good=where(pb gt 0)
	good=[0,good,max(good)+1]				; restore end 0s
	w=wb(good)  &  t=pb(good)
;	plot,w,t,psym=4,xr=[w(0)-100,w(-1)+100]
	wnod=[3600.,3700,3850,3950,4040,4250,findgen(8)*200+4200]
	ynod=wnod*0+.5
	fit=splinefit(w,t,w*0+1.,wnod,ynod)
	wmin=long(w(0))  &  wmax=long(w(-1)+.999)
	wl=findgen(wmax-wmin+1)+wmin				; 1A del-lambda
	fit=cspline(wnod,ynod,wl)
	good=where(fit ge 0)
	wl=wl(good)  &  fit=fit(good)
	if wl(0) gt w(0) then begin				; 2015FEB12
		wl=[wl(0),wl]  &  fit=[0,fit]
	    end else fit(0)=0					;insure 0 at end
	if wl(-1) lt w(-1) then begin
		wl=[wl,w(-1)]  &  fit=[fit,0]
	    end else fit(-1)=0
;	oplot,wl,fit,th=0
	npts=n_elements(wl)
	wfilt(0:npts-1,1)=wl  &  tfilt(0:npts-1,1)=fit
;read,st
	nnodes=15
	good=where(pv gt 0)
	good=[0,good,max(good)+1]				; restore end 0s
	w=wv(good)  &  t=pv(good)
;	plot,w,t,psym=4,xr=[w(0)-100,w(-1)+100]
	dlam=(w(-1)-w(0))/(nnodes-1)
	wnod=findgen(nnodes)*dlam+w(0)
	wnod(3:4)=[5100.,5320]
	ynod=wnod*0+.5
	fit=splinefit(w,t,w*0+1.,wnod,ynod)
	wmin=long(w(0))  &  wmax=long(w(-1)+.999)
	wl=findgen(wmax-wmin+1)+wmin
	fit=cspline(wnod,ynod,wl)
	good=where(fit ge 0)
	wl=wl(good)  &  fit=fit(good)
	if wl(0) gt w(0) then begin				; 2015FEB12
		wl=[wl(0),wl]  &  fit=[0,fit]
	    end else fit(0)=0					;insure 0 at end
	if wl(-1) lt w(-1) then begin
		wl=[wl,w(-1)]  &  fit=[fit,0]
	    end else fit(-1)=0
;	oplot,wl,fit,th=0
	npts=n_elements(wl)
	wfilt(0:npts-1,2)=wl  &  tfilt(0:npts-1,2)=fit
;read,st
	nnodes=15
	good=where(pr gt 0)
	good=[0,good,max(good)+1]				; restore end 0s
	w=wr(good)  &  t=pr(good)
;	plot,w,t,psym=4,xr=[w(0)-100,w(-1)+100]
	dlam=(w(-1)-w(0))/(nnodes-1)
	wnod=findgen(nnodes)*dlam+w(0)
	wnod=[5500,5600,5700,5800,5900,wnod(2:-1)]
	ynod=wnod*0+.5
	fit=splinefit(w,t,w*0+1.,wnod,ynod)
	wmin=long(w(0))  &  wmax=long(w(-1)+.999)
	wl=findgen(wmax-wmin+1)+wmin
	fit=cspline(wnod,ynod,wl)
	good=where(fit ge 0)
	wl=wl(good)  &  fit=fit(good)
	if wl(0) gt w(0) then begin				; 2015FEB12
		wl=[wl(0),wl]  &  fit=[0,fit]
	    end else fit(0)=0					;insure 0 at end
	if wl(-1) lt w(-1) then begin
		wl=[wl,w(-1)]  &  fit=[fit,0]
	    end else fit(-1)=0
;	oplot,wl,fit,th=0
	npts=n_elements(wl)
	wfilt(0:npts-1,3)=wl  &  tfilt(0:npts-1,3)=fit
;read,st
	nnodes=15
	good=where(pi gt 0)
	good=[0,good,max(good)+1]				; restore end 0s
	w=wi(good)  &  t=pi(good)
;	plot,w,t,psym=4,xr=[w(0)-100,w(-1)+100]
	dlam=(w(-1)-w(0))/(nnodes-1)
	wnod=findgen(nnodes)*dlam+w(0)
	wnod=[7000.,7080,wnod(1:-1)]
	ynod=wnod*0+.5
	fit=splinefit(w,t,w*0+1.,wnod,ynod)
	wmin=long(w(0))  &  wmax=long(w(-1)+.999)
	wl=findgen(wmax-wmin+1)+wmin
	fit=cspline(wnod,ynod,wl)
	good=where(fit ge 0)
	wl=wl(good)  &  fit=fit(good)
	if wl(0) gt w(0) then begin				; 2015FEB12
		wl=[wl(0),wl]  &  fit=[0,fit]
	    end else fit(0)=0					;insure 0 at end
	if wl(-1) lt w(-1) then begin
		wl=[wl,w(-1)]  &  fit=[fit,0]
	    end else fit(-1)=0
;	oplot,wl,fit,th=0
	npts=n_elements(wl)
	wfilt(0:npts-1,4)=wl  &  tfilt(0:npts-1,4)=fit
; read,st
    	endif					; END Bessell
    if bndpas eq 'mann' then begin
    	readcol,'ubvri.mann',wu,pu,wb,pb,wv,pv,wr,pr,wi,pi	;filter thruputs
	wfilt=fltarr(75,5)  &  tfilt=wfilt
	wfilt(*,0)=wu  &  tfilt(*,0)=pu
	wfilt(*,1)=wb  &  tfilt(*,1)=pb
	wfilt(*,2)=wv  &  tfilt(*,2)=pv
	wfilt(*,3)=wr  &  tfilt(*,3)=pr
	wfilt(*,4)=wi  &  tfilt(*,4)=pi
	tfilt=tfilt/wfilt			; CONVERT engy BP to photons
    	endif					; END Mann
    airtovac,wfilt	;diff = 0.003mag in U and <.001 at B,V
    endif					; END common filling.
if n_elements(wstar) eq 1 then return		; Just load common block

siz=size(wfilt)  &  nfilt=siz(2)
mags=fltarr(nfilt)+99.				; 99 flag for missing WLs
for ifilt=0,nfilt-1 do begin
       good=where(tfilt(*,ifilt) gt 0 and wfilt(*,ifilt) gt 2900) ;for U WL<2900
; Elim zeros but put back one pt @ each end
	if good(0) gt 0 then good=[good(0)-1,good]
	if wfilt(max(good)+1,ifilt) gt 0 then good=[good,max(good)+1]
	wuse=wfilt(good,ifilt)  &  tuse=tfilt(good,ifilt)	;filter bandpass
; 2014Dec15-Implement BP shifts
	if keyword_set(shft) then if shft(ifilt) ne 0.			$
						then wuse=wuse+shft(ifilt)
; For filter out of range, leave 99 for missing WL coverage:
	if min(wstar) le min(wuse) and max(wstar) ge max(wuse)  then begin
; finer sampling in filter than for star:
		linterp,wstar,fstar,wuse,finterp,missing=0
; 2014Nov10-Add missing WL multiplier and denom to get proper MEAN FLUX:
; 2014nov10 wrong mags(ifilt)=-2.5*alog10(integral(wuse,finterp*tuse.	$
;;;;; 					min(wuse),max(wuse)))
		mags(ifilt)=-2.5*alog10(integral(wuse,finterp*tuse*wuse,     $
 			min(wuse),max(wuse))/integral(wuse,tuse*wuse,      $
			min(wuse),max(wuse)))
		indx=where(wstar ge min(wuse) and wstar le max(wuse),nck)
		if nck ge n_elements(wuse) then begin
; case of hi-res spec, eg WD models. Fine resamp of Cohen misses sometimes here.
; finer sampling in star than for filter:
		   linterp,wuse,tuse,wstar,trans,missing=0
; 2014nov10 wrong	mags(ifilt)=-2.5*alog10(integral(wstar,fstar*trans,   $
;;;;; for Cohen w/ WL in trans			min(wuse),max(wuse)))
		   mags(ifilt)=-2.5*alog10(integral(wstar,fstar*trans*wstar,  $
 			min(wuse),max(wuse))/integral(wstar,trans*wstar,      $
			min(wuse),max(wuse)))
		   print,'Hi-Res Spectrum for '+sysname+		      $
		   	' filter #, pts in spectrum, pts defining filt=',     $
		   	string([ifilt,nck,n_elements(wuse)],'(i2,2i6)')
		   endif
		endif
	endfor						; END 5 filter loop
if bndpas eq 'cohen' then begin				; 2014dec15 (moved up)
; the Cohen mags are instrumental, so make the color corr to J-C system per
;	Landolt (1992), which are >.001 for U & B:
	umb=mags(0)-mags(1)  &  bmv=mags(1)-mags(2)	; U-B  &  B-V
	umbcor=-0.04116+0.93072*umb
	if umb gt -0.2 then umbcor=-.02729+1.02378*umb
	if umb gt 0.6 then umbcor=-.01407+1.02328*umb
	bmvcor=.00144+1.05416*bmv
	if bmv gt .1 then bmvcor=.00923+.99676*bmv
	if bmv gt .8 then bmvcor=.00830+.99124*bmv
	if mags(1) ne 99. then mags(1)=bmvcor+mags(2)	; Bcor=bmvcor+V
	if mags(0) ne 99. then mags(0)=umbcor+mags(1)	; Ucor=umbcor+B
	endif

; NORMAL RETURN. Ck above zp values, if used below.
if keyword_set(nozp) then return
mags=mags+zp

end
