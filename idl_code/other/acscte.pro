function acscte,time,elect,dely,aper=aper
;+
;
; PURPOSE
;	compute the CTE correction for case of zero background and >2e4 electron
;
; INPUT
;	time - Time of the observation as fractional year 
;	elect - total measured electrons for a single flt image in the aper
;	aper - optional aperture size of 20, 3, 5, 13 px radius.
;						Default is 20px=1arcsec.
;	dely - rows from the read-out amp
; OUTPUT
;	the correction
; HISTORY
;	2010Dec8 - rcb
;	2011aug23 - generalize for any interpolated aper size
;	2013aug1 - Update a,b per ctemeas.pro.
;		Base on subarr obs of 2013.15 avg time & far from Amps.
;	2016jan20 - Update min elect to 6000 for new EE.pro and aperad=1
;	2017sep5  - See also xycte.pro for serial CTE corr.
;-

; correction coef from ctemeas.pro. Linear fits in the log-log space
;a=[ -2.60, -2.60, -2.71, -2.77d]	; for CTI in 20,3,7,13 px radius
;b=[-0.543,-0.474,-0.465,-0.479d]	; old orig. See acscte_orig.pro
;a=[ -3.034, -2.450, -2.655, -2.897d]	; 2013 Aug 1
;b=[-0.4088,-0.4702,-0.4383,-0.4126d]	; for 2013.15
a=[-2.644,-2.439,-2.683,-2.833d]	; 2013Aug28
b=[-0.4951,-0.4719,-0.4330,-0.4268d]	; for 2013.15

apersz=[20,3,7,13]
;if min(elect) lt 1.8e4 then begin
;if min(elect) lt 1.55e4 then begin	; for 2m0559-14 F775W 3pxradius-2015Oct1
if min(elect) lt 6000 then begin	;for 2m0559-14 F775W 1pxradius-2016jan20
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
	     end else begin				;interpol in aper radius
		indx=where(aper gt apersz)  &  indx=max(indx)
		if indx lt 0 then indx=1		; extrap w/ apersz=3,7
		amin=a(indx)
		bmin=b(indx)
		apsize=apersz(indx)
		indx=indx+1				; r=14 or 21-->indx=4
		if indx gt 3 then indx=0		; biggest apersz is (0)
		amax=a(indx)
		bmax=b(indx)
		delaper=apersz(indx)-apsize
		ause=amin+(amax-amin)*(aper-apsize)/delaper	; lin interpol.
		buse=bmin+(bmax-bmin)*(aper-apsize)/delaper	;  the coefs
		print,'INTERPOLATE in acscte for aper=',aper,' a,b=',ause,buse
		endelse
	endif
;deltim=(time-2002.2)/7.4d				;norm to 2009.6
deltim=(time-2002.2)/10.95d				;norm to 2013.15
cte=1.-deltim*10^(ause+buse*alog10(elect))		; avg CTE, 1 row
return,cte^dely						; the correction
end
