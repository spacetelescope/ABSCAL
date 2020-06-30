; 2018jul13 sens.pro to derive stare grism flux calibrations, ie sens=net/flux
;	- using Rauch models *mod_010
; 2020feb14 - new prime WD models *mod_011
; Need to wgt by exp time because of the wide range of exp times for
;	ea star & short exp are noisier & less reliable.
; 	See obsolete sensck.pro & sensall.pro for unwgted method, which could be
;	rescued by adding exp time wgt in splinefit in sensall.
; paschen gamma,beta=10941.1, 12821.6 (10938.1, 12818.1-air)
;	 delta,P5, P6=10052.6,9548.8,9232.2... 
; 2018jul19-the smoothing to the resol of 200,150 works well, except for G191
;	12822A. So I must mask that region & interpol across.
; mv sens.* to /ref when verified
; sensall.pro is obsolete. ff this run w/ mrgall.
;-
st=''
red=[0,255,  0,  0,255] 		; see flxlim.pro for 6 saturated colors
gre=[0,  0,200,  0,255]
blu=[0,  0,  0,255,255]
loadct,0
tvlct,red,gre,blu
!p.multi=[0,1,2,0,0]
!p.font=-1
!xtitle='!17WAVELENGTH (!7l!17m)'		; microns
!ytitle=''
!p.charsize=1.4
!x.style=1
!y.style=1
!p.noclip=0

star=['g191b2b','gd153','gd71']
wbeg=[7600.,10000]				; 1st order
wend=[11800.,17500]
grat=['g102','g141']
resol=[200,150]
;NICMOS Ang/px=55.2,80.2,113.5 for 3 gratings
;WFC3 Ang/px=24.5,46.5: WL/disp=10000/24.5=408, 14000/46.5=301,
;		Thus, for 2Px R~200,150
; @ 1micron, the max earthvel of 30km/s is 1Ang.                 

for igrat=0,1 do begin
	hydlin=9332.
	if igrat eq 1 then hydlin=12822.
	!mtitle=strupcase(grat(igrat))
	plot,[wbeg(igrat),wend(igrat)]/1e4,[.98,1.02],/nodata
	oplot,[wbeg(igrat),wend(igrat)]/1e4,[1,1.0],lin=2
	for istar=0,n_elements(star)-1 do begin
		model='../calspec/deliv/'+star(istar)+'_mod_011.fits'
		ssreadfits,model,hdr,swav,stdf
		good=where(swav ge 7000 and swav le 20000)	; trim std star
		swav=swav(good)  &  stdf=stdf(good)
		strvel=starvel(star(istar))
; corr std * MODEL  to obs. wl frame.
		swav=swav+swav*strvel/3e5
	    	print,'std star. corr to observed frame by:',strvel,'km/s'
		
		rdf,'spec/'+star(istar)+'.'+grat(igrat),1,d
		wl=d(*,0)  &  net=d(*,1)  &  flxold=d(*,2)
		good=where(wl ge wbeg(igrat) and wl le wend(igrat))
		wl=wl(good)  &  net=net(good)  &  flxold=flxold(good)
		if istar eq 0 then begin
			npts=n_elements(wl)
			wmastr=wl  &  snsall=fltarr(npts,3)  &  endif
		if wl(0) ne wmastr(0) or wl(-1) ne wmastr(-1) then stop
		targ=star(istar)
		dsmo=wl(n_elements(wl)/2)/resol(igrat)		; Middle WL
; too much smo-		stdf=smomod(swav,stdf,dsmo)
		sflx=smomod(swav,stdf,dsmo)
		print,'Smoothed model to WFC3 resolution'
		oplot,[1.0053,1.0053],[.98,1.02]	; Pdelta
		oplot,[1.0941,1.0941],[.98,1.02]	; Pgamma
		oplot,[1.2822,1.2822],[.98,1.02]	; Pbeta

		absratio,wl,net,swav,sflx,0,0,0,0,wsns,sens
		
; a +/-80A mask is required for 12822A & g191
		mask=(wsns lt 12742 or wsns gt 12902)		 ;P-beta
		good=where(mask,ngood)
		bad=where(mask eq 0,nbad)
		if nbad gt 0 then begin
;			!p.multi=[0,0,0,0,0]
;			plot,wsns,sens,xr=[12000,13600],psym=-4
;			oplot,wsns,mask*5e17
;interpolate across
			linterp,[wsns(bad(0)-1),wsns(bad(-1)+1)],	$
			    [sens(bad(0)-1),sens(bad(-1)+1)],wsns(bad),snsfix
			sens(bad)=snsfix
;			oplot,wsns,sens,lin=1
;			stop
			endif

		snsall(*,istar)=sens				; store the 3*s

    		endfor				; 3 std star istar loop
	avsens=avg(snsall,1)			; Equal wgt for ea star
	for iplt=0,2 do oplot,wmastr/1e4,snsall(*,iplt)/avsens,color=iplt+1,th=6
	
;	xyouts,.05,.2,'SENS RATIO to Avg (g191-red,gd153-gre,gd71-blu',	$
;			/norm,orient=90.,charsi=2.2,charthic=4
	xyouts,.05,.35,'Ratio to Average',				$
			/norm,orient=90.,charsi=2.2,charthic=4	; pub
	plotdate,'sens'
; write results
        close,6  &  openw,6,strlowcase('sens.'+grat(igrat))
	printf,6,strmid(!stime,0,11)
	printf,6,'sens.pro: AVG. pt-by-pt sensitivity'
	printf,6,grat(igrat)
	for j=0,npts-1 do printf,6,wmastr(j),avsens(j),form='(F11.4,8x,E11.3)'
	close,6
 	endfor			; 2 grating igrat loop
end
