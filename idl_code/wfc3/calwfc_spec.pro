;+
;				calwfc_spec
;
; Routine to extract wfc3 point source spectrum from a calibrated image
; file.
;
; CALLING SEQUENCE:
;	calwfc_spec,file,xco,yco,xerr,yerr,wave,flux,errf,epsf
;
; INPUTS:
;	file - name of the calibrated image file
;	xco - target x position in camera mode observation. Subarr ref. px, ie
;	yco - target y position in camera mode observation. 0,0 is subarr corner
;	xerr- X pointing error in px from calwfc_imagepos
;	yerr- Y pointing error in px from calwfc_imagepos
;
; OUTPUTS:
;	wave - wavelength vector
;	flux - net count rate spectrum
;	errf - propagated statistical errors for flux
;	epsf - data quality vector
;
; OPTIONAL KEYWORD INPUTS:
;	ywidth - width of the search area for spectra location
;		default = 11 if crval1 and crval2 are specified
;		default = 30, otherwise
;	yoffset - distance from YC to center search area for spectral location.
;		(default = 0) {NOT used for WFC3}
;	gwidth - width of the spectral extraction region (i.e. height of the
;		extraction slit). default = 6
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
;		parameters instead of input parameters. {NOT enabled here-RCB}
;	/DISPLAY - display camera mode image and located target if IMAGEFILE
;		is specified.
;	/TRACE - display spectra image with the extraction regions overplotted
; 	flatfile - name of the text file containing the flat field files
;		versus wavelength.  (The reference files are located in
;		directory indicated by environment variable WFC3_REF)
;		default = 'g1*ffcube.fits'
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
;	dirimg - flag to use direct image for wavecal, instead of default z-ordr
;	dirimnam-direct image name. 2015may4
;	noprnt-to avoid garbage pointing & WL info in scanned data headers.
;	/target - name for the target that is in dir log file. 2020feb4

; OUTPUT FILE:
;	Results are placed into an output FITS binary table with name:
;		spec_<input file name>.fits
;	It has columns:
;		x - x position (column of the extracted spectral values)
;		y - y center of the spectrum versus the x position
;		wave - wavelength vector
;		net - extracted net count rate spectrum.
;		gross - gross count rate spectrum
;		back  - smoothed average background  count rate spectrum
;		eps - data quality vector (using standard CALWFC values)
;		err - propagated statistical errors for flux
;
;	 	   {x,y,wave,flux,err and eps all have the same length}
;
;		xback - xpositions of the background extractions
;		bupper - upper background level (counts/pixel)
;		blower - lower background level (counts/pixel)
;		sback - smoothed average upper and lower background level
;			(counts/pixel) {If save_back keyword is set.-rcb}
;		time  - Exp time
;
;		   {xb, blower, bupper, and sback all have the same length
;		    and are slightly longer than the net vector}
;
; HISTORY:
;	version 1, D. Lindler, Oct. 2003
;	version 2, D. Lindler, July 2004, added /BEFORE option, added
;		extraction of gross spectrum. added star id input.
;	06jan9 - RCB subtract the scaled grism flat to remove contin contrib.
;	06feb28- RCB add mean bkg to header from wfc_flatscal & subtr bkg
;		continuum.
;	06aug08- DJL added effective exposure time for each extracted flux value
;	    Modified output GROSS and BACK to be extractions from the raw image.
;	06aug18 - DJL - modified to flat field sky image with sky flat and
;		extract the flat fielded sky background which is included
;		in the output background arrays.  Gross is now just the
;		extracted net flux plus the smoothed background
;	07Jun08 - DJL - moved flat fielding before spectral location.
;	12Feb - RCB mod of calnic_spec for WFC3 IR & multiply by PAM--
;		NO! remove PAM. No doc & makes a worse variation around FOV.
;	12Feb28-Add scaling of net,bkg, & gross for dispersion corr to center
;	2012June - add scanned spectral image reduction
;	2013April - Add my WL solution when 0-order is on the images. Otherwise,
;		retain the AXE direct image WLs
;	2013apr20 - add dirimg keyword
;	2015may4  - add direct image rootname to hdr as DIRIMAGE
;	2015may4  - add x,yactual keywords for found dir image location
;	2015may5  - switch to believing the grism astrom+Petro for pred. Z-ord
;			position, instead of x,y shifts at 506,506 for STARE.
;	2015July14- add flatfile='none', etc. capability for point sources
;	2018apr18 - add corr for Proper motion of target in wfcdir.pro
;	2018may   - add astrom err for dirimg and Z-ord to headers.
;	2018jun26 -implement Pirzkal ISR 2016-15 WL solution in CALWFC_SPEC_WAVE
;	2018jul19-repair also dq=8, unstable: Big help-fixes most of the big
;			dropouts.
;	2020feb - Add target name to input & call wfcread instead of fits_read
;		to do coord corr. & replace that func in wfcdir for multiple
;		targets on an image.
;	2020feb4 - switch from cntrd to gcntrd for Z-ord fit
;========================================================  CALWFC_SPEC_WAVE

; ##### 2020feb4 - If ever have 2 spectra on same img that need this AXE code,
;	then need to add targname to WFCWLFIX.PRO ###########

;
; Routine to compute wavelength vector and column numbers to extract
;
pro calwfc_spec_wave,h,xcin,ycin,x,wave,angle,wav1st,noprnt=noprnt
; USE FOR AXE SOLUTION ONLY. Z-ORD SOLUTION USES WFC_WAVECAL
;
; INPUTS:
;	h - header
;	xcin,ycin - as above for xco,yco
;	noprint - optional keyword to avoid writing to header and printing.
; OUTPUTS:
;	x    - indgen(1014)
;	wave - wavelength vector, customized for each order
;	angle - avg slope of spectrum
;	wav1st - 1st order WLs for flat fielding w/ FF data cube
;-
; This CALWFC_SPEC_WAVE & is only used if NO Z-order
if not keyword_set(noprnt) then					$
	sxaddpar,h,'xc',xcin(0),'Dir img ref X position used for AXE WLs'
if not keyword_set(noprnt) then					$
	sxaddpar,h,'yc',ycin(0),'Dir img ref Y position used for AXE WLs'
filter = strtrim(sxpar(h,'filter'))
x=indgen(1014)				; indices of image x size
xc=xcin  &  yc=ycin
; if subarr, put input position onto 1014x1014 grid;
ns=sxpar(h,'naxis1')
if ns lt 1014 then begin
	ltv1=-sxpar(h,'ltv1')         	; positive subarr offset
	ltv2=-sxpar(h,'ltv2')         	; positive subarr offset
	xc=xcin+ltv1			; onto 1014X1014 ref frame
	yc=ycin+ltv2
	endif

	case filter of
	 'G102': begin
; WFC3 ISR 2016-15 - AXE
; +1st order:
		b=0.20143085d  &  c=0.080213136d
		d=-0.00019613d &  e=0.0000301396d  &  f=-0.0000843157d
	      	a0 = 6344.081+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		b=-0.00071606d  &  c=0.00084115d
		d=8.9775481d-7 &  e=-3.160441d-7  &  f=7.1404362d-7
		a1 = 24.00123+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		wave = a0 + a1 * (x - xc)
		if not keyword_set(noprnt) then	begin
		  sxaddpar,h,'a0+1st',a0,'Constant Term of the +1st order disp.'
		  sxaddpar,h,'a1+1st',a1,'Linear Term of the +1st order disp.'
		  endif
; zero order: Susana says the ISR is crap and seem true to me... Ignore 0-order.
; -1st order:
		b=0.  &  c=-1.11124775d
		d=0. &  e=0.  &  f=0.00095901d
	      	a0 = -6376.843+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		b=0.  &  c=-0.003251784d
		d=0. &  e=0.  &  f=1.4988d-6
		a1 = -24.27561+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
;-1 formula seems better than +1 order for finding pixel of 0-order.
		indx=where(wave lt 300,npts)
		if npts gt 0 then begin
		 wave(indx)=-(a0+a1*(indx-xc))
; ck monotonicity:
		 if wave(indx(-1)) le wave(indx(-1)-1) then stop
		 if not keyword_set(noprnt) then begin
		  sxaddpar,h,'a0-1st',a0,'Constant Term of the -1st order disp.'
		  sxaddpar,h,'a1-1st',a1,'Linear Term of the -1st order disp.'
		  endif
		 endif
		wav1st=wave			; 1st order WLs for FF
; 2nd order:
		b=0.291324446d  &  c=0.039748254d
		d=-0.000405844d &  e=6.5079365d-6  &  f=-0.00003221d
	      	a0 = 3189.9195+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		b=-0.00046352d  &  c=0.000670315d
		d=5.7894508d-7 &  e=0.  &  f=5.667d-8
		a1 = 12.08004+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		indx=where(wave gt 14000,npts)
		if npts gt 0 then begin
		  wave(indx)=2*(a0+a1*(indx-xc))
		  wav1st(indx)=a0+a1*(indx-xc)
; enforce monotonicity:
		  ibreak=min(indx)
		  bad=where(wave(0:ibreak-1) gt wave(ibreak),npts)
		  	if npts gt 0 then begin
			   delwl=((wave(ibreak)-wave(ibreak-1-npts))>1)/(npts+1)
			   wave(ibreak-npts:ibreak)=wave(ibreak-npts)+	$
					delwl*indgen(npts+1)
			   wav1st(ibreak-npts:ibreak)=wave(ibreak-npts:ibreak)/2
			   endif
		 if not keyword_set(noprnt) then begin
		  sxaddpar,h,'a0+2nd',a0,'Constant Term of the +2nd order disp.'
		  sxaddpar,h,'a1+2nd',a1,'Linear Term of the +2nd order disp.'
		  endif
		 endif
; 3nd order, orig Axe:
;		b=0  &  c=5.01084E-02
;		a0=2.17651E+03+b*xc+c*yc
;		b=0  &  c=4.28339E-04
;		a1=8.00453E+00+b*xc+c*yc
;		indx=where(wave gt 23500,npts)
;		if npts gt 0 then begin
;		  wave(indx)=3*(a0+a1*(indx-xc))
;		  wav1st(indx)=a0+a1*(indx-xc)
;		  sxaddpar,h,'a0+3rd',a0,'Constant Term of the +3rd order disp.'
;		  sxaddpar,h,'a1+3rd',a1,'Linear Term of the +3rd order disp.'
;		  endif

	       angle=0.66			; 2018may10-see angle.pro
	       end
	 'G141': begin
; WFC3 ISR 2009-17
; +1st order:
		b=0.08044033d  &  c=-0.00927970d
		d=0.000021857d &  e=-0.000011048d  &  f=0.000033527d
	      	a0 = 8951.386+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		b=0.000492789d  &  c=0.00357824d
		d=-9.175233345d-7 &  e=2.235506d-7  &  f=-9.25869d-7
		a1 = 44.972279+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		wave = a0 + a1 * (x - xc)
		if not keyword_set(noprnt) then begin
		 sxaddpar,h,'a0+1st',a0,'Constant Term of the +1st order disp.'
		 sxaddpar,h,'a1+1st',a1,'Linear Term of the +1st order disp.'
		 endif
; -1st order:
		b=0.  &  c=-0.8732184d
		d=0. &  e=0.  &  f=0.0009233797d
	      	a0 = -9211.190+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		b=0.  &  c=-0.004813895d
		d=0. &  e=0.  &  f=2.0768286663d-6
		a1 = -46.4855+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
;-1 formula is better than +1 order for finding pixel of 0-order.
		indx=where(wave lt 300,npts)
		if npts gt 0 then begin
		  wave(indx)=-(a0+a1*(indx-xc))
; enforce monotonicity:
		  ibreak=max(indx)
		  bad=where(wave(ibreak+1:1013) lt wave(ibreak),npts)
		  if npts gt 0 then begin
			   delwl=((wave(ibreak+1+npts)-wave(ibreak))>1)/(npts+1)
			   wave(ibreak:ibreak+npts)=wave(ibreak)+	$
					delwl*indgen(npts+1)
			   endif
		 if not keyword_set(noprnt) then begin
		  sxaddpar,h,'a0-1st',a0,'Constant Term of the -1st order disp.'
		  sxaddpar,h,'a1-1st',a1,'Linear Term of the -1st order disp.'
		  endif
		 endif
		wav1st=wave			; 1st order WLs for FF
; 2nd order:
		b=0.17615670d  &  c=0.046354019d
		d=-0.00012965d &  e=0.00001513d  &  f=-0.00002961d
	      	a0 = 4474.5297+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		b=-0.0002159637d  &  c=0.00133454d
		d=4.277729d-8 &  e=-8.522518d-8  &  f=6.08125d-8
		a1 = 22.8791467+b*xc+c*yc+d*xc^2+e*xc*yc+f*yc^2
		indx=where(wave gt 19000,npts)
		if npts gt 0 then begin
		 wave(indx)=2*(a0+a1*(indx-xc))
		 wav1st(indx)=a0+a1*(indx-xc)
; ck monotonicity:
		 if wave(indx(0)) le wave(indx(0)-1) then stop
		 if not keyword_set(noprnt) then begin
		  sxaddpar,h,'a0+2nd',a0,'Constant Term of the +2nd order disp.'
		  sxaddpar,h,'a1+2nd',a1,'Linear Term of the +2nd order disp.'
		  endif
		 endif
; 3nd order:
;		b=1.04205E-01  &  c=-1.18134E-03
;		a0=3.00187E+03+b*xc+c*yc
;		b=-2.08555E-04  &  c=9.55645E-04
;		a1=1.52552E+01+b*xc+c*yc
;		indx=where(wave gt 31000,npts)
;		if npts gt 0 then begin
;		  wave(indx)=3*(a0+a1*(indx-xc))
;		  wav1st(indx)=a0+a1*(indx-xc)
;		  sxaddpar,h,'a0+3rd',a0,'Constant Term of the +3rd order disp.'
;		  sxaddpar,h,'a1+3rd',a1,'Linear Term of the +3rd order disp.'
;		  endif

	       angle=0.44			; 2018may10-see angle.pro
	       end				; G141
	endcase
; 2018jun23 - try moving wfcwlfix here instead of at bottom.
root=strtrim(sxpar(h,'rootname'),2)
offset=wfcwlfix(root)				; offset in Ang
wave=wave+offset
wav1st=wav1st+offset

;2018May1 - pick out wave subset in subarr
if ns lt 1014 then begin
	ibeg=ltv1
	iend=ltv1+ns-1
	wave=wave(ibeg:iend)
	wav1st=wav1st(ibeg:iend)
	endif
if not keyword_set(noprnt) then 				$
  print,string(minmax(wave),'(2f8.1)')+' minmax WLs. Ref. (1014)px at=',xc,yc
end

;========================================================  calwfc_spec_flat
;
; Routine to flat field the data with wavelength depended flats
;
pro calwfc_spec_flat,h,image,err,dq,xindex,wave,flatfile
; where wave is the FIRST order WLs * all parameters are input, except flatfile
;	in the case of using orig AXE default. New SED default flatfil is INPUT.
; Not used in this pro are: err,dq,xindex
; Output is FF'd image and flatfile=name of FF file of coef.
;-
; 2012mar7 - Implement:
; 2018Apr26 - mod for subarrays
; AXE method of using quadratic fits to the FF vs WL for ea px. See doc/ff.grism

filt=strtrim(sxpar(h,'filter'),2)

; add here code to use default FF when flatfile=''

coef3=fltarr(1014,1014)				;for quadrat. fits of SED & Ryan
if strpos(flatfile,'both') lt 0 then begin	; BOTH-g102&141 pkgd. together
; Current default:
	if filt eq 'G102' then 						$
		flatfile=find_with_def('g102ffcube.fits','WFC3_REF') else $
		flatfile=find_with_def('g141ffcube.fits','WFC3_REF')
	fits_read,flatfile,coef3,hdr,exten=3		;only case w/ cubic fits
endif else begin
    flatfile=find_with_def(flatfile,'WFC3_REF')
endelse
print,'FF file=',flatfile
sedoff=0			;Susana has hdr in exten=0, coef0 in exten=1 etc
if strpos(flatfile,'sed') ge 0 then sedoff=1
; WMIN and WMAX are actually in the zeroth header.
;	We *can* use Ralph's custom fits_read file here, which will get
;	coefficients regardless of extension through some black magic, or
;	we can just read in the primary header and get them there, then proceed.
;
;	I'm doing the latter.
fits_read,flatfile,ignore,hdr,exten=0
wmin = float(sxpar(hdr,'wmin'))
wmax = float(sxpar(hdr,'wmax'))

fits_read,flatfile,coef0,hdr,exten=0+sedoff
fits_read,flatfile,coef1,hdr,exten=1+sedoff
fits_read,flatfile,coef2,hdr,exten=2+sedoff

; 1st ord WLs defined for 1014 px, but for subarr: wave(0) is for 1st subarr px
abswl=abs(wave)
x=(abswl-wmin)/(wmax-wmin)		; normalized 1st order wavelengths
good=where(abswl ge 7000 and abswl le 12000)	; Range to be FF'ed
if filt eq 'G141' then good=where(abswl ge 9000 and abswl le 18000)
xgood=x(good)				; do just applicable range
ff=image*0+1.				; the AXE model flat field
siz=size(abswl)				; 1-D:pt source; 2-D:trailed image
ltv1=-sxpar(h,'ltv1')         	; positive subarr offset
ltv2=-sxpar(h,'ltv2')         	; positive subarr offset
ns=sxpar(h,'naxis1')
nl=sxpar(h,'naxis2')
;for i=0,1013 do begin			; Fill row-by-row:
for i=0,nl-1 do begin			; Fill row-by-row:
	if siz(0) eq 2 then begin	; for 2-D scanned case
		good=where(abswl(*,i) ge 7000 and abswl(*,i) le 12000)
		if filt eq 'G141' then good=where(abswl(*,i) ge 9000 	$
							and abswl(*,i) le 18000)
		xgood=x(good,i)		; do just applicable range
		endif
; offsets into 1014x1014 coefs:
	xpx=good+ltv1  &  ypx=i+ltv2
; orig	ff(good,i)=coef0(good,i)+coef1(good,i)*xgood+		$
;				coef2(good,i)*xgood^2+coef3(good,i)*xgood^3
	ff(good,i)=coef0(xpx,ypx)+coef1(xpx,ypx)*xgood+		$
				coef2(xpx,ypx)*xgood^2+coef3(xpx,ypx)*xgood^3
	endfor
if ns lt 1014 then print,'subarray w/ ltv1,ltv2=',ltv1,ltv2
ff(where(ff le 0.5))=1			; fix AXE glitches (96px le 0)
image=image/ff
sxaddpar,h,'flatfile',flatfile
print,'CALWFC_SPEC_FLAT for number of wave points=',ns
;tvscl,ff>.9<1.1  &  stop
end
;============================================================= CALWFC_SPEC
;
; MAIN ROUTINE
;
pro calwfc_spec,file,xco,yco,xerr,yerr,wave,flux,errf,epsf,		$
	yoffset=yoffset,ywidth = ywidth, gwidth = gwidth, bdist = bdist,$
	bwidth = bwidth, bmedian = bmedian, bmean1 = bmean1, bmean2 = bmean2, $
	imagefile=imagefile, display=display, trace=trace,		$
	subdir = subdir, star=star, before=before,flatfile=flatfile,	$
	slope=slope,Ubdist=Ubdist, Lbdist=Lbdist, 			$
	crval1=crval1, crval2=crval2,dirimg=dirimg,dirimnam=dirimnam,	$
	target=target
st=''
!x.style=1  &  !y.style=1
!p.font=-1
if not keyword_set(flatfile) then flatfile=''		;2015jul-Use default FF
;
if n_params(0) eq 0 then begin
	print,'calwfc_spec,file,xco,yco,xerr,yerr,wave,flux,errf,epsf'
	print,'KEYWORD INPUTS: ywidth, gwidth, bwidth, bdist'
	print,'                bmedian, bmean1, bmean2, imagefile'
	print,'                /display, /trace, subdir'
	print,'                star, /before, /slope'
	print,'		       slope, Ubdist, Lbdist, crval1, crval2'
	return
	endif
;
; set defaults
;
if n_elements(yoffset) eq 0 then yoffset = 0
if n_elements(gwidth) eq 0 then gwidth = 6.		; Nicmos: 4.0
if n_elements(bwidth) eq 0 then bwidth = 13
if n_elements(bdist) eq 0 then bdist =25+bwidth/2	;2018may-add bwidth/2+3
if n_elements(Ubdist) eq 0 then ubdist = bdist
if n_elements(Lbdist) eq 0 then lbdist = bdist
if n_elements(bmedian) eq 0 then bmedian = 7
if n_elements(bmean1) eq 0 then bmean1 = 7
if n_elements(bmean2) eq 0 then bmean2 = 7
if n_elements(imagefile) eq 0 then imagefile = ''
if n_elements(subdir) eq 0 then subdir = 'spec'
if n_elements(star) eq 0 then star=''
;
; determine center of the object in the camera mode image if IMAGEFILE is
; supplied. But is NOT supplied for WFC3. Here, the direct image is supplied
; automatically via wfc_process, so that xco,yco are input here, rather than
; output.
if imagefile ne '' then stop		;ck del below. WFC3 no-op

pos=strpos(file,'.fits')
sptfil=file
strput,sptfil,'spt',pos-3
fdum=findfile(sptfil)
if fdum eq '' then scnrat=0. else begin
	fits_read,sptfil,dum,hdspt
	scnrat=sxpar(hdspt,'scan_rat')
;;	fracyr=absdate(sxpar(hdspt,'pstrtime'))
	if scnrat gt 0 then strput,file,'ima',pos-3
	endelse
; Search a smaller box, if there crval's are defined from dir image;
if n_elements(ywidth) eq 0 then $
		if n_elements(crval1) gt 0 then ywidth = 11 else ywidth=30
;
; Read data and flag any bad pixels not already flagged
;
;2020feb4-replace reading of header w/ wfcread, which will corr coord, as needed
;fits_read,file,image,h, extname='SCI'
wfcread,file,target,image,h, extname='SCI'

filter = strtrim(sxpar(h,'filter'))
print,'calwfc_spec Processing file '+filter+' '+file
siz=size(image)
xsiz=siz(1)  &  ysiz=siz(2)
fits_read,file,err, extname='ERR'
fits_read,file,time,extname='time'
fits_read,file,dq, extname='DQ'

if scnrat gt 0 then begin		; trim crapola for scanned data
	image=image(5:1018,5:1018)
	err=err(5:1018,5:1018)
	time=time(5:1018,5:1018)
	dq=dq(5:1018,5:1018)
; Clean false dq for 2048-signal in 0-read & 8192-CR detected:
	dq=dq-(dq and (2048+8192))
	endif
; dq(119,95) = "777			;mask NICMOS hot pixel
if strtrim(sxpar(h,'imagetyp'),2) eq 'FLAT' then begin	; 05nov15 rcb
	good=where(time gt 0)
	image(good)=image(good)/time(good)	; flats not div by exptm
	err(good)=err(good)/time(good)		; 05nov28
	endif
;;; end else begin				; 12feb28-PAM NG
;;;		fits_read,'~/wfc3/ref/ir_wfc3_map.fits',pam
;;;		image=image*pam
;;;		print,'Multiply by PAM for WFC3 IR channel.'
;;;		endelse
sxaddpar,h,'xactual',xco,'Actual Found direct image X Position'
sxaddpar,h,'yactual',yco,'Actual Found direct image Y Position'
sxaddpar,h,'xcamerr',xerr,'Pointing error XACTUAL-PREDICT (px)'
sxaddpar,h,'ycamerr',yerr,'Pointing error YACTUAL-PREDICT (px)'
;
; compute offsets from the dithers
;
if n_elements(crval1) gt 0 then begin
	extast,h,astr,status	;get astrometry information
	if status eq -1 then begin
		print,'CALWFC_SPEC: Error - Invalid astrometry ' + $
		    		'info in the image '+file
		retall
		endif
; crval1,crval2 are input RA, DECL of ref px from direct image
;							where xco,yco are found.
	ad2xy,crval1,crval2,astr,x1,y1   ;center position of targ acq
						 ;image in the current image
; xydither must be the built in offset for a grism, as I ckd the direct img
;	ic6906byq astrom, which gives 506,506 for x1,y1, while the ff G141
;	ic6906bzq has x1=440.18, y1=506.54 !
; REFERENCE PIXEL 2018may1
	refpx1=sxpar(h,'crpix1')-1	; minus 1 for IDL
	refpx2=sxpar(h,'crpix2')-1
	xdither = x1[0]-refpx1		;  pos from direct image
	ydither = y1[0]-refpx2		; 506,506 is usual ref px for x1,y1
	print,'calwfc_spec grsm x,y-dither from dir image '+	$
		'at'+string([refpx1,refpx2],'(2i4)')+' in px=',xdither,ydither
     end else begin
	xdither = 0.0
	ydither = 0.0
	endelse
fit_slope = 1				;default is to fit the slope
if keyword_set(slope) then begin			;06jun28-rcb
	fit_slope = 0		; do not fit slope
	if slope ne 1 then angle = slope	; specified slope=slope
	endif
; ################################SCANNED################################
;
;SCANNED SPECTRA have no direct image. Read SPT file, get scan rate & est.xc,yc
;
if scnrat gt 0 then begin		; start trailed processing
	sxaddpar,h,'scan_rat',scnrat,'Trail scan rate'
	xpostarg=sxpar(h,'postarg1')
;find zero order @ y=559. SCANNED ONLY, as locates Z-order in 1-D (X) only.
	ycmean=559  &  ytop=926		;G141 means from scnoffset.pro
	xzappr=303.6+ 7.336*xpostarg  ;G141 scnoffset 0-ord pos @y=558.8
	if filter eq 'G102' then xzappr=000	; 2020jan zx-->xz
	bn=rebin(image(*,559-20:559+20),1014,1)	; binned spectrum @y=559
	plot,bn,xr=[xzappr-60,xzappr+60]
	oplot,[xzappr,xzappr],[0,1e4],line=2
	xind=dindgen(1014)
	mx=where(bn(xzappr-50:xzappr+50) eq 			$
			max(bn(xzappr-50:xzappr+50),mxpos))
	mxpos=fix(mxpos+xzappr-50+.5)
	good=where(bn(mxpos-50:mxpos+50) gt 0.5*bn(mxpos))+mxpos-50
	xzfound=total(xind(good)*bn(good))/total(bn(good))
	oplot,[xzfound,xzfound],[0,1e4]
	xyouts,.15,.2,'Xfound,at y-posn='+			$
			string([xzfound,ycmean],'(f6.1,i4)'),/norm
;	read,st
;find zero order @ y=926 (G141)
	bn=rebin(image(*,ytop-20:ytop+20),1014,1) ;binned spectrum @ytop
	xzfix=fix(xzfound+.5)
	plot,bn,xr=[xzfix-60,xzfix+60]
	oplot,[xzfix,xzfix],[0,1e4],line=2
	mx=where(bn(xzfix-50:xzfix+50) eq 			$
			max(bn(xzfix-50:xzfix+50),mxpos))
	mxpos=mxpos+xzfix-50
	good=where(bn(xzfix-50:xzfix+50) gt 0.5*bn(mxpos))+xzfix-50
	xztop=total(xind(good)*bn(good))/total(bn(good))
	oplot,[xztop,xztop],[0,1e4]
;help,xzfix,mxpos,xztop  &	stop
	xyouts,.15,.2,'Xztop,at y-posn='+			$
			string([xztop,ytop],'(f6.1,i4)'),/norm
	z0coef0=xzfound			   ;coef-0 for 0-ord xz vs yz
	z0coef1=(xztop-xzfound)/(ytop-559) ;coef-1 for del-y, ie (y-559)
	print,'coef for 0-order vs (Y-yzcent)',z0coef0,z0coef1
;	read,st
;amount to add to found x of 0-order for G141 at ycmean=559 from scnoffset.pro
	delx=187.63 + 0.0121233*xpostarg
	xc=xzfound+delx
	yc=ycmean				;avg y for center
	if filter eq 'G102' then begin
		xc=0	; run scnoffset.pro
		stop
		endif
; x is range of spec
	calwfc_spec_wave,h,xc,yc,x,wave,angle,wav1st	;master WLs wfc_wavecal?

; Differences btwn 0-order X znd xc posit of ref * from scnoffset.pro:
	delxbot=191.91+0.0096832*xpostarg	;G141 @ y=184
	delxtop=183.71+0.0134596*xpostarg	;G141 @ y=926
	yzord=[184.,559,926]
	xdelx=[delxbot,delx,delxtop]
; make wlimg for use in flat fielding
	wlimg=image*0.
	for i=0,1013 do begin
		xz=z0coef0+z0coef1*(i-ycmean)		; 0-ord x-posn
		del=interpol(xdelx,yzord,i)		; do all rows
		xref=xz+del				; ref * posn
; WLs @ y=i
		calwfc_spec_wave,h,xref,i,x,wli,dum,wl1st,/noprnt
		wlimg(*,i)=wl1st			;1-ord WL for FF
		endfor
	if strupcase(flatfile) ne 'NONE' then $
		calwfc_spec_flat,h,image,err,dq,x,wlimg,flatfile      ; FF image
	disp=24.5					; G102
	if filter eq 'G141' then disp=46.5
; make new image where each row is resampled to WL scale of avg Y position
	rectim=image*0.		; image rectified for disp & angle
	recter=rectim  &  rectdq=rectim
	for i=0,1013 do begin
		xz=z0coef0+z0coef1*(i-ycmean)		; 0-ord x-posn
		yfit=i+(x-xz)*sin(angle/!radeg)		;trace @ row=i
		yfit=round(yfit)		       ;nearest neighbor
		yfit=yfit>0<1013
		del=interpol(xdelx,yzord,i)		; do all rows
		xref=xz+del				; ref * posn
		calwfc_spec_wave,h,xref,i,x,wli,/noprnt	; full WLs @ y=i
; use disp of -1st order for corr; but the +1st change w/ Y is the same to <0.1%
		indx=where(wli ge -12000,npts)
		indx=indx(0)
		dsprow=wli(indx+1)-wli(indx)
; Accomodate slope of spectra to get a few more good rows at lowest good Y
		rowspc=image(x,yfit)*disp/dsprow      ;corr to +1st disp
; row on master WL scale:
		linterp,wli,rowspc,wave,spcterp,missing=0
		rectim(*,i)=spcterp
	if i eq 511 then stop
		rowerr=err(x,yfit)*disp/dsprow
		linterp,wli,rowerr,wave,errterp,missing=0
		recter(*,i)=errterp
		rowdq=dq(x,yfit)
; Expand dq to near neighbors & use dq=2 for missing, ie fill data:
		linterp,wli,rowdq,wave,dqnotrp,missing=2,/nointerp
		linterp,wli,rowdq,wave,dqterp,missing=2
		bad=where(dqterp ne 0,nbad)
		if nbad gt 0 then for ibad=0,nbad-1 do begin
			indx=bad(ibad)
			dqterp(indx)=max(dqnotrp((indx-1)>0:(indx+1)<1013))
			endfor
		rectdq(*,i)=dqterp
		endfor
; 2018may -see above now	fdecomp,file,disk,dir,root
;	root = gettok(root,'_')

	sxaddhist,'Written by IDL calwfc_spec.pro '+!stime,h
	exptim=sxpar(h,'exptime')
	rectim=rectim*exptim*scnrat/0.13	;Texp=plate-scale/scnrat
	recter=recter*exptim*scnrat/0.13
	ext='fits'
	if strupcase(flatfile) eq 'NONE' then begin
		ext='_noff.fits
		sxaddhist,'z.scimage NOT flat-fielded.',h
		endif
	mwrfits,{wave:wave,scimage:rectim,err:recter,dq:rectdq},  $
					subdir+'/imag_'+root+ext,h,/create
;	read,st
	return						; END SCAN SECT
	endif
; ######################### STARE SECTION #############################

; xco=yco=0 means NO Direct image or target off edge of direct image.
; ###change - If no direct img. XCo=yco=0 fails after 1st direct image.
;     The 2nd Z-order find way below is redundant, if I always do this bit here.
; 2013mar26 - try always finding Z-order and updating Z-ord posit: xc,yc:
; ###change
if xco eq 0 and yco eq 0 and keyword_set(dirimg) then begin
	print,'No useful Direct image. No AXE WL results written.'
	goto,skipall
	endif
; 2013apr11 - make default to use zero-order to set WL scale.

tra=sxpar(h,'ra_targ')		; corrected for PM per wfcdir.pro
tdec=sxpar(h,'dec_targ')
targ=sxpar(h,'targname')

extast,h,astr,status	;get astrometry information
if status eq -1 then begin
	print,'CALWFC_SPEC: Error - Invalid astrometry info in the image '+file
	retall
	endif
ad2xy,tra,tdec,astr,ix,iy
print,'Pred. targ img posit w/grism astr',ix,iy
ix=ix+xerr  &  iy=iy+yerr
print,'Add pointing err per dir image=',xerr,yerr,' For best'+	$
		' targ img posit=',ix,iy,form='(a,2f5.1,a,2f6.1)'
;xc=ix-188  &  yc=iy		; G141 Petro TIR 2010-03 Z-order pred. posit.
xc=ix-188  &  yc=iy-1		; 2015may8 - for icqv02gjq
yshift = 0				; 2015may8 - for G141
if filter eq 'G102' then begin
	yshift =0					; 2015may8
	if strpos(file,'iab90') ge 0 then yshift = +1	; 2015may8 - Fudge
;	xc=ix-252  &  yc=iy-4  &  ENDIF		; Petro
;	xc=ix-252  &  yc=iy-6  &  ENDIF	; for ic6906c0q
	xc=ix-252  &  yc=iy-2  &  ENDIF	;2015may8 for icqv01aoq
xastr=xc  &  yastr=yc		; save astrom est

; if keyword_set(dirimg) then begin NG=150-300A errors.
;	Best to use meas Dir-image & axe disp. when ZO is off image,
;	eg ibbu01aqq & ibbu02u5q at -50 xpostarg - 2015May29
; 2018may4 - try reducing 15 to 4 for ibcf61xnq at xc=4.96
if xc lt 4 or xc gt 998 or keyword_set(dirimg) then begin
	print,xc,yc,'=pred. Z-ord posit. is off grism img.'
	print,'Distort sensitive "measur" posit',xco+xdither,yco+ydither
; use ix,iy predicted dir img location for WL solution:
; 2015May-Switch from actual found xc,yc+dither to the pred. astrom x,y+Petro+
;			Pointing error
;x is range of spec. Do the AXE WL solution when Z-ord is off image or /dirimg:
;NG for ic6906c6q   calwfc_spec_wave,h,xc+xdither,yc+ydither,x,wave,angle,wav1st
	print,'USE Predicted direct image posit per astrom=',ix,iy
	calwfc_spec_wave,h,ix,iy,x,wave,angle,wav1st	; Prints minmax(WL)
	print,'WAVELENGTH solution per AXE coef. No Z-order.'
	sxaddhist,'WAVELENGTH solution per AXE coef. No Z-order.',h
	axeflg=1		; est position. Do NOT fit, if have 2nd order
; GOOD Z-order:
     end else begin
	xbeg=round(xc)  &  ybeg=round(yc)
; 2018may3 - try reducing 16 to 4 for iblf01deq w/ Z-ord at xc=9
	if xbeg le 4 or xbeg ge 997 then goto,nozord	; Z-ord off img
; find Z-order for WLs & do Bohlin-Duestua solution: ##########################
 	ywidth=11			; limit Y-range spectral search
	ns=31
	ibeg=(xbeg-ns/2)>0
	iend=xbeg+ns/2
	ns=iend-ibeg+1
	nl=31
	sbimg=image(ibeg:iend,ybeg-nl/2:ybeg+nl/2)
	indmx=where(sbimg eq max(sbimg))
	xpos = indmx mod ns
	ypos = indmx/ns
	print,'1st Z-ord centroid from astrom+ Petro starts at',xc,yc
;	cntrd,sbimg,xpos,ypos,xc,yc,2	;uses derivatives
; 2010feb4-try Gaussian fit for ie3f10caq sat Z-ord., which fails w/ cntrd
	gcntrd,sbimg,xpos,ypos,xc,yc,2
	if xc(0) lt 0 then begin		; peak too close to edge
		print,'Use approx position in 31x31 sbimg='+	$
				string([xpos,ypos],'(2i3)')
		xc=xpos  &  yc=ypos			; try approx pos
		stop					; NO! fix
		endif
	xc=xc(0)+ibeg			; put back sbimg offset
	yc=yc(0)+ybeg-nl/2
	print,'Zero-ord centroid at',xc,yc,ns,nl,' search area'
;if strpos(file,'ibcf61xnq') ge 0 then stop
nozord:							; Z-ord off image
	if round(xc) le 4 or round(xc) ge 997 then 			$
		print,'Z-order off image at',xc,yc else		$
; Good Z-order;
		print,'Z-order found by calwfc_spec at',xc,yc
	sxaddpar,h,'xzorder',xc,'Zero order found X Position'
	sxaddpar,h,'yzorder',yc,'Zero order found Y Position'
	sxaddpar,h,'xzerr',xastr-xc,'Zero order PREDICT-FOUND (px)'
	sxaddpar,h,'yzerr',yastr-yc,'Zero order PREDICT-FOUND (px)'
	print,'X,Y astrom error=',xastr-xc,yastr-yc
; Implement my z-order WL solution per coef from wlmake.pro.
;   xc,yc is px relative to 0,0 subarr corner.
	wfc_wavecal,h,xc,yc,x,wave,angle,wav1st		; Prints minmax(WLs)
	print,'WAVELENGTH solution per Bohlin/Deustua ISR &'+	$
				' 0-order position=',xc,yc
	axeflg=0
	sxaddhist,'WAVELENGTH solution per 0-order position ISR',h
	Ydither=0				; for use w/ Z-ord xc,yc below
	yshift=0				; NO dir-grism shift
	endelse					;END Z-order Wl solution

if keyword_set(display) then begin
	window,1,xsize=1014,ysize=1014
	tvscl,alog10(image>.1)
	plots,[xc,xc],[-8,-18]+yc,/dev
	plots,[xc,xc],[8,18]+yc,/dev
	plots,[-8,-18]+xc,[yc,yc],/dev
	plots,[8,18]+xc,[yc,yc],/dev
	read,st
	endif
;
; set bad data to zeros
;
raw_image = image 	;save for gross and back extractions
;
; subtract a scaled Flat field (for pt-source spectrum) & div by AXe FF.
;	x index vector set to x-size of subarray.
image=image-wfc_flatscal(h,image,x,yfit,filter,gwidth,flat)
if n_elements(flat) le 1 then stop		; idiot ck. as never true
if n_elements(flat) gt 1 then begin
	sky_image = raw_image/(flat>0.001)	;properly flat field sky
     end else sky_image = raw_image*0		;non hi-bkg obs
;
; flat field using the wavelength dependent flat, for wav1st=1st order WLs
;
;normal case here. (*NOT* case far below)
;
if keyword_set(before) then 						$
	if strupcase(flatfile) ne 'NONE' then 	$
		calwfc_spec_flat,h,image,err,dq,x,wav1st,flatfile
;
; compute approximate location of the spectrum.
;
; ff OK for xc,yc of Z-order. ic6906c2q etc. suggest there is 0.98 grism magnif.
;		BUT NG in general.... Uses avg angle from wavecal:
yapprox=yc+yoffset+(x-xc)*sin(angle/!radeg)+yshift   ;2015-yc curr posit
;
; find the spectrum  ------------------------------
;

; Edit patches of isolated glitches after FF:
root=strtrim(sxpar(h,'rootname'),2)
if root eq 'ibwi08mkq' then image(548,555)=8.2			;G141 WD1657+343
if root eq 'ibwib6mbq' then image(940:941,557)=220		;G102 P330E
if root eq 'ibwib6mbq' then image(940:941,558)=1010		;G102 P330E
if root eq 'idpo02pjq' then image(431,712)=110			;G141 GD153
if root eq 'idpo02pjq' then image(433,713)=122			;G141 GD153
if root eq 'ic5z03grq' then image(548,555)=310			;G141 GRW deadpx
if root eq 'ic5z03gsq' then image(548,555)=10			;G102 GRW deadpx
if root eq 'ibll92fqq' then image(548,555)=68			;G102 GRW deadpx
if root eq 'ibuc05awq' then image(548,555)=53			;G141 GRW deadpx
if root eq 'ibuc15acq' then image(548,555)=131			;G141 GRW deadpx
if root eq 'ibuc15adq' then image(548,555)=23			;G102 GRW deadpx
if root eq 'ibuc22h6q' then image(548,555)=10			;G141 GRW deadpx
if root eq 'ibuc54skq' then image(548,555)=93			;G141 GRW deadpx
if root eq 'ibuc42lsq' then image(548,555)=321			;G141 GRW deadpx
if root eq 'ibuc45eiq' then image(548,555)=234			;G141 GRW deadpx
if root eq 'ic5z03grq' then image(548,555)=311			;G141 GRW deadpx
if root eq 'ic5z04bvq' then image(548,555)=99			;G141 GRW deadpx
if root eq 'ic5z05ilq' then image(548,555)=7			;G141 GRW deadpx
if root eq 'ic5z07doq' then image(548,555)=9.5			;G141 GRW deadpx
if root eq 'ic5z07dpq' then image(548,555)=6			;G102 GRW deadpx
if root eq 'ic5z08itq' then image(548,555)=45			;G141 GRW deadpx
if root eq 'ic5z10ofq' then image(548,555)=8			;G141 GRW deadpx
if root eq 'ic5z10ofq' then image(548,555)=321			;G141 GRW deadpx
if root eq 'ibwl81xhq' then image(334,290)=1900		;G141 1757132 deadpx
if root eq 'ibll72npq' then image(605,557)=208			;G102 GRW deadpx
if root eq 'ibll72npq' then image(605,558)=280			;G102 GRW deadpx
if root eq 'ibuc05axq' then image(548,555)=75			;G102 GRW deadpx
if root eq 'ic5z09hkq' then image(548,555)=49			;G102 GRW deadpx
if root eq 'ich319oeq' then image(534,562)=683			;G141 GRW deadpx
if root eq 'ibll92fpq' then image(548,555)=45			;G141 GRW deadpx
if root eq 'ibbt03f6q' then image(502:503,168)=178		;G102 gd71deadpx
if root eq 'ibbt03f6q' then image(502:503,169)=150		;G102 gd71deadpx
if root eq 'ibbt03f6q' then image(501:503,170)=27		;G102 gd71deadpx
if root eq 'ibbt04hwq' then image(501:503,169)=35		;G141 gd71deadpx
if root eq 'ibbt04hwq' then image(501:503,170)=115		;G141 gd71deadpx
if root eq 'ibbt04hwq' then image(501:503,171)=52		;G141 gd71deadpx
if root eq 'ibbt04hwq' then image(501:503,172)=20		;G141 gd71deadpx
if root eq 'ibwq1bldq' then image(111,816)=45			;G141gd153deadpx
if root eq 'ibwq1bldq' then image(95:96,818)=82			;G141gd153deadpx
if root eq 'ibwq1bldq' then image(95:97,819)=15			;G141gd153deadpx
if root eq 'ibwq1aszq' then image(453:454,182)=94		;G102gd153deadpx
if root eq 'ibwib6m8q' then image(924:925,183)=830		;G102p330edeadpx
if root eq 'ibwib6m8q' then image(922:925,184)=160		;G102p330edeadpx
if root eq 'ibwib6m8q' then image(980,184)=625			;G102p330edeadpx
if root eq 'ibwib6m8q' then image(878,182)=250			;G102p330edeadpx
if root eq 'ic6903y8q' then image(927,136)=334			;G102 g191deadpx
if root eq 'ic6903y8q' then image(929,137)=63			;G102 g191deadpx
if root eq 'ic6901x2q' then image(877,960)=250  		;G141 g191deadpx
if root eq 'ic6901x2q' then image(877,961)=728  		;G141 g191 hotpx
if root eq 'icqw01b5q' then image(185,119)=168  	;G102gd71 deadpx dq=8
if root eq 'icrw12l9q' then image(372,260)=1910  	;G141VB8 deadpx dq=32
if root eq 'ibwi08mkq' then image(606,557)=1      	;G141wd1657 hotpx dq=0
if root eq 'ibwi08mkq' then image(607,554)=2     	;G141wd1657 hotpx dq=0
if root eq 'ibwi08mkq' then image(625,556)=3.1  	;G141wd1657 hotpx dq=0

;if root eq 'idpo02pjq' then stop


fimage = image
for i=0,ysiz-1 do fimage(0,i) = median(image(*,i),7)
; default is to fit slope (keyword slope=1)
if fit_slope then begin					; Default
; 2012Feb23 - try fitting just one pt per order
	wlrang=[8000,11000.]			;2018may8-get hot * -1 ord peak
	if star eq 'PN' then wlrang=[8800,11000.]	; G102 2015may7 for PN ibbu01aaq
;	if filter eq 'G141' then wlrang=[10333,16000.]
	if filter eq 'G141' then wlrang=[10800,16000.]	; squeeze down 2018apr24
; begin & endpts of bins for a max of 4 orders: -1 to +2
	x1bin=fltarr(4)  &  x2bin=x1bin  &  nbins=-1  ;minmax px of bins
	xfound=x1bin  &  yfound=x1bin	; x,y positions of the order

	for iord=-1,2 do begin		; 2012Jun5-do only main orders
; 2nd order low signal and ibbu02u5q has spurious 0 order at ~28000A/2
;2018apr24-squeeze down too avoid overlapping stars. For finding orders:
		if iord eq 1 and filter eq 'G102' then wlrang=[8800,11000]
		if iord eq 2 and filter eq 'G102' then wlrang=[8000,10000]
		if iord eq 2 and filter eq 'G141' then wlrang(1)=13000.
		if iord ne 0 then begin
		   xrang=where(wave ge iord*wlrang(0) and		$
		  				wave le iord*wlrang(1),npts)
		   if iord lt 0 then xrang=where(wave ge iord*wlrang(1) and   $
		  				wave le iord*wlrang(0),npts)
;use brite line but WLs uncert. Attempt for info only as
; <10555,11000 fails for ic6906c2q but ic6906c6q needs 10545,<11100
		   if star eq 'PN' and iord eq -1 then xrang=		$
		  	where(wave ge -11000 and wave le -10555,npts)
; So forget it for -1 order and pick the brightest px below.
; enough of order to process. Narrow band PN search has only ~9 pts for G141
		   if xrang(0) ge 985 then npts=0	; too close to edge
		   if npts ge 50 or (star eq 'PN' and npts gt 5) then begin
			nbins=nbins+1
; 2013apr21 - try limit on x2:
		        x1bin(nbins)=xrang(0)  &  x2bin(nbins)=max(xrang)<990
			xfound(nbins)=avg(xrang)	; midpoint of order
; find begin (x1) & endpts (x2) of bins
			x1=x1bin(nbins)
			x2=x2bin(nbins)
; x,yapprox(x) is spectrum location predicted from disp constants.
		  	y1 = (round(yapprox((x1+x2)/2))-ywidth/2)>0
		  	y2 = (y1 + ywidth-1)<(ysiz-1)	; ywidth=11 normally
			print,'x,y search range=',x1,x2,y1,y2
			y1pred=0
			if iord eq 1 then y1pred=yapprox((x1+x2)/2)
; 2018apr25 - tweak up 2nd order search based on found posit for 1st order:
			if iord eq 2 then begin
			    ydel=yfound(nbins-1)-			$
			    	yapprox((x1bin(nbins-1)+x2bin(nbins-1))/2)
			    y1=round(y1+ydel)  &  y2=round(y2+ydel)
			    print,ydel,'=2nd ord yposit tweak to yrange=',y1,y2
;if root eq 'ibcf51ifq' then stop
			    endif
;HELP,WAVE,ywidth,yapprox  &  STOP
		  	ny = y2-y1+1
		  	profile = fltarr(ny)
			iter=0
iter:		; iterate 1st order posit, if max is at an end of search range
			iter=iter+1
		  	for j=0,ny-1 do profile(j) = total(fimage(x1:x2,y1+j))
		  	profile = (profile - median(profile))>0
; patch for PN-G045.4-02 w/ low contin. & another spec just above:
			if keyword_set(star) then if star eq 'PN' then begin
				profile(0)=0  &  profile(ny-1)=0  &  endif
		  	yprofile = findgen(ny) + y1
		  	pmax = max(profile,maxpos)
			if pmax le 0 then stop		;& fix. No signal.
			if maxpos le 0 or maxpos ge ny-1 or		$;try
				  pmax le 2 then 			$
				yfound(nbins)=-999 else			$
				yfound(nbins)=total(			$
				yprofile(maxpos-1:maxpos+1)*		$
				profile(maxpos-1:maxpos+1))/		$
				total(profile(maxpos-1:maxpos+1))
			print,'calwfc_spec: order, contin. x,'+	$
				  'y position=',iord,xfound(nbins),yfound(nbins)
; 2018may7-if 1st order is not found, then iterate:
			if iord eq 1 and yfound(nbins) eq -999 and	$
					iter eq 1 then begin
				if maxpos eq 0 then y1=(y1-(ywidth-3))>0$
				   else y1=(y1+(ywidth-3))<(ysiz-ywidth-1)
				y2=(y1+ywidth-1)<(ysiz-1)
				print,'Iterating w/ ysearch=',y1,y2
				goto,iter
				endif
; std above continuum technique fails for PN em line and faint -1 order, SO,
;		try the brightest px in the range:
			if iord eq -1 and star eq 'PN' then begin
				imax=where(image(x1:x2,y1:y2) eq 	$
					max(image(x1:x2,y1:y2)))
					nsamp=fix(x2-x1+1)
					xfound(nbins)=x1+imax mod nsamp
					yfound(nbins)=y1+imax/nsamp
					print,'PN em line at ',xfound(nbins), $
						yfound(nbins),' for ordr=-1'
					endif
;ck y-pos of order
			if keyword_set(trace) then begin
				!Xtitle='Y-px'  &  !ytitle='Signal'
				!mtitle=file
				plot,yprofile,profile,psym=-4,symsiz=2,th=2
				xyouts,.15,.88,'order='+string(iord,'(i2)'),/nor
				read,st
				endif
; ibm201jvq has bright stray 1st order by the faint -1 order that I want
			endif			; end enough pts to find sp. ord
	     	end else begin			; npts in WL range <50, &iord=0
; Store zero order, always for nbins=0 or 1
			nbins=nbins+1
			xfound(nbins)=xc
			yfound(nbins)=yc
			if axeflg then yfound(nbins)=-yc
			endelse			; end find 0-order
		endfor				; 3 order search loop for slope
;2018may6 - need to use pred. dir img position for Tremblay WD2341+322
	good = where(xfound ge 4 and yfound ge 0,ngood)	; use neg Axe flag
		if ngood eq 1 then begin
			print,'Only 1 order. Try using pred. Z-order position'
			print,'Adjust Z-ord for Y-err in 1st order=',	$
				yfound(1),y1pred,yfound(1)-y1pred,	$
				form='(a,f8.2,"-",f8.2,"=",f8.2)'
; adjust Z-ord & account for neg yfound Axe flag:
			yfound(0)=abs(yfound(0))+(yfound(1)-y1pred)
; Update AXE WLs
; del?			iy=iy+(yfound(1)-y1pred)		; adjust Z-ord
			print,'WLs differ by <1A for corr. dir img at',	$
				ix,yfound(0)
			endif
; allow neg predict positions
	good = where(xfound ge -500 and yfound ne -999 and yfound ne 0,ngood)
; Cannot fit 1 pt, eg iblf02d4q w/ 256x256 G141 subarr.
	if ngood le 1 then begin
		print,'Only 1 order. Cannot meas. spectral angle '+	$
			'for subarr of'+string([xsiz,ysiz],'(2i4)')+' SKIPPing'
		stop				; AND flag image as BAD
;		goto,skipall
		endif
	if ngood ge 3 and axeflg then begin
		print,'PROFILE yfound for AXE case=',yfound
		good=where(yfound gt 0)			; elim axe est. of Z-ord
	     end else yfound=abs(yfound)			; rm axe Z-ord flag.
;if root eq 'icwg01geq' then stop

	coef = poly_fit(xfound(good),yfound(good),1,fit)
	angle=atan(coef(1))*180./!pi
	if keyword_set(trace) then begin
		window,1
		!p.noclip=1
		!xtitle='X-pixel'
		!ytitle='Y-pixel'
		plot,xfound(good),yfound(good),psym=-4,symsiz=2
		oplot,xfound(good),fit,th=2
		oplot,x,yapprox,line=2,th=2
		xyouts,.7,.15,'Angle ='+string(angle,'(f5.2)'),chars=2,/norm
		xyouts,.18,.85,'Dash is approx location of orders',/norm
		xyouts,.18,.75,filter,chars=2.2,/norm
		print,filter,' Meas. Angle=',angle
		endif
;
; find y-center with a fixed slope. Default is to fit slope above.
;
     end else begin
	profile = fltarr(ywidth)
	yoff = findgen(ywidth) - ywidth/2
	for i=0,ywidth-1 do $
		profile(i) = total(interpolate(fimage,x,yapprox+yoff(i)))
	profile = profile - median(profile)
	profile = (profile - max(profile)/4)>0
		ycent = total(profile*yoff)/total(profile)
		ypos = yapprox + ycent
		coef = poly_fit(x,ypos,1,fit)
	endelse					; end specified slope option.

print,'Coef of trace fit='+string(coef,'(2f10.4)')
yfit = coef(0) + coef(1)*x
sxaddpar,h,'extc0',coef(0),'Extraction Position: Constant Term'
sxaddpar,h,'extc1',coef(1),'Extraction Position: Linear Term'
; 2015May4 - add direct image name
sxdelpar,h,'dirimage'
sxaddpar,h,'dirimage',dirimnam,'Direct Image',before='end'
;
; Extract background spectra
;
ns=n_elements(x)
nsb=ns  &  xb=x			;bgk # points and index array x(0) is normally 0
blower = fltarr(nsb)
bupper = fltarr(nsb)
sky_blower = fltarr(nsb)
sky_bupper = fltarr(nsb)
yfitb = coef(0) + coef(1)*xb
					; simplify?
for i=0,nsb-1 do begin
	ypos = round(yfitb(i) - Lbdist)
	y1 = (ypos - bwidth/2)>0
	y2 = (ypos + bwidth/2)<(ysiz-1)
	blower(i) = median(image(xb(i),y1:y2))
	sky_blower(i) = median(sky_image(xb(i),y1:y2))
	ypos = round(yfitb(i) + Ubdist)
	y1 = (ypos - bwidth/2)>0
	y2 = (ypos + bwidth/2)<(xsiz-1)
	bupper(i) = median(image(xb(i),y1:y2))
	sky_bupper(i) = median(sky_image(xb(i),y1:y2))
	endfor
;
; average upper and lower background and smooth
;
raw_sky_back = (sky_blower+sky_bupper)/2.0
; Default: bmedian, bmean1, bmean2 all =7
if bmedian gt 1 then sky_back = median(raw_sky_back,bmedian) $
		else sky_back = raw_sky_back
if bmean1 gt 1 then sky_back = smooth(sky_back,bmean1)
if bmean2 gt 1 then sky_back = smooth(sky_back,bmean2)

back = (blower + bupper)/2.0
;2018may-upgrade the sback that is subtr from image. sky_back only affects gross.
;if bmedian gt 1 then sback = median(back,bmedian) else sback = back
;if bmean1 gt 1 then sback = smooth(sback,bmean1)
;if bmean2 gt 1 then sback = smooth(sback,bmean2)

sbacklo=median(blower,bmedian)
sbackup=median(bupper,bmedian)
xbf=double(xb)
locoef=poly_fit(xbf,sbacklo,3,yfit=lofit,yerror=loerr)	; cubic fit to bkg
upcoef=poly_fit(xbf,sbackup,3,yfit=upfit,yerror=uperr)	; cubic fit to bkg
; iterate once
sigless=loerr<uperr

goodlo=where(abs(sbacklo-lofit) lt sigless,nlo)
locoef=poly_fit(xbf(goodlo),sbacklo(goodlo),3,yerror=loerr)
print,"Lower fit coefficients: ",locoef
lofit=locoef(0)+locoef(1)*xbf+locoef(2)*xbf^2+locoef(3)*xbf^3

; 2018may-fancy bkg. Might do better @ 0.5 DN level for some -1,+2 ord, if I
;      took the lowest fit in sections of crossings of the 2 fits, eg some P330E
goodup=where(abs(sbackup-upfit) lt sigless,nup)
upcoef=poly_fit(xbf(goodup),sbackup(goodup),3,yerror=uperr)
print,"Upper fit coefficients: ",upcoef
upfit=upcoef(0)+upcoef(1)*xbf+upcoef(2)*xbf^2+upcoef(3)*xbf^3
loslp=locoef(1)+2*locoef(2)*xbf+3*locoef(3)*xbf^2
upslp=upcoef(1)+2*upcoef(2)*xbf+3*upcoef(3)*xbf^2
sback=lofit
print,"Initial fit set to lower fit"
if avg(upfit) lt avg(lofit) then begin
    sback=upfit
    print,"Initial fit set to upper fit"
end
; NG if avg(abs(upslp)) lt avg(abs(loslp)) then sback=upfit
bettr=where(abs(upfit)-abs(sback) gt 3*sigless and upfit lt lofit,nbet)
if nbet gt 0 then begin
    sback(bettr)=upfit(bettr)
    print,nbet," points set to upper fit."
end
bettr=where(abs(lofit)-abs(sback) gt 3*sigless and lofit lt upfit,nbet)
if nbet gt 0 then begin
    sback(bettr)=lofit(bettr)
    print,nbet," points set to lower fit"
end
if nlo lt nsb/5 then begin
    sback=upfit
    print,"Final fit set to upper fit"
end
if nup lt nsb/5 then begin
    sback=lofit
    print,"Final fit set to lower fit"
end

if keyword_set(trace) then begin
	window,0
	!ytitle='Background'
	plot,xbf(goodlo),sbacklo(goodlo),psym=-4,yr=[-1,1]
	oplot,lofit
	oplot,xbf(goodup),sbackup(goodup),lin=1,psym=-6
	oplot,upfit,lin=2
	oplot,sback,th=4
	xyouts,.15,.15,targ+' '+filter+' '+root,/norm
	help,nlo,nup,loerr,uperr,goodlo,goodup

; 2020jan
	if loerr gt 0.5 or uperr gt 0.5 then begin
		plot,xbf(goodlo),sbacklo(goodlo),psym=-4
		oplot,lofit
		oplot,xbf(goodup),sbackup(goodup),lin=1,psym=-6
		oplot,upfit,lin=2
		oplot,sback,th=4
		xyouts,.15,.15,targ+' '+filter+' '+root,/norm
		xyouts,.18,.85,'Low:diam,line,fit-line',/norm
		xyouts,.18,.88,'Upp:squar,dots,fit-dash',/norm
		xyouts,.18,.8,'Final Bkg:Thick',/norm
		endif

	if nlo lt nsb/5 and nup lt nsb/5 then stop	;not enough points tofit
	read,st
	endif
;if abs(avg(sback)) gt 3 then begin			;2020feb4 - was 2
if avg(sback) gt 3 then begin			;2020feb4-neg. Bkg is OK
	print,'WARNING: High Bkg=',avg(sback)
	if keyword_set(trace) then  stop
	endif

;if root eq 'ibwi08mkq' then stop
;
; subtract background
;
; ff line creates non-zero fluxes where image may have been zeroed.
;		sback can be <0
for i=0,nsb-1 do image(xb(i),*) = image(xb(i),*)-sback(i)	; full img subtr

; ff eliminated most of unsmoothed bkg near each end for default bmean1=bmean2=7
; 2018may13 - ends not useful anyhow. keep full range
;sback = sback(5:n_elements(sback)-6) * gwidth			; cut siz by 10
;sky_back = sky_back(5:n_elements(sky_back)-6) * gwidth
;back = back(5:n_elements(back)-6) * gwidth
;raw_sky_back = raw_sky_back(5:n_elements(raw_sky_back)-6) * gwidth
sback=sback*gwidth
sky_back=sky_back*gwidth
back=back*gwidth
raw_sky_back=raw_sky_back*gwidth
;
; make background results for optional output
;
back_results = {sback:frebin(sback,5,/total)/gwidth, 			$
	    gross:transpose( 						$
		frebin(raw_image(xb(0):xb(0)+nsb-1,*),5,256,/total)), 	$
	    net:transpose(frebin(image(xb(0):xb(0)+nsb-1,*),5,256,/total)), $
	    wave:frebin(wave,5), 					$
	    bupper:frebin(bupper,5,/total), 				$
	    blower:frebin(blower,5,/total), 				$
	    x:frebin(x,5), 						$
	    y:frebin(yfitb,5), 						$
	    Ubdist:Ubdist,lbdist:lbdist}
;
; create trace image
;
fdecomp,file,disk,dir,name
if keyword_set(trace) then begin
	window,4,xs=xsiz,ys=ysiz
	imagt=image  &  ytmp=yfit
	if max(yfit) gt 700 then begin
		window,4,xs=1014,ys=514
		imagt=image(*,500:1013)
		ytmp=yfit-500
		endif
	tvscl,alog10(imagt>0.1)
	plots,x,ytmp+gwidth/2,/dev
	plots,x,ytmp-gwidth/2,/dev
	plots,x,ytmp+ubdist-bwidth/2,/dev
	plots,x,ytmp+ubdist+bwidth/2,/dev
	plots,x,ytmp-lbdist-bwidth/2,/dev
	plots,x,ytmp-lbdist+bwidth/2,/dev
	xyouts,.05,.05,name+' '+filter,chars=2.2,/norm
;	wait,2.0
	read,st
	endif
;
; flat field the data
;
if not keyword_set(before) then begin		; 'NOT' normal case
		if strupcase(flatfile) ne 'NONE' then 			$
			calwfc_spec_flat,h,image,err,dq,x,wave,flatfile
		endif
;
; Extract spectra
;
flux = fltarr(ns)
epsf = intarr(ns)
errf = fltarr(ns)
spec_time = fltarr(ns)

hwidth = gwidth/2.0
for i=0,ns-1 do begin				; col by col, whole img
		y1 = (yfit(i) - hwidth)>0		;extract from y1 to y2
		y2 = (yfit(i) + hwidth) <ysiz >y1
		iy1 = round(y1)
		iy2 = round(y2)
; gwidth=6 is sum of 6 rows (NOT 7). eg yfit=10 is sum of rows 8-12 +.5*rows7,13
; 2018may10-clean all involved rows iy1-iy2 of hot px spikes by interp in row
		for irow=iy1,iy2 do begin
; 16=hot px and do not fix endpoints. Hope adjacent hot px are not important.
;	ie interpolate over hot px in wl direction.
; 2018jul19-try also dq=8, unstable:
		    if ((dq(i,irow) and 16) eq 16 or (dq(i,irow) and 8)	eq 8) and x(i) ne 0 and	x(i) ne (ns-1) then 	$
			    image(i,irow)=(image(i-1,irow)+image(i+1,irow))/2
		endfor
		frac1 = 0.5 + iy1-y1  		;frac of pixel i1y
		frac2 = 0.5 + y2-iy2  		;frac of pixel iy2
		ifull1 = iy1+1  	      	;range of full pixels to extract
		ifull2 = iy2-1
		print,"i=",i,"extraction=",ifull1,", ",frac1," -> ",ifull2,", ",frac2
		if ifull2 ge ifull1 then begin
			tot = total(image(x(i),ifull1:ifull2))
			var = total(err(x(i),ifull1:ifull2)^2)
			tot_time = total(time(x(i),ifull1:ifull2)*(image(x(i),ifull1:ifull2)>0))
			time_weight = total(image(x(i),ifull1:ifull2)>0)
		end else begin
		    tot = 0.0
			var = 0.0
			time_weight = 0.0
			tot_time = 0.0
		end
  		tot = tot + frac1*image(x(i),iy1)+frac2*image(x(i),iy2)
  		var = var + frac1*err(x(i),iy1)^2 +frac2*err(x(i),iy2)^2
		tot_time = tot_time + frac1*time(x(i),iy1)*(image(x(i),iy1)>0)+frac2*time(x(i),iy2)*(image(x(i),iy2)>0)
		time_weight = time_weight + frac1*(image(x(i),iy1)>0) + frac2*(image(x(i),iy2)>0)
		if time_weight gt 0 then begin
		    ave_time = tot_time/time_weight
		end else begin
		    ave_time = max(time(x(i),iy1:iy2))
		    print,"X=",i,", extraction range=(",ifull1,",",ifull2,") time_weight=0, time set to ",ave_time
		end
		e = 0
		for j=iy1,iy2 do e = e or dq(x(i),j)		; data qual

		flux(i) = tot
		errf(i) = sqrt(var)
		epsf(i) = e
		spec_time(i) = ave_time
	end
;if root eq 'ibwib6mbq' then stop
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

targwlfix='
if strpos(targ,'GAIA') ge 0 then targwlfix=targ
offset=wfcwlfix(root+targwlfix)				; offset in Ang
sxaddpar,h,'wloffset',offset
;2018jun23 -  move to top & put in wfc_wavecal.pro	wave=wave+offset
sxaddpar,h,'Angle',angle,'Found angle of spectrum wrt X-axis'
sxaddhist,'Written by calwfc_spec.pro '+!stime,h
;
; corr. response to +1st order disperion at y-center. RCB 12Feb28
;
indx=where(wave ge 10900,npts)
indx=indx(0)
; no (G102) +1st order,eg. ic6902puq,etc w/ xpostarg=+62
; no +1st order, use -1 order
if npts le 10 then begin
	indx=where(wave le -12000,npts)
	indx=indx(-2)					; WL closest to -12000A
	endif
disp=wave(indx+1)-wave(indx)
dcorr=24.5/disp					; G102
if filter eq 'G141' then dcorr=46.5/disp

dcorr=1.		; 2018jun19 BIG improvement

print,' ***END *** ',file
flux=flux*dcorr					; net=flux
sback=sback*dcorr
sky_back=sky_back*dcorr
;help,sback,sky_back,flux  &  stop
errf=errf*dcorr
xb=xb
blower=blower*dcorr
bupper=bupper*dcorr
sky_blower=sky_blower*dcorr
sky_bupper=sky_bupper*dcorr
gross = flux + sback + sky_back		;sky_back is for subtracted wfc_flatscal

if strpos(file,'icqw01') ge 0 then begin ;GD71 G102 contam by another star.
	bad=where(wave gt 11450 and wave lt 15400)
	spec_time(bad)=0.
	endif
if strpos(file,'icqw02') ge 0 then begin ;GD71 G141 contam by another star.
	bad=where(wave gt 17000)
	spec_time(bad)=0.
	endif
if keyword_set(trace) then begin		; plot result
	window,2
	!xtitle='Wavelength'
	!ytitle='Net, Bkg:thick dash, Sky:thick dots'
	plot,wave,flux
	oplot,wave,gross,lin=1
	oplot,wave,sback,th=4,lin=2
	oplot,wave,sky_back,th=2,lin=1
	read,st
	endif
;
; write results
;
name = gettok(name,'_')
if keyword_set(dirimg) ne 1 or star ne 'PN' then name=name+strlowcase(star)
mwrfits,{x:x,y:yfit,wave:wave,net:flux,gross:gross, $ ;12feb28-flux->net
		back:sback+sky_back, $
		eps:epsf,err:errf,xback:xb, $
		blower:blower+sky_blower,bupper:bupper+sky_bupper,	$
			time:spec_time},subdir+'/spec_'+name+'.fits',h,/create
if keyword_set(save_back) then $
	   mwrfits,back_results,subdir+'/back_'+name+'.fits',h,/create
return
skipall:
stop						; AND flag image as BAD
end
