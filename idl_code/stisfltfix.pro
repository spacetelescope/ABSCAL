pro stisfltfix,flat,center,range,factor
;+
;
; stisfltfix,flat,center,range,factor
;
; PURPOSE:
;	Fix the STIS dust motes in a range about center to make them deeper by
;			a factor.
; INPUT:
;	flat - the flat field to be fixed
;	center-2 element vector [x,y] = the center of a dust mote to fix
;	range- the +- pixels over which to fix
;	factor-scaler factor to increase the depth of the flat values <1
; OUTPUT:
;	flat - fixed flat field image
; AUTHOR-R.C.BOHLIN
; HISTORY:
; 99mar9 - written
;-

subimg=flat(center(0)-range:center(0)+range,center(1)-range:center(1)+range)
indx=where(subimg lt 1)				; fix only px less than unity
subimg(indx)=1-((1-subimg(indx))*factor)	; THE FIX

flat(center(0)-range,center(1)-range)=subimg
return
end
