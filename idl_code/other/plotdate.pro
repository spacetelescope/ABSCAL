pro plotdate,PROG,Name,x,y
;+
;
; plotdate,PROG,Name,x,y
;
; put the system time and date on the lower right hand corner of a plot.
;
;-
  
  IF N_PARAMS(0) EQ 0 THEN PROG='INTERACTIVE'
  TMP=!P.CHARTHICK
  !P.CHARTHICK=1

; 2015sep29 xyouts,14000.,-600.,'Bohlin: '+PROG+'  '+STRMID(!stime,0,17),SIZE=.5,/device
xyouts,14000.,-500.,'Bohlin: '+PROG+'  '+STRMID(!stime,0,17),SIZE=.5,/device

  !P.CHARTHICK=TMP
  return
end
