function xycte,x,y,chip,time,aper=aper
;+
;  PURPOSE:
;	return the time dependent correction for XYCTE losses for bright stars 
;		to divide into counts
; CALLING SEQUNCE:
;	xycte(x,y,chip,time)
; Inputs scaler or vector:
;	x,y - the vector coordinates of the star on each chip, where Y<2048
;	chip - vector for WFC CCD chip 1 or 2
;	time - vector time of obs in fractional year
;	aper - optional aperture size. Default is 20px=1arcsec.
; OUTPUT:
;	xycte - the correction, extrapolated for aper=1 & 2
; HISTORY
;	2017jun20 - rcb
;	2017jul6  - Add 110px
;	2071sep25 - update for fixes in ee.pro
;	2017sep26 - not converging. Try actual B values - OK now!
;-

if n_elements(chip) ne n_elements(x) then stop			; idiot ck

; corr coef from ISR. Use B for 20px radius, as smaller radii are w/i 1sigma
apersz=[3,5,10,20,110]
;;a=[0.872,0.922,1.338,1.421,1.453]	; 2017sep28 stdphot missed the 14405 pt!
a=[0.872,0.922,1.450,1.421,1.453]	; 2017sep28 conv
;;B=[-0.001013,-0.001071,-0.001185,-0.001158,-0.001153]	; 2017sep28
B=[-0.001013,-0.001071,-0.001188,-0.001158,-0.001153]	; 2017sep28 conv
; Add elect to calling seq?
;if min(elect) lt 6000 then begin	;for 2m0559-14 F775W 1pxradius-2016jan20
;		print,'STOP in acscte. Corr not defined for elect=',min(elect)
;		stop
;		endif
if min(time) lt 2002.16 then begin
		print,'STOP in acscte. BAD time=',time
		stop
		endif
ause=a[3]  &  buse=b[3]			; default is20 px radius
if keyword_set(aper) then begin
	if aper lt 1 or aper gt 110 then stop
; linterp truncates and does not extrapolate
	indx=where(aper ge apersz)  &  indx=max(indx)>0<3
	ause=a(indx)+(aper-apersz(indx))*(a(indx+1)-a(indx))/		$
					(apersz(indx+1)-apersz(indx))
	buse=B(indx)+(aper-apersz(indx))*(B(indx+1)-B(indx))/		$
					(apersz(indx+1)-apersz(indx))
	end else aper=20

; compute distances from nearest corner amp:
dx=x
rhs=where(x ge 2048,nrhs)
if nrhs gt 0 then dx(rhs)=4095-x[rhs]
dy=y
top=where(chip eq 1,ntop)
if ntop gt 0 then dy[top]=2047-y[top]

xycte=1.+0.01*(ause + buse*(dx+ dy))*(time- 2002.16)/(2013.15 - 2002.16)

;print,'XYCTE ause,buse=',ause,buse,' for aper=',aper

return,xycte
end
