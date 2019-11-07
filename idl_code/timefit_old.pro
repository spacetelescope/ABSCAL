function timefit_old,endpts,yinput,times,mode=mode
;+
;
; timefit(endpts,yinput,times)
; INPUT:
;	endpts - x start & end times for each line segment (4-9 elements)
;	yinput - y value of the fit at each endpts 1-2 dim: (ge 5 elements,nwl)
;		There are 2 yinput's at the discontinuities.
;	times   - array of times @ endpts to compute the output y values
; OUTPUT:
;	yfit   - the value of the fit defined by endpts,yinput at each times pt.
;			or at each wl for one time
; CALLED BY: ttcorr.pro
; 99sep2 -rcb for STIS changing sensitivity.
; 02apr4 - G140L has four yinput values.
; 12jan12 - G430L has 3 endpts, 4 yinputs, & 2 line segments. (discont @2009.5)
; 14Feb17 - G230* has 7 endpts, 8 yinputs, & 6 line segments. (discont @2009.5)
; 14Jul22 - G430L & G750L have 5 yinputs & 3 segments (discont @2009.5)
; 18jun8 - G140L has 8 yinput values & 5 endpts.
; 18jun11- G230* has 10 ... ... ... .. 9
;-
if not keyword_set(mode) then stop	; idiot check
s=size(yinput)   &  nwl=s(2)		; number of wl bins for make-tchang use
ntim=n_elements(times)			; ... of time points 
; for special use in make-tchang w/ one wl and many times:
if s(0) eq 1 then nwl=1			; 1D array for ttcorr
yfit=fltarr(nwl,ntim)+1.
indx=where(times+.1 lt endpts(0),npts)	; 00jun2 put in .1yr slop at 1997.38
if npts gt 0 then begin
	print,'   ******  WARNING  ****** TIME correction set to unity at:',  $
							times(indx),endpts(0)
	endif
xtrapt=0						; extra pt for G140L,etc
for i=0,n_elements(endpts)-2 do begin
	indx=where(times+.1*(i<1) ge endpts(i),npts)	; last iter & extrap ok
	if npts gt 0 then begin
		if mode eq 'G140L' and i eq 1 then xtrapt=1	; discont
		if endpts(i) eq 2009.5 then xtrapt=xtrapt+1   ;G230*,etc discont
	        slope=(yinput(i+1+xtrapt,*)-yinput(i+xtrapt,*))		$
							/(endpts(i+1)-endpts(i))
		if n_elements(slope) eq 1 then				$
; one wl, many times for make-tchang:
		  yfit(indx)=yinput(i+xtrapt)+slope(0)*(times(indx)-endpts(i)) $
		 else							$
; many wl bins (*) & one time (indx) for ttcorr.pro:
                  yfit(*,indx)=yinput(i+xtrapt,*)+slope*(times(0)-endpts(i))
		endif
	endfor
indx=where(times gt endpts(n_elements(endpts)-1)+1,npts)	; one yr grace
if npts gt 0 then print,'   ******  WARNING  ****** corrections '+	$
	'extrapolated more than 1 year at:',times(indx)
return,yfit
end
