;+
;				calnic_spec
;
; Routine to extract NICMOS point source spectrum from a calibrated image
; file.
;
; CALLING SEQUENCE:
;	calnic_spec,file,xc,yc,wave,flux,errf,epsf
;
; INPUTS:
;	file - name of the calibrated image file
;	xc - target x position in camera mode observation
;	yc - target y position in camera mode observation
;
; OUTPUTS:
;	wave - wavelength vector (microns)
;	flux - net count rate spectrum
;	errf - propagated statistical errors for flux
;	epsf - data quality vector
;
; OPTIONAL KEYWORD INPUTS:
;	xbinsize - value of binning in x-direction for generating profiles
;		by summing in x when computing spectral location. default=11
;	ywidth - width of the search area for spectra location
;		default = 11 if crval1 and crval2 are specified
;		default = 30, otherwise
;	yoffset - distance from YC to center search area for spectral location.
;		(default = 0)
;	gwidth - width of the spectral extraction region (i.e. height of the
;		extraction slit). default = 4
;	bwidth - width (in Y) of the upper and lower background regions.
;		default = 13
;	bdist - distance in Y to the center of the upper and lower background
;		regions (default = 15)
;	Ubdist - upper background distance (if supplied it overrides the
;		bdist parameter)
;	Lbdist - lower background distance (if supplied it overrides the
;		bdist parameter)
;		To only use an upper or lower background distance set
;		the value of Ubdist = -Lbdist (a negative value for one of
;		the bdist parameters can be used to sample both from the
;		same side of the spectrum.
;	bmedian - median filter width for background spectrum (default=7)
;	bmean1 - first mean filter width for smoothing the background spectrum
;		(default = 7)
;	bmean2 - second mean filter width for smoothing the background spectrum
;		(default = 7)
;	imagefile - name of the camera mode image to find the target centroid
;		position.  If supplied, parameters XC and YC become output
;		parameters instead of input parameters.
;	/DISPLAY - display camera mode image and located target if IMAGEFILE
;		is specified.
;	/TRACE - display spectra image with the extraction regions overplotted
; 	flatfile - name of the text file containing the flat field files
;		versus wavelength.  (The reference files are located in
;		directory indicated by environment variable NICREF)
;		default = 'sm3b_flats.list', If set to '' or to 'NONE' then
;		no spectral flatfielding is done.
; 08Oct17:	default = 'tp5.list'
;	/before - if set, flat fielding is done before background
;		subtraction
;	star - string star id to be added to the output file names
;	/save_back - save background information
;	/slope - fix slope of spectrum instead of fitting it
;	slope = floating point value of the slope in degrees (overides default
;		value if /slope is used)
;	crval1 = crval1 value from the camera mode observation
;			(ra at the center of the image)
;	crval2 = crval2 value from the camera mode observation
;			(dec at the center of the image)
;
; OUTPUT FILE:
;	Results are placed into an output FITS binary table with name:
;		spec_<input file name>.fits
;	It has columns:
;		x - x position (column of the extracted spectral values)
;		y - y center of the spectrum versus the x position
;		wave - wavelength vector (microns)
;		flux - extracted net count rate spectrum.
;		gross - gross count rate spectrum
;		back  - smoothed average background  count rate spectrum
;		eps - data quality vector (using standard CALNIC values)
;		err - propagated statistical errors for flux
;
;	 	   {x,y,wave,flux,err and eps all have the same length}
;
;		xb - xpositions of the background extractions
;		bupper - upper background level (counts/pixel)
;		blower - lower background level (counts/pixel)
;		sback - smoothed average upper and lower background level
;			(counts/pixel) {If save_back keyword is set.-rcb}
;
;		   {xb, blower, bupper, and sback all have the same length
;		    and are slightly longer than flux vector}
;
; HISTORY:
;	version 1, D. Lindler, Oct. 2003
;	version 2, D. Lindler, July 2004, added /BEFORE option, added
;		extraction of gross spectrum. added star id input.
;	August 30 2004, changed dispersion relation to R. Thompson grism
;		recal from 02nov8 Table 5. Added Bohlin August 2004
;		non-linearity correction
;	Dec 8, 2004, changed to new Bohlin non-linearity correction
;	04dec17 - give up the non-lin correction to the image. see nicflx-rcb.
;	19-Jan-2005 - deleted non-linearity correction, added background
;		information output file
;	Jan 25, 2005 - added slope and yshift keyword parameters
;	Jan 30, 2005 - deleted yshift parameter, added crval1, crval2,
;		bdistU, bdistL parameters.  Computes yshift from crvals
;	Feb 2, 2005, added bad pixel flag for pixel 84,50
;	June 8, 2005, added x dithers
;	05nov15-divide lamp on, IMAGETYP=FLAT, by exposure time array
;	05nov28-	also divide the err array by exp time array
;	06jan9 - RCB subtract the scaled grism flat to remove contin contrib.
;	06feb28- RCB add mean bkg to header from nic_flatscal & subtr bkg
;		continuum for all G206 images.
;	06jul12-djl fix angle sign from r. thompson & fix rcb bug
;	06aug08- DJL added effective exposure time for each extracted flux value.
;		Modified output GROSS and BACK to be extractions from the raw image.
;	06aug18 - DJL - modified to flat field sky image with sky flat and
;		extract the flat fielded sky background which is included
;		in the output background arrays.  Gross is now just the 
;		extracted net flux plus the smoothed background
;	07Jun08 - DJL - moved flat fielding before spectral location.
;	08Oct17 - RCB: change default flat to new tp5 for new calnicA pipeline.
;       08Nov12 - DJL - modified to zero out data, time, and errors for bad
;		data (needed for new CALNICA outputs).
;	09mar17 - RCB: start testing Nor's new field dependent WL solution,
;		including addition of yc to calnic_spec_wave
;
;========================================================  CALNIC_SPEC_WAVE
;
; Routine to compute wavelength vector and column numbers to extract
;
pro calnic_spec_wave,h,xc,yc,x,wave,angle
;
; August 31, 2004, dispersion coef. changed to R. Thompson recal 03Nov8 Table 5
	filter = strtrim(sxpar(h,'filter'))
	case filter of
;	  'G096': begin
;	  	a0 = 0.9415				; from nicmoslook 0.9487
;		a1 = -0.00552				; -0.005369
;		wmin = 0.79
;		wmax = 1.21
;		angle = 2.97187
;		end
;	  'G141': begin
;	  	a0 = 1.396				; 1.401
;		a1 = -0.008016				; -0.007992
;		wmin = 1.05
;		wmax = 1.98
;		angle = 0.495124
;		end
;	  'G206': begin
;	  	a0 = 2.039				; 2.045
;		a1 = -0.011353				; -0.01152
;		wmin = 1.35
;		wmax = 2.55
;		angle = 1.42622
;		end
; Nor's solution of 09jun2:
;a + b * x + c * y
;G096:
;b: a -> 0.939668, b -> 0.00001489, c -> -6.29038*10^-7
;m: a -> -0.00562402, b -> 1.90631*10^-8, c -> -6.63082*10^-8
;G141:
;b: a -> 1.39384, b -> 0.0000248266, c -> -5.77059*10^-7
;m: a -> -0.00799263, b -> 6.28868*10^-8, c -> -1.36104*10^-7
;G206:
;b: a -> 2.03351, b -> 0.0000347129, c -> 2.66593*10^-6
;m: a -> -0.0114426, b -> -2.71002*10^-8, c -> -3.57863*10^-7
	 'G096': begin
	       b=0.00001489 &  c=-6.29038e-7
	       a0 = 0.939668+b*xc+c*yc  
	       b= 1.90631e-8  &  c=-6.63082e-8
	       a1 = -0.00562402+b*xc+c*yc      
	       wmin = 0.79
	       wmax = 1.21
	       angle = 2.97187
	       end
	 'G141': begin
	       b=0.0000248266  &  c=-5.77059e-7
	       a0 = 1.39384+b*xc+c*yc  
	       b=6.28868e-8  &  c=-1.36104e-7
	       a1 =-0.00799263+b*xc+c*yc      
	       wmin = 1.05
	       wmax = 1.98
	       angle = 0.495124
	       end
	 'G206': begin
	       b=0.0000347129 &  c=2.66593e-6
	       a0 = 2.03351+b*xc+c*yc  
	       b=-2.71002e-8  &  c=-3.57863e-7
	       a1=-0.0114426+b*xc+c*yc      
	       wmin = 1.35
	       wmax = 2.55
	       angle = 1.42622
	       end
	end
	print,'disp const=',a1,a0,' AT:',xc,yc
	wave = a0 + a1 * (indgen(256) - xc)
	x = where((wave ge wmin) and (wave le wmax))
	wave = wave(x)
	sxaddpar,h,'a0',a0,'Constant Term of the dispersion relation'
	sxaddpar,h,'a1',a1,'Linear Term of the dispersion relation'
end

;========================================================  CALNIC_SPEC_FLAT
;
; Routine to flat field the data with wavelength depended flats
;
pro calnic_spec_flat,h,image,err,dq,x,wave,flatfile
;
; read flat field files
;

	list = find_with_def(flatfile,'NICREF')
	if list(0) eq '' then begin
		print,'ERROR: '+flatfile+' not found in NICREF'
		retall
	end
	readcol,list(0),name,wflat,format='a,f',/silent
	nflat = n_elements(wflat)
	cube = fltarr(256,256,nflat)
	errcube = fltarr(256,256,nflat)
	dqcube = fltarr(256,256,nflat)
	for i=0,nflat - 1 do begin
	   list = find_with_def(name(i),'NICREF')
	   if list(0) eq '' then begin
		print,'ERROR: flat file '+name(i)+' not found in NICREF'
		stop
		retall
	   end
	   fits_read,list(0),d,extname='SCI'
	   cube(0,0,i) = d>0
	   fits_read,list(0),d,extname='ERR'
	   errcube(0,0,i) = d
	   fits_read,list(0),d,extname='DQ'
	   dqcube(0,0,i) = d
	end
;
; loop on columns that are to be extracted
;
	x1 = round((min(x)-5)>0)
	x2 = round((max(x)+5)<255)
	xextend = findgen(x2-x1+1)+x1
	linterp,x,wave,xextend,wave_extend
	for i=0,n_elements(xextend) - 1 do begin
;
; extract column
;
	    col = xextend(i)
	    image_col = image(col,*)
	    err_col = err(col,*)
	    dq_col = dq(col,*)
;
; find flats to interpolate between
;
	    tabinv,wflat,wave_extend(i),index
	    index = fix(index)
	    index1 = index>0<(nflat-2)
	    index2 = index1 + 1
;
; interpolate between flats index1 and index2
;
	    w1 = wflat(index1)
	    w2 = wflat(index2)
	    frac1 = (w2-wave_extend(i))/(w2-w1)
	    frac2 = (wave_extend(i)-w1)/(w2-w1)
	    col_flat = cube(col,*,index1)*frac1 + cube(col,*,index2)*frac2
	    dq_flat = dqcube(col,*,index1) or dqcube(col,*,index2)
	    err_flat = sqrt((errcube(col,*,index1)*frac1)^2 + $
	    		   (errcube(col,*,index2)*frac2)^2)
	    new_col = image_col*col_flat
	    new_err = sqrt( (err_flat*image_col)^2 + (err_col*col_flat)^2)
	    dq_col = dq_col or dq_flat

	    bad = where((err_col eq 0) or (err_flat eq 0),nbad)
	    if nbad gt 0 then new_col(bad) = 0.0
;
; insert back into the image
;
	    image(col,*) = new_col
	    dq(col,*) = dq_col
	    err(col,*) = new_err
	end
	sxaddpar,h,'flatfile',flatfile
end
;============================================================= CALNIC_SPEC
;
; Main routine
;
pro calnic_spec,file,xc,yc,wave,flux,errf,epsf, yoffset=yoffset, $
	xbinsize = xbinsize, ywidth = ywidth, gwidth = gwidth, bdist = bdist, $
	bwidth = bwidth, bmedian = bmedian, bmean1 = bmean1, bmean2 = bmean2, $
	imagefile=imagefile, display=display, trace=trace, flatfile=flatfile, $
	subdir = subdir, star=star, before=before, $
	slope=slope,Ubdist=Ubdist, Lbdist=Lbdist, $
	crval1=crval1, crval2=crval2

;
	if n_params(0) eq 0 then begin
		print,'calnic_spec,file,xc,yc,wave,flux,errf,epsf'
		print,'KEYWORD INPUTS: xbinsize, ywidth, gwidth, bwidth, bdist'
		print,'                bmedian, bmean1, bmean2, imagefile'
		print,'                /display, /trace, flatfile, subdir
		print,'                star, /before, /slope'
		print,'		       slope, Ubdist, Lbdist, crval1, crval2'
		return
	end
;
; set defaults
;
	if n_elements(yoffset) eq 0 then yoffset = 0
	if n_elements(xbinsize) eq 0 then xbinsize=15
	if n_elements(gwidth) eq 0 then gwidth = 4.0
	if n_elements(bdist) eq 0 then bdist = 15
	if n_elements(Ubdist) eq 0 then ubdist = bdist
	if n_elements(Lbdist) eq 0 then lbdist = bdist
	if n_elements(bwidth) eq 0 then bwidth = 13
	if n_elements(bmedian) eq 0 then bmedian = 7
	if n_elements(bmean1) eq 0 then bmean1 = 7
	if n_elements(bmean2) eq 0 then bmean2 = 7
	if n_elements(imagefile) eq 0 then imagefile = ''
;	if n_elements(flatfile) eq 0 then flatfile='sm3b_flats.list'
	if n_elements(flatfile) eq 0 then flatfile='tp5.list'	; 08Oct17
	if n_elements(subdir) eq 0 then subdir = 'spec'
	if n_elements(star) eq 0 then star=''
;
; determine center of the object in the camera mode image if IMAGEFILE is
; supplied
;
	if imagefile ne '' then calnic_imagepos,imagefile,xc,yc,crval1,crval2, $
			display=display
	print,'Processing file '+file
	sxaddpar,h,'targetx',xc,'Target X position'
	sxaddpar,h,'targety',yc,'Target Y position'
	if n_elements(ywidth) eq 0 then $
		if n_elements(crval1) gt 0 then ywidth = 11 else ywidth=30
;
; Read data and flag a couple of bad pixels not already flagged
;
	fits_read,file,image,h, extname='SCI'
; 05dec23 - RCB patch for intermitant hot px that effects just 2 images:
	if strpos(file,'n97u54d6q') ge 0 then image(74,83)=0.56
	if strpos(file,'n97u54d8q') ge 0 then image(74,83)=0.55
; 08aug5 - patch bad Feige110 for bad barscorr that Edie says should NOT be on:
	if strpos(file,'na5306m1q') ge 0 then begin
		fits_read,'../data/spec/nic/na5306m1q_copy.IMA-save',	$
					imfix,exten=1		; final read
		image(*,91)=imfix(*,91)
		image(*,93)=imfix(*,93)
		endif

	fits_read,file,err, extname='ERR'
	fits_read,file,time,extname='time'
	fits_read,file,dq, extname='DQ'
	dq(119,95) = "777			;mask a hot pixels
	dq(167,131) = "777
	dq(120,82) = "777
	dq(84,50) = "777
;
; set bad data to zeros
;
	bad = where((dq and (32+64+128+256+512)) gt 0,nbad)
	if nbad gt 0 then begin
		image(bad) = 0
		err(bad) = 0
		time(bad) = 0
	end
	if strtrim(sxpar(h,'imagetyp'),2) eq 'FLAT' then begin	; 05nov15 rcb
		good=where(time gt 0)
		image(good)=image(good)/time(good)	; flats not div by exptm
		err(good)=err(good)/time(good)		; 05nov28
		endif
	filter = strtrim(sxpar(h,'filter'))
	raw_image = image 	;save for gross and back extractions
;
; compute offsets from the dithers
;
	if n_elements(crval1) gt 0 then begin
		extast,h,astr,status	;get astrometry information
		if status eq -1 then begin
		    print,'CALNIC_SPEC: Error - Invalid astrometry ' + $
		    		'info in the image '+file
		    retall
		end
		ad2xy,crval1,crval2,astr,x1,y1   ;center position of targ acq
						 ;image in the current image
		ydither = y1[0]-127
		xdither = x1[0]-127
	   end else begin
	   	xdither = 0.0
		ydither = 0.0
	end
;
; compute wavelengths -----------------------------------------------------
;
	print,'xc+xdither',xc+xdither
	calnic_spec_wave,h,xc+xdither,yc+ydither,x,wave,angle
	ns = n_elements(x)
;
; compute approximate location of the spectrum.
;
	fit_slope = 1				;default is to fit the slope
	if keyword_set(slope) then begin			;06jun28-rcb
		    fit_slope = 0		; do not fit slope
	   	    if ((datatype(slope) eq 'LON') or $
		       (datatype(slope) eq 'INT')) and $
	   	       (slope eq 1) then begin
				case filter of
	  			'G096': angle = 3.03	;degrees
	  			'G141': angle = 0.65
	  			'G206': angle = 1.59
				endcase
	       		end else angle = slope
	end
	case filter of
	  	'G096': yshift = -4
	  	'G141': yshift = -6
	  	'G206': yshift = -2
	endcase
	yapprox = yc + yoffset + (x-xc)*sin(angle/!radeg) + yshift + ydither
;
; subtract a scaled Flat field (for hi-bkg obs). 06jan9 - rcb
;			(normal returned value is 0 for G096 & G141)
;
	image=image-nic_flatscal(h,image,x,yfit,filter,gwidth,flat)
	if nbad gt 0 then begin
		image(bad) = 0
		err(bad) = 0
	end
	if n_elements(flat) gt 1 then begin
		sky_image = raw_image/(flat>0.001)	;properly flat field sky
	   end else begin
	   	sky_image = raw_image*0			;non hi-bkg obs
	end
;
; flat field the data using the wavelength dependent flat
;
	if keyword_set(before) then begin
		flatfile = strtrim(flatfile)
		if flatfile ne '' and strupcase(flatfile) ne 'NONE' then $
			calnic_spec_flat,h,image,err,dq,x,wave,flatfile
		if nbad gt 0 then begin
			image(bad) = 0
			err(bad) = 0
		end
	end
;
; find the spectrum  ------------------------------
;
	fimage = image
	for i=0,255 do fimage(0,i) = median(image(*,i),7)
; default is to fit slope (keyword slope=0)
	if fit_slope then begin					;06jul11-djl

		nbins = ns/xbinsize
		xfound = findgen(nbins)*xbinsize + x(0) + (xbinsize-1)/2.0
		yfound = fltarr(nbins)

		x1 = x(0)
		for i=0,nbins-1 do begin
		    x2 = x1 + xbinsize-1
		    y1 = (fix(yapprox(x1-x(0)))-ywidth/2)>0
		    y2 = (y1 + ywidth + 1)<255
		    ny = y2-y1+1
		    profile = fltarr(ny)
		    for j=0,ny-1 do profile(j) = total(fimage(x1:x2,y1+j))
		    profile = profile - median(profile)
		    profile = (profile - max(profile)/4)>0
		    yprofile = findgen(ny) + y1
		    pmax = max(profile,maxpos)
		    ymax = yprofile(maxpos)
		    if pmax gt 0 then ycent = $
		    			total(yprofile*profile)/total(profile) $
	    		      else ycent = -999.0
		    if abs(ymax-ycent) le 1.5 then yfound(i) = ycent $
		    			      else yfound(i) = -999
		    x1 = x1 + xbinsize
		end
		good = where(yfound ge 0,ngood)
		coef = poly_fit(xfound(good),yfound(good),1,fit)
	   end else begin
;
; find y-center with a fixed slope
;
		profile = fltarr(ywidth)
		yoff = findgen(ywidth) - ywidth/2
		for i=0,ywidth-1 do $
			profile(i) = total(interpolate(fimage,x, $
						yapprox+yoff(i)))
		profile = profile - median(profile)
		profile = (profile - max(profile)/4)>0
		ycent = total(profile*yoff)/total(profile)
		ypos = yapprox + ycent
		coef = poly_fit(x,ypos,1,fit)
	end



	yfit = coef(0) + coef(1)*x
	sxaddpar,h,'extc0',coef(0),'Extraction Position: Constant Term'
	sxaddpar,h,'extc1',coef(1),'Extraction Position: Linear Term'
;
; Extract background spectra
;
	x1 = (x(0)-5)>0
	x2 = (x(ns-1)+5)<255
	nsb = (x2-x1+1)
	blower = fltarr(nsb)
	bupper = fltarr(nsb)
	sky_blower = fltarr(nsb)
	sky_bupper = fltarr(nsb)
	xb = indgen(nsb)+x1
	yfitb = coef(0) + coef(1)*xb

	for i=0,nsb-1 do begin

		ypos = round(yfitb(i) - Lbdist)
		y1 = (ypos - bwidth/2)>0
		y2 = (ypos + bwidth/2)<255
		blower(i) = median(image(xb(i),y1:y2))
		sky_blower(i) = median(sky_image(xb(i),y1:y2))
		ypos = round(yfitb(i) + Ubdist)
		y1 = (ypos - bwidth/2)>0
		y2 = (ypos + bwidth/2)<255
		bupper(i) = median(image(xb(i),y1:y2))
		sky_bupper(i) = median(sky_image(xb(i),y1:y2))
	end
;
; average upper and lower background and smooth
;
	back = (blower + bupper)/2.0
	raw_sky_back = (sky_blower+sky_bupper)/2.0

	if bmedian gt 1 then sback = median(back,bmedian) $
			else sback = back
	if bmean1 gt 1 then sback = smooth(sback,bmean1)
	if bmean2 gt 1 then sback = smooth(sback,bmean2)

	if bmedian gt 1 then sky_back = median(raw_sky_back,bmedian) $
			else sky_back = raw_sky_back
	if bmean1 gt 1 then sky_back = smooth(sky_back,bmean1)
	if bmean2 gt 1 then sky_back = smooth(sky_back,bmean2)
;
; subtract background
;
	for i=0,nsb-1 do image(xb(i),*) = image(xb(i),*)-sback(i)
	sback = sback(5:n_elements(sback)-6) * gwidth
	sky_back = sky_back(5:n_elements(sky_back)-6) * gwidth
	back = back(5:n_elements(back)-6) * gwidth
	raw_sky_back = raw_sky_back(5:n_elements(raw_sky_back)-6) * gwidth
;
; print background results
;
	back_results = {sback:frebin(sback,5,/total)/gwidth, $
	    gross:transpose( $
		frebin(raw_image(xb(0):xb(0)+nsb-1,*),5,256,/total)), $
	    net:transpose(frebin(image(xb(0):xb(0)+nsb-1,*),5,256,/total)), $
	    wave:frebin(wave,5), $
	    bupper:frebin(bupper,5,/total), $
	    blower:frebin(blower,5,/total), $
	    x:frebin(x,5), $
	    y:frebin(yfitb,5), $
	    Ubdist:Ubdist,lbdist:lbdist}
;
; create trace image
;
	if keyword_set(trace) then begin
		window,4,xs=256,ys=256
		tvscl,alog10(image>0.1)
		plots,x,yfit+gwidth/2,/dev
		plots,x,yfit-gwidth/2,/dev
		plots,x,yfit+ubdist-bwidth/2,/dev
		plots,x,yfit+ubdist+bwidth/2,/dev
		plots,x,yfit-lbdist-bwidth/2,/dev
		plots,x,yfit-lbdist+bwidth/2,/dev
		wait,2.0
	end
;
; flat field the data
;
	if not keyword_set(before) then begin
		flatfile = strtrim(flatfile)
		if flatfile ne '' and strupcase(flatfile) ne 'NONE' then $
			calnic_spec_flat,h,image,err,dq,x,wave,flatfile
		if nbad gt 0 then begin
			image(bad) = 0
			err(bad) = 0
		end
	end
;
; Extract spectra
;
	flux = fltarr(ns)
	epsf = intarr(ns)
	errf = fltarr(ns)
	spec_time = fltarr(ns)

	hwidth = gwidth/2.0

	for i=0,ns-1 do begin
		y1 = (yfit(i) - hwidth)>0		;extract from y1 to y2
		y2 = (yfit(i) + hwidth) <255 >y1
		iy1 = round(y1)
		iy2 = round(y2)
		frac1 = 0.5 + iy1-y1  ;frac of pixel i1y
		frac2 = 0.5 + y2-iy2  ;frac of pixel iy2
		ifull1 = iy1+1  	      ;range of full pixels to extract
		ifull2 = iy2-1

		if ifull2 ge ifull1 then begin
			tot = total(image(x(i),ifull1:ifull2))
			var = total(err(x(i),ifull1:ifull2)^2)
			tot_time = total(time(x(i),ifull1:ifull2)* $
					(image(x(i),ifull1:ifull2)>0))
			time_weight = total(image(x(i),ifull1:ifull2)>0)
		    end else begin
		    	tot = 0.0
			var = 0.0
			time_weight = 0.0
			tot_time = 0.0
		end
  		tot = tot + frac1*image(x(i),iy1)+frac2*image(x(i),iy2)
  		var = var + frac1*err(x(i),iy1)^2 +frac2*err(x(i),iy2)^2
		tot_time = tot_time + frac1*time(x(i),iy1)*(image(x(i),iy1)>0)	+ $
				frac2*time(x(i),iy2)*(image(x(i),iy2)>0)
		time_weight = time_weight + frac1*(image(x(i),iy1)>0)	+ $
			frac2*(image(x(i),iy2)>0)
		if time_weight gt 0 then ave_time = tot_time/time_weight $
			else ave_time = max(time(x(i),iy1:iy2))
		e = 0
		for j=iy1,iy2 do e = e or dq(x(i),j)

		flux(i) = tot
		errf(i) = sqrt(var)
		epsf(i) = e
		spec_time(i) = ave_time
	end

;
; extraction parameters
;
	sxaddpar,h,'gwidth',gwidth
	sxaddpar,h,'bwidth',bwidth
	sxaddpar,h,'ubdist',ubdist
	sxaddpar,h,'lbdist',lbdist
	sxaddpar,h,'bmedian',bmedian
	sxaddpar,h,'bmean1',bmean1
	sxaddpar,h,'bmean2',bmean2
;
; write results
;
	gross = flux + sback + sky_back
	fdecomp,file,disk,dir,name
	name = gettok(name,'_')
	mwrfits,{x:x,y:yfit,wave:wave,flux:flux,gross:gross, $
		back:sback+sky_back, $
		eps:epsf,err:errf,xback:xb, $
		blower:blower+sky_blower,bupper:bupper+sky_bupper,time:spec_time}, $
		subdir+'/spec_'+name+strlowcase(star)+'.fits',h,/create
	if keyword_set(save_back) then $
	   mwrfits,back_results,subdir+'/back_'+name+strlowcase(star)+'.fits', $
		h,/create
end
