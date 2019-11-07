;TO PLOT several SWP IUE SPECTRA ON A LOG PLOT-88JUL16 RCB
; 91AUG28-CONVERT TO V2
;
SET_XY,1100,2000
;!fancy=2
;!type=20
!XTICKS=9
!YTICKS=10
!XTITLE='WL (A)'
;!YTITLE='LOG FLUX!D1988!N (ERG CM!E-2!N S!E-1!N A!E-1!N)'
!YTITLE='LOG (S/F) [SR!E-1!N]'
;NEXT 2 LINES FOR BOX PLOT OPTION
PBOX,2
!PSYM=-8
oldymax=!ymax
oldymin=!ymin
        w=sw(*,0)
	f=sw(*,1)
; 90FEB23-GET RID OF BAD REGIONS
	BAD=WHERE ((F EQ -1.E-20) OR ((W GT 1200) AND (W LT 1230))) & NBAD=!ERR
;	f=sw(*,5)
;	norm=total(f(450:550 ))
        f=alog10(f>1e-20)
	good=where(w gt 1350)
;	!ymax=max(f(good))-.2
	!ymax=max(f(good))
;	!ymin=!ymax-1.5
	!ymin=!ymax-.9
PRINT,!YMAX,!YMIN
;PLOT,w,f
IF NBAD GT 0 THEN F(BAD)=1.6E38
NULL_PLOT,W,F
PLOTDATE,'IUE]PLOGSWP'
; normalize to a standard region
offset=0
; rest of stars

;wl=sw2(*,0)
;f =sw2(*,1)
;f =sw2(*,5)
;newflx=total(f(450:550 ))
;f=alog10(f>1e-20)
;offset=offset+.1
;f=f+alog10(norm/newflx)-offset
;if w(0) ne wl(0) then begin
;	print,'wl arrays do not agree',w(0),wl(0)
;	stop
;	endif
;!LINETYPE=1
;oplot,wl,f

;wl=sw3(*,0)
;f =sw3(*,5)
;newflx=total(f(450:550 ))
;f=alog10(f>1e-20)
;offset=offset+.1
;f=f+alog10(norm/newflx)-offset
;if w(0) ne wl(0) then begin
;	print,'wl arrays do not agree',w(0),wl(0)
;	stop
;	endif
;oplot,wl,f
; clean up
;
!LINETYPE=0
!ymin=oldymin
!ymax=oldymax
!PSYM=0
END
