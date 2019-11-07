FUNCTION FOSTIT,HEADER,GPAR
;+
;
; NAME:
;	FOSTIT
; PURPOSE:
;	TO CONSTRUCT A NICE !MTITLE FROM A FOS HEADER
; CALLING SEQUENCE:
;	fosTIT(header,gpar)
; INPUTS:
;	HEADER - AN FOS HEADER
;	GPAR   - FOS GROUP PARAM BLOCK
; OUTPUTS:
;	NICE TITLE
; 93AUG14 - RCB
; 93aug20 - add rootname
; 94jul26 - compute upper or lower for paired apers per fosdir.pro
;-

fgwas =[['H13','H19','H27','H40','H57','L15','L65','PRI'],      $       ;BLUE
        ['H19','H27','H40','H57','H78','L15','L65','PRI']]              ;RED
; MIDDLE POSITION YBASES FROM CAL/FOS 110 CORRES TO ABOVE FGWAS
MIDYBS=[[-661,-1017,-1647,291,237,-902,-708,-778],              $
        [-316,349,-1401,-1506,257,-227,-351,-344]]

	pairs=['C-1','A-2','A-3','A-4']         ;PAIRED APERTURES
	SIDE=STRTRIM(SXPAR(HEADER,'DETECTOR'),2)
	IF SIDE EQ 'AMBER' THEN SIDE='RED'
        EXPTM= 'EXPOSURE'
        for i=1,sxpar(HEADER,'pcount') do $
                if strtrim(sxpar(HEADER,'ptype'+strtrim(i,2))) eq 'EXPTIME' $
                then EXPTM= 'EXPTIME'
        targnam=strtrim(SXPAR(HEADER,'TARGNAM1'),2)
        if !err lt 0 then targnam=strtrim(SXPAR(HEADER,'TARGNAME'),2)
        FGW=STRTRIM(SXPAR(HEADer,'FGWA_ID'),2)
        APER=STRTRIM(SXPAR(HEADer,'APER_ID'),2)
        DUM=WHERE(APER EQ PAIRS,COUNT)
        IF COUNT GT 0 THEN BEGIN ;SPECIAL PROCESSING TO FIND LOW OR UP OF PAIRS:
                IDET=0 & IF side EQ 'RED' THEN IDET=1
                INDX=WHERE(FGW EQ FGWAS(*,IDET))  &  INDX=INDX(0)
                MIDY=MIDYBS(INDX,IDET)
                YBASE=FLOAT(SXPAR(HEADer,'YBASE'))
                IF YBASE GT MIDY THEN APER=APER+'U' ELSE APER=APER+'L'
		endif
	MTITLE=TARGNAM+' '+SIDE+' '+fgw+' '+aper+			    $
; SOME OLD GARBAGE HEADERS LIKE IN PROPID=2811 GIVE A FLOAT ERROR IN FF LINE
;     DON'T WORRY
	' T(SEC)='+STRTRIM(STRING(SXGPAR(HEADER,GPAR,EXPTM)),2)+'/XSTEP '+  $
		strtrim(sxpar(header,'ROOTNAME'),2)
RETURN,MTITLE
END
