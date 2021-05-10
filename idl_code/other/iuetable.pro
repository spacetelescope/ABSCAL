PRO IUETABLE,NAME,first,last

;
; procedure to make summary file of data read from tape
; to use type: iuetable,'qsospc',1,110
;
CLOSE,2
OPENW,2,'IUETABLE.TXT'
FOR I=first,last DO BEGIN
 FNAME=NAME+STRtrim(I,2)
 SxOPEN,1,FNAME,HEAD
 number = string(i)
 for j = 0,n_elements(head)-1 do begin 
    IF STRMID(head(j),8,6) EQ 'SUM OF' THEN BEGIN
	HIST=STRMID(head(j),8,32)+STRMID(head(j),48,30)
	PRINTF,2,number+'  '+HIST
	number = '        '
	ENDIF
 end
END
CLOSE,2
RETURN
END
