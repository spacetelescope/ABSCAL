problematic... eg 16411A line in Rudy's IC5117 spec w/ flat top &
asymmetric falloff to long vs. short WL...

Asked don & he says:

I don't know of a routine.  I usually just subtract 20% of the line peak from
the data, clip at zero, and then compute a centroid.

{which should be OK, as the flux=weights of the clipped wings approach 0.
See eg wfc3/wlpn.pro & wlmeas.pro}



pro lcntrd,wav,spec,xappr,fwhm,xact,wxact
;+
; Compute the centroid of a line with a derivative search like ctrd does in 2-D,
;	which ignores the weak and possibly contaminated line wings. The
;	derivatives are computed and fit over the range xappr +/- fwhm/2.
;
;  INPUTS:     
;       wav - wavelenth vector
;	spec - spectral flux or counts
;       xappr - approximate center, usually the peak (or min) pixel value
;	fwhm - Full width at half max in pixels.
;  OUTPUTS:   
;       xact - the computed X exact centroid position in px
;	wxact - the computed X exact centroid position in wavelength units
;  HISTORY
;	2013May23-RCB
;-


minpx=fix(xappr-fwhm/2.)
maxpx=fix(xappr+fwhm/2.+1)

slope=spec(minpx+1:maxpx)-spec(minpx:maxpx-1)
xslope=indgen(maxpx-minpx)+minpx+.5

plot,xslope,slope,psym=-4,xr=[minpx,maxpx]
oplot,[minpx,maxpx],[0,0],lin=2

pos=where(slope gt 0)
neg=where(sl.....
help,slope,xslope & stop

return
end
