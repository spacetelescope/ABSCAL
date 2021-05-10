PRO FOSDIR,SUBDIR,GRNDMODE=GRNDMODE,WAVE=WAVE
;+
;
; 93SEP1-FIND ALL OBSERVATIONS FOR A PROPOSAL ID AND WRITE OUTPUT FILE
; INPUT:
;	SUBDIR-SUBDIR OF FOSDATA TO SEARCH, IF STRING LE 5 CHAR,
;		ELSE COMPLETE SUBDIR NAME
;	GRNDMODE-OPTIONAL KEYWORD EXAMPLE TO RESTRICT THE SEARCH, EG:
;		GRNDMODE='TARGET ACQUISITION,
;		GRNDMODE=['LED-FLAT-FIELD-MAP','SPECTROSCOPY','IMAGE'] (DEFAULT)
;		USE GRNDMODE='' TO GET ALL GRNDMODES
; 93SEP13-ADD TARGET AND MORE ROBUST DATE SEARCH TO OUTPUT
; 93OCT22-MOD TO WORK FOR A RANDOM LINDLER DIR
; 93OCT26-PRINT DISK + DIR IN FIRST OUTPUT LINE TO MAKE MODS TO FOSOBS WORK
; 93nov12-add propid to output and omit pre-1991.0 data
; 94jan15-ck for upper or lower ybase on C1,A2,A3,A4 and add to output
; 94JAN27-ADD WAVE KEYWORD TO OVERIDE NEW DEFAULT OF NOT WRITING WAVECAL SPEC
; 94jul26-tack on exp time
; 95apr10-mod to work when .shh in my dir and the only .c5h is in lindler dir,
;	i.e. when subdir = 'stddata:'
; 96feb9-move up test for wrong grndmode ahead of midybs bit
; 96apr22-trap IO err if no .c5h file for expo time. Get time from exposure/4.
; 96jul30-lengthen targname field from 12 to 14 char for NGC6822-OB13-9
; 96sep20-since i do not get/need d0 files anymore, change default to find *.c5h
;-
;
pairs=['C-1','A-2','A-3','A-4']		;PAIRED APERTURES
fgwas =[['H13','H19','H27','H40','H57','L15','L65','PRI'],	$	;BLUE
        ['H19','H27','H40','H57','H78','L15','L65','PRI']]		;RED
; MIDDLE POSITION YBASES FROM CAL/FOS 110 CORRES TO ABOVE FGWAS
MIDYBS=[[-661,-1017,-1647,291,237,-902,-708,-778],		$
	[-316,349,-1401,-1506,257,-227,-351,-344]]

; SET UP DEFAULT KEYWORD GRNDMODE

IF NOT KEYWORD_SET(GRNDMODE) THEN 		$
		GRNDMODE=['LED-FLAT-FIELD-MAP','SPECTROSCOPY','IMAGE']

;sea for .d0h files, as .shh files are always assoc, and do trick for djl .c5h
;IF STRLEN(SUBDIR) LE 5 THEN FIL='DISK$DATA2:[BOHLIN.FOSDATA.'+SUBDIR+']y*.d0H'$
IF STRLEN(SUBDIR) LE 5 THEN FIL='DISK$DATA2:[BOHLIN.FOSDATA.'+SUBDIR+']y*.c5h' $
		ELSE FIL=SUBDIR+'y*.d0H'
RES=FINDFILE(fil)	;LIST OF FILES IN SUBDIR
if res(0) eq '' then begin
	IF STRLEN(SUBDIR) LE 5 THEN 			$
		FIL='DISK$DATA2:[BOHLIN.FOSDATA.'+SUBDIR+']*.c5H'  $
                ELSE FIL=SUBDIR+'*.c5H'		;for lindler dir w/o d0h files
	RES=FINDFILE(fil)	;LIST OF FILES IN SUBDIR
	endif
PRINT,'SEARCH IN DIR= FOR GRNDMODE=',FIL,GRNDMODE
SIZ=SIZE(RES)
NOBS=SIZ(1)-1
SUBNAM=SUBDIR
IF STRLEN(SUBDIR) GT 5 THEN SUBNAM=''
CLOSE,1  & OPENW,1,'DIR'+SUBNAM+'.LOG'	;OPEN OUTPUT FILE W/ FOSOBS NAME CONVEN
FDECOMP,RES(0),DISK,DIR,ROOTNAME,EXT
PRINTF,1,disk+dir
PRINTF,1,'SEARCH FOR *.',EXT

FOR I=0,NOBS DO BEGIN
	SXHREAD,RES(I),HEAD
	GRNDTST=STRTRIM(SXPAR(HEAD,'GRNDMODE'),2)
; 95jun2-skip for target acq, as i deleted the *.c5 t/acq files in 5658!
;********NOTE targ/acq searches will still fail on such cases! So i would need
;	to replace the *.c5 files or omit the exp time bit below for t/aqc.
	ck=where(GRNDMODE EQ GRNDTST)
	IF ((GRNDMODE(0) ne '') and (ck(0) eq -1)) THEN goto,skipitall

	FDECOMP,RES(I),DISK,DIR,ROOTNAME,EXT
	DETECTOR=STRTRIM(SXPAR(HEAD,'DETECTOR'))
	IF DETECTOR EQ 'AMBER' THEN DETECTOR='RED'
	FGW=STRTRIM(SXPAR(HEAD,'FGWA_ID'),2)
	APER=STRTRIM(SXPAR(HEAD,'APER_ID'),2)
	DUM=WHERE(APER EQ PAIRS,COUNT)
	IF COUNT GT 0 THEN BEGIN ;SPECIAL PROCESSING TO FIND LOW OR UP OF PAIRS:
		IDET=0 & IF DETECTOR EQ 'RED' THEN IDET=1
		INDX=WHERE(FGW EQ FGWAS(*,IDET))  &  INDX=INDX(0)
		MIDY=MIDYBS(INDX,IDET)
		YBASE=FLOAT(SXPAR(HEAD,'YBASE'))
		IF YBASE GT MIDY THEN APER=APER+'U' ELSE APER=APER+'L'
;PRINT,DETECTOR,APER,FGW,IDET,INDX,MIDY,YBASE		;DEBUG
		ENDIF
        targ=strtrim(SXPAR(HEAD,'TARGNAM1'),2)
        if !err lt 0 then targ=strtrim(SXPAR(HEAD,'TARGNAME'),2)

	GRNDPRT=STRMID(STRTRIM(SXPAR(HEAD,'GRNDMODE'),1),0,12)
	YSTEPS=STRTRIM(SXPAR(HEAD,'YSTEPS'),2)
	DATE=STRTRIM(SXPAR(HEAD,'DATE-OBS'),2)
	TIME=STRTRIM(SXPAR(HEAD,'TIME-OBS'),2)
	date=date+':'+time				;95jun7
        if ((!err lt 0) or (strpos(date,'/') gt  0)) then BEGIN
		SXHREAD,DISK+DIR+ROOTNAME+'.SHH',H
		DATE=strmID(SXPAR(H,'PSTRTIME'),0,17)	;95jun7-get all of date
		TIME=strmID(SXPAR(H,'PSTRTIME'),9,8)
		ENDIF
	date=absdate(date)  &  date=date(0)	; convert to frac of year
	propid=STRTRIM(SXPAR(HEAD,'PROPOSID'),2)
        GROUP=SXPAR(HEAD,'GCOUNT')
; must use .c5h for exptime, as d0h has 0 values
; case of .c5 in lindler dir:
	if strupcase(subdir) eq 'STDDATA:' THEN BEGIN
		djlfil=findfile(subdir+rootname+'.c5h')	; not always a djl fil
		fdecomp,djlfil(0),disk,dir
		endif
	on_ioerror,NOc5				;96apr22, since all .c* deleted
; test for presence of .c5h
	close,7  &  openr,7,disk+dir+ROOTNAME+'.c5h'	
	close,7  &  sxopen,7,disk+dir+ROOTNAME+'.c5h'
	dum=sxread(7,group-1,gpar)
        EX=SXGPAR(HEAD,GPAR,'EXPOSURE')
;OLD STYLE KEYWD
; 95oct2 - fix for 1992 data from propid=2581
        IF (!ERR EQ -1) or (ex le .1) or (ex gt 10000) THEN begin
		if !err ne -1 then print,'Assume bad fos group exp time=',ex
NOc5:
		EX=SXPAR(HEAD,'EXPTIME')/4		;add /4 96apr22
		print,'No .c5h or bad exp time. Use header exp time/4=',ex
		endif
 ; SKIP WAVES BY DEFAULT:
	IF (NOT KEYWORD_SET(WAVE)) AND (TARG EQ 'WAVE') THEN BEGIN
		PRINT ,'NOT OUTPUT: ',ROOTNAME,DETECTOR,FGW,APER,TARG,      $
				GRNDPRT,YSTEPS,DATE,TIME,propid
			goto,skipitALL
			endif
	SIZ=SIZE(GRNDMODE)
	IF SIZ(0) EQ 0 THEN NMODES=0 ELSE NMODES=SIZ(1)-1
	FOR J=0,NMODES DO BEGIN
		IF ((GRNDMODE(0) EQ '') OR (GRNDMODE(J) EQ GRNDTST)) THEN begin
		    if date lt 1991.0 then begin
			print,'Observation in 1990 not written to output file'
			PRINT ,ROOTNAME,DETECTOR,FGW,APER,TARG,      $
				GRNDPRT,YSTEPS,DATE,TIME,propid
			goto,skipit
			endif
		     FMT='(A10,A5,A4,A5,1X,A14,A13,A3,f9.3,A9,a6,f7.1)
		     PRINTF,1,FORM=FMT,ROOTNAME,DETECTOR,FGW,APER,TARG,      $
				GRNDPRT,YSTEPS,DATE,TIME,propid,ex
		     endif
SKIPIT:
		ENDFOR	; end nmodes loop
skipitALL:
	ENDFOR		;nobs loop
CLOSE,1
END
