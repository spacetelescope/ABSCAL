pro ZPLOT,FILE,I
;
; only input is the IUE file name. Example of use:
;        FOR I=1,6 DO ZPLOT,'QSOSPC',I
;
;91MAY11
;


rd,file,i,x
rdz,!mtitle,z,ZA		;read z-EM value...3 ARG NEED TO GET QSO LIST
if !err lt 0 then begin
	print,'No Z keyword found in file '+name
	return
	endif
wave = x(*,0)
FLUX = ALOG10(x(*,5)>1.E-20)
EPS= X(*,1)
;
; find bad data points
;
        bad=where((eps le -1600) OR ((WAVE GT 1200) AND (WAVE LT 1230))) $
						& nbad=!err
IF MIN(WAVE) LT 1500 THEN BEGIN
	WMIN=1150
    END ELSE BEGIN
	WMIN=2000
	END
WMIN=FIX(WMIN/(1+Z)/200)*200
SET_XY,WMIN,WMIN+2000
;!type=
!fancy=2
!XTICKS=10
!YTICKS=7
!XTITLE='WAVELENGTH(A)'
!YTITLE='LOG FLUX (ERG CM!E-2!N S!E-1!N A!E-1!N)'
!MTITLE=!MTITLE+'  Z='+STRTRIM(STRING(Z,'(F5.3)'),2)
;
; determine yscale
;
        !Ymax=max(flux(where(((wave gt 1240.0) OR (wave Lt 1190.)) and $
                        (wave lt 3200) and (wave Gt WMIN) AND       $
                        ((wave lt 2180) or (wave gt 2210)) and        $
                        (eps gt -1600) )))
        !ymin=!ymax-1.6
	wave = x(*,0)/(1+Z)
        if nbad gt 0 then flux(bad)=1.6e38
	!C=0            ;GETS RID OF BOX ON PLOT
        null_plot,wave,flux
        PLOTDATE,'.QSO]ZPLOT'
	return
end
