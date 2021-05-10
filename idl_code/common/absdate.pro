function absdate,indates
;+
; NAME:
;	ABSDATE
; PURPOSE:
;	Convert input dates in format: YYYY.DDD:HH:MM:SS.SSS to
;	fractional year.
; CALLING SEQUENCE:
;	frac_year = absdate( dates )
; INPUTS:
;	dates - a single date of the above format, or a list of dates
; OUTPUTS:
;	returns the fractional year
; HISTORY:
;	28-JAN-92, Written, JDN @ ACC
;-
; format input
;
ind = [indates]
nd = n_elements(ind)
odates = dblarr(nd)
;
; loop over input dates
;
for i=0,nd-1 do begin
	t = ind(i)
	yr = fix(gettok(t,'.'))
	day= fix(gettok(t,':'))
	hr = fix(gettok(t,':'))
	min= fix(gettok(t,':'))
	sec= float(t)
	dpy = 365.25d0
	out = sec/24.0d0/60./60. + min/24.0d0/60. + hr/24.0d0 $
   		+  double(day)
	out = double(yr) + out / dpy
	odates(i) = out
endfor
;
return,odates
end		; absdate.pro
