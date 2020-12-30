; analyze the dispersions in wlmeas.output and solve for global WL scales
; Fits are a function of ZO position, so ignore those w/ZO off image.
; HISTORY
;	2013Apr1 - written
;	2013May7 - revamp to use new input file w/o dispersions
; PROCEDURE
;	--> Install new fits for b,m in wfc_wavecal, re-run prewfc, & iterate
;		this program to get proper sigmas for the lines.
;-
st=''
red=[0,255,  0,  0,255] 		; see flxlim.pro for 6 saturated colors
gre=[0,  0,255,  0,255]
blu=[0,  0,  0,255,255]
tvlct,red,gre,blu
!y.style=1

;wlref=[9075.5,9529.6,10861.0,12821.5]			; Nor vac
;wlref=[9071.1,9533.2,10833.3,12823.0]			; isr 2009-17-18, vac
;wllab=[9068.6,9531.4,10830.,12818.1,16109.3,16407.2]	;air lab 2013May23

wlvac=[	 [9070.0,  9070.0,  9071.4,  9070.5],			$
	 [9535.1,  9535.1,  9535.1,  9535.2],			$
	[10833.5, 10834.6, 10833.4, 10833.4],			$
	[12820.8, 12820.8, 12821.6, 12821.0],			$
	[16413.2, 16414.0, 16412.1, 16412.7]]

readcol,'wlmeas.output',file,star,grat,zxpos,zypos,order,x0,x1,x2,x3,x4,	$
			x5,form='(a,a,a,f,f,i,f,f,f,f,f,f)'
; estimate z-order posit when off image:??? 
bad=where(zxpos eq 0.,nbad)
;for ibd=0,nbad-1,2 do begin ??????????		; always order 1,2 pairs

grsm=['G102','G141']
for igr=0,1 do begin
    !xtitle='X-px of shorter WL em. line'
    !ytitle='Dispersion (A/px)'
    !mtitle=grsm(igr)+' Size~Y'
;del    plot,[0,1013],[23,27]+[22,23.5]*igr,/nodata

	nline=3 				    ; 3 lines for ea grat
    for iord=-1,2 do begin
    	if iord eq 0 then goto,skip0
; ignore cases with w/ ZO off image, ie zxpos=0
		good=where(grat eq grsm(igr) and zxpos gt 0 and order eq iord,ngood)
		dofil=file(good)
		dostr=star(good)
		doord=order(good)
		dozx=zxpos(good)
		dozy=zypos(good)
		dox1=x0(good)					; for dispersion
		dox2=x2(good)
		doxi=fltarr(ngood,nline)			; for rms calc
		doxi(0,0)=x0(good)
		doxi(0,1)=x1(good)
		doxi(0,2)=x2(good)
		indwl=igr+(abs(iord)-1)*2
		reflin=fltarr(ngood)+wlvac(indwl,0)		; 9070 for g102
		velall=fltarr(ngood)-71.			; radial veloc of vy2-2
		gdhb12=where(strpos(dostr,'G111') gt 0,nhb12)
		print,grsm(igr),nhb12,' HB12 obs w/ Vr=-5km/s'
		if nhb12 gt 0 then velall(gdhb12)=-5.
		disp=(wlvac(indwl,2)-wlvac(indwl,0))*doord*(1+velall/3e5)/(dox2-dox1)
		if igr eq 1 then begin  		    ; G141
	    	dox1=x2(good)
		    dox3=x3(good)			; G141 2nd order cutoff=13000
		    dox2=x5(good)
; del	    nline=4				; 4 lines for G141 --> 3
; del	    doxi=fltarr(ngood,nline)
	    	doxi(0,0)=x2(good)
		    doxi(0,1)=x3(good)
		    doxi(0,2)=x5(good)
;del	    doxi(0,3)=x5(good)
   	    	reflin=fltarr(ngood)+wlvac(indwl,2)		;use 10833.5 for G141
; disp3 for using 3rd line is for G141 2nd order:
	   	    disp3=(wlvac(indwl,3)-wlvac(indwl,2))*doord*(1+velall/3e5)/	$
		    							(dox3-dox1)
   	    	disp=(wlvac(indwl,4)-wlvac(indwl,2))*doord*(1+velall/3e5)/	$
	    								(dox2-dox1)
	    endif
		reflin=reflin*(1+velall/3e5)			; obs WL of ref. line
; Omit color plot. Not esp useful & would need to update the disp values.
;    for igd=0,ngood-1 do begin
;	z=mrdfits('spec/spec_'+dofil(igd)+'pn.fits',1,hd,/silent)
;	ypos=z.y
;	if doord(igd) eq -1 then color=1
;	if doord(igd) eq 1 then color=2
;	if doord(igd) eq 2 then color=3
;	x=dox1(igd)
;	siz=3*(ypos(x+.5))/1013+.5		; big is large Y
;	oplot,[x],[disp(igd)],psym=4,syms=siz,color=color
;	if igr eq 1 then oplot,[x],[disp3(igd)],psym=4,syms=siz,color=color
;    	endfor							; end good loop
;    xyouts,.15,.15,'Order -1,1,2:red,green,blue',/norm
;    plotdate,'wlmake

; MAKE polynomial fit to WL=b+m*delpx, spit out coef, and iterate to ck results.
;	where delpx=x-x0, b=b1+b2*x+b3*y  and similarly m=m1+...
;	and x0 is the z-order ref px location
		xpx=indgen(1014)
    
		if igr eq 1 and iord eq 2 then begin	; no 16413A line in 2nd order
			disp=disp3
			dox2=dox3
			nline=2				; ONLY 2 lines
		endif
		good=where(dox1 gt 0 and dox2 gt 0,ngood)
; b3rd - third element of b array. First 2 are X,Y of z-order.
; b = lam - m*delx, lam is ref WL for 1st line. (Do not try to get ZO @ lam=0)
		b3rd=reflin(good)*iord-disp(good)*(dox1(good)-dozx(good))	
		b=dblarr(ngood,3)
		b(0,0)=dozx(good)
		b(0,1)=dozy(good)
		m=b					; m has same zx,zy positions
		b(0,2)=b3rd
		b=transpose(b)
		bfit=sfit(b,1,/irr,max_deg=1,kx=bx)			; Y coef is 1st:
		bval=bx(0)+bx(2)*506+bx(1)*506				; b at y=506
;	print,'b at 506,506=',bval
		xr=minmax(dozx(good))					; 0-order range
		print,grsm(igr),' ORDER=',iord,' ZO X-range=',xr
		print,'b0=',bx(0),'  &  b1=',bx(2),'  &  b2=',bx(1),form=	$
							'(a,f8.3,a,f9.6,a,f9.6)'
		m(0,2)=disp(good)
		m=transpose(m)
		mfit=sfit(m,1,/irr,max_deg=1,kx=kx)
		mval=kx(0)+kx(2)*xpx+kx(1)*506				; m at y=506
		color=iord+1+1*(iord eq -1)
;del	oplot,xr,mval(xr),color=color,th=3+5*(!d.name eq 'PS')	; obs X range
;	oplot,mval,color=color,lin=2
		mval=kx(0)+kx(2)*xpx+kx(1)*106				; m at y=106
;	oplot,xr,mval(xr),color=color,th=3+5*(!d.name eq 'PS')
;	oplot,mval,color=color,lin=2
		mval=kx(0)+kx(2)*xpx+kx(1)*906				; m at y=906
;	oplot,xr,mval(xr),color=color,th=3+5*(!d.name eq 'PS')
;	oplot,mval,color=color,lin=2
		print,'m0=',kx(0),'  &  m1=',kx(2),'  &  m2=',kx(1),form=	$
							'(a,f7.4,a,f9.6,a,f9.6)'
; compute rms WL diff of fit and good meas line positions
		line=wlvac(indwl,0:2)					; G102
		if igr eq 1 then line=wlvac(indwl,2:4)			; G141
		for ilin=0,nline-1 do begin
		    good=where(doord eq iord and dox1 gt 0 and dox2 gt 0	$
	    		and doxi(*,ilin) gt 0,ngood)
		    if ngood le 0 then goto,skip0
		    wlerr=fltarr(ngood)
	    	print,'   file   Xmeas (px) Xfit err(A)'
		    for igd=0,ngood-1 do begin			; for ea grat & order
				indx=good(igd)
				bval=bx(0)+bx(2)*dozx(indx)+bx(1)*dozy(indx)
				mval=kx(0)+kx(2)*dozx(indx)+kx(1)*dozy(indx)
				wnew=bval+mval*(xpx-dozx(indx))
; VY2 (-71) and HB12 (-5km/s)
				if strpos(dostr(indx),'G111') ge 0 then vel=-5. else vel=-71.
				xfit=ws(wnew,line(ilin)*iord*(1+vel/3e5))
				wlerr(igd)=(doxi(indx,ilin)-xfit)*mval
				print,dofil(indx),doxi(indx,ilin),xfit,wlerr(igd),	$
						' YZO=',dozy(indx),form='(a,2f8.2,f5.1,a,f4.0)'
			endfor					;end igd indiv meas loop
	    	print,'Line, rms(A), and avg=',line(ilin),stdev(wlerr,av),	$
	    				av,' #Obs=',ngood,form='(a,3f8.1,a,i3)'
		    read,st
	    endfor					; end ilin ref line loop
	    
	    
; ###change
;	goto,skip0
; check by comparing fitted and measured line positions:
		dmeas=m(2,*)
		bmeas=b(2,*)
		xpos=dozx(good)  &  ypos=dozy(good)
		berr=bmeas-bfit
		print,'   root     ZX (px) ZY     bfit (A) bmeas   berr'
		for i=0,ngood-1 do print,dofil(good(i)),xpos(i),ypos(i),		$
				bfit(i),bmeas(i),berr(i),form='(a,5f8.2)'
		print,'b rms=',stdev(bmeas-bfit)
;	plot,xpos,bmeas,psym=4,symsiz=.5,th=3		;cf b vals==nonsense
;	oplot,xpos,bfit,psym=4,symsiz=2.5
		merr=dmeas-mfit
;	for i=0,ngood-1 do print,dofil(good(i)),xpos(i),ypos(i),		$
;			mfit(i),dmeas(i),merr(i),form='(a,5f8.3)'
		print,'m rms=',stdev(dmeas-mfit)
;	plot,xpos,dmeas,psym=4,symsiz=.5,th=3		;cf m vals==nonsense
;	oplot,xpos,mfit,psym=4,symsiz=2.5
		read,st
; errors are correlated.
		!xtitle='B-error'  &  !ytitle='M-error'
;	plot,berr,merr					; Nonsense
;	read,st
; ###change
;	goto,skip0					; skip details
; show each order of each obs:
		!xtitle='WL'
		!ytitle='Net'
		xr=[9000,11000]
		if igr eq 1 then xr=[10500,17500]
		for igd=0,ngood-1 do begin			; for ea grat & order
			indx=good(igd)
			bval=bx(0)+bx(2)*dozx(indx)+bx(1)*dozy(indx)
			mval=kx(0)+kx(2)*dozx(indx)+kx(1)*dozy(indx)
			wnew=bval+mval*(xpx-dozx(indx))
			z=mrdfits('spec/spec_'+dofil(indx)+'pn.fits',1,hd,/silent)
			wl=z.wave
			net=z.net
			!mtitle=dostr(indx)+' '+grsm(igr)+' '+dofil(indx)+' order='+   $
							string(iord,'(i2)')
			plot,wl/iord,net,xr=xr
			vel=-71.  &  if strpos(star(indx),'G111') ge 0 then vel=-5.
; shift ref WL fiducial:
			for i=0,n_elements(wlvac(indwl,*))-1 do oplot,[wlvac(indwl,i), $
					wlvac(indwl,i)]*(1.+vel/3e5),[0,1e5],lin=2
			xyouts,.4,.85,'Zero-order at'+				$
		    	string([dozx(indx),dozy(indx)]+.5,'(2I4)'),/norm,chars=1.6
			oplot,wnew/iord,net,th=2			; ck wl
			print,grsm(igr),' ',dofil(indx)
			print,'b,m=',bval,mval
;OK		print,sxpar(hd,'b-1st'),sxpar(hd,'m-1st')
			print,'Measured Disp=',dmeas(igd)
			print,'Measured b=',bmeas(igd)
			print,'b,m errors=',bval-bmeas(igd),mval-dmeas(igd)
			print,'Angle=',sxpar(hd,'angle')
			read,st
		endfor
skip0:
	endfor							; end order loop
    if !d.name eq 'X' then read,st
endfor							; end 2 gratings
end
