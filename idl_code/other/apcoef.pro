pro apcoef,refap,reflist
;+
;
; PURPOSE:
;	AVERAGE indiv coef (*.*cf) files and write sdas (apcoef.tab) and ascii
;		(fosap.coef) tables of avg aper transm for pipeline use. 
; APCOEF,refap,reflist
; INPUT: refap='A-1', normally
;	 reflist-ascii list of any propids that are used in denom only, eg 4776
; OUTPUT: apcoef.tab for delivery and fosap.coef equiv ascii file
; EXAMPLE: apcoef,'A-1','4776'
; 94jan28-add rows of unity c0 for refap
; 94FEB1-AVERAGE UPPER AND LOWER APERTURES OF PAIRS
; 94jun17-add col of aper_pos w/ values of single, lower, or upper
; 94JUN20-AUTOMATE FINDING LIST OF PROPOSAL ID's and add reflist input, which is
;		used only for the output header history.
;-

CLOSE,2 & OPENW,2,'FOSAP.COEF'
PRINTF,2,'OUTPUT OF APCOEF.PRO AND APFIT.PRO ',!STIME
PRINTF,2,'SUMMARY OF AVERAGE FOS APERTURE COEFICIENTS'
PRINTF,2,''
PRINTF,2,'DETEC FGWA APER APRPOS      C0           C1           C2',	$
		'       WMIN    WMAX  NAV',FORM='(2A)'
COEF=FLTARR(3)
WMIN=FLTARR(2)
WMAX=FLTARR(2)
H=STRARR(1)
propids=''
NROW=-1
AVCOEF=FLTARR(3,2)
TAB_CREATE,TCB,TAB
NAV=1				;NUMBER OF SETS OF COEF AVERAGED PER MODE
files=findfile('*.*cf',count=loop)	;FIND FILES TO PROCESS
FDECOMP,FILES(0),DISK,DIR,NAME,QUAL

FOR I=0,LOOP-1 DO BEGIN
	CLOSE,1 & OPENR,1,NAME+'.'+QUAL
	if strpos(propids,strmid(qual,0,4)) eq -1 then propids=      $
						propids+','+strmid(qual,0,4)
	NWL=-1			;NUMBER OF WL INTERVALS PER MODE
	WHILE NOT EOF(1) DO BEGIN ; SUBLOOP FOR MULTIPLE WL INTERVALS
		NWL=NWL+1
		READF,1,COEF,WMN,WMX
		AVCOEF(*,NWL)=AVCOEF(*,NWL)+COEF
		WMIN(NWL)=WMN
		WMAX(NWL)=WMX
		ENDWHILE
	LSTNAM=STRMID(NAME,0,7)
	LSTUPLO=STRMID(NAME,7,1)
; LSTNAM-CURRENT FILE TO PROCESS... NAME IS NEXT FILE:
	IF I NE LOOP-1 THEN FDECOMP,FILES(I+1),DISK,DIR,NAME,QUAL
;WRITE AVG COEF AFTER FINDING ALL OF THE ONES W/ SAME 'NAME',BUT DIF QUAL=PROPID
;    TREAT UPPER AND LOWER AS SAME APER FOR AVERAGING:
        IF (LSTNAM NE STRMID(NAME,0,7)) OR (I EQ LOOP-1)   $
					  THEN BEGIN

		AVCOEF=AVCOEF/NAV
		pair=1
		if (LSTUPLO EQ 'U') then pair=2
		for ipair=1,pair do begin
			if ipair eq 1 then aperpos='LOWER'
			if ipair eq 2 then aperpos='UPPER'
			if pair  eq 1 then aperpos='SINGLE'
		FOR J=0,NWL DO BEGIN
			NROW=NROW+1
			DET='BLUE '
			IF STRMID(LSTNAM,0,1) EQ 'R' THEN DET='AMBER'
			TAB_PUT,'DETECTOR',DET,TCB,TAB,NROW
			FGWA=STRMID(LSTNAM,1,3)
			TAB_PUT,'FGWA_ID',FGWA,TCB,TAB,NROW
			APER=STRMID(LSTNAM,4,3)
			TAB_PUT,'APER_ID',APER,TCB,TAB,NROW
			TAB_PUT,'APER_POS',APERpos,TCB,TAB,NROW
			C0=AVCOEF(0,J)
			TAB_PUT,'C0',C0,TCB,TAB,NROW
			C1=AVCOEF(1,J)
			TAB_PUT,'C1',C1,TCB,TAB,NROW
			C2=AVCOEF(2,J)
			TAB_PUT,'C2',C2,TCB,TAB,NROW
			TAB_PUT,'WMIN',WMIN(J),TCB,TAB,NROW
			TAB_PUT,'WMAX',WMAX(J),TCB,TAB,NROW
			TAB_PUT,'NUM_AVG',NAV,TCB,TAB,NROW
			PRINTF,2,DET,FGWA,APER,aperpos,AVCOEF(*,J),WMIN(J),    $
				WMAX(J),NAV,                                   $
				FORM='(3A5,a7,3e13.5,2f8.2,I2)'
			ENDFOR	; end j loop
			ENDFOR	; end ipair loop
		NAV=1
		AVCOEF=FLTARR(3,2)
		ENDIF ELSE BEGIN
			NAV=NAV+1
			ENDELSE
	ENDFOR

;94JAN28-TACK ON refap DEFAULTS FOR DJL
fgwas = ['H13','H19','H27','H40','H57','H78','L15','L65','PRI']
for i=0,8 do begin			; 9 fgwas
	for idet=0,1 do begin		; 2 detectors
		NROW=NROW+1
		det='BLUE' & if idet eq 1 then det='AMBER'
		TAB_PUT,'DETECTOR',DET,TCB,TAB,NROW
		TAB_PUT,'FGWA_ID',FGWAs(i),TCB,TAB,NROW
		TAB_PUT,'APER_ID',refap,TCB,TAB,NROW
		TAB_PUT,'APER_POS','SINGLE',TCB,TAB,NROW
		TAB_PUT,'C0',1,TCB,TAB,NROW
		TAB_PUT,'C1',0,TCB,TAB,NROW
		TAB_PUT,'C2',0,TCB,TAB,NROW
		TAB_PUT,'WMIN',0,TCB,TAB,NROW
		TAB_PUT,'WMAX',9999.,TCB,TAB,NROW
		TAB_PUT,'NUM_AVG',0,TCB,TAB,NROW
		ENDFOR
	ENDFOR

SXADDPAR,H,'DATE',!STIME,'CREATION DATE BY APCOEF.PRO AND APFIT.PRO'
SXADDPAR,H,'REF_APER','A-1'
SXADDHIST,'SUMMARY OF AVERAGE FOS APERTURE CORRECTIONS',H
SXADDHIST,'THE 3 COEF ARE QUADRATIC FITS AS A FUNCTION OF WAVELENGTH',H
if (n_params(0) ge 2) then propids=propids+','+reflist
SXADDHIST,'DATA FROM PROPIDS='+strmid(propids,1,strlen(propids)),H
TAB_WRITE,'APCOEF.TAB',TCB,TAB,H
CLOSE,1
CLOSE,2
END
