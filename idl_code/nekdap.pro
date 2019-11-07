pro NEKDAP,image,xc,yc,mags,errap,sky,skyerr,bscale,apr,skyrad,$
         badpix, TEXTOUT=textout,SILENT = silent, MEAN = mean, MODE = mode,$
         SETSKYVAL = setskyval
;+
;
; NAME:
;    NEKDAP ALIAS UIT_APER W/ V. LITTLE DIF
; PURPOSE:
;    Procedure (from DAOPHOT) to compute concentric aperture photometry.
;    A separate sky value is determined for each aperture using specified
;    inner and outer sky radii.    This version uses the FFVAR function to
;    determine the variance of the photographic intensities.   The procedure
;    UIT_MMM is used to determine the sky background.
; CALLING SEQUENCE:
;   NEKDAP, image, xc, yc, mags, errap, sky, skyerr, bscale, $ 
;              [apr, skyrad, badpix, TEXTOUT = , /MODE, /MEAN, /SILENT,
;               SETSKYVAL  ]
;            
; INPUTS:
;   IMAGE  - input image array
;   XC     - array of x coordinates.  COORDINATE VALUE
;            MUST BE IN IDL CONVENTION! (First pixel is 0 not 1!)
;            If XC, YC or APR are entered as scalars they will be
;            converted by APER into single element arrays
;   YC     - array of y coordinates
; OPTIONAL INPUTS:
;   BSCALE - Scale factor to give absolute calibration.  BSCALE may
;            be obtained from an image header HDR by the command
;                    BSCALE = SXPAR(HDR,'BSCALE')
;            Set BSCALE = 1 to keep data units rather than convert to
;            magnitudes
;   APR    - Vector of up to 16 REAL photometry aperture radii.
;   SKYRAD - Two element vector giving the inner and outer radii
;                to be used for the sky annulus
;   BADPIX - Two element vector giving the minimum and maximum value
;            of a good pixel (Default [-32765,32767])
; OPTIONAL INPUT KEYWORDS:
;   TEXTOUT - Optional, textout = 3 prints to a file APER.PRT, 
;             textout = 1 prints to the screen.   The file APER.PRT is
;             usually best printed using Landscape orientation.
;   SILENT -  If supplied and non-zero then no output is displayed to the
;             terminal.
;   MEAN -  If this keyword is set, then the sky is always computed by
;             UIT_MMM using the mean of the unrejected sky values
;   MODE -  If this keyword is set, then NEKDAP uses the original DAOPHOT
;             algorithm for computing the sky background, i.e. there is no 
;             check for a mean value under 5 E-units.
;             The MODE keyword is ignored if the MEAN keyword is supplied
;   SETSKYVAL - Use this keyword to force the sky to a specified value rather
;              than have NEKDAP compute a sky value.    SETSKYVAL can either
;              be a scalar specifying the sky value to use for all sources,
;              or a 3 element vector specifying the sky value, the sigma of
;              the sky value, and the number of elements used to compute a
;              a sky value
; OUTPUTS:
;  MAGS   -  NAPER by NSTAR array giving the magnitude for each star in
;            each aperture.  (NAPER is the number of apertures, and UIT_NSTAR
;            is the number of stars).   After computing an aperture flux,
;            FLUX, in data units, a magnitude flux is computed from the
;            relation 
;                   MAGS = -2.5 * alog10(BSCALE*FLUX) - 21.1 
;
;            If BSCALE =1 then MAGS will return the output flux in data 
;            units, and not convert to magnitudes.
;  ERRAP  -  NAPER by NSTAR array giving error in magnitude (or flux if
;            BSCALE =1) for each star.  If a magnitude could not be deter-
;            mined then ERRAP = 9.99 (magnitude) or -9.99 (flux units)
;    SKY  -  NSTAR element vector giving sky value for each star
;  SKYERR -  NSTAR element vector giving error in sky values
; REVISON HISTORY:
;    UIT version, derived from DAOPHOT version of September 1984
;    1986 January 21   J. K. Hill, S.A.S.C.
;    Display negative fluxes   W. Landsman   STX   August, 1991
;    Add mean mode keywords, call UIT_MMM    W. Landsman   December, 1991
;    93MAR15-RCB QUICKY PATCH UP FOR AREA IN CALLING SEQ AND AREA NORM AT
;                BOTTOM.
;    93Jul16-EV  Changes made to avoid floating divide by zero and floating
;		 overflow, with BSCALE=1.  Search for "93Jul16" for changes.
;                Program indentation fixed so someone can actually read this!
;-                                                
On_error,2                              ; Return to caller
;             				; Set parameter limits
minsky = 20   ;Smallest number of pixels from which the sky may be determined
maxrad = 55.  ;Maximum outer radius permitted for the sky annulus.
maxsky = 4000 ;Maximum number of pixels allowed in the sky annulus.
;
if N_params() LT 3 then begin    ;Enough parameters supplied?
  print,'Syntax - ', $
        'NEKDAP,image,xc,yc,mags,errap,sky,skyerr,bscale,[apr,skyrad,badpix,'
  print,'         TEXTOUT = ,/SILENT, /MODE, /MEAN, SETSKYVAL =  ]  
  return                       
endif
;
if not keyword_set(TEXTOUT) then textout = !TEXTOUT
;
silent = keyword_set(SILENT)
;
if not keyword_set(MODE) then mode = 0
if not keyword_set(MEAN) then mean = 0
;
if keyword_set( SETSKYVAL ) then begin
  if N_elements( SETSKYVAL ) EQ 1 then setskyval = [setskyval,0.,1.]
  if N_elements( SETSKYVAL ) NE 3 then message, $
    'ERROR - Keyword SETSKYVAL must contain 1 or 3 elements'
  skyrad = [ 0., max(apr) + 1]
endif
;
if N_elements(badpix) NE 2 then begin 		;Bad pixel values not supplied
  GET_BADPIX:  ans = ''
  print,'Enter low and high bad pixel values, [RETURN] for defaults: '
  read,'Low and high bad pixel values [-32765,32767]: ',ans
  if ( ans EQ  '' ) then badpix = [-32765,32767] else begin
    badpix = getopt(ans,'F')
    if ( N_elements(badpix) NE 2 ) then begin
      print,string(7B),'INPUT ERROR - expecting 2 scalar values'
      goto, GET_BADPIX  
    endif
  endelse
endif 
;
if not keyword_Set(SETSKYVAL) then begin
  if ( N_elements(skyrad) NE 2 ) then begin
    skyrad = fltarr(2)
    read,'Enter inner and outer sky radius (pixel units): ',skyrad
  endif else skyrad = float(skyrad)
endif
;
if ( N_elements(apr) LT 1 ) then begin
  apr = fltarr(16)
  read,'Enter first aperture radius: ',ap
  apr(0) = ap
  ap = 'aper'
  for i = 1,15 do begin
    GETAP:  read,'Enter another aperture radius, [RETURN to terminate]: ',ap
    if ( ap EQ '') then goto, DONE
    result = strnumber(ap,val)
    if ( result EQ 1 )  then apr(i) = val else goto,getap
  endfor
  DONE:  apr = apr(0:i-1)
endif

if (N_elements(bscale) LT 1)  then begin
  bscale = ''
  read,'Enter BSCALE factor for absolute calibration ([RETURN] for none): ', $
    bscale
  if ( bscale EQ '') then bscale = 1. else bscale = float(bscale)
endif
;
Naper = N_elements(apr)		            	   	;# of apertures
Nstars = min( [ N_elements(xc), N_elements(yc) ] ) 	;# of stars to measure
if ( bscale EQ 1 ) then begin                      	;Flux units
  ms = strarr(Naper)
  units = 'NET FLUX'                 ;String to display flux for each aperture 
  fmt = '(F8.1,A,F7.1)'                       		;Flux format
  fmt2 = '(I5,2F8.2,F7.2,3A,5(/,28x,3A,:))'   		;Screen format
  fmt3 = '(I4,5F8.2,4A,4(/,44X,4A,:))'        		;Print format
  signerr = -1
endif else begin                                 	;Magnitude units
  ms = strarr(Naper)            ;String to display mag for each aperture
  units = 'MAGNITUDES'                       
  fmt = '(F6.2,A,F4.2)'                      		;Magnitude format
  fmt2 = '(I5,2F8.2,F7.2,4A,3(/,28x,4A,:))'   		;Screen format
  fmt3 = '(I4,5F8.2,6A,2(/,44X,6A,:))'        		;Print format
  signerr = 1
 endelse
;                  
s = size(image)
ncol = s(1) & nrow = s(2)	    ;Number of columns and rows in image array
;
mags = fltarr( Naper, Nstars ) & errap = mags           ;Declare arrays
sky = fltarr( Nstars ) & skyerr = sky     
area = fltarr( Naper )  & apmag = area   & magerr = area   & smstvr = area
error1 = area   & error2 = area   & error3 = area
;
if not keyword_Set(SETSKYVAL) then begin
  if skyrad(1) GT maxrad then begin
    message,/INF,  $
      'WARNING - Outer sky radius being reset to '+ strtrim(maxrad) 
    skyrad(1) = (maxrad-0.001)             ;Outer sky radius less than MAXRAD?
  endif
  rinsq =  (skyrad(0)> 0.)^2
  routsq = skyrad(1)^2
endif
;
if textout NE 1 then begin            ;Open output file and write header info?
  textopen, 'NEKDAP', TEXTOUT = textout
  printf, !TEXTUNIT, 'Program: NEKDAP ' + strmid(!stime,0,20)
  printf, !TEXTUNIT, form='(a,i5,a,i5)', 'IMAGE SIZE - X:', ncol, ' Y:', nrow
  FOR j = 0,Naper-1 do printf, !TEXTUNIT, $
    form='(a,i2,a,f4.1)','RADIUS OF APERTURE ',j,' = ',apr(j)
  printf, !TEXTUNIT, form='(a,f4.1)', $ 
    'INNER RADIUS FOR SKY ANNULUS = ',skyrad(0)
  printf, !TEXTUNIT, form='(a,f4.1)',  $
    'OUTER RADIUS FOR SKY ANNULUS = ',skyrad(1)
  printf,!TEXTUNIT,form='(A)', $
    'STAR   X       Y        SKY   SKYSIG    SKYSKW   '+UNITS
endif   
;
;
;  For each star APER perform computations on a subarray which includes 
;  all pixels within the outer sky radius.  This section computes the
;  limits of the subarray.
;
;	93Jul16-EV allowed minimum lx $ ly = 0 (previously 1)
;  
lx = fix( xc - skyrad(1) ) > 0	       ;Lower limit X direction
ux = fix( xc + skyrad(1) ) < (ncol-1)  ;Upper limit X direction
nx = ux-lx+1                           ;Number of pixels X direction
ly = fix( yc-skyrad(1) ) > 0           ;Lower limit Y direction
uy = fix( yc+skyrad(1) ) < (nrow-1)    ;Upper limit Y direction
ny = uy-ly +1                          ;Number of pixels Y direction
dx = xc-lx                             ;X coord of star's centroid in subarray
dy = yc-ly                             ;Y coord of star's centroid in subarray
edge = (dx-0.5) < (nx+0.5-dx) < (dy-0.5) < (ny+0.5-dy) ;Closest edge to array
;                                      ;Eliminate stars off the image
badstar = ( (xc LT 0.5) or (xc GT ncol-1.5) or (yc LT 0.5) or $ 
  (yc GT nrow-1.5) )
;
badindex = where( badstar, nbad)
if ( nbad GT 0 ) then message, /INF, $
  'WARNING -' + strtrim(nbad,2)+ ' star positions outside image'
;
if not silent then print, $ 
 format="(1X,'STAR',5X,'X',7X,'Y',6X,'SKY',8X,A)" ,units      ;Print header
;
;
for i = 0, Nstars-1 do begin                  ;Compute magnitudes for each star
  if not badstar(i) then begin                ;Don't bother for badstars
    rotbuf = image( lx(i):ux(i), ly(i):uy(i) ) ;Extract subarray from image
;
;  RSQ will be an array, the same size as ROTBUF containing the square of
;      the distance of each pixel to the center pixel.
;                                                                    
    dxsq = ( findgen(nx(i)) - dx(i) )^2
    rsq = fltarr( nx(i), ny(i) )
    for ii=0,NY(i)-1  DO rsq(0,ii) = dxsq + (ii-dy(i))^2
;
;  Select pixels within sky annulus, and eliminate pixels falling
;       below BADLO threshold.  SKYBUF will be 1-d array of sky pixels
;
    if not keyword_set( SETSKYVAL ) then begin
      sindex =  where( (rsq GE rinsq) and (rsq LE routsq) and $ 
        (rotbuf GT badpix(0)) )
      nsky =   N_elements(sindex) < maxsky     ;Must be less than MAXSKY pixels
      skybuf = rotbuf(sindex(0:nsky-1))       
;
      if ( nsky LT minsky )  then begin			;Sufficient sky pixels?
        print,'NEKDAP: There aren''t enough pixels in the sky annulus.'
        print,'      Are you sure your bad pixel threshold is all right?'
        print,'      If so, then you need a larger outer sky radius.'
        return
      endif
;
;  Obtain the mode, standard deviation, and skewness of the peak in the
;      sky histogram, by calling UIT_MMM.
;
      uit_mmm, skybuf, skymod, skysig, skyskw, MODE = mode, MEAN = mean
      skyvar = skysig^2                       ;Variance of the sky brightness
      sigsq = skyvar/nsky                     ;Square of standard error of
;                                              ;  mean sky brightness
;
;			            ;If the modal sky value could not be found
      if ( skysig LT 0.0 ) then begin                  ;then this star is bad
        apmag(*) = signerr*99.999   
        magerr(*) = signerr*9.999
        goto, BADSTAR          
      endif
      skysig = skysig < 999.99                 ;Don't overload output formats
      skyskw = skyskw >(-99)<999.9
    endif else begin			       ;if SETSKYVAL is set
      skymod = setskyval(0)
      skysig = setskyval(1)
      nsky = setskyval(2)
      skyvar = skysig^2
      sigsq = skyvar/nsky
      skyskw = 0
    endelse
;
    r = sqrt(rsq) - 0.5 ;2-d array of the radius of each pixel in the subarray
;
;	93Jul16-EV reorder IF statements in FOR loop below.  This will always
;	leave AREA non-zero, even if edge of frame is exceeded.  IF statements
;	are place at bottom of loop to set APMAG = -1.0E20 (specifically) if
;	desired APR exceeds EDGE.
;	Also, APMAG error value changed from -1.0E36 to -1.0E20, to avoid
;	floating overflow errors when MAGS divided by AREA.
;
    for k = 0, Naper-1 do begin	         ;Find pixels within each aperture
      thisap = where(r lt apr(k))             ;Pixels within aperture radii
      thisapd = rotbuf(thisap)
      thisapr = r(thisap)
      fractn = (apr(k)-thisapr) < 1.0 >0.0    ;Fractional value of pixel used
      apmag(k) = total(thisapd*fractn)        ;Total over irregular aperture
      smstvr(k)= total(fractn*ffvar(thisapd))
      area(k)  = total(fractn)
      if ( edge(i) LT apr(k) ) then $    ;Aperture extends past edge of image?
        apmag(k) = -1.0E20
      if (( min(thisapd) LE badpix(0) ) or $      ;Bad pixels within aperture?
         ( max(thisapd) GE badpix(1) )) then  apmag(k) = -1.0E20
    endfor ;K
;
      apmag = apmag-skymod*area  ;Subtract sky from the integrated brightnesses
;
;	Now compute 3 error terms and combine in quadrature
;	MAGERR will be wrong if APMAG=-1.0E20, but is skipped in test
;       statements just below; see NBAD.
;
    error1 = area*skyvar          	   ;Scatter in sky values
    error2 = smstvr               	   ;Random "photographic" noise 
    error3 = sigsq*area^2         	   ;Uncertainty in mean sky brightness
    magerr = sqrt(error1 + error2 + error3)
;
    if ( bscale NE 1 ) then begin              ;Convert to magnitudes?
      good = where (apmag GT 0.0, Ngood)       ;Are there any valid integrated
;	 				       ;  fluxes?
      if ( Ngood GT 0 ) then begin              ;If YES then convert to mags
        magerr(good) = 1.0857*magerr(good)/apmag(good)   ;1.0857 = log(10)/2.5
        apmag(good) = (-2.5*alog10(bscale*apmag(good)) - 21.1) < 99.9
      endif                          
      nogood = where( apmag LE 0.0, Nbad)       ;Assign fluxes to bad stars
      if ( Nbad GT 0 ) then begin               
        apmag(nogood) = signerr*99.999
        magerr(nogood) = signerr*9.999
      endif
    endif                                    
;                                       
    BADSTAR:
;
    for ii = 0, Naper-1 do $                ;Printout magnitudes for this star
      ms(ii) = string(apmag(ii),'+-',magerr(ii), FORM=fmt)
    if not silent then print, form= fmt2, $
      i,xc(i),yc(i),skymod,ms   		     ;Print results to terminal
    if ( textout GT 2 ) then printf,!TEXTUNIT, $     ;Write results to file?
      form = fmt3, i,xc(i),yc(i),skymod,skysig,skyskw,ms
; 
    sky(i) = skymod    &  skyerr(i) = skysig         ;Store in output variable
    mags(0,i) = apmag  &  errap(0,i)= magerr
  endif 
endfor ;i
;
if textout NE 1 then textclose		              ;Close output file
;
;        93MAR15-RCB FIXUPFOR MORE PRECISE AREA
;	 93JUL16-EV set MAGS > 0 to avoid APMAG = -1.0E20
;
IF BSCALE EQ 1 THEN MAGS=MAGS*3.14159*APR^2/AREA > 0
;for k = 0, Naper-1 do print,K,APR(K),area(k),MAGS(K),APMAG(K)
return
end
