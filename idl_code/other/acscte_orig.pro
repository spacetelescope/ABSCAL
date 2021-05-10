function acscte_orig,time,elect,dely,aper=aper
;+
;
; PURPOSE
;	compute the CTE correction for case of zero background and >2e4 electron
;
; INPUT
;	time - Time of the observation as fractional year 
;	elect - total measured electrons for a single flt image in the aper
;	aper - optional aperture size of 20, 3, 5, 13 px radius. (interpolation
;		not implemented.) Default is 20px=1arcsec.
;	dely - rows from the read-out amp
; OUTPUT
;	the correction
; HISTORY
;	2010Dec8 - rcb
;	2011aug23 - generalize for any interpolated aper size
;-

; correction coef from ctemeas.pro. Linear fits in the log-log space
a=[ -2.60, -2.60, -2.71, -2.77d]	; for CTI in 20,3,7,13 px radius
b=[ -0.543,-0.474,-0.465,-0.479d]

apersz=[20,3,7,13]
if min(elect) lt 1.8e4 then begin
		print,'STOP in acscte. Corr not defined for elect=',min(elect)
		stop
		endif
if min(time) lt 2002.2 then begin
		print,'STOP in acscte. BAD time=',time
		stop
		endif
ause=a(0)  &  buse=b(0)					; default
if keyword_set(aper) then begin
	apindx=where(aper eq apersz,match)  &  apindx=apindx[0]
	if match eq 1 then begin
		ause=a(apindx)  &  buse=b(apindx)
	     end else begin
		indx=where(aper gt apersz)  &  indx=max(indx)
		amin=a(indx)
		bmin=b(indx)
		apsize=apersz(indx)
		indx=indx+1
		if indx gt 3 then indx=0		; biggest apersz is (0)
		amax=a(indx)
		bmax=b(indx)
		delaper=apersz(indx)-apsize
		ause=amin+(amax-amin)*(aper-apsize)/delaper	; lin interpol.
		buse=bmin+(bmax-bmin)*(aper-apsize)/delaper	;  the coefs
		print,'INTERPOLATE in acscte for aper=',aper,' a,b+',ause,buse
		endelse
	endif
deltim=(time-2002.2)/7.4d				;norm to 2009.6
cte=1.-deltim*10^(ause+buse*alog10(elect))		; avg CTE, 1 row
return,cte^dely							; the correction
end
