PRO FOSRD,NAME,HEADER,GPAR,WAVE,counts,QUAL,MASK,serr,bkgr,		$
		flux=flux,sctval=BKG,scterr=scterr,SILENT=SILENT,trim=trim,    $
		noflux=noflux,tot=tot
;+
;
; NAME:
;	FOSRD
; PURPOSE:
;	Read in count rate file and associated mask and wavelength files
;	Subtract scattered light
; CALLING SEQUENCE:
;	fosrd,name,header,gpar,wave,counts,qual,mask,serr,bkgr,	$
;		flux=flux,sctval=sctval,scterr=scterr,SILENT=SILENT,trim=trim, $
;		noflux=noflux
; INPUTS:
;	name - rootname of observation
; OUTPUTS:
;	header - FITS header
;	gpar - group parameters for last group read
;	wave - template wavelength array
;	counts - COUNT rate of observation
;	qual - data quality array as output by CALFOS into *.cqh/cqd file
;	mask - mask for points used in calculating ratio to standard flux
;	serr - statistical uncertainty array (c2*)
;	bkgr - DARK count rate (c7*)
; KEYWORDS:
;	flux-added as a keyword that is transparent to OLD code
;		to get flux from .c1 files instead of counts
;		and making the use of jdn fosrdflx unnecessary. 
;       sctval-value of any scattered light subtraction (counts/sec)
;       scterr-uncertainty in sctval
;	silent - if present, no output to screen
;	trim   - to trim out zero wl's (eg in prism) and reverse backward wl
;		 array... NOTE: some arrays will be shorter than 2064!
;	noflux - if set, do not try to read .c1 files
;	tot - vector of 3 elements giving masked .c5h total in each of the
;		three ysteps.
; HISTORY:
;	90NOV01-TO READ FOS WL AND COUNTS AND FLUX-rcbohlin
;	90DEC25-BEGIN MOD TO BE THE GENERAL PURPOSE FOS READ ROUTINE-rcb
;	90DEC30-BEGIN THE SMARTENING PROCESS WITH PICKING THE MAX OF
;		3YSTEP CAL DATA-rcb
;	91DEC05-ADDED READING OF DATA QUALITY FILE-jdn
;	91DEC18-ADDED CREATING MASK VECTOR-jdn
;	92MAY06-USES ALL THREE YSTEPS NORMALIZED TO BRIGHTEST YSTEP-jdn
;	92dec  -start to convert back to be useful for my GO data. copied jdn
;		version from disk$user1:[neill.fos.abscal.pro]-rcb
;	93APR1 -ADDED OPTIONAL PRINT FOR FILE 11
;	93jun24-get wl's via FOS_wave
;	93JUL31-IF EXTENT IS SPECIFIED ON NAME, JUST GET W, C, FLUX AND RETURN
;	93aug2-move gpar from c to q sxread to read .hhh simple files
;	93aug11-trim zero wavelengths and reverse backward wl cases, if /TRIM
;	93aug12-add stat error array (cq*) and background (c7*) to calling seq
;	93aug16-update good region definition for PRI-RED and for zero counts 
;				in the 3 ystep case.
;	93AUG19- for pri-red (1985:2063) SET WL=0
;	93aug16-set qual=180 for zero wl regions--see STSDAS CALIB GUIDE p 4-17
;	93AUG16-ADD SCATT LITE BKG FOR PRI-BLUE***--> incompat w/ OLD abs calib!
;	93aug19-delete neg limit for SCAT bkg subtraction
;	93aug25-account for fill data in 3 ystep case
;	93oct27-ADDED KEYWORD-FLUX
;	93nov5-ADDED KEYWORDS-SCTVAL,SCTERR w/ reading ck from header grp param
;	94jan13-add /noflux keyword to avoid trying to read .c1h files in the 
;		old JDN data... also go back to reading .c1h if ext is specified
;	94apr1-fix bug that gave sct_val=0 before
;	94may11 - DJL, changed to normallize to center ystep
;-

STAT=FSTAT(11)
IF N_PARAMS(0) EQ 0 THEN BEGIN
	PRINT,'FOSRD,NAME,HEADER,GPAR,WAVE,counts,QUAL,MASK,serr,bkgr,',    $
	    'FLUX=FLUX,SCTVAL=SCVAL,SCTERR=SCTERR,/SILENT,/trim,/noflux,tot=tot'
	RETALL
	ENDIF
;
;
; OPEN INPUT counts FILE
	ext='.c5h'
	len=strlen(name)
	if strmid(name,len-4,1) eq '.' then ext=''	;DO NON-C1 OR C5 FILE
	sxopen,1,NAME+ext,HEADER			
	GROUP=strtrim(SXPAR(HEADER,'GCOUNT'),2)
	GRAT=STRUPCASE(STRTRIM(SXPAR(HEADER,'FGWA_ID'),2))
	DET=STRMID(STRUPCASE(STRTRIM(SXPAR(HEADER,'DETECTOR'),2)),0,1)
	IF DET EQ 'A' THEN DET='R'
	GRCASE=GRAT+DET
	if ext NE '' then sxopen,2,NAME+'.cqh'
	if not keyword_set(noflux) then sxopen,5,NAME+'.c1h'	;ABS FLUX
	bkg=0. & scterr=0	;initialize scat lite bkg & uncertainty
; n_params=8 test-93nov5 in order to make gpar reading of scat's tidy
;
; GET TEMPLATE WAVELENGTHS AND MASK VECTORS
;	GET_TWAVE,HEADER,WAVE,MASK	;rcb comment out
; 92dec18-this above routine pulls out the wl vectors w/ date 91jun24 from
;	DISK$DATA5:[NEILL.WAVREF], while
;	the latest dispersion coef in cdbs are dated 91dec20 from Wm. blair.
;	See his ISR CAL/FOS 70. The external offsets are incl. So until I get
;	ambitious enough to install the new wl vectors, read the PODPS .c0* WL
;	scales, which differ from 91jun24 values by .18-.19A for H13-rcb.
; 93apr15-djl says that we will not resurrect the get_twave nonsense, but will
;       instead rerun all the data thru calfos anytime wavelengths change.
;        sxopen,3,NAME+'.c0h',HEADER		;wavelength files
;        WAVE=SXREAD(3,GROUP-1,GPAR)
;        CLOSE,3
; 93-june-25: convert to lindler's wl from avg disp.constants
;	wave=fos_wave(det,grat) 
; 93aug3-back to more general get_twave (lindler version) as masks are needed
	GET_TWAVE,HEADER,WAVE,MASK
	if grcase eq 'PRIR' then WAVE(1985:2063)=0	;PATCH BAD WL ARRAY

;
; 90DEC30-PICK MAX counts FROM 3 YSTEP ABS CAL DATA
; ********************* BEGIN 3 YSTEP SECTION *********************************
;
	IF SXPAR(HEADER,'YSTEPS') EQ 3 THEN BEGIN
		C=FLTARR(2064,3)
		Q=FLTARR(2064,3)
		QUAL=FLTARR(2064)
		qgcount=intarr(3)
		TOT=FLTARR(3)
;
; 92MAY07-RESTRICT WAVELENGTH RANGE FOR ALL CONFIGS
		case grcase of
		'H19R': BEGIN & WMIN=1650 & WMAX=2300 & END
		'H27R': BEGIN & WMIN=2250 & WMAX=3250 & END
		'H40R': BEGIN & WMIN=3250 & WMAX=4750 & END
		'H57R': BEGIN & WMIN=4600 & WMAX=6800 & END
		'H78R': BEGIN & WMIN=6300 & WMAX=7800 & END
		'L15R': BEGIN & WMIN=1650 & WMAX=2400 & END
		'L65R': BEGIN & WMIN=3700 & WMAX=6900 & END
		'PRIR': BEGIN & WMIN=2200 & WMAX=8700 & END
		'H13B': BEGIN & WMIN=1250 & WMAX=1580 & END
		'H19B': BEGIN & WMIN=1600 & WMAX=2300 & END
		'H27B': BEGIN & WMIN=2250 & WMAX=3250 & END
		'H40B': BEGIN & WMIN=3300 & WMAX=4700 & END
		'L15B': BEGIN & WMIN=1300 & WMAX=2400 & END
		'PRIB': BEGIN & WMIN=1850 & WMAX=5500 & END    ;93feb10 was 2200
		 else : BEGIN & WMIN=MIN(WAVE)  &  WMAX=MAX(WAVE) & END
		endcase

;
; pick last three groups, in CASE OF POSSIBLE MULT READOUTS
;   ALL FILES not PRESENT in [...3106] eg-so ck for # of arguments
		I = 0
		qmax=0				; count for good data qual
		FOR IG = GROUP-3,GROUP-1 DO BEGIN
			C(0,I)=SXREAD(1,IG)
			Q(0,I)=SXREAD(2,IG,gpar)
			dum=where(((WAVE GE WMIN) AND (WAVE LE WMAX)   $
				     and (Q(*,i) lt 100)),qgood)
			qgcount(i)=qgood	;good qual count for each ystep
			if qgood gt qmax then qmax=qgood
			I = I + 1
			ENDFOR

		if qmax le 20 then begin	;idiot check
			print,'stop in fosrd, because all pts bad qual'+ $
				' except ',qmax
			stop
			endif

        	bad=bytarr(2064)	;positive count ck initializion
		for i=0,2 do bad=(bad or (c(*,i) gt 0))
		GOOD=WHERE((WAVE GE WMIN) AND (WAVE LE WMAX) and (bad gt 0))
		if grcase eq 'PRIR' then good=good(where(good le 1984))
		for i=0,2 do begin
;require 90% of max good qual in each y-step
			if qgcount(i) ge .9*qmax then TOT(I)=TOTAL(C(GOOD,I))
			endfor
		TMAX=MAX(TOT)
		TCENTER = TOT(1)
		IF TCENTER/TMAX LT 0.8 THEN TCENTER=TMAX ; USE MAX YSTEP IN THIS
							 ;    CASE
		NUM=0
		sum=0 & esum=0 & bsum=0 & fsum=0
		IF N_PARAMS(0) GE 8 THEN BEGIN	;GET SERR,BKGR,flux IF REQUESTED
			sxopen,3,NAME+'.c2h'	;STAT ERR
			sxopen,4,NAME+'.c7h'	;DARK
			endif
		I=-1
		FOR IG = GROUP-3,GROUP-1 DO BEGIN	;main 3ystep loop
			I=I+1
			IF TOT(I)/TMAX GT .8 THEN BEGIN
				NUM = NUM + 1
				SUM = SUM + C(*,I) * TCENTER / TOT(I)
				if not keyword_set(noflux) then		$
				      FSUM=FSUM+SXREAD(5,IG,gpar)*TCENTER/TOT(I)
				sctvl=sxgpar(header,gpar,'sct_val')
				if !err eq -1 then sctvl=!err
				if sctvl ne -1 then begin
					bkg=bkg+sctvl
					scterr=scterr+sxgpar(header,gpar,      $
							            'sct_err')
					endif
				IF N_PARAMS(0) GE 8 THEN BEGIN
; DO NOT BOTHER W/ RISK OF 0 FOR 1/ERR^2 AVG, AS ERRORS ARE ~SAME FOR EACH STEP
					ESUM=ESUM + SXREAD(3,IG) * $
								TCENTER / TOT(I)
; BKG NOT SCALED FOR YBASE ERROR
					BSUM=BSUM + SXREAD(4,IG)
					endif
				QF = WHERE(Q(*,I) GT QUAL,NBAD)  ;NBAD=# GT
				IF NBAD GT 0 THEN QUAL(QF) = Q(QF,I)
				ENDIF
			ENDFOR
		bad=where(wave le 0,NBAD)
		if NBAD gt 0 then qual(bad)=180
		if grcase eq 'PRIR' then qual(1985:2063)=180
		counts=SUM/NUM
		SERR=ESUM/NUM
		BKGR=BSUM/NUM
		FLUX=FSUM/NUM
		bkg=bkg/num  &  scterr=scterr/num
		IF NOT KEYWORD_SET(SILENT) THEN BEGIN
			PRINT,'3 YSTEPS RATIOS=',TOT/TCENTER
			PRINT,'# USED FOR counts=',NUM,' BKG=',BKG
			IF STAT.OPEN THEN BEGIN
  	        	        PRINTF,11,'3 YSTEPS RATIOS=',TOT/TCENTER
        	                PRINTF,11,'# USED FOR counts=',NUM
				ENDIF
		ENDIF
; NON-3 YSTEP CASE:
	END ELSE BEGIN
		counts=SXREAD(1,GROUP-1)
		if not keyword_set(noflux) then FLUX=SXREAD(5,GROUP-1,gpar)
		sctvl=sxgpar(header,gpar,'sct_val')
		if !err eq -1 then sctvl=!err
		if sctvl ne -1 then begin
			bkg=sctvl
			scterr=sxgpar(header,gpar,'sct_err')
			endif
		if ext NE '' then begin
			QUAL=SXREAD(2,GROUP-1,GPAR) & bad=where(wave le 0,NBAD)
	                if NBAD gt 0 then qual(bad)=180
			if grcase eq 'PRIR' then qual(1985:2063)=180
			endif
		IF N_PARAMS(0) GE 8 THEN BEGIN	;GET SERR AND BKGR, IF REQUESTED
			sxopen,1,NAME+'.C2H',HEADER	;FLUX UNCERT.
			SERR=SXREAD(1,GROUP-1)
			sxopen,1,NAME+'.C7H',HEADER	;PARTICLE-DARK COUNTrate
			BKGR=SXREAD(1,GROUP-1)
			ENDIF
	ENDELSE
CLOSE,1
CLOSE,2
;
; subtract scattered light background
;
	if sctvl eq -1 then begin	;hand calc of bkg for old style process.
		MNB=0 & MXB=0
		case grcase of
		'H13B': BEGIN & MNB=30 & MXB=129 & END
		'PRIR': BEGIN & MNB=0  & MXB=899 & END
		'PRIB': BEGIN & MNB=1860 & MXB=2059 & END
		'H19R': BEGIN & MNB=2040 & MXB=2059 & END
		'H78R': BEGIN & MNB=10 & MXB=149 & END
		'L15B': BEGIN & MNB=900  & MXB=1199 & END
		'L15R': BEGIN & MNB=600  & MXB=899 & END
		'L65R': BEGIN & MNB=1100 & MXB=1199 & END
		ELSE : BEGIN & 	bkg = 0. & SCTERR=0. & END
		endcase
		IF MXB GT MNB THEN SCTERR=STDEV(COUNTS(MNB:MXB),BKG)	       $
							/SQRT(MXB-MNB+1)
		counts=counts-bkg
		if (not keyword_set(silent)) AND (BKG NE 0) then BEGIN
			print,'bkg subtracted for ' + grcase + '=',bkg
			IF STAT.OPEN THEN           $
			printF,11,'bkg subtracted for ' + grcase + '=',bkg
			endif
		ENDIF
IF (keyword_set(TRIM)) THEN BEGIN
	good=WHERE(WAVE GT 0)			;93aug11 changes
	wave=wave(good)
	counts=counts(good)
	mask=mask(good)
	FLUX=FLUX(GOOD)
	if ext NE '' then qual=qual(good)
	IF N_PARAMS(0) GE 8 THEN BEGIN
		SERR=SERR(GOOD)
		BKGR=BKGR(GOOD)
		ENDIF
	if wave(0) gt min(wave) then begin
		wave=reverse(wave)
		counts=reverse(counts)
		qual=reverse(qual)
		mask=reverse(mask)
		FLUX=REVERSE(FLUX)
		IF N_PARAMS(0) GE 8 THEN SERR=REVERSE(SERR)
		IF N_PARAMS(0) GE 8 THEN BGKR=REVERSE(BKGR)
		endif				;93aug11-end changes
	ENDIF
!MTITLE=FOSTIT(HEADER,GPAR)
RETURN
END
