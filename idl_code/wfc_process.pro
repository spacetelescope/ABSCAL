pro wfc_process,target,subobs,directory=directory,			      $
	ywidth = ywidth, gwidth = gwidth, bdist = bdist, 		      $
	bwidth = bwidth, bmedian = bmedian, bmean1 = bmean1, bmean2 = bmean2, $
	trace=trace,flatfile=flatfile,display=display, subdir=subdir, 	      $
	before=before, star=star, xstar=xstar, ystar=ystar,dirimg=dirimg,     $
	slope=slope, Ubdist=Ubdist, Lbdist=Lbdist,dirlog=dirlog,grism=grism
;+
; 			wfc_process
;
; routine to run calwfc_spec on list of files in logfile w/ 1st 6 char=subobs
;
; CALLING SEQUENCE:
;	wfc_process,target,subobs,directory=directory,....
;
; INPUTS:
;	target - target name in the logfile created by dirwfc.pro
;	subobs - first 6 char of the subset of filenames of mult obs of the
;		target to process. OR an array of 9char rootnames to process.
;		Optional-if not present, process all obs.
;
; OPTIONAL INPUT:
;	directory - directory containing the calibrated image files.
;		default = none yet
;	ywidth - width of the search area for spectra location (starting
;		from position YC+YOFFSET). (see calwfc_spec for default)
;	yoffset - distance from YC to center search area for spectral location.
;		(see calwfc_spec for default)
;	gwidth - width of the spectral extraction region (i.e. height of the
;		extraction slit).(see calwfc_spec for default)
;	bwidth - width (in Y) of the upper and lower background regions.
;		(see calwfc_spec for default)
;	bdist - distance in Y to the center of the upper and lower background
;		regions (see calwfc_spec for default)
;	Ubdist - upper background distance (if supplied it overrides the
;		bdist parameter)
;	Lbdist - lower background distance (if supplied it overrides the
;		bdist parameter)
;		To only use an upper or lower background distance set
;		the value of UbdistU = -Lbdist (a negative value for one of
;		the bdist parameters can be used to sample both from the
;		same side of the spectrum.
;	bmedian - median filter width for background spectrum
;	bmean1 - first mean filter width for smoothing the background spectrum
;		(see calwfc_spec for default)
;	bmean2 - second mean filter width for smoothing the background spectrum
;		(see calwfc_spec for default)
;	/DISPLAY - display camera mode image and located target
;	/TRACE - display spectra image with the extraction regions overplotted
; 	flatfile - name of the text file containing the flat field files
;		versus wavelength.  (The reference files are located in
;		directory indicated by environment variable WFCREF)
;		If set to '' or to 'NONE' then no spectral flatfielding is done.
;		(see calwfc_spec for default)
;	subdir - output subdirectory for the results (default = 'spec')
;	/before - if set, flat fielding is done before background
;		subtraction
;	star - optional string name for star ID to be added to the output
;		filenames
;	xstar - approximate x position of the star
;	ystar - approximate y position of the star
;	xstar,ystar defaults: Per calnic_imagepos, pick peak of median of
;		central part of direct reference image.
;	/slope - fix slope of spectrum instead of fitting it
;	slope = floating point value of the slope in degrees (overides default
;		value if /slope is used)
;	dirlog - log of observations. default= dirwfc.log
;	grism  - process just one grism mode
;
; OUTPUT FILES:
;	Results are placed into an output FITS binary table with name:
;		spec_<input file name>.fits
;	It has columns:
;		x - x position (column of the extracted spectral values)
;		y - y center of the spectrum versus the x position
;		wave - wavelength vector (microns)
;		flux - extracted net count rate spectrum.
;		eps - data quality vector (using standard CALWFC values)
;		err - propagated statistical errors for flux
;
;	 	   {x,y,wave,flux,err and eps all have the same length}
;
;		xb - xpositions of the background extractions
;		bupper - upper background level (counts/pixel)
;		blower - lower background level (counts/pixel)
;		sback - smoothed average upper and lower background level
;			(counts/pixel)
;
;		   {xb, blower, bupper, and sback all have the same length
;		    and are slightly longer than flux vector}
;
; HISTORY:
;	converted from nic_process Feb 2012 - RCB
; 2015May4 - Add direct image name to output header
; 2015May6 - calwfc_imagepos & calwfc_spec mod to include xerr,yerr
; 2018Apr - process subarr
;-
;2013Mar flag for em line obj
	if strpos(target,'PN') ge 0 or strpos(target,'VY2-2') ge 0 or	$
					target eq 'IC-5117' then star='PN'
	if not keyword_set(subdir) then subdir = 'spec'
	logfil = 'dirwfc.log'
	if keyword_set(dirlog) then logfil = dirlog
	
	if keyword_set(directory) then begin
		if strpos(logfil, '/') lt 0 then logfil = directory + '/' + dirlog
		if strpos(subdir, '/') lt 0 then subdir = directory + '/' + subdir
	endif
	wfcobs,logfil,allobs,allfilt,allaper,stardum,'','',target
; Rm Bad obs:
	good=where(strpos(allobs,'iab907jdq') lt 0 and  $; wrong signed postarg
		strpos(allaper,'UVIS') lt 0) 	;and 			$
;2018apr25-try for ibll82ouq	strpos(allaper,'SUB') lt 0) ; ignore subarr
	allobs=allobs(good)
	allfilt=allfilt(good)
	if keyword_set(grism) then begin			;06jun27-rcb
		good=where(strpos(allfilt,'F') eq 0 or 		$
			strpos(allfilt,strupcase(grism)) eq 0)
		allobs=allobs(good)  &  allfilt=allfilt(good)
		endif
	if n_params(0) eq 1 then begin		; no subobs specified
		obs=allobs
		filter=allfilt
	     end else							$
		if n_elements(subobs) le 1 then begin	; normal prewfc case
; if one element, then must be 6 char to pick up a set that incl the acq image!
			good=where(strmid(allobs,0,6) eq subobs)
; special patch to include an orphan obs that should be part of iab901 or iab904
			if subobs eq 'iab901' then good=		$
				where(strmid(allobs,0,6) eq subobs or 	$
				strmid(allobs,0,6) eq 'iab9a1')		; G102
			if subobs eq 'iab904' then good=		$
				where(strmid(allobs,0,6) eq subobs or 	$
				strmid(allobs,0,6) eq 'iab9a4')		; G141
			obs=allobs(good)
			filter=allfilt(good)
		     end else begin		; subobs is list to process
			obs=subobs  &  filter=obs
			for i=0,n_elements(subobs)-1 do begin
				good=where(allobs eq subobs(i))
				filter(i)=allfilt(good(0))
				endfor
			endelse
;
; move first camera mode image to the front if not already there
;
	fmode = (where(strmid(filter,0,1) eq 'F'))[0]
	if fmode gt 0 then begin
		n = n_elements(filter)
		sub = indgen(n)
		if fmode eq (n-1) then sub = [n-1,sub(0:n-2)] $
			else sub = [fmode,sub(0:fmode-1),sub(fmode+1:*)]
		obs = obs(sub)
		filter = filter(sub)
		endif
	file = obs+'_flt.fits'
	lst = directory+'/'+file

; none yet for WFC3  nic_coadd_dither,lst,filter;co-adds @ same dither position
	print,'WFC_process reducing ',file
	xc=0.  &  yc=0.  &  dirimnam='NONE'
	xerr=0.  &  yerr=0.
	for i = 0,n_elements(lst)-1 do begin
	    if strmid(filter(i),0,1) ne 'G' then begin	; ref. images
	    	if filter(i) ne 'Blank' then begin	; skip scan mode darks
	    	     calwfc_imagepos,lst(i),xc,yc,crval1,crval2,xerr,	$
		     		yerr,display=display,xstar=xstar,	$
					ystar=ystar,target=target
		     dirimnam=obs(i)
		     endif
	      end else begin					; grism obs
	        print,target
	        calwfc_spec,lst(i),xc,yc,xerr,yerr,			$
			ywidth = ywidth, gwidth = gwidth, bdist = bdist,$
			bwidth = bwidth, bmedian = bmedian, bmean1 = bmean1, $
			bmean2 = bmean2, trace=trace,flatfile=flatfile,	$
			subdir = subdir, star = star, before=before,	$
			slope=slope,crval1 = crval1, crval2 = crval2,	$
			Lbdist = Lbdist,Ubdist = Ubdist,display=display,$
			dirimg=dirimg,dirimnam=dirimnam,target=target
	      endelse
	endfor						; end of lst
;
; clean up coadded dithers
;
; not needed yet, see above	spawn,'/bin/rm *_dither_tempfile.fits'
end
