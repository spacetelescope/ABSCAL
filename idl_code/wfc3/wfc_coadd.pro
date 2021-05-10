;+
;			wfc_coadd
;
; Plot and Co-add wfc3 spectra
;
; CALLING SEQUENCE:
;	wfc_coadd,target,root
;
; INPUTS:
;	target - target name
;	root   - first 6 char of rootname to distinguish repeat obs.
;
; OPTIONAL KEYWORD INPUTS:
;	subdir = subdirectory to read input spec files from and to write
;		the output files to. (default = 'spec')
;	/ps - write the output files to a postscript file
;	/noplot - do not plot the results
;	prefix - prefix of the output ascii file
;		default = target name
;	dlam - wavelength shift in microns to be added to output wavelengths
;			dlam is a vector corresponding to the 2 grism modes.
;	star - string star id to be added to the output file names
;	/double - double the length of the output wavelength vector by
;		subsampling by a factor of 2.
;	dirlog - log of observations. default= dirwfc.log
;
; History:
;	version 1, D. Lindler, Feb. 2004
;	04jul23 - add root & dlam keyword for wavelength shifts. RCB
;	July 2004, Lindler, added STAR keyword input, added double
;		keyword input
;	Sept. 27, 2004, modified to use average of bad data for points where
;		all the data have a bad data quality
;	05feb12 - rcb added dirlog keyword
;	15-Mar-2005 - DJL, changed output formats to E11.3, added date-obs
;		to title in output ascii file
;	18-Mar-2005 - added stat. error computation when all data bad. npts
;		set to zero.
;	05dec01 - djl, added coaddition of multiple observations at the same
;		dither location.
;	06feb28 - rcb, added mean back from contin subtraction to output bkg
;			to get approx idea of the total bkg.
;	06mar19 - rcb require more >2 mult obs at same loc for sep. dith output
;	06aug7  - rcb add output wfc_COADD + time stamp line
;	06aug8-DJL added weighting using the effective obs. time for each value.
;		added time to output table
;	06aug18 - DJL - average background is now a straight average of the
;		individual backgrounds
;	07Jun08 - DJL - removed old dither processing.  (obs at same dither
;		position now coadded by wfc_PROCESS)
;       12apr13 - RCB - DQ flags (4,8,16,32+64+128+256+512) are bad data.
;	12Apr18 - RCB - cross-correlate each order separately & resamp to
;			same dispersion, ie delam/px
;	12jun5 -Make plots, sum, & output only for orders -1,1,2
;	12jul24-GROSS output is Un-weighted avg, while NET is wgted by exptime
;		for some antique reason in NIC_coadd. Ignore GROSS.
;	15may26-Try omitting 32-CTE tail and 512-Bad FF from bad DQ flagging
;-
;---------------------------------------------------------------------------
pro wfc_coadd_write,filename,target,star,obs,h, 			$
			filter,wave,gross,back,net,sigma, 		$
			stat_error,error_mean,npts,time


		close,1 & openw,1, filename
		printf,1,'Gross and Back columns have Flat Field applied'
		printf,1,'Written by prewfc/wfc_COADD.pro '+!stime
		printf,1,'Co-add list=',obs
		printf,1,'    wave     gross      back      net        stdev' +$
			'      stat     error    Npts   Expo'
		printf,1,'                                                  ' +$
		        '      error     mean           Time'
		printf,1,' ###    1'
		printf,1,' '+target+star+' '+filter+' '+ $
			strmid(obs(0),0,6)+'   '+strtrim(sxpar(h,'date-obs'),2)
		sub = sort(wave)
		for k=0,n_elements(wave)-1 do begin
			i = sub(k)
			printf,1,wave(i),gross(i),back(i),net(i),sigma(i), $
			   stat_error(i),error_mean(i),fix(npts(i)),time(i),$
			   format='(F7.0,6E11.3,I4,F9.2)'
		end
		printf,1,'0 0 0 0 0 0 0 0 0'
		close,1
end

; %%%%%%%%%%%%%%%%   MAIN ROUTINE    %%%%%%%%%%%%%%%%%%%%%%%%

pro wfc_coadd,target,root,ps=ps,noplot=noplot,subdir=subdir, 		$
	prefix = prefix, star=star, double=double,dirlog=dirlog
print,'STARTING wfc_coadd'
st=''
	!x.style=1
	!p.charsize=2
	if n_elements(subdir) eq 0 then subdir = 'spec'
	if n_elements(star) eq 0 then star = ''
	!ytitle='DN/sec for '+target+star
	!xtitle='!17WAVELENGTH (microns)'
;
; get observation list
;
	logfil='dirwfc.log'
	if keyword_set(dirlog) then logfil=dirlog
;	flags=(4+8+16+32+64+128+256+512); add 4, 8, & 16-RCB 2012apr13
	flags=(4+8+16+64+128+256)	;512 & 32 OK per icqv02i3q RCB 2015may26
	filters = ['G102','G141']
	for ifilt=0,1 do begin
		wfcobs,logfil,allobs,allfilt,aper,starname,		$
					filters(ifilt),'',target
		obs=allobs  &  filter=allfilt
		good = where(strpos(obs,root) ge 0 and strpos(aper,'UVIS') lt 0)
; 2018May2	 and strpos(aper,'SUB') lt 0)
; special patch to include an orphan obs that should be part of iab901 or iab904
		if root eq 'iab901' then good=		$
				where(strmid(allobs,0,6) eq root or 	$
				strmid(allobs,0,6) eq 'iab9a1')		; G102
		if root eq 'iab904' then good=		$
				where(strmid(allobs,0,6) eq root or 	$
				strmid(allobs,0,6) eq 'iab9a4')		; G141
		if good(0) eq -1 then goto,next_ifilt
; ck if PN wavecal data:
		obs=obs(good)  &  filter = filter(good)
		pnposs=findfile(subdir+'/*'+obs(0)+'*')
		print,"pnposs",pnposs
		good=where(strpos(pnposs,'pn.fits') gt 0,npn)
		if npn gt 0 then star='pn'		

		file_list = subdir+strlowcase('/spec_' + obs + star + '.fits')
		ckscan=findfile(file_list(0))
		if ckscan eq '' then file_list=subdir+			$
					strlowcase('/imag_'+obs+star+'.fits')
		ngood=n_elements(file_list)		;# of spec to do
		files = file_list
		nout = 0
		for i=0,ngood-1 do begin
			file=files(i)
			a = mrdfits(file,1,h,/silent)		; READ DATA
			if nout eq 0 then begin
; 2018may2- why extra 5? I see no reason...	
;			   ns=n_elements(a.wave)+5;1st spec must have most pts
;1st spec must have most pts, otherwise longer spec will overflow arr below. I
;	could just make them all 1014 & cut down later.
			   ns=1014		; 2018may14 TRY
			   w = fltarr(ns,ngood)-1e20	; flag for no data
			   f = fltarr(ns,ngood)
			   e = fltarr(ns,ngood)
			   g = fltarr(ns,ngood)
			   b = fltarr(ns,ngood)
			   eps = intarr(ns,ngood)
			   y = fltarr(ns,ngood)
			   crval1 = dblarr(ngood)
			   crval2 = dblarr(ngood)
			   time = fltarr(ns,ngood)
			end
; no-op?? could decrease but NOT increase!
; 2018may14 - NG subarr+full???		ns = n_elements(a.wave)<ns
			w(0,nout) = a.wave
; *****************************************************************************
; CHECK for SCAN or STARE obs:
			if ckscan eq '' then begin
; SCANNED DATA: Sum up all the good lines for ea spectrum
; for now assume rows 500-950 are good and that bkg=0 & statistical err~0
			   img=a.scimage
			   err=a.err
			   dq=a.dq
			   ybeg=500  &  yend=950	; good Y range of scan
			   gross=fltarr(1014)		; re-initialize ea scan
			   tim=gross
			   timcon=tim+0.13/sxpar(h,'scan_rat')	; exptime/row
			   for iy=ybeg,yend do begin
			   	mask=(dq(*,iy) and flags) eq 0	;mask of good px
				gross=gross+img(*,iy)*mask	;tot good signal
			   	tim=tim+timcon*mask		;total good time
				endfor
; Corr spectrum in e/s to good exp time. Assume Bkg=0
			   f(0,nout) =  gross*(yend-ybeg+1)*timcon/(tim>1)
			   e(0,nout) =  gross*0.
			   y(0,nout) =  gross*0		; not used?
			   eps(0,nout)= gross*0	
			   b(0,nout) =  gross*0
			   g(0,nout) = gross		; NO wgt, curiously?
			   time(0,nout)=tim
			 end else begin
; POINT SOURCE DATA
			   f(0,nout) = a.net	; rcb says this would fail for
			   e(0,nout) = a.err	;longer than orig ns,ngood array
			   y(0,nout) = a.y
			   eps(0,nout) = a.eps
			   b(0,nout) = a.back
			   g(0,nout) = a.gross
			   time(0,nout) = a.time
			   endelse
			nout = nout + 1		; # of spectra to process
nexti:
		end				;i loop to read & store all data


; CO-ADDING SECTION **********************************************************
		if nout eq 0 then begin
			print,'ERROR: Spectra not found for '+filters(ifilt)+ $
					' '+target+' '+root
			stop
		end		; ngood loop to read in all data for grism
; In case there are spectra w/ ns=# of samples < original ns=1014:
		ns=0					; reset & pick max #:
		for ick=0,ngood-1 do begin
			dum=where(w(*,ick) gt -1e19,ngd) ;elim -1e20 flags
			ns=max([ns,ngd])
print,file_list(ick),ns,ngd
;if ns gt ngd then stop
;bad=where(w(*,ick) gt 11450 and w(*,ick) lt 15400,nbad)
;if nbad gt 0 then stop
			endfor
		print,'Set input arrays to max # of good points=',ns
		w = w(0:ns-1,0:nout-1)
		f = f(0:ns-1,0:nout-1)
		e = e(0:ns-1,0:nout-1)  	    
		eps = eps(0:ns-1,0:nout-1)
		y = y(0:ns-1,0:nout-1)
		b = b(0:ns-1,0:nout-1)
		g = g(0:ns-1,0:nout-1)
		time = time(0:ns-1,0:nout-1)

;
; create net array (ie f) without bad data
;
		fgood = f			; fgood approx rm bad data
		mask = (eps and flags) eq 0	;mask=1 for good unflagged pixels
		nspec=nout
;2018may13 - Patching flagged points w/ previous point is a BAD idea, esp 
;	if spec drops fast. Try just omitting bad data, but omitting bad pts 
;	screws up indexing.
;	Interolate to fix bad data, only if both neighboring pts are good.
		for ii=0,nspec-1 do begin
		    for jj=1,ns-3 do if mask(jj,ii) eq 0 then begin
			if mask(jj-1,ii) gt 0 and  mask(jj+1,ii) gt 0	$
			    then fgood(jj,ii)=(fgood(jj-1,ii)+fgood(jj+1,ii))/2$
; 2018may19 - also interpolate for 2 bad pts together
			else if mask(jj-1,ii) gt 0 and  mask(jj+2,ii) gt 0   $
			    then fgood(jj:jj+1,ii)=			$
			    (fgood(jj-1,ii)+fgood(jj+2,ii))/2	
;if ii eq 2 and jj ge 939 then stop 
			endif
			endfor

		regbeg=[-13500.,-3800,13500]		;2012jun5: 3 order limit
		regend=[-3800,13500,27000]
		wbeg=7500.  &  wend=11800.		; endpoints for X-correl
		if root eq 'icqw01' then wend=11450	; end of uncontam. WLs
		if filters(ifilt) eq 'G141' then begin
			regbeg=[-19000.,-5100,19000]
			regend=[-5100,19000,38000]	
			wbeg=10000.  &  wend=17500.
			endif
; update WL regions to actual WL coverage:
		regbeg(0)=min(w(0,*))>regbeg(0)
; 2018may2 - -1 was 1013
		regend(2)=max(w(-1,*))<regend(2)
; 3rd order poor, eg G102 7600*3=22800 - 11700*3=35100A, while 4th starts at
;	7600*4=30400 or 10133 in the 3rd order & may be noisy anyhow, so:
; Register just 3 orders: -1 to +2, even tho 2&3 overlap a bit from 22800 to
;	23400, ie 11400 to 11700A. Incl 0-ord w/ +1 for a check.
		ireg=-1				; WL region init.
		wmrg=1e6			; merged WL init.

		for iord=-1,2 do begin
		  if iord eq 0 then goto,nodata
		  ireg=ireg+1
		  wb=wbeg*iord  &  we=wend*iord ; region to X-corelate
		  if iord eq -1 then begin	; 2015May25
		  	wb=-wend  &  we=-wbeg  &  endif
; find indices of spectra covering each order at 90% level
		  d10=(we-wb)*.14	;2018may19-.10->.14 for ibwib6m8q
		  jgood=intarr(nspec)-1		; init index for ea spec to -1
		  for j=0,nspec-1 do begin
; j is number of spec w/ data in region at 90% level. Works for wl=-1e20 flags.
			if max(w(*,j)) ge (we-d10) and w(0,j)   	$
				le (wb+d10) then jgood(j)=j	; Neg d10 OK
;if root eq 'ibwib6' then print,obs(j),max(w(*,j)),(we-d10),w(0,j),(wb+d10)
;if iord eq 1 then stop
;if ireg eq 3 and j eq 6 then stop
			endfor
		  if max(jgood) lt 0 then goto,nodata		; jgood=-1 init.
		  igood=jgood(where(jgood ge 0))
		  print,filters(ifilt),' order, spectra to X-correlate',$
		  						iord,',',igood
; find approximate offset between spectra using input wavelength scales
; and actual offsets using cross correlation
; 2012Apr18-hrs_shift NG for diff dispersions, so find wcor differently:
		  ngood=n_elements(igood)	; spec covering region wb--we
		  wcor=fltarr(ns,ngood)
		  wcor(*,0)=w(*,igood(0))		; corr to 1st good spec
		  if ngood eq 1 then goto,onespec	; only one to use
		  wl1=w(*,igood(0))			; 1-D 1st good WL arr
		  good=where(wl1 gt -1e10)	; elim -1e20 no-data flags
		  wl1=wl1(good)
		  net1=fgood(good,igood(0))
		  wcent=(wb+we)/2
;if iord eq 1 then stop
		  icen1=fix(ws(wl1,wcent))		; px of central WL
		  delam=wl1(icen1+1)-wl1(icen1)		; dispersion
		  if wb lt min(wl1) then wb=min(wl1)
		  if we gt max(wl1) then we=max(wl1)
; X-correl remaining igood spectra to net1 of 1st igood(0) spec/
		  for i=1,ngood-1 do begin	;wcor corr for offsets & shifts
		    wli=w(*,igood(i))		; 1-D current WL arr
		    good=where(wli gt -1e10)	; elim -1e20 no-data flags
		    wli=wli(good)		;2018may3 rm no data pts
		    flxi=fgood(good,igood(i))
; put both approx nets on same px scale
		    linterp,wli,flxi,wl1,neti
; find px range for common WL coverage
		    wbcm=wb  &  wecm=we		;common wl range
; 2015May22-restrict lower S/N G102 2nd order to FWHM region
		    if iord eq 2 and filters(ifilt) eq 'G102' then begin
		    	wbcm=15500.  &  wecm=18000.  & endif
		    if wbcm lt min(wli) then wbcm=min(wli)
		    if wecm gt max(wli) then wecm=max(wli)
		    ib=fix(ws(wl1,wbcm)+.5)>5		; beg index of xcorel-
		    ie=fix(ws(wl1,wecm)+.5)<1009	; end index      -region
		    if ie le ib then stop		; idiot ck
		    print,'Cross-corel WL range=',wbcm,wecm
; 2015may22 - increase search region from default 15 to 20 for ibbt03f2q and to
;		24 for ibwq1asmq 2nd ord.(ZO off img)
;		22 for ic6904b4q partial -1 ord
		    width=22
		    if root eq 'ibwt01' then width=26

		    cross_correlate,net1(ib:ie),neti(ib:ie),offset,width=width

; not enough coverage. Allow only 1000A to be missing in X-correl:
		    if (wend-wbeg)-abs((we-wb)/iord) gt 1000 then offset=0.
		    print,files(igood(0)),' ',files(igood(i)),' shift=',offset
		    if abs(offset) gt 2.7 or root eq 'xxxxxx' then begin
		  	plot,wl1,net1,xr=[wb,we]		;1st spec
		  	oplot,wl1,neti,lin=1  			;resamp ith spec
; WL corr. ith
		  	oplot,w(*,igood(i))+offset*delam,fgood(*,igood(i)),th=2 
			print,offset,'=X-corel offset set to 0'
			offset=0
;		 	read,st
			endif
;if iord eq 1 then stop
		    wcor(*,i)=w(*,igood(i))+offset*delam	; Corr WLs
		    if abs(offset) gt 12 then stop	; corners in ibwt01(uqq)
		    if !err ne 0 then stop ; offset at max of search region=15px
		    endfor				; i loop 1-->ngood-1
;if iord eq 1 and ifilt eq 1 then stop
;
; postscript output
;
		  if keyword_set(ps) then begin
			dev = !d.name
			set_plot,'ps'
			device,file=subdir+'/'+				$
				strlowcase(target+star+'-'+root(0))+	$
				'_coadd'+string(ireg,'(i1)')+		$
				strlowcase(filters(ifilt))+'.ps'
			!p.font=0
			end else if not keyword_set(noplot) then window,0
		  if not keyword_set(noplot) then begin
; 1st plot - uncorr WLs
			wmin=min(w)>regbeg(ireg)  &  wmax=max(w)<regend(ireg)
			xrang=[wmin,wmax]/1e4
		  	ind=where(w(*,igood(0)) ge regbeg(ireg) and 	$
		  		w(*,igood(0)) lt regend(ireg))
			!p.title=filters(ifilt) + ' '+strmid(obs(0),0,6)
			plot,w(ind,igood(0))/1e4,f(ind,igood(0)),xstyle=1,$
				xr=xrang,yrange=[0,max(f(ind,igood(0)))]
			for i=1,ngood-1 do begin
; ireg=iord+1, ie. 0,1,2 for iord=-1,1,2
		  		ind=where(w(*,igood(i)) ge regbeg(ireg) and $
		  			w(*,igood(i)) lt regend(ireg))
				oplot,w(ind,igood(i))/1e4,f(ind,igood(i))
				endfor
			xyouts,0,0,'wfc_coadd '+!stime,/norm,charsize=0.7
; 2nd plot - Corr, WLs
		  	ind=where(wcor(*,0) ge regbeg(ireg) and 	$
		  		wcor(*,0) lt regend(ireg))
			!p.title=filters(ifilt) + '  WLs matched '+	$
				'for order='+string(iord,'(i2)')
			plot,wcor(ind,0)/1e4,f(ind,igood(0)),xstyle=1,	$
				xr=xrang,yrange=[0,max(f(ind,igood(0)))]
			for i=1,ngood-1 do begin
		  		ind=where(wcor(*,i) ge regbeg(ireg) and $
		  				wcor(*,i) lt regend(ireg))
				oplot,wcor(ind,i)/1e4,f(ind,igood(i))
				endfor
			xyouts,0,0,'wfc_coadd '+!stime,/norm,charsize=0.7
;
; 3rd plot - remove bad data
;
			!p.title=filters(ifilt) + ' Bad DQ removed'
			fcor1 = f + (mask eq 0)*9e9
		  	ind=where(wcor(*,0) ge regbeg(ireg) and 	$
		  		wcor(*,0) lt regend(ireg))
			plot,wcor(ind,0)/1e4,fcor1(ind,igood(0)),xr=xrang, $
			 	max_val=1e9,yrange=[0,max(f(ind,igood(0)))]
		   	for i=1,ngood-1 do begin
		  		ind=where(wcor(*,i) ge regbeg(ireg) and $
		  				wcor(*,i) lt regend(ireg))
				oplot,wcor(ind,i)/1e4,		$
					fcor1(ind,igood(i)),max_val=1e9
				endfor
		   	xyouts,0,0,'wfc_coadd '+!stime,/norm,charsize=0.7
			if not keyword_set(ps) then read,st
			if !d.name eq 'PS' then psclose
		    endif				; end postscript

; coadd the ngood spectra separately for each region
;
onespec:
		  var = e*e
; Master WL scale that covers all of region, or whatever part covered by data:
		  imin=where(wcor(0,*) eq min(wcor))  &  imin=imin(0)
		  wave=wcor(*,imin)			;min WL covered
		  if max(wave) lt regend(ireg) and 			$
		  			max(wcor) gt max(wave) then begin
; 2018may2 - -1 was 1013
		  	imax=where(wcor(-1,*) eq max(wcor))  &  imax=imax(0)
			ind=where(wcor(*,imax) gt max(wave))
			wave=[wave,wcor(ind,imax)]	;max WL covered
			endif
		  if keyword_set(double) then begin
		  	dlam=mode(wave(1:*)-wave(0:-2))/2
			wave = [wave,wave(0:-2)+dlam]
			wave = wave(sort(wave))
;bad=where(wave gt 11450 and wave lt 15400,nbad)
;help,wave,iord,good,wave
;if nbad gt 0 then stop
			endif
		  nsd = n_elements(wave)
		  fsum = dblarr(nsd)
		  ftsum = dblarr(nsd)
		  f2sum = dblarr(nsd)
		  gsum = fltarr(nsd)
		  bsum = fltarr(nsd)
		  tsum = fltarr(nsd)
		  npts = fltarr(nsd)
		  varsum = fltarr(nsd)
		  f_interp = fltarr(nsd,ngood)
		  b_interp = fltarr(nsd,ngood)
		  g_interp = fltarr(nsd,ngood)
		  m_interp = intarr(nsd,ngood)
		  y_interp = fltarr(nsd,ngood)
		  var_interp = fltarr(nsd,ngood)
		  time_interp = fltarr(nsd,ngood)

		  for i=0,ngood-1 do begin		; # spec covering region
; account for short spectra w/ lots of zero WLs:
		    good=where(wcor(*,i) gt -1e10)	;-1e20 flags no data
		    wli=wcor(good,i)
		    linterp,wli,f(*,igood(i)),wave,fint,missing=0.
		    linterp,wli,b(*,igood(i)),wave,bint,missing=0.
		    linterp,wli,g(*,igood(i)),wave,gint,missing=0.
		    linterp,wli,var(*,igood(i)),wave,vint,missing=0.
		    linterp,wli,float(mask(*,igood(i))),	 $
		  				wave,mint,missing=0.
		    linterp,wli,y(*,igood(i)),wave,yint,missing=0.
		    linterp,wli,time(*,igood(i)),wave,tint,missing=0.
		    mint = mint ge 1.0		  ;mask either 0(bad) or 1(good)
		    fsum = fsum + mint*fint	  ; sum of net ct/s
		    ftsum = ftsum + mint*tint*fint ;sum of net counts*exptime
		    gsum = gsum + mint*gint	  ; gross ct/s. NO wgt?
		    tsum = tsum + mint*tint	  ; sum of exptimes
		    f2sum = f2sum + mint*double(fint)^2 ; sum of the squares
		    varsum = varsum + mint*tint^2*vint  ; time wgtd variance
		    npts = npts + mint		  ; sum of good pts
		    f_interp(*,i) = fint  	  ; retain  indiv.
		    b_interp(*,i) = bint  	  ;	  interpolated
		    g_interp(*,i) = gint  	  ;	  values...
		    m_interp(*,i) = mint
		    y_interp(*,i) = yint
		    var_interp(*,i) = vint
		    time_interp(*,i) = tint
;help,i,igood(i),ngood
;print,minmax(wave),minmax(wli),minmax(gsum),minmax(ftsum),minmax(tsum)
		    endfor
;if filters(ifilt) eq 'G141' then stop
;if iord eq 1 and ifilt eq 1 then stop
;
; use average when all data is bad
;
		  all_bad = where(npts eq 0,n_all_bad)
		  if n_all_bad gt 0 then begin
			fbad = double(f_interp(all_bad,*))
			tbad = time_interp(all_bad,*)
			if ngood gt 1 then begin	; num. of spectra 
				fsum(all_bad) = total(fbad,2)
				tsum(all_bad) = total(tbad,2)
				ftsum(all_bad) = total(fbad*tbad,2)
				gsum(all_bad) = total(g_interp(all_bad,*),2)
				f2sum(all_bad) = total(fbad*fbad,2)
				varsum(all_bad) = total(var_interp(all_bad,*)  $
								*tbad^2,2)
			    end else begin
				fsum(all_bad) = fbad
				tsum(all_bad) = tbad
				ftsum(all_bad) = fbad*tbad
				gsum(all_bad) = g_interp(all_bad,*)
				f2sum(all_bad) = fbad*fbad
				varsum(all_bad) = var_interp(all_bad,*)*tbad^2
				end
			npts(all_bad) = ngood	; ngood= # of spec
			endif
; Compute means on wave grid:
		  if ngood gt 1 then bsum = total(b_interp,2) else bsum=b_interp
		  totweight = tsum + (tsum eq 0)	; make 0 exptimes=1
		  stat_error = sqrt(varsum)/totweight 	;propagated stat. err
		  net= float(ftsum/totweight)		; WEIGHTED avg
		  back = bsum/ngood
		  gross = gsum/(npts>1)			; UN-WEIGHTED avg?
		  sigma = float(sqrt(f2sum/(npts>1) - (fsum/(npts>1))^2))
		  error_mean = sigma/sqrt(npts>1)
		  if n_all_bad gt 0 then npts(all_bad) = 0	; OK 
; make merged array from as many as the 3 WL regions:
		  good=where(wave ge regbeg(ireg) and wave lt regend(ireg))
;help,ireg,regbeg(ireg),regend(ireg) & print,minmax(wave) & read,st
		  if wmrg(0) gt 9e5 then begin	; initialized to 1e6 for iord=-1
			wmrg=wave(good)		; reset wmrg for higher iord
			gmrg=gross(good)
			bmrg=back(good)
			nmrg=net(good)
			simrg=sigma(good)
			stmrg=stat_error(good)
			emrg=error_mean(good)
			npmrg=npts(good)
			tmrg=tsum(good)
		    end else begin			; concatenate iord=1,2
			wmrg=[wmrg,wave(good)]
			gmrg=[gmrg,gross(good)]
			bmrg=[bmrg,back(good)]
			nmrg=[nmrg,net(good)]
			simrg=[simrg,sigma(good)]
			stmrg=[stmrg,stat_error(good)]
			emrg=[emrg,error_mean(good)]
			npmrg=[npmrg,npts(good)]
			tmrg=[tmrg,tsum(good)]
			endelse
		    	
;if filters(ifilt) eq 'G141' then stop
nodata:							; no data in region
		  endfor				; iord loop
;
; write results
;
		if n_elements(prefix) eq 0 then prefix = target+star
		filename = strlowcase(subdir+'/'+prefix+'.'+		$
				filters(ifilt)+'-'+strmid(obs(0),0,6))
		wfc_coadd_write,filename,target,star,obs,h,		$
			filters(ifilt),wmrg,gmrg,bmrg,nmrg,		$
			simrg,stmrg,emrg,npmrg,tmrg

next_ifilt:
	end					; end 2 grism loop
	!p.title=''
	!x.title = ''
	!y.title = ''
end
