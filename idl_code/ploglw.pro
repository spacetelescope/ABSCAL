;TO PLOT LW IUE SPECTRA ON A LOG PLOT-90JUL15 RCB
; 91AUG28-CONVERT TO NEWIDL
;
SET_XY,2000,3200
!XTICKS=12
!YTICKS=10
!XTITLE='WL (A)'
;!YTITLE='LOG FLUX!D1988!N (ERG CM!E-2!N S!E-1!N A!E-1!N)'
!YTITLE='LOG (S/F) [SR!E-1!N]'
;NEXT 2 LINES FOR BOX PLOT OPTION
PBOX,2
!PSYM=-8
oldymax=!ymax
oldymin=!ymin
        w=Lw(*,0)
	f=Lw(*,1)
; 90FEB23-GET RID OF BAD REGIONS
	BAD=WHERE ((F EQ -1.E-20) OR ((W GT 1200) AND (W LT 1230))) & NBAD=!ERR
        f=alog10(f>1e-20)
	good=where((w gt 2000) AND (W LT 3200))
;	!ymax=max(f(good))-.2
	!ymax=max(f(good))
;	!ymin=!ymax-1.5
	!ymin=!ymax-.9
IF NBAD GT 0 THEN F(BAD)=1.6E38
NULL_PLOT,W,F
PLOTDATE,'IUE]PLOGLW'
offset=0
!LINETYPE=0
!ymin=oldymin
!ymax=oldymax
!PSYM=0
END
