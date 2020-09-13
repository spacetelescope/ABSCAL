pro wlmeas,dir,specdir=specdir,display=display
; 2013mar29 - collect meas of PN em lines for making dispersion relations
; 2013May6 - revamp... mv disp calc to wlmake.pro
; PROCEDURE: preceed w/ prewfc, follow w/ wlmake.pro (iterate)
;-
if not keyword_set(specdir) then specdir = 'spec'

if n_elements(dir) eq 0 then begin
	dir = ''
	wlmeas_file = 'wlmeas.tmp'
endif else begin
	if strpos(specdir, '/') lt 0 then specdir = dir + '/' + specdir
	wlmeas_file = dir + '/' + 'wlmeas.tmp'
endelse

fils = findfile(specdir+'/'+'spec_i*pn.fits')
filspn = fils
;	fils=strmid(fils,0,19)+'.fits'			; ECF direct image files

st=''
!y.style=1

nfils=n_elements(fils)
fwhm=[80.,40,120.,60]

;wlref=[9075.49,9529.61,10861.0,12821.5]		;Nicmos ISR 2009-06
;wlref=[9071.1, 9533.2, 10833.3,12823.0]		; isr 2009-17-18
;Eff WL always w/i 0.06px of lab WL. air lab:
wlair=[9068.6,9532.5,10830.,12818.1,16109.3,16407.2]
wlvac=wlair  &  airtovac,wlvac

; Rest vac WLs= 9071.1 9535.1 10833.  12821.6 16113.7 16411.7
ic5117_rudy=find_with_def('IC5117_rudy.txt','PNREF')
readcol,ic5117_rudy,wrudinput,frud	; IC5117-Rudy vac, no Vr corr

; NO airtovac wrud already vac---

close,6  &  openw,6,wlmeas_file
printf,6,'WLMEAS.pro for PN em line positions '+!stime
printf,6,' ROOT      STAR   GRAT X_0-ORD Y_0-ORD ORD'+string(wlvac,'(9I8)')

!xtitle='X (px) Fiducials: Dash=ref. WL (prelim scl), Dots=WFC3 line centroid'
!ytitle=''
pbox
xpx=findgen(1014)
for ifil=0,nfils-1 do begin
;for ifil=61,nfils-1 do begin
	z=mrdfits(fils(ifil),1,hd,/silent)
	wl=z.wave  &  net=z.net  &  dq=z.eps
; 256 is sat., 512 FF glitches, 32-CTE tail Table 2.5
	bad=where((dq and (32+256+512)) gt 0,nbad)
	pltnet=net
	if nbad ge 0 then pltnet(bad)=1.6e38
	fdecomp,fils(ifil),dsk,root_dir,root
	name=strmid(root,5,9)
	zxpos=sxpar(hd,'xzorder')
	zypos=sxpar(hd,'yzorder')
	grat=strtrim(sxpar(hd,'filter'),2)
	star=sxpar(hd,'targname')
	wrang=[8900,11100]  &  if grat eq 'G141' then wrang=[10800,17500]
;adj IC5117 (Vr=-26) template to Vy2-2 or HB12 (Vr=-5km/s) for Hb12 data
	vel=-71.2+26.1			; -71 & -26.1 radial veloc.
	if strpos(star,'G111') gt 0 then vel=-5+26.1
	wrud=wrudinput*(1+vel/3e5)		; IC5117 on WFC3 WL scl
; adj lab WLs to WFC3 obs:
	if strpos(star,'G111') gt 0 then pnvel=-5 else pnvel=-71.2
	wlref=wlvac*(1+pnvel/3e5)			; lab ref lines
; ###change for testing
;if grat ne 'G102' then goto,skipfil
;	for iord=1,1 do begin
	for iord=-1,2 do begin
	    if iord eq 0 then goto,skipord
	    dlam=fwhm(abs(iord)-1+(grat eq 'G141')*2)
;3rd order 10830 at 32490 dominates 2rder beyond 32490/2=~16245.
	    if iord eq 2 and grat eq 'G141' then wrang(1)=13000

	    xline=wlref*0.
	    for ilin=0,n_elements(wlref)-1 do begin		; meas wls
	    	; 
	    	; 	Okay, here's how it is with interactivity in this section.
	    	; 
	    	;	Basically, there are 2 times that you get a change to make
	    	;	input.
	    	;		- if ilin=4 (looking at the line at 16109.3 angstroms or
	    	;		  1.61 um). In this case, we *always* stop twice, once 
	    	;		  before and once after the fit, whether there's a good fit 
	    	;		  or not.
	    	;		- if lincen can't find a good fit
	    	;
	    	;	In either case, if you enter any text in the last input point
	    	;	(after flagging bad if ilin != 4 or after the second ilin=4 
	    	;	stop whether or not it's a bad fit), the program will enter a 
	    	;	manual fitting routine.
	    	;
	    	;	Manual fitting:
	    	;		- ask you to enter a center
	    	;		- plot that center
	    	;		- read in a line
	    	;		- if the line is empty, done. Otherwise, repeat manual fit.
	    
			if wrang(1) gt max(wl/iord) then goto,skipord
			if wlvac(ilin) lt wrang(0) then goto,skiplin
			if wlvac(ilin) gt wrang(1) then goto,skiplin
; analyze lines:
			smorud=smomod(wrud,frud,dlam)		;hi-res smoothed
			dw=(150+100*(grat eq 'G141'))/abs(iord)
			xgdrud=where(wrud gt wlref(ilin)-dw and wrud lt wlref(ilin)+dw)
		
			xgood=where(wl/iord gt wlref(ilin)-dw and wl/iord lt wlref(ilin)+dw)
			
			if keyword_set(display) then begin
				min_x = wl(min(xgood))
				max_x = wl(max(xgood))
				wl_good = where(wl gt min_x-1000. and wl lt max_x + 1000.)
				!mtitle=grat+' '+name+' Order,line='+string([iord,wlref(ilin)],'(i2,f8.1)')+'search range'
				plot,wl(wl_good),net(wl_good)
				plots,[min_x,min_x],[net(min(xgood))*0.5,net(min(xgood))*1.5]
				plots,[max_x,max_x],[net(max(xgood))*0.5,net(max(xgood))*1.5]
				read,st
			endif
			
	    	!mtitle=grat+' '+name+' Order,line='+string([iord,wlref(ilin)],'(i2,f8.1)')
			mx=max(net(xgood))
			maxpos=where(mx eq net)
			null_plot,xpx,pltnet,0,psym=-8,xr=[xgood(0),max(xgood)],yr=[0,mx],th=2
			oplot,net,lines=1,psym=-4		; show bad data as dots
			xrud=ws(wl/iord,wrud(xgdrud)); Hi-res mapped to WFC3
			smorud=smorud*!cymax/max(smorud(xgdrud)); norm ref data
			oplot,xrud,smorud(xgdrud),lin=1,th=0
			xorig=ws(wl/iord,wlref(ilin))
			oplot,[xorig,xorig],[0,1e6],lin=2
			xyouts,.12,.85,'FWHM='+string(dlam,'(i3)'),/norm

; bad lines w/ eyeball centers 256 is sat. 32-CTE tail Table 2.5
		    if name eq 'iab908seq' and iord eq  2 and ilin eq 3 then xline(ilin)=685.4
		    if name eq 'ibbu02uyq' and iord eq  1 and ilin eq 3 then xline(ilin)=422.6
   			if name eq 'ibbu02v9q' and iord eq -1 and ilin eq 4 then xline(ilin)=133.2
   			if name eq 'ic6906c0q' and iord eq  1 and ilin eq 0 then xline(ilin)=902.2
   			if name eq 'ic6907ciq' and iord eq -1 and ilin eq 5 then xline(ilin)= 69.6

			bad=where((dq(maxpos-1:maxpos+1) and (32+256+512)) gt 0,nbad)
			if ilin eq 2 and iord  eq 1 then begin		; brite 10830A
			    wlimaz,name,z.y,z.wave,xcen,ycen,dir
		    	xline(2)=xcen
			    xyouts,.12,.9,'X position from _ima',/norm		    
			end else begin				; usual process
; ###change 2013may27-retool -- start over w/ better centroiding:
;		    	if nbad gt 0 then begin	; new start ignore above bad's	    		
		    	if nbad gt 0 and xline(ilin) eq 0. then begin
					print,'WARNING: CNTRD USING BAD DQ'
; ###change
					if ilin eq 4 then begin
						print,"ilin=4"
						read,st ; extra SED reminder
					endif
				endif
; ###change 2013may27-retool -- start over w/ better centroiding:
			    badflag=0
			    if xline(ilin) eq 0 then begin	; comment to ignore bads
					del=max(xgood)-xgood(0)
					cont=(avg(net(where(xpx ge xgood(0) and xpx le xgood(0)+del/5)))+avg(net(where(xpx ge max(xgood)-del/5 and xpx le max(xgood)))))/2
					lincen,xgood,net(xgood),cont,xcentr,badflag
					xline(ilin)=xcentr
				endif
			endelse
			oplot,[xline(ilin),xline(ilin)],[0,99999],lin=1
			if badflag eq 1 then begin
				print,"badflag set"
				read,st
			endif
; ###change
;			if strpos(fils(ifil),'_ic6906c0q') ge 0 then read,st	; test
			if ilin eq 4 then begin
				print,'2nd ilin=4 stop'
				read,st
			endif
			if st ne '' then begin
redo:		   	print,'Enter Line Center Value'
				xcentr=1.			; set to float
				read,xcentr
		   		xline(ilin)=xcentr
				oplot,[xline(ilin),xline(ilin)],[0,99999],lin=1
		   		print,"   if name eq '"+name+"' and iord eq "+string(iord,'(i2)')+' and ilin eq '+string(ilin,'(i1)')+' then xline(ilin)='+string(xcentr,'(f5.1)')
				read,st
				if st ne '' then goto,redo
			endif
skiplin:
		endfor					; end line loop
		printf,6,name,star,grat,zxpos,zypos,iord,xline,form='(a9,1x,a7,a5,2f8.2,i3,1x,9f8.2,1x)'
				
skipord:					; skip 0-order
	endfor					; end order loop
skipfil:
endfor						; end file loop
close,6
end
