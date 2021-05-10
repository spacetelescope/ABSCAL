pro sdas_ascii,file,NAME
;+
; 
; Routine to read SDAS file and convert it to ascii
; Output file will have same name as input file with the .HHH changed
; to .txt
;	example:  sdas_ascii,'popdat/mrg1447.hhh','hz44'
; INPUT:
;	FILE-FULLY QUALIFIED NAME OF FILE TO CONVERT
; OUTPUT:
;	NAME-NAME OF OUTPUT FILE, AS IN NAME.TXT W/O .TXT
; HISTORY:
;	94apr8-converted from sstar_ascii-rcb
;	95JUN26-CUT OFF AT 3350A
;	2013Feb19 -convert net output to E11.3 to get blank separator for sirius
;-

	sxopen,1,file,h
	dat=sxread(1)
	W=DAT(*,0)  &  W=W(WHERE(W LT 3350))
	
;
; open output text file
;
	openw,unit,name+'.txt',/get_lun
	PRINT,'WRITE FILE: ',name+'.txt'
;
; print header
;
	n = 0
	while strmid(h(n),0,8) ne 'END     ' do begin
		printf,unit,h(n)
		n = n+1
	end
	PRINTF,UNIT,'HISTORY SDAS_ASCII.PRO '+!STIME
	PRINTF,UNIT,'HISTORY ORIG FILE='+FILE
;
; print data
;
	printf,unit,' '
	printf,unit,'   LAM    EPS    GROSS     BKG       NET/TIME ABNET'+   $
			'   TIME(sec)     SIGMA'
	printf,unit,' '
	PRINTF,UNIT,' ###    1'
	PRINTF,UNIT,' '+NAME
	for i=0,n_elements(w)-1 do PRINTF,UNIT,DAT(I,0),DAT(I,1),DAT(I,2),     $
		DAT(I,3),DAT(I,4),DAT(I,5),DAT(I,6),DAT(I,7),		       $
		FORM='(F7.1,F7.0,2I9,2E11.3,F10.2,F10.4)'
	PRINTF,UNIT,' 0 0 0 0 0 0 0 0 0'
	free_lun,unit
	return
end
