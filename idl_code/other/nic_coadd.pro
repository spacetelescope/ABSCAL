;+
;			nic_coadd
;
; Plot and Co-add Nicmos spectra
;
; CALLING SEQUENCE:
;	nic_coadd,target,root
;
; INPUTS:
;	target - target name
;	root   - first 6 char of rootname to distinguish repeat obs.
;		OR 05nov15: an array of rootnames to process.
;
; OPTIONAL KEYWORD INPUTS:
;	/PRF - generate prf files needed to recompute the pixel response
;		function
;	/FCOR_SAVE - write the fcor fits table containing the corrected
;		net (aka djl "flux") for each of the observations.
;	subdir = subdirectory to read input spec files from and to write
;		the output files to. (default = 'spec')
;	/ps - write the output files to a postscript file
;	/noplot - do not plot the results
;	prefix - prefix of the output ascii file
;		default = target name
;	dlam - wavelength shift in microns to be added to output wavelengths
;			dlam is a vector corresponding to the 3 grism modes.
;	star - string star id to be added to the output file names
;	/double - double the length of the output wavelength vector by
;		subsampling by a factor of 2.
;	/no_prf - turn off pixel response function currection
;	dirlog - log of observations. default= dirnic.log
;	/self_prf - use observation itself to compute the Pixel Response
;		function.
;
; History:
;	version 1, D. Lindler, Feb. 2004
;	04jul23 - add root & dlam keyword for wavelength shifts. RCB
;	July 2004, Lindler, added STAR keyword input, added double
;		keyword input
;	Sept. 23, 2004, added /no_prf switch
;	Sept. 27, 2004, modified to use average of bad data for points where
;		all the data have a bad data quality
;	05feb12 - rcb added dirlog keyword
;	15-Mar-2005 - DJL, changed output formats to E11.3, added date-obs
;		to title in output ascii file
;	18-Mar-2005 - added stat. error computation when all data bad. npts
;		set to zero.
;	05nov15 - rcb added logic for Lamp on/off obs, where root is the
;		array of rootnames to process
;	05dec01 - djl, added coaddition of multiple observations at the same
;		dither location.
;	06feb28 - rcb, added mean back from contin subtraction to output bkg
;			to get approx idea of the total bkg.
;	06mar19 - rcb require more >2 mult obs at same loc for sep. dith output
;	06aug7  - rcb add output NIC_COADD + time stamp line
;	06aug8 - DJL added weighting using the effective obs. time for each flux value.
;		added time to output table
;	06aug18 - DJL - average background is now a straight average of the
;		individual backgrounds
;	07Feb07 - DJL - added SELF_PRF option
;	07Jun08 - DJL - removed old dither processing.  (obs at same dither
;		position now coadded by NIC_PROCESS)
;	08jul30 - RCB change WL output format from f9.4 to f10.7
;       08Nov12 - DJL - modified to only consider DQ flags (32+64+128+256+512)
;			as bad data.
;	16aug22 - list --> lst
;-
;---------------------------------------------------------------------------
pro nic_coadd_write,filename,target,star,obs,h, $
			dlam,filter,wave,gross,back,flux,sigma, $
			stat_error,error_mean,npts,time


		close,1 & openw,1, filename
		printf,1,'Wavelength shift (mic)=',dlam,form='(a,f7.4)'
		printf,1,'Gross and Back columns have Flat Field applied'
		printf,1,'Written by NIC_COADD.pro '+!stime
		printf,1,'    wave     gross        back      net        stdev' + $
			'      stat      error       Npts   Expo'
		printf,1,'                                                    ' + $
		        '      error     mean               Time'
		printf,1,' ###    1'
		printf,1,' '+target+star+' '+filter+' '+ $
			strmid(obs,0,6)+'   '+strtrim(sxpar(h,'date-obs'),2)
		sub = sort(wave)
; Fix wavelengths for shifts - rcb
		if dlam ne 0 then print,'nic_coadd corrected WL by ', $
			dlam,filter
		wave1=wave+dlam
		for k=0,n_elements(wave)-1 do begin
			i = sub(k)
			printf,1,wave1(i),gross(i),back(i),flux(i),sigma(i), $
				stat_error(i),error_mean(i),fix(npts(i)),time(i), $
				format='(F10.7,6E11.3,I8,F9.2)'
		end
		printf,1,'0 0 0 0 0 0 0 0 0'
		close,1
end

pro nic_coadd_prf_coef,filter,y,prf,flux,m_interp,coef,ps=ps,noplot=noplot
;
; Subroutine to compute PRF coef when /self_ps is specified
;
	s = size(prf) & ns = s(1) & nspec = s(2)
	
	threshold = median(flux)
	fbin = rebin(flux,ns,nspec)	
	frac = y-round(y)
	good = where((m_interp gt 0) and (fbin gt threshold) and $
		     (prf gt 0.7) and (prf lt 1.3))
	P = prf(good)
	F = frac(good)

	sub = sort(F)
	F = F(sub)
	P = P(sub)
		
	coef = poly_fit(double(F),double(P),4,fit)

	xx = findgen(1000)/1000.0 - 0.5
	yy = coef(0) + coef(1)*xx + coef(2)*xx^2 + coef(3)*xx^3 + $
	    coef(4)*xx^4

	if not keyword_set(noplot) then begin
	    plot,F,P,title=filter+' PRF Fit',ytitle='PRF correction', $
	    	    xtitle='Y pixel position',psym=4,symsize=0.5, $
	    	    yrange=[0.8,1.2]
	    oplot,xx,yy,thick=2
	    if not keyword_set(ps) then wait,2
	end
end



pro nic_coadd,target,root,prf=prf,fcor_save=fcor_save,ps=ps,noplot=noplot, $
	subdir=subdir, prefix = prefix,dlam=dlam, star=star, double=double, $
	no_prf = no_prf,dirlog=dirlog,self_prf=self_prf

	!p.charsize=2
	if n_elements(subdir) eq 0 then subdir = 'spec'
	if n_elements(dlam) eq 0 then dlam = fltarr(3)
	if n_elements(star) eq 0 then star = ''
	!ytitle='DN/sec for '+target+star
	!xtitle='!17WAVELENGTH (microns)'
;
; postscript output
;
	if keyword_set(ps) then begin
		dev = !d.name
		set_plot,'ps'
		device,file=subdir+'/'+strlowcase(target+star)+'_coadd.ps'
		!p.font=0
	end else if not keyword_set(noplot) then window,0
;
; get observation list
;
	logfil='dirnic.log'
	if keyword_set(dirlog) then logfil=dirlog
	stisobs,logfil,allobs,allfilt,aper,starname,'','',target
	obs=allobs  &  filter=allfilt
	nroots=n_elements(root)
	if nroots gt 1 then begin		; 05nov15 for lamp on/off tests
		obs=strarr(nroots)  &  filter=strarr(nroots)
		for i=0,nroots-1 do begin
			good=where(allobs eq root(i))
			obs(i)=allobs(good(0))
			filter(i)=allfilt(good(0))
			endfor
	endif
	if nroots eq 1 then begin
		good = where(strpos(obs,root) ge 0)
		obs=obs(good)
		filter = filter(good)
	end else root = ''

	file_list = strlowcase('spec_' + obs + star + '.fits')	;star usually ''

	filters = ['G096','G141','G206']
; Read & store all input data:
	for ifilt=0,2 do begin

		good = where(filter eq filters(ifilt),ngood)
		if ngood eq 0 then goto,next_ifilt
		files = file_list(good)				; all repeats
		nout = 0
		for i=0,ngood-1 do begin
			file = subdir+'/'+files(i)
			lst = findfile(file)
			if lst(0) eq '' then goto,nexti		
;the one file that combines the repeats but has the rootname of just one repeat:
			a = mrdfits(file,1,h,/silent)
			if nout eq 0 then begin
				w = a.wave
				ns = n_elements(w)+5
				w = fltarr(ns,ngood)
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
			ns = n_elements(a.wave)<ns
			w(0,nout) = a.wave
			f(0,nout) = a.flux
			e(0,nout) = a.err
			y(0,nout) = a.y
			eps(0,nout) = a.eps
			b(0,nout) = a.back
			g(0,nout) = a.gross
			time(0,nout) = a.time
			nout = nout + 1
nexti:
		end
		if nout eq 0 then begin
			print,'Nic_coadd ERROR: Spectra not found for '	$
				+filters(ifilt)+' '+target+' '+root
			retall
		end
		w = w(0:ns-1,0:nout-1)
		f = f(0:ns-1,0:nout-1)
		e = e(0:ns-1,0:nout-1)
		eps = eps(0:ns-1,0:nout-1)
		y = y(0:ns-1,0:nout-1)
		b = b(0:ns-1,0:nout-1)
		g = g(0:ns-1,0:nout-1)
		time = time(0:ns-1,0:nout-1)
		ngood = nout
;
; plot calnic data
;
		if not keyword_set(noplot) then begin
			!p.title=filters(ifilt) + '  calnic_spec'
			plot,w(*,0),f(*,0),xstyle=1,yrange=[0,max(f)]
			for i=0,ngood-1 do oplot,w(*,i),f(*,i)
			xyouts,0,0,'nic_coadd '+!stime,/norm,charsize=0.7
			if not keyword_set(ps) then wait,0.5
		end
;
; create net array without bad data
;
		fgood = f
		flags = (32+64+128+256+512)
		mask = (eps and flags) eq 0	;mask=1 for good pixels 
		s = size(f) & ns =s(1) & nspec = n_elements(f)/ns
		for ii=0,nspec-1 do begin
			for jj=1,ns-1 do if mask(jj,ii) eq 0 then $
					fgood(jj,ii) = fgood(jj-1,ii)
		end
;
; register wavelengths
;
		xdither = (w(0,*)-w(0,0))/(w(1)-w(0))
		hrs_shift,w,fgood,centers,xshift
		if max(abs(xshift-xdither) gt 1.0) then begin
			print,target+' '+filters(ifilt)+' too noisy to register'
			print,'All wavelength offsets set to zero'
			xshift = xdither
		end

		hrs_wavecor,w,centers,xshift,wcor
		if not keyword_set(noplot) then begin
			!p.title=filters(ifilt) + '  Wavelengths matched'
			plot,wcor(*,0),f(*,0),xstyle=1,yrange=[0,max(f)]
			for i=0,ngood-1 do oplot,wcor(*,i),f(*,i)
			xyouts,0,0,'nic_coadd '+!stime,/norm,charsize=0.7
			if not keyword_set(ps) then wait,0.5
		end
;
; prf correction
;

		if keyword_set(self_prf) then first_try = 1 else first_try=0
;		if (filters(ifilt) eq 'G206') and $
;		   keyword_set(self_prf) then begin   	; Don't do G206 self
;		   	coef = [1.0,0,0,0,0]		; correction, skip
;			first_try = 0			; correction
;		end
prf_step:
		if not keyword_set(no_prf) then begin
		   yfrac = y - round(y)
		   if not keyword_set(self_prf) then begin
			lst = find_with_def('prfcoef_'+ $
				strlowcase(filters(ifilt))+'.txt','NICREF')
			if (lst(0) eq '') then begin
			    print,'ERROR: PRF file not found in NICREF'
			    retall
			end
			readcol,lst(0),coef,/silent
		     end else begin
		        if first_try then coef = [1.0,0,0,0,0]
		   end
		   prf_cor = coef(0) + coef(1)*yfrac + coef(2)*yfrac^2 + $
				coef(3)*yfrac^3 + coef(4)*yfrac^4
		   fcor = f/prf_cor
		   if (not keyword_set(noplot)) and (first_try eq 0) then begin
			   !p.title=filters(ifilt) + ' PRF corrected'
			   plot,wcor(*,0),fcor(*,0),xstyle=1,yrange=[0,max(f)]
			   for i=0,ngood-1 do oplot,wcor(*,i),fcor(*,i)
			   xyouts,0,0,'nic_coadd '+!stime,/norm,charsize=0.7
			   if not keyword_set(ps) then wait,0.5
		   end
		end else fcor = f
;
; remove bad data
;
		!p.title=filters(ifilt) + ' Bad DQ removed'
		fcor1 = fcor + (mask eq 0)*100000.0
		if not keyword_set(noplot) and (first_try eq 0) then begin
		   plot,wcor(*,0),fcor1(*,0),xstyle=1,max_val=90000.0, $
		   		yrange=[0,max(f)]
		   for i=0,ngood-1 do oplot,wcor(*,i),fcor1(*,i),max_val=90000.0
		   xyouts,0,0,'nic_coadd '+!stime,/norm,charsize=0.7
		   if not keyword_set(ps) then wait,0.5
		end
;
; coadd the data
;

		var = e*e
		wave = wcor(*,0)
		if keyword_set(double) then begin
			wave = [wave,(wave(1:*)+wave)/2.0]
			wave = wave(sort(wave))
		end
		ns = n_elements(wave)
		fsum = dblarr(ns)
		ftsum = dblarr(ns)
		f2sum = dblarr(ns)
		gsum = fltarr(ns)
		bsum = fltarr(ns)
		tsum = fltarr(ns)
		npts = fltarr(ns)
		varsum = fltarr(ns)
		f_interp = fltarr(ns,ngood)
		fcor_interp = fltarr(ns,ngood)
		b_interp = fltarr(ns,ngood)
		g_interp = fltarr(ns,ngood)
		m_interp = intarr(ns,ngood)
		y_interp = fltarr(ns,ngood)
		var_interp = fltarr(ns,ngood)
		time_interp = fltarr(ns,ngood)
		for i=0,ngood-1 do begin
			linterp,wcor(*,i),f(*,i),wave,fint
			linterp,wcor(*,i),b(*,i),wave,bint
			linterp,wcor(*,i),g(*,i),wave,gint
			linterp,wcor(*,i),fcor(*,i),wave,fcint
			linterp,wcor(*,i),var(*,i),wave,vint
			linterp,wcor(*,i),float(mask(*,i)),wave,mint
			linterp,wcor(*,i),y(*,i),wave,yint
			linterp,wcor(*,i),time(*,i),wave,tint
			mint = mint ge 1.0
			fsum = fsum + mint*fcint
			ftsum = ftsum + mint*tint*fcint
			gsum = gsum + mint*gint
			tsum = tsum + mint*tint
			f2sum = f2sum + mint*double(fcint)^2
			varsum = varsum + mint*tint^2*vint
			npts = npts + mint
			f_interp(*,i) = fint
			fcor_interp(*,i) = fcint
			b_interp(*,i) = bint
			g_interp(*,i) = gint
			m_interp(*,i) = mint
			y_interp(*,i) = yint
			var_interp(*,i) = vint
			time_interp(*,i) = tint
		end
;
; use average when all data is bad
;
		all_bad = where(npts eq 0,n_all_bad)
		if n_all_bad gt 0 then begin
			fbad = double(fcor_interp(all_bad,*))
			tbad = time_interp(all_bad,*)
			if nspec gt 1 then begin
				fsum(all_bad) = total(fbad,2)
				tsum(all_bad) = total(tbad,2)
				ftsum(all_bad) = total(fbad*tbad,2)
				gsum(all_bad) = total(g_interp(all_bad,*),2)
				f2sum(all_bad) = total(fbad*fbad,2)
				varsum(all_bad) = total(var_interp(all_bad,*)*tbad^2,2)
			    end else begin
				fsum(all_bad) = fbad
				tsum(all_bad) = tbad
				ftsum(all_bad) = fbad*tbad
				gsum(all_bad) = g_interp(all_bad,*)
				f2sum(all_bad) = fbad*fbad
				varsum(all_bad) = var_interp(all_bad,*)*tbad^2
			end
			npts(all_bad) = ngood
		end
		if nspec gt 1 then bsum = total(b_interp,2) else bsum=b_interp
		totweight = tsum + (tsum eq 0)
		stat_error = sqrt(varsum)/totweight ;propagated statistical error
		flux= float(ftsum/totweight)
		back = bsum/ngood
		gross = gsum/(npts>1)
		sigma = float(sqrt(f2sum/(npts>1) - (fsum/(npts>1))^2))
		error_mean = sigma/sqrt(npts>1)
		if n_all_bad gt 0 then npts(all_bad) = 0
;
; write results
;
		if first_try eq 0 then begin
		    if n_elements(prefix) eq 0 then prefix = target+star
		    filename = strlowcase(subdir+'/'+prefix+'.'+ $
				filters(ifilt)+'-'+strmid(obs(0),0,6))
		    nic_coadd_write,filename,target,star,obs(0),h, $
			dlam(ifilt),filters(ifilt),wave,gross,back,flux,sigma, $
			stat_error,error_mean,npts,tsum
		end
;
; compute prf if /self_prf and first time through
;
		prfval = f_interp / rebin(flux,ns,ngood,/sample)
		if first_try then begin		;compute PRF using the data
			nic_coadd_prf_coef,filters(ifilt),y_interp,prfval, $
				flux,m_interp,coef,ps=ps,noplot=noplot
			first_try=0
			goto,prf_step
		end
;
; optionally write PRF file for routine PRF_COMPUTE
;
		if keyword_set(prf) then begin
			mwrfits,{prf:prfval,flux:flux,m_interp:m_interp, $
					y:y_interp,obs:obs}, $
					subdir+'/'+strlowcase(target+star+ $
					'_prf_'+filters(ifilt)+'.fits'), h
		end
;
; optionally write IDL save set
;
		if keyword_set(fcor_save) then begin
		   save,f=strlowcase(subdir+'/'+target+star+ $
				filters(ifilt)+'.idl'), $
		    		target,obs,h,wcor,fcor,mask,wave,flux,xshift, $
						fcor_interp, m_interp
		end
next_ifilt:
	end
	if keyword_set(ps) then begin
		device,/close
		set_plot,dev
	end
	!p.title=''
	!x.title = ''
	!y.title = ''
end
