function timefit,endpts,yinput,times
;+
;
; timefit(endpts,yinput,times)
; INPUT:
;	endpts - the times in frac. yr of the spline nodes
;	yinput-y value of the spline nodes. Dim=2 for ttcorr, =1 for make-tchang
;		eg for ttcorr: N spline nodes # M WL bins.
;	times   - array of times @ endpts to compute the output y values
; OUTPUT:
;	yfit(nwl,ntim) - the value of the fit defined by endpts,yinput at each
;		 times pt.
;		for make-tchang or at each wl for one time in ttcorr
; CALLED BY: ttcorr.pro & make-tchang
; 2019may8 - convert to spline fits, instead of piecewise linear
;-
s=size(yinput)   &  nwl=s(2)		; number of wl bins for make-tchang use
ntim=n_elements(times)			; ... of time points 
; for special use in make-tchang w/ one wl and many times:
if s(0) eq 1 then nwl=1			;1D array. (ttcorr has 2-D array)
yfit=fltarr(nwl,ntim)+1.
indx=where(times lt endpts(0)-.2,npts)
if npts gt 0 then begin
	print,'   ******  WARNING  ****** TIMFIT correction too early at:', $
							times(indx),endpts(0)
	stop						; idiot ck
	endif

if nwl eq 1 then							$
; one wl, many times for make-tchang:
	yfit=cspline(endpts,yinput,times)				$
		 else							$
; many wl bins yinput(spline-vals,n-WLs) & one times(0) for ttcorr.pro:
       for i=0,nwl-1 do yfit(i,*)=cspline(endpts,yinput(*,i),times(0))
		 
indx=where(times gt endpts(-1)+1,npts)	; one yr grace
if npts gt 0 then begin
	print,'   ******  WARNING  ****** timefit.pro corrections '+	$
			'extrapolated more than 1 year at:',times(indx)
	stop
	endif
return,yfit
end
