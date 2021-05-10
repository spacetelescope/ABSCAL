pro iueplot,FILE,IPLOT,fmax,wave,flux
;+
;
; Driver for sglplot.  Its only input is the IUE file name.
; use as:  FOR I=1,30 DO iueplot,'QSOSPC',33
;	USE A TITLE W/ LOG IN IT TO GET A LOG PLOT, OTHERWISE A 
;	LINEAR PLOT RESULTS.
; INPUT IS SDAS FILES--COMPARE PLTONE FOR ASCII FILES
;91jul18-newidl version djl and rcb
;91jul20-add fmax to calling seq
;93mar23-add optional wave and flux return
;-
;
;	TITLE=''
;	TITLE='FLUX (ERG CM!E-2!N S!E-1!N A!E-1!N)'
        TITLE='LOG FLUX (ERG CM!E-2!N S!E-1!N A!E-1!N)'
; SET SCALE=0 OR -2 TO TURN OFF SCALING PER *.SCALE FILE
	if (n_params(1) le 2) or (datatype(fmax) eq 'UND') then FMAX = -1.
	SCALE=0.
	IF SCALE EQ -1. THEN BEGIN
		INDEX=IPLOT
		IF IPLOT GE 150 THEN INDEX=IPLOT-32
;
; read SCALE file
; 90APR14--THIS SECTION NOT USED ANYMORE...SEE QSOMAIN.PRO-RCB
;
		close,1 & openr,1,'QSO.SCALE'
		nz = 1
		while NZ LE INDEX  do begin
			readf,1,'$(E7.1)',SCALE
			nz = nz+1
		endwhile
		FMAX = SCALE
	close,1
PRINT,' SCALE FACTOR=',FMAX
	ENDIF

		if FMAX eq 0. then goto,SKIPIT
		if n_params(0) gt 1 then NAME=FILE+STRTRIM(IPLOT,2) $
			else name=file
		sxopen,1,name,h
		x = sxread(1)
		wave = x(*,0)
		flux = x(*,5)
		err = x(*,7)*100.
		gross = x(*,2)
		back = x(*,2)-x(*,4)*x(*,6)	;89dec18-fix to smooth bkg-rcb
		eps = x(*,1)
		merged = 1			;hardcoded for merged wave-
						;length range
		sglplot,h,wave,flux,err,gross,back,eps,TITLE,FMAX,merged
; 91jul21-add history info to plots
		n=0
		Y=3500.
                while strmid(h(n),0,3) ne 'END' do begin
                        if strmid(h(n),0,11) EQ 'HISTORY SUM' THEN BEGIN
;PRINT,H(N)
				xyouts,0.,Y,STRMID(H(N),0,32),SIZE=.35,/device
				Y=Y-500.
				ENDIF
			n=n+1
			ENDWHILE
pset	;reinitialize plotting 93mar23
SKIPIT:		
end
