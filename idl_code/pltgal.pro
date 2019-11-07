pro pltgal,FILE,IPLOT,PMAX
;+
;
; Driver for galplot.  Its only input is the IUE file name
; use as:  FOR I=1,30 DO pltgal,'galSPC.MRG',I,PMAX
; 91AUG14-ADD PMAX OPTION
;-
;
; read  line tables
;
	rdlines,'DISK$data2:[BOHLIN.gal]emabs.list',emm,emm_name,emm_off
        rdlines,'DISK$data2:[BOHLIN.QSO]absorp.list',absorp,abs_name,abs_off
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
rdf,file,iplot,x	;91jan28-read ascii file... 94mar25-change from rd
target=!mtitle
rdz,target,ze		;read z values

;READ WLSHIFT
;	RDWLSHIFT,TARGET,DWL
	wave = x(*,0)

;MAKE THE SWP WL CORR OF 1.08A ; 92jan22-should not add the 1.08 to .mrg data

	IF WAVE(0) LT 1500 THEN WAVE=WAVE+1.08

;READ THE ARTIFACT LIST-90MAR28 RCB
	ARTIF = fltarr(4) 				;WL'S OF ARTIFACTS
	openr,1,'DISK$data2:[BOHLIN.gal]ARTIFACTS.list'
	st=' '
	while strmid(st,0,8) ne target do begin
		readf,1,st				;find target
		if eof(1) then goto,NOARTIF		;target not found
		endwhile
	readf,1,'$(14X,4F6.0)',ARTIF
print,'artifacts at:',artif
NOARTIF:
;	close,1

	abs = x(*,5)
	eps = x(*,1)
	err = x(*,7)*100.0
	gross = x(*,2)
	back = x(*,2)-x(*,4)*x(*,6)
	IF N_PARAMS(0) GE 3 THEN FMAX=PMAX	
	galplot,dummy,wave,abs,eps,err,gross,back,ze,za, $
		emm,emm_name,emm_off, $
		absorp,abs_name,abs_off, $
		det_abs,det_num,ARTIF,FMAX,merged
PLOTDATE,'.gal]pltgal'
SKIPIT:
	return
end
