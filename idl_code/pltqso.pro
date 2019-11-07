pro pltqso,FILE,IPLOT
;
; Driver for galplot.  Its only input is the IUE file name
; use as:  FOR I=1,30 DO pltqso,'galSPC',I

;
; read  line tables
;
	rdlines,'DISK$USER2:[BOHLIN.qso]emline.list',emm,emm_name,emm_off
        rdlines,'DISK$USER2:[BOHLIN.QSO]absorp.list',absorp,abs_name,abs_off
;
; SET SCALE=0 OR -2 TO TURN OFF SCALING PER *.SCALE FILE
	FMAX = -1.
	SCALE=-2.
	IF SCALE EQ -1. THEN BEGIN
		INDEX=IPLOT
		IF IPLOT GE 150 THEN INDEX=IPLOT-32
;
; read SCALE file
;
		close,1 & openr,1,'[BOHLIN.QSO]QSO.SCALE'
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

fdecomp,file,disk,dir,name,ext
if strupcase(ext) eq 'MRG' then merged=1 else merged=0
rd,file,iplot,x				;91jan28-read ascii file
rdz,!mtitle,ze,za		;read z values
	wave = x(*,0)

;READ WLSHIFT...91aug1--note cannot apply wl corr to merged spectra AND
;	the header h is not avail anyhow (easily) w/ the asci version
;	target=!mtitle			;91aug1-patch
;	RDWLSHIFT,TARGET,DWL
;MAKE THE SWP WL CORR OF 1.08A AND THE CORRECTION FOR THE DWL FOR SWP EXCEPT
;QSO 1634+706, WHERE DWL IS FOR THE LW. THERE ARE 3 DWL'S FOR 0121-590.
;	IF WAVE(0) LT 1500 THEN WAVE=WAVE+1.08
;	IF (WAVE(0) LT 1500) AND (TARGET NE '1634+706') $
;		AND (TARGET NE '0121-590') $
;	THEN WAVE=WAVE-DWL(0)*1.1797
;	IF (WAVE(0) GT 1500) AND (TARGET EQ '1634+706') $
;		THEN WAVE=WAVE-DWL(0)*1.8693
;	IF (TARGET EQ '0121-590') AND (WAVE(0) LT 1500) THEN BEGIN
;	n=0
;	while strmid(h(n),0,13) ne 'HISTORY L-AP:' do n=n+1
;	SWPNO=STRMID(H(N),17,5)
;	IF SWPNO EQ '27399' THEN WAVE=WAVE-DWL(0)*1.1797
;	IF SWPNO EQ '28633' THEN WAVE=WAVE-DWL(1)*1.1797
;	IF SWPNO EQ ' 1804' THEN WAVE=WAVE-DWL(2)*1.1797
;	ENDIF
;
;READ THE ARTIFACT LIST-90MAR28 RCB
	ARTIF = fltarr(4) 				;WL'S OF ARTIFACTS
	openr,1,'DISK$USER2:[BOHLIN.QSO]ARTIFACTS.list'
	st=' '
	while strmid(st,0,8) ne !mtitle do begin
		readf,1,st				;find target
		if eof(1) then goto,NOARTIF		;target not found
		endwhile
	readf,1,st
	st = strtrim(st,2)
	for i=0,2 do artif(i) = strtrim(gettok(st,' '))
NOARTIF:
	close,1

	abs = x(*,5)
	eps = x(*,1)
	err = x(*,7)*100.0
	gross = x(*,2)
	back = x(*,2)-x(*,4)*x(*,6)

	galplot,!MTITLE,wave,abs,eps,err,gross,back,ze,za, $
		emm,emm_name,emm_off, $
		absorp,abs_name,abs_off, $
		det_abs,det_num,ARTIF,FMAX,merged
SKIPIT:
	return
end
