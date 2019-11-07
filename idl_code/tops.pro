pro TOPS,orient
;90dec17-RETURN TO POSTSCRIPT FILE GENERATION WITH OPEN PS FILE-RCB
; 94may13-add orient option
!p.charthick=3
!p.thick=3
!x.thick=4
!y.thick=4
; 04nov22 - NG resets !y.style: pset			;02sep27
; the ff line FAILS to reset from portrait to landscape!
IF N_PARAMS(0) EQ 0 THEN set_PLOT,'PS' ELSE SETPS,7.5,10.,.5,.5
end
