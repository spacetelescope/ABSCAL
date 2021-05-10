; 2018jun25 - to measure spectral offsets
;
; INPUT - see ###changes below
; METHOD - Xcorrel all the .mrg Flux or net for WDs w/ hrs_offset for ranges:
; g102: 7500- 11800   g141: 10000-17500 against gd153.g102,141-ich401 for WDs
; g102: 9752.6 -11241 g141: 12520-13120 against Vega model for A-stars grw.etc
; g102: 8000-10000    g141: skip  	vs Calspec for kf*,2m*,p330e,etc. 
;							Fix g141 during mrgall
; 	Nominal Disp is Ang/px=24.5, 46.5 for g102,141.
; Units in output file are px in 1st line & Ang. in 2nd line.
; OUTPUT - wl.offset file & rename as wl.offsets-prev to save
;	   wl.fixes for formatted  shifts for >0.4px or >0.2px for 3 prime WDs,
;		where eye shift, etc takes precedence??
;	 - ENTER in wfcwlfix.pro
; HISTORY - adapted from stiscal/nowavcal.pro
;	  - 2018jul3 - add smoothing to ref SED, which makes little diff, maybe
;		-5A for GRW G102.

; SIGN CONVENTION: same as stiswlfix.pro, ie convert px to A & ADD to wl array
;	Paschen gamma,beta=10941.1, 12821.6 (10938.1, 12818.1-air)
; GOOD templates w/ paschen lines: gd153.g102-ich401, gd153.g141-ich401

; 2020jan - #### BUT Paschen lines are wrong! cf gd71,153 w/ 1802271, eg !!!!!!!

;	 10052.6,9548.8,9332.2...
; 8752.86 8865.32 9017.8 9232.2 9548.8 10052.6 10941.082 12821.578 18756.4 vac
;-

st=''
pset
red=[0,255,  0,  0,255] 		; see flxlim.pro for 6 saturated colors
gre=[0,  0,255,  0,255]
blu=[0,  0,  0,255,255]
loadct,0
tvlct,red,gre,blu
!y.style=1
!xtitle=''
!ytitle=''
!p.charsize=1.5

wdref='spec/'+['gd153.g102-ich401','gd153.g141-ich401']		; WD net ref
fils=findfile('spec/*.mrg')
; ###change
fils=findfile('spec/gaia59349039.mrg')
fdecomp,fils,disk,dir,dostar
grating=['G102','G141']
lcmode=strlowcase(grating)
close,6  &  openw,6,'wl.offsets'
printf,6,'Wavelength offsets from wavoff.pro '+!stime
printf,6,'     Rootname      Star   Grat  Aperture Propid'+    $
		' hrs_offset'
close,7  &  openw,7,'wl.fixes'		; the lines for wfcwlfix.pro

; ###change
for imod=0,n_elements(grating)-1 do begin
;for imod=1,1 do begin
    last=''				   ; last ref spec.
    optmode=grating(imod)
; ###change
    for istr=0,n_elements(dostar)-1 do begin
;    for istr=0,0 do begin
	wbeg=7500.  &  wend=11800.		   ; G102 endpoints for X-correl
	if optmode eq 'G141' then begin
   	    wbeg=10000.  &  wend=17500.  &  endif
	curr=wdref(imod)			   ;current ref spectrum
	wfcobs,'dirirstare.log',fils,grat,aper,star,optmode,'',dostar(istr)
	if fils(0) eq '' or star(0) eq 'C26202' then goto,skipit
	fils=fils(where(fils ne ''))
	print,fils
	icnt=0
	for ifil=0,n_elements(fils)-1 do begin
;	for ifil=71,71 do begin
		help,fils(ifil)
; read indiv obs
		wfcflx,'spec/spec_'+fils(ifil)+'.fits',hd,wl,forig,net
		worig=wl
		aperture=aper(ifil)
        	targ=strtrim(sxpar(hd,'targname'),2)
        	root=strlowcase(strtrim(sxpar(hd,'rootname'),2))
        	prop=strtrim(sxpar(hd,'proposid'),2)
      		date=strtrim(sxpar(hd,'date-obs'),2)
		icnt=icnt+1
		starnam=strlowcase(targ)  &  remchar,starnam,'+'	
		if strmid(starnam,0,1) eq '1' or 			$
				strmid(starnam,0,2) eq 'bd'  or 	$
				strmid(starnam,0,3) eq 'grw'  or 	$
				strmid(starnam,0,2) eq 'hd'  or 	$
				strmid(starnam,0,4) eq 'gaia' or	$ ;20jan
				strmid(starnam,0,2) eq 'wd' and		$
				strmid(starnam,0,4) ne 'wd16' then begin 
			curr='../calspec/alpha_lyr_mod_002.fits'		; R=500 A-star model
;2018jul3		wbeg=9400.  &  wend=11100.; G102 endpoints for X-correl
			wbeg=9752.6  &  wend=11241.;G102 endpoints for X-correl
    			if optmode eq 'G141' then begin
   	    			wbeg=12520.  &  wend=13120.  &  endif
			if strmid(starnam,0,4) eq 'gaia' then begin	;20jan
				wbeg=10800  &  wend=11100		;g102
				if optmode eq 'G141' then begin
					wbeg=10650  &  wend=11250  &  endif
				endif
			endif
        	 if strpos(starnam,'kf') eq 0 or		$ ;X-cor w/ STIS 
        	 		strpos(starnam,'2m') eq 0 or		$
        	 		starnam eq 'p330e' or			$
        	 		starnam eq 'snap2' or			$
        	  		starnam eq 'vb8' then begin
        		curr='../calspec/'+starnam+'_stisnic_006.fits'
			if starnam eq 'p330e' then curr=		$
				'../calspec/'+starnam+'_stisnic_008.fits'
			if starnam eq 'kf06t2' then curr=		$
				'../calspec/'+starnam+'_stisnic_004.fits'
			wbeg=8000.  &  wend=10000.; G102 endpoints for X-correl
; Fix G102 WLs vs STIS and then G141 vs G102 during mrgall
   			if optmode eq 'G141' then goto,skipit
			endif
		if curr ne last then begin
			if strpos(curr,'fits') gt 0 then ssreadfits,	$
					curr,hdr,sumwav,sumflx else begin
				rdf,curr,1,d	 ; WD REF SPECTRUM
		   		sumwav=d(*,0)  &  sumflx=d(*,3)  &  endelse
			if strpos(curr,'stis') gt 0 then		$
				sumflx=smomod(sumwav,sumflx,25.)	;18jul3
			if strpos(curr,'mod') gt 0 then		$
				sumflx=smomod(sumwav,sumflx,100.)	;18jul3
			print,'REFERENCE SPECTRUM='+curr
			printf,6,'REFERENCE SPECTRUM='+curr
			endif
		if wl(0) gt wbeg+400 or wl(-1) lt wend-400 and 		$
				strpos(curr,'gd153') ge 0 then begin
			print,'skip partial coverage ',root,minmax(wl)
			printf,6,'skip partial coverage ',root,minmax(wl)
			goto,skipit
			endif
		last=curr
		if strpos(curr,'gd153') ge 0 then forig=net   ;weak line,use net
		fx=median(forig,3)		; rm noise and dropdown px
		indx=where(wl ge wbeg and wl le wend)		;G102
		wl=wl(indx)  &  fx=fx(indx)
		!mtitle=root+' '+targ+' '+optmode
; resample to a 10x finer grid:
		npts=n_elements(wl)
		wfine=findgen(10*npts+1)*(wl(npts-1)-wl(0))/(10*npts)+wl(0)
		linterp,wl,fx,wfine,fx			; resamp data
; ref spectr on fine data WL scale:
		linterp,sumwav,sumflx,wfine,sumfine
; normalize ref to data
		sumfine=sumfine*total(fx)/total(sumfine)
; DJL: With absolute flux units the sigmas are too small, so *1e14 !!!
; Width 100 is 10px=+/-5px allowable range for the offset
		hrs_offset,fx*1e14,sumfine*1e14,xofagk,0,100 
; for net		hrs_offset,fx,sumfine,xofagk,0,100
		if strmid(starnam,0,4) eq 'gaia' and optmode eq 'G141'	$
				then xofagk=0	; no lines. Use whole net?

		avoff=-xofagk		; Use hrs_offset result. Units of 0.1px
		sft4plt=shift(fx,avoff)  &  npts=n_elements(wfine)
		good=where(indgen(npts) ge avoff and indgen(npts) lt npts+avoff)
		woff=avoff/10.				; back to px units
		wloff=woff*(wl(10)-wl(0))/10		; Ang units using disp.
; ###change
;		goto,skiplts				; 2017apr24
		if !d.name eq 'X' then window,0
		yrang=minmax(sumfine)
		yrang=[yrang(0)*.8,yrang(1)*1.2]
	        plot,wfine,sumfine,/nodata,yr=yrang	; estab x,y axes
		oplot,wfine,sumfine,color=1		; Ref star
		oplot,worig,forig				; orig data
		oplot,wfine(good),sft4plt(good),lines=1,thic=3
		xyouts,.3,.55,'Ref. spectrum='+curr,/norm
		xyouts,.4,.6,'offset (px,A)='+string([woff,wloff],	$
							'(f6.2,f6.1)'),/norm
		xyouts,.3,.5,'thin-orig, red-Reference, dots-shifted',/norm
		plotdate,'wavoff'
skiplts:
		fmt='(i3,a10,a12,a5,a10,a6,f8.2,"px",a11)'
		printf,6,icnt,strupcase(root),targ,optmode,aperture,prop,  $
				woff,date,form=fmt

; add to corr already made:
		wlfix=sxpar(hd,'WLOFFSET')
		
; ####CHANGE
;		WLFIX=0					; to start over
		
		newfix=wlfix+wloff
		printf,6,'     original wlfix='+string(wlfix,'(f6.1)')+	$
			'        New fix='+string(newfix,'(f6.1/)')+' Angstrom'
		minfix=0.4
		if strmid(targ,0,2) eq 'G1' or strmid(targ,0,2) eq 'GD'	$
							then minfix=minfix/2
		if abs(woff) ge minfix then printf,7,"        '"+root+	$
			"': offset="+string(newfix,'(f5.0/)')+		$
			'			;'+strmid(!stime,9,2)+	$
			strmid(!stime,3,3)+'-'+strmid(targ,0,5)+' '+optmode
 		if !d.name eq 'X' then read,st
skipit:
		endfor				; ifils loop
	    endfor				; 3 star loop
	endfor					; 2 grating loop
close,6  &  close,7
end
