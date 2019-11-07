pro fosyerr,name,seldet,selgrt,selapr,selstr
;+
;
; 93aug14 - ck obs w/ three ysteps for ybase errors-rcb
; input - name=file of fos observations to process, where NAME is file that is 
;		output by fosdir and has the list of obs to process
; optional input-seldet,selgrt,selapr,selstr to restrict processing
;	eg: fosyerr,'dircal.log','BLUE','H19','','BD+28D4211'--see fosobs---
;	ALL 4 OPTIONS MUST BE PRESENT, IF ANY ARE SPECIFIED
; output- plot ratios of 1st(0)-solid & last(2)-dotted of 3 ysteps to middle(1)
; history:
;	93nov19-rename from yerr to fosyerr
;	94JAN15-FIX FOR MULTI-READOUTS TO READ LAST 3 GROUPS
;	94apr4-add optional input to restrict list of obs to process
;	94may6-add yspace value to plot
;-
if n_params(0) lt 5 then begin
	seldet=''
	selgrt=''
	selgrt=''
	selapr=''
	selstr=''
	endif
fosobs,name,LIST,det,grat,aper,star,seldet,selgrt,selapr,selstr
siz=size(list)
num=siz(1)
st=''
!xtitle='WAVELENGTH(A)'
!YTITLE='RESPONSE RELATIVE TO MIDDLE Y STEP'
C=FLTARR(2064,3)
TOT=FLTARR(3)

for i=0,num-1 do begin
	sxopen,1,list(i)+'.c5h',head
	group=sxpar(head,'gcount')
	ysteps=SXPAR(HEAD,'YSTEPS')
	if ysteps ne 3 then begin
		print,'YSTEPS NE 3 in fosyerr w/ group,ysteps,root=',	$
			group,ysteps,list(i)
		stop
		goto,skipit		; for .con
		endif
	GET_TWAVE,HEAD,WAVE
        GRAT=STRUPCASE(STRTRIM(SXPAR(HEAD,'FGWA_ID'),2))
        DET=STRMID(STRUPCASE(STRTRIM(SXPAR(HEAD,'DETECTOR'),2)),0,1)
	IF DET EQ 'A' THEN DET='R'
        GRCASE=GRAT+DET
                case grcase of
                'H19R': BEGIN & WMIN=1650 & WMAX=2350 & END
                'H27R': BEGIN & WMIN=2250 & WMAX=3250 & END
                'H40R': BEGIN & WMIN=3250 & WMAX=4750 & END
                'H57R': BEGIN & WMIN=4600 & WMAX=6800 & END
                'H78R': BEGIN & WMIN=6300 & WMAX=7800 & END
                'L15R': BEGIN & WMIN=1650 & WMAX=2500 & END
                'L65R': BEGIN & WMIN=3700 & WMAX=6900 & END
                'PRIR': BEGIN & WMIN=2200 & WMAX=6500 & END
                'H13B': BEGIN & WMIN=1250 & WMAX=1580 & END
                'H27B': BEGIN & WMIN=2250 & WMAX=3250 & END
                'H40B': BEGIN & WMIN=3300 & WMAX=4700 & END
                'L15B': BEGIN & WMIN=1200 & WMAX=2500 & END
                'PRIB': BEGIN & WMIN=1900 & WMAX=5000 & END
                 else : BEGIN & WMIN=MIN(WAVE)  &  WMAX=MAX(WAVE) & END
                endcase

	CQUAL=FLTARR(2064)+1.		;INITIALIZE GOOD DATA quality TO ALL 1's
	FOR J= 0,2 DO BEGIN
		C(0,J)=SXREAD(1,GROUP-3+J,GPAR)	;READ LAST 3 GROUPS
		bad=WHERE(C(*,J) le 0)		;KEEP WHITTLING DOWN cqual array
		if !err gt 0 then cqual(bad)=0
		if max(cqual) eq 0 then begin
; fix for all bad data qual in one step, eg djl fix of Y0K40408T bd75 H19R
			CQUAL=FLTARR(2064)+1.	;reinitialize
			print,'***** WARNING *****  all data qual is bad in',  $
				' step=',j
			endif
		ENDFOR
	GOOD=WHERE((WAVE GE WMIN) AND (WAVE LE WMAX) and (cqual eq 1))
	if grcase eq 'PRIR' then good=good(where(good le 1984))	;special fix
	FOR J=0,2 DO TOT(J)=TOTAL(C(GOOD,J))
	Tot=tot/MAX(TOT)

	!MTITLE=name+' '+FOSTIT(HEAD,GPAR)
	plot,wave(GOOD),c(GOOD,0)/c(GOOD,1),yr=[.8,1.2]
	for J=1,2 do oplot,wave(GOOD),c(GOOD,J)/c(GOOD,1),LINEST=J-1
	yspace=SXPAR(HEAD,'YSPACE')
	xyouts,!CXMAX*.5+!CXMIN*.5,1.16,'YSPACE='+string(yspace,'(f3.0)')
	plotdate,'FOSyerr'
	if !d.name eq 'X' then read,st
skipit:
	endfor
end
