;       Date:   May 24, 2004 12:08:56 PM EDT
; I haven't done any recent work with apphot.pro

;1. I get an error sometimes, even tho the photom looks ok?
;"% Program caused arithmetic error: Floating illegal operand"

;This is almost certainly benign, probably due to a small value that gets
;truncated to zero.    You can find more information by setting !EXCEPT
;=2 prior to running the program and then noting the line number where
;the problem occurs. 

;2. I have been using imerr=0, as putting in the actual err array
;makes it bomb. this workaround seems to be ok?

;Yes, the flux calculations are independent of the error calcs, so you
;can set imerr=0 to only get the fluxes.  BUT:
; APHOT computes flux errors from 3 sources: (1) uncertainty in the
;sky subtraction: (2) fluctuation in the sky (which are presumed to also
;occur within the aperture radius), and (3) propagating indivdual pixel
;errors when summing the flux within the aperture.    If you do not
;supply the statistical error array, then error source (3) will be
;neglected.

;In my version there was a misspelling of the 'buferr' variable (as
;bugerr).     When I correct this misspelling (attached version) 
;apphot.pro seems to work fine when the error array is input.

;Fri May 30 16:13:50 2003

;i am dabbling w/ that evil science of photometry and trying to use
;the "aper.pro" routine. we want to define an infinite aper to be 2.5"
;for ACS, ie 100 px radius for HRC. so i picked a sky of 104-140px.
;this is no good as i get an error msg. now i see maxrad=100 and maxsky=
;10000.

;am i using the best routine for my purposes? if so, why is my radius getting
;chopped back to 100 ( w/ a fairly oblique err msg)? why can't you just
;remove any limits on radius and maxsky? ralph,
;    Those limits were part of the original DAOPHOT code from which aper.pro was 
;adapted. It probably make sense to have some limits to flag when the user is 
;likely given nonsensical input, but yes, the current limits are probably too 
;strict.
    
;  The attached procedure apphot.pro is a modification of aper.pro that I plan 
;to eventually add to the Library. The main advantage is it accepts an error 
;image, rather than assuming Poisson statistics. It also uses the NaN notation 
;for bad pixels, and some of the limits are removed or loosened. But note that 
;I haven't used it for a year or so.   --Wayne

;	Date: 	February 4, 2007 11:00:32 AM EST
;	From: 	  landsman@milkyway.gsfc.nasa.gov

;The apphot bug was due to short integer overflow when using large sky
;radii. The sky pixels are determined by comparing their squared distance to
;the center of the aperture to the square of the inner and outer sky radii, so
;problems occurred for sky radii larger than sqrt(32767) ~ 180 pixels.

;Here are 3 different ways to fix the bug.

;1.   Add the line
;    compile_opt idl2   rcb-done 02Feb5
;    as the first line of the program.     This makes the default integer type Long.     The bug did not occur in aper.pro since it includes  this line (as do nearly all program in the IDL Astro library now.)
  
;2.  Change the line

;for ii = 0, ny[i]-1 do rsq[0,ii] = dxsq + (ii-dy[i])^2
;    to

;for ii = 0L, ny[i]-1 do rsq[0,ii] = dxsq + (ii-dy[i])^2

;3. Always use long or float types for the star position.

compile_opt idl2			; 07Feb5-rcb
pro apphot,image,imerr,xc,yc,flux,eflux,sky,skyerr,apr,skyrad, APRAD = APRAD,$
       SETSKYVAL = setskyval,PRINT = print, SILENT = silent, EXACT = exact
;+
; NAME:
;      APPHOT
; PURPOSE:
;      Compute concentric aperture photometry (adapted from DAOPHOT) 
; EXPLANATION:
;     APPHOT can compute photometry in several user-specified aperture radii.  
;     A separate sky value is computed for each source using specified inner 
;     and outer sky radii.   
;
; CALLING SEQUENCE:
;     apphot, image, imerr, xc, yc, [ flux, eflux, sky, skyerr, apr, skyrad, 
;                     /EXACT,  PRINT = , /SILENT, SETSKYVAL = ]
; INPUTS:
;     IMAGE -  input image array
;     IMERR -  array of sigma values associated with the image array
;     XC     - vector of x coordinates. 
;     YC     - vector of y coordinates
;
; OPTIONAL INPUTS:
;     APR    - Vector of up to 12 REAL photometry aperture radii.
;     SKYRAD - Two element vector giving the inner and outer radii
;               to be used for the sky annulus
;
; OPTIONAL KEYWORD INPUTS:
;     APRAD -  An alternative method to the APR parameter for specifying up to 
;              12 photometry aperture radii
;     /EXACT -  By default, apphot counts subpixels, but uses a polygon 
;             approximation for the intersection of a circular aperture with
;             a square pixel (and normalize the total area of the sum of the
;             pixels to exactly match the circular area).   If the /EXACT 
;             keyword, then the intersection of the circular aperture with a
;             square pixel is computed exactly.    The /EXACT keyword is much
;             slower and is only needed when small (~2 pixels) apertures are
;             used with very undersampled data.    
;     /PRINT - if set and non-zero then apphot will also write its results to
;               a file apphot.prt.   One can specify the output file name by
;               setting PRINT = 'filename'.
;     /SILENT -  If supplied and non-zero then no output is displayed to the
;               terminal.
;     SETSKYVAL - Use this keyword to force the sky to a specified value 
;               rather than have apphot compute a sky value.    SETSKYVAL 
;               can either be a scalar specifying the sky value to use for 
;               all sources, or a 3 element vector specifying the sky value, 
;               the sigma of the sky value, and the number of elements used 
;               to compute a sky value.   The 3 element form of SETSKYVAL
;               is needed for accurate error budgeting.
;
; OUTPUTS:
;     FLUX  -  Naper by NSTAR array giving the flux for each star in
;               each aperture.  (Naper is the number of apertures, and NSTAR
;               is the number of stars).   
;     EFLUX  -  Naper by NSTAR array giving error in magnitude
;               for each star.  If a magnitude could not be deter-
;               mined then ERRAP = 9.99.
;     SKY  -    NSTAR element vector giving sky value for each star
;     SKYERR -  NSTAR element vector giving error in sky values
;
; PROCEDURES USED:
;       GETOPT, MMM, PIXWT(), STRN()
; NOTES:
;       Reasons that a valid magnitude cannot be computed include the following:
;      (1) Star position is too close (within 0.5 pixels) to edge of the frame
;      (2) Less than 20 valid pixels available for computing sky
;      (3) Modal value of sky could not be computed by the procedure MMM
;      (4) *Any* pixel within the aperture radius is a "bad" pixel
;
; REVISON HISTORY:
;       Adapted from aper.pro                    W. Landsman  December 2000
;       Fix typo in buferr                     May 2004 
; version from wayne 05mar4    
; rm maxsky nonsense 15feb16 - rcb
;-
; On_error,2
;             Set parameter limits
 minsky = 20   ;Smallest number of pixels from which the sky may be determined
; 2015Feb15 - Maxsky is nonsense! Makes a tiny diff. Rm:
; maxsky = 20000         ;Maximum number of pixels allowed in the sky annulus.
;                                
if N_params() LT 3 then begin    ;Enough parameters supplied?
  print, $
  'Syntax - APPHOT,image,imerr,xc,yc,flux,eflux,sky,skyerr,apr,skyrad, '
  print,'            SETSKYVAL=, /PRINT, /SILENT, APRAD = '
  return
endif 

 s = size(image)
 if ( s[0] NE 2 ) then message, $
       'ERROR - Image array (first parameter) must be 2 dimensional'
 ncol = s[1] & nrow = s[2]           ;Number of columns and rows in image array

  silent = keyword_set(SILENT)
  chkerr = N_elements(imerr) GT 1
  if N_elements(apr) EQ 0 then $
      if N_elements(aprad) EQ 0 then message, $
     'ERROR - An aperture radius must be specified either by ' + $
             'parameter or keyword' else apr = aprad


 if N_elements(SETSKYVAL) GT 0 then begin
     if N_elements( SETSKYVAL ) EQ 1 then setskyval = [setskyval,0.,1.]
     if N_elements( SETSKYVAL ) NE 3 then message, $
        'ERROR - Keyword SETSKYVAL must contain 1 or 3 elements'
     skyrad = [ 0., max(apr) + 1]

 endif else begin   ;Get radii of sky annulii

   if N_elements(skyrad) NE 2 then begin
      skyrad = fltarr(2)
      read,'Enter inner and outer sky radius (pixel units): ',skyrad
 endif else skyrad = float(skyrad)
 endelse


 
 
 Naper = N_elements( apr )                        ;Number of apertures
 Nstars = min([ N_elements(xc), N_elements(yc) ])  ;Number of stars to measure

 ms = strarr( Naper )       ;String array to display mag for each aperture
           fmt = '(F8.1,1x,A,F7.1)'          ;Flux format
 fmt2 = '(I5,2F8.2,F7.2,3A,3(/,28x,4A,:))'       ;Screen format
 fmt3 = '(I4,5F8.2,6A,2(/,44x,9A,:))'            ;Print format

 flux = fltarr( Naper, Nstars) & eflux = flux           ;Declare arrays
 sky = fltarr( Nstars )        & skyerr = sky     
 area = !PI*apr*apr                 ;Area of each aperture
 apmag= fltarr(Naper)    
                      error1=apmag   & error2 = apmag   & error3 = apmag

 if keyword_set(EXACT) then begin
      bigrad = apr + 0.5
      smallrad = apr/sqrt(2) - 0.5 
 endif
     

 if not keyword_set(SETSKYVAL) then begin
     rinsq =  (skyrad[0]> 0.)^2 
     routsq = skyrad[1]^2
 endif 


 print = keyword_set(PRINT)
 if print then begin      ;Open output file and write header info?
   if size(PRINT,/TNAME) NE 'STRING'  then file = 'apphot.prt' $
                                   else file = print
   message,'Results will be written to a file ' + file,/INF
   openw,lun,file,/GET_LUN
   printf,lun,' Program: apphot '+ systime(), '   User: ', $
      getenv('USER'),'  Node: ',getenv('NODE')
   for j = 0, Naper-1 do printf,lun, $
               format='(a,i2,a,f4.1)','Radius of aperture ',j,' = ',apr[j]
   printf,lun,f='(/a,f4.1)','Inner radius for sky annulus = ',skyrad[0]
   printf,lun,f='(a,f4.1)', 'Outer radius for sky annulus = ',skyrad[1]
   printf,lun,f='(/a)', $
           'STAR   X       Y        SKY   SKYSIG    SKYSKW   FLUXES'

;         Print header
 if not SILENT then $
        print, format="(/1X,'STAR',5X,'X',7X,'Y',6X,'SKY',8X,'FLUXES')"

 endif
;  Compute the limits of the submatrix.   Do all stars in vector notation.

 lx = fix(xc-skyrad[1]) > 0           ;Lower limit X direction
 ux = fix(xc+skyrad[1]) < (ncol-1)    ;Upper limit X direction
 nx = ux-lx+1                         ;Number of pixels X direction
 ly = fix(yc-skyrad[1]) > 0           ;Lower limit Y direction
 uy = fix(yc+skyrad[1]) < (nrow-1);   ;Upper limit Y direction
 ny = uy-ly +1                        ;Number of pixels Y direction
 dx = xc-lx                         ;X coordinate of star's centroid in subarray
 dy = yc-ly                         ;Y coordinate of star's centroid in subarray

 edge = (dx-0.5) < (nx+0.5-dx) < (dy-0.5) < (ny+0.5-dy) ;Closest edge to array
 badstar = ((xc LT 0.5) or (xc GT ncol-1.5) $  ;Stars too close to the edge
        or (yc LT 0.5) or (yc GT nrow-1.5))
;
 badindex = where( badstar, Nbad)              ;Any stars outside image
 if ( Nbad GT 0 ) then message, /INF, $
      'WARNING - ' + strn(nbad) + ' star positions outside image'
 
 for i = 0L, Nstars-1 do begin           ;Compute magnitudes for each star
   skymod = 0. & skysig = 0. &  skyskw = 0.  ;Sky mode sigma and skew
   if badstar[i] then begin         ;
      apmag[*] = !Values.F_NAN
      goto, BADSTAR 
   endif

   rotbuf = image[ lx[i]:ux[i], ly[i]:uy[i] ] ;Extract subarray from image
   if chkerr then errbuf = imerr[ lx[i]:ux[i], ly[i]:uy[i]  ]

;  RSQ will be an array, the same size as ROTBUF containing the square of
;      the distance of each pixel to the center pixel.

   dxsq = ( findgen( nx[i] ) - dx[i] )^2
   rsq = fltarr( nx[i], ny[i], /NOZERO )
   for ii = 0, ny[i]-1 do rsq[0,ii] = dxsq + (ii-dy[i])^2


 if keyword_set(exact) then begin 
       nbox = lindgen(nx[i]*ny[i])
       xx = reform( (nbox mod nx[i]), nx[i], ny[i])
       yy = reform( (nbox/nx[i]),nx[i],ny[i])
       x1 = abs(xx-dx[i]) 
       y1 = abs(yy-dy[i])
  endif else begin 
   r = sqrt(rsq) - 0.5    ;2-d array of the radius of each pixel in the subarray
 endelse

;  Select pixels within sky annulus, and eliminate pixels falling
;       below BADLO threshold.  SKYBUF will be 1-d array of sky pixels
 if not keyword_set (SETSKYVAL) then begin

 annulus = ( rsq GE rinsq ) and ( rsq LE routsq )
 sindex =  where(annulus, Nsky)
 if ( nsky LT minsky ) then begin                       ;Sufficient sky pixels?
    if not silent then $
        message,"There aren't enough valid pixels in the sky annulus.",/con
    apmag[*] = !VALUES.F_NAN
    goto, BADSTAR
 endif 

;  Obtain the mode, standard deviation, and skewness of the peak in the
;      sky histogram, by calling MMM.

; rcb 2015Feb16 nsky =   Nsky < maxsky                 ;Must be less than MAXSKY pixels
 skybuf = rotbuf[ sindex[0:nsky-1] ]     
 mmm, skybuf, skymod, skysig, skyskw
 skyvar = skysig^2    ;Variance of the sky brightness
 sigsq = skyvar/nsky  ;Square of standard error of mean sky brightness
; 2017sep4-For my big 6-8" sky aper, the skymod, i.e. sky value still seems OK: 
;rcb if ( skysig LT 0.0 ) then begin   ;If the modal sky value could not be
;rcb       apmag[*] = !VALUES.F_NAN          ;determined, then all apertures for
;rcb       goto, BADSTAR               ;this star are bad.
;rcb endif  

 skysig = skysig < 999.99      ;Don't overload output formats
 skyskw = skyskw >(-99)<999.9
 endif else begin
    skymod = setskyval[0]
    skysig = setskyval[1]
    nsky = setskyval[2]
    skyvar = skysig^2
    sigsq = skyvar/nsky
    skyskw = 0
endelse



 for k = 0,Naper-1 do begin      ;Find pixels within each aperture
; 2015oct20-allow aper to extend into sky region:
;rcb  if ( edge[i] LT apr[k] ) then $   ;Does aperture extend outside the image?
;rcb           apmag[k] = !VALUES.F_NAN $
;rcb   else begin
     if keyword_set(EXACT) then begin
       mask = fltarr(nx[i],ny[i])
       good = where( ( x1 LT smallrad[k] ) and (y1 LT smallrad[k] ), Ngood)
       if Ngood GT 0 then mask(good) = 1.0
       bad = where(  (x1 GT bigrad[k]) or (y1 GT bigrad[k] ))
       mask(bad) = -1

       gfract = where(mask EQ 0.0, Nfract) 
       if Nfract GT 0 then mask[gfract] = $
		PIXWT(dx[i],dy[i],apr[k],xx[gfract],yy[gfract]) > 0.0
       thisap = where(mask GT 0.0)
        fractn = mask[thisap]
     endif else begin
;
       thisap = where( r LT apr[k] )   ;Select pixels within radius
       thisapr = r[thisap]
       fractn = (apr[k]-thisapr < 1.0 >0.0 ) ;Fraction of pixels to count
       full = fractn EQ 1.0
       gfull = where(full, Nfull)
       gfract = where(1 - full)
       factor = (area[k] - Nfull ) / total(fractn[gfract])
      fractn[gfract] = fractn[gfract]*factor
    endelse

     thisapd = rotbuf[thisap]
     if chkerr then errapd = errbuf[thisap]

        apmag[k] = total(thisapd*fractn)  ;Total over irregular aperture
       if chkerr then error2[k] =  total( (errapd^2*fractn))

;rcb   endelse
 endfor ;k

 apmag = apmag - skymod*area  ;Subtract sky from the integrated brightnesses

    error1 = area*skyvar   ;Scatter in sky values
   error3 = sigsq*area^2  ;Uncertainty in mean sky brightness
  magerr = sqrt(error1 + error2 + error3)

 BADSTAR:   
                                           ;Assign fluxes to bad stars
 
;Print out magnitudes for this star

 for ii = 0,Naper-1 do $              ;Concatenate mags into a string

    ms[ii] = string( apmag[ii],'+-',magerr[ii], FORM = fmt)
   if PRINT then  printf,lun, $      ;Write results to file?
      form = fmt3,  i, xc[i], yc[i], skymod, skysig, skyskw, ms
   if not SILENT then print,form = fmt2, $       ;Write results to terminal?
          i,xc[i],yc[i],skymod,ms

   sky[i] = skymod    &  skyerr[i] = skysig  ;Store in output variable
   flux[0,i] = apmag  &  eflux[0,i]= magerr
 endfor                                              ;i

 if PRINT then free_lun, lun             ;Close output file

 return
 end
