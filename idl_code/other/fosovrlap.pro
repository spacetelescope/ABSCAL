PRO FOSovrlap,w1,w2,f1,f2,fo1,fo2
;+
;
; smoothly correct the input fluxes in overlapping region to force continuity
;
; INPUT:
;	w1, w2 - wavelength vectors of SHORT, long WAVELENGTH SPECTRa
;	F1, f2 - fluxes OF SHORT, long WAVELENGTH SPECTRa
; OUTPUT:
; 	FO1, fo2 - fluxes corrected for agreement in overlap region
;
;HISTORY:
; 94mar29-rcb
; 95sep12 - keep 11 points off ends instead of 5 to fix gd71 blue h19
;-------------------------------------------------------------------------
;
fo1=f1
fo2=f2
last=n_elements(w1)-1
if w1(last) lt w2(0) then begin		;error condition
	print,'stop in fosovrlap for non-overlapping spectra. w1(last)',  $
			',w2(0)=',w1(last),w2(0)
	stop
	endif

;compute ratio f1/f2 in bin of 0.1*overlap region at ends. keep 11 pts off ends

lastw1=last
frstw1=ws(w1,w2(0))  &  if (lastw1-frstw1) gt 30 then lastw1=fix(lastw1-10.)
frstw2=0
lastw2=ws(w2,w1(lastw1))  & if lastw2 gt 30 then frstw2=fix(frstw2+11.)
wbeg=w2(frstw2)
wend=w1(lastw1)
dlam=(wend-wbeg)/10.

; correct f1
rat=tin(w2,f2,wend-dlam,wend)/tin(w1,f1,wend-dlam,wend)-1.
indx=where(w1 gt w2(0))
fo1(indx)=f1(indx)*(1.+rat(0)*(w1(indx)-wbeg-dlam/2.)/(9.*dlam))

; correct f2
rat=tin(w1,f1,wbeg,wbeg+dlam)/tin(w2,f2,wbeg,wbeg+dlam)-1.
indx=where(w2 lt w1(last))
fo2(indx)=f2(indx)*(1.+rat(0)*(wend-dlam/2.-w2(indx))/(9.*dlam))

RETURN
END
