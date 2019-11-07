pro nic_process,target,subobs,directory=directory,				$
	xbinsize = xbinsize, ywidth = ywidth, gwidth = gwidth, bdist = bdist, $
	bwidth = bwidth, bmedian = bmedian, bmean1 = bmean1, bmean2 = bmean2, $
	trace=trace, flatfile=flatfile, display=display, subdir=subdir, $
	before=before, star=star, xstar=xstar, ystar=ystar, 		$
	slope=slope, Ubdist=Ubdist, Lbdist=Lbdist, dirlog=dirlog,grism=grism
;+
; 			nic_process
;
; routine to run calnic_spec on list of files in logfile
;
; CALLING SEQUENCE:
;	nic_process,target,subobs,directory=directory,....
;
; INPUTS:
;	target - target name in the logfile created by dirstis.pro
;	subobs - first 6 char of the subset of filenames of mult obs of the
;		target to process. OR 05nov15: an array of rootnames to process.
;		Optional-if not present, process all obs.
;		but the wrong ref image may be selected. Right, Don?
;
; OPTIONAL INPUT:
;	directory - directory containing the calibrated image files.
;		default = '/internal/1/data/spec/nic/'
;	xbinsize - value of binning in x-direction for generating profiles
;		by summing in x when computing spectral location.
;		(see calnic_spec for default)
;	ywidth - width of the search area for spectra location (starting
;		from position YC+YOFFSET). (see calnic_spec for default)
;	yoffset - distance from YC to center search area for spectral location.
;		(see calnic_spec for default)
;	gwidth - width of the spectral extraction region (i.e. height of the
;		extraction slit).(see calnic_spec for default)
;	bwidth - width (in Y) of the upper and lower background regions.
;		(see calnic_spec for default)
;	bdist - distance in Y to the center of the upper and lower background
;		regions (see calnic_spec for default)
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
;		(see calnic_spec for default)
;	bmean2 - second mean filter width for smoothing the background spectrum
;		(see calnic_spec for default)
;	/DISPLAY - display camera mode image and located target
;	/TRACE - display spectra image with the extraction regions overplotted
; 	flatfile - name of the text file containing the flat field files
;		versus wavelength.  (The reference files are located in
;		directory indicated by environment variable NICREF)
;		If set to '' or to 'NONE' then no spectral flatfielding is done.
;		(see calnic_spec for default)
;	subdir - output subdirectory for the results (default = 'spec')
;	/before - if set, flat fielding is done before background
;		subtraction
;	star - optional string name for star ID to be added to the output
;		filenames
;	xstar - approximate x position of the star
;	ystar - approximate y position of the star
;	xstar,ystar defaults: Per calnic_imagepos, pick peak of median of
;		central 71:139,41:119 of direct reference image.
;	/slope - fix slope of spectrum instead of fitting it
;	slope = floating point value of the slope in degrees (overides default
;		value if /slope is used)
;	dirlog - log of observations. default= dirnic.log
;
; OUTPUT FILES:
;	Results are placed into an output FITS binary table with name:
;		spec_<input file name>.fits
;	It has columns:
;		x - x position (column of the extracted spectral values)
;		y - y center of the spectrum versus the x position
;		wave - wavelength vector (microns)
;		flux - extracted net count rate spectrum.
;		eps - data quality vector (using standard CALNIC values)
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
;	version 1, D. Lindler, Oct. 2003
;	version 2, D. Lindler, July 2004, added star, xstar, ystar keyword
;		inputs.
;	August 30, 2004, added no_nonlinearity keyword parameter
;	Sept. 23, 2004, added case where first image is not a camera mode image.
;	04Dec1 - add subobs input option
;	Jan 25, 2005 - added slope keyword parameter
;	Jan 31, 2005, Lindler, got rid of yshifts parameter. added crval1 and
;		crval2 inputs to calnic_spec and calnic_imagepos. added
;		Ubdist and Lbdist
;	05feb12 - rcb added dirlog keyword
;	05nov15 - rcb added logic for Lamp on/off obs, where subobs is the
;		array of rootnames to process
;       05dec01 - small change to make the routine work on a PC.
;	06jun27 - add grism keyword, so that modes can be processed separately
;	07Jun08 - added coaddition of images at same dither position
;	16aug18 - rcb added xc,yc common, so that once the ref star position is
;		found, xc,yc will continue to be used until updated.
;	16aug22 - list --> lst
;-
common xcyc,xc,yc
	if n_elements(directory) eq 0 then directory = 			$
						'/internal/1/data/spec/nic/'
	if n_elements(subdir) eq 0 then subdir = 'spec'
	logfil='dirnic.log'
	if keyword_set(dirlog) then logfil=dirlog
	stisobs,logfil,allobs,allfilt,aperdum,stardum,'','',target
	if keyword_set(grism) then begin			;06jun27-rcb
		good=where(strpos(allfilt,'F') eq 0 or 		$
			strpos(allfilt,grism) eq 0)
		allobs=allobs(good)  &  allfilt=allfilt(good)
		endif
	if n_params(0) eq 1 then begin
		obs=allobs
		filter=allfilt
	     end else							$
		if n_elements(subobs) le 1 then begin
; if one element, then must be 6 char to pick up a set that incl the acq image!
			good=where(strmid(allobs,0,6) eq subobs)
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
	end

	file = obs+'_cal.fits'
	if strpos(target,'FAKE') ge 0 or strpos(target,'PSF') ge 0 then	$
			file=obs+'_cal_'+strlowcase(target(0))+'.fits'
	lst = directory+file

	nic_coadd_dither,lst,filter	; writes a dither template

	for i = 0,n_elements(lst)-1 do begin
	    if strmid(filter(i),0,1) ne 'G' then begin
	    	calnic_imagepos,lst(i),xc,yc,crval1,crval2, $
			display=display,xstar=xstar,ystar=ystar
	      end else begin
	        calnic_spec,lst(i),xc,yc, xbinsize = xbinsize,  $
			ywidth = ywidth, gwidth = gwidth, bdist = bdist, $
			bwidth = bwidth, bmedian = bmedian, bmean1 = bmean1, $
			bmean2 = bmean2, trace=trace, flatfile=flatfile, $
			subdir = subdir, star = star, before=before, $
			slope=slope, $
			crval1 = crval1, crval2 = crval2, Lbdist = Lbdist, $
			Ubdist = Ubdist

	    end
	end
;
; clean up coadded dithers
;
	spawn,'/bin/rm *_dither_tempfile.fits'
end
