PRO ABSRATIO,WOBS,FOBS,WSS,FSS,MODE,XSTEPS,WFIRST,DELW,WAVE,SENS
;+
; PURPOSE:
;	COMPUTE RATIO OF TWO SPECTRA, EG. COUNTS AND STANDARD STAR FLUX
; CALLING SEQUENCE:
;	ABSRATIO,WOBS,FOBS,WSS,FSS,MODE,XSTEPS,WFIRST,DELW,WAVE,SENS
;
; VERSION 1  BY D. LINDLER  APR. 9, 1986
;
; INPUT:
;	WOBS - WAVELENGTH VECTOR OF THE OBSERVATION
;	FOBS - FLUX OF OBSERVATION
;	WSS - WAVELENGTH VECTOR OF STANDARD STAR
;	FSS - FLUX OF STANDARD STAR
;	MODE - OPERATING MODE
;
;			VALUE   	PROCESSING
;			  0	Interpolate standard star spectrum to
;				same scale as observation.
;			  1	Interpolate in observation to match
;				wavelengths of the standard star.
;			  2	Integrate flux in observation to match
;				standard star wavelengths
;			  3	Integrate standard star flux to match
;				wavelengths of observation
;			  4	Integrate both stars to wavelength
;				scale specified by WFIRST and DELW
;
;
;	XSTEPS = Number of xsteps if oversampling is used. 
;		(1,2 OR 4),Used for mode 3 only
;	WFIRST = Starting wavelength to use for mode 4. If set to
;		zero, the procedure selects it for you
;	DELW = Wavelength interval for mode 4 used to generate
;				the output sensitivity curve.
; OUTPUT:
;	WAVE - wavelength scale for sensitivity curve
;	SENS - sensitivity 
;
;HISTORY
; 90NOV14-RCB MOVE THE BIT TO REVERSE BACKWARD ARRAY IN FROM FOS_ABSRATIO
; May 2002, DJL, modified to sort wavelengths if not monotonic
; oct 14, 2003 - rcb to work w/microns in WL arrays
; 2015oct13 - mod to work w/ neg WFC3 orders
;-----------------------------------------------------------------------
;-

; get rid of zero wavelength points in the input spectrum and
; place into ascending order
;
;       good = where(wobs gt 0.1) & ngood = !err	; 03oct14-was 100.0
        good = where(wobs ne 0) & ngood = !err		; 15oct13
        wobs = wobs(good) & fobs = fobs(good)
        if wobs(ngood/2) gt wobs(ngood/2+1) then begin
                wobs = reverse(wobs)
                fobs = reverse(fobs)
        endif
        bad = where(wobs(0:ngood-2) gt wobs(1:ngood-1)) & nbad = !err
        if nbad gt 0 then begin
		print,'ABSRATIO warning: wavelengths not monotonically '+ $
				'increasing'
		sub = sort(wobs)
                wobs = wobs(sub)
                fobs = fobs(sub)
        end
CASE MODE OF
 
    0:	BEGIN				;INTERP. IN STANDARD STAR
	MINW=MIN(WSS)
	MINW=MINW>MIN(WOBS)		;MIN. OUTPUT WAVELENGTH
	MAXW=MAX(WSS)
	MAXW=MAXW<MAX(WOBS)		;MAX. OUTPUT WAVELENGTH
	GOOD=WHERE((WOBS GE MINW) AND (WOBS LE MAXW))
	IF !ERR LT 1 THEN GOTO,NOOVERLAP
	WAVE=WOBS(GOOD)			;GOOD POINTS
	FLUX=FOBS(GOOD)
	LINTERP,WSS,FSS,WAVE,FSTAR	;INTERP. IN STANDARD STAR
	END; MODE 0
;
;----------------------------------------------------------------------
;
    1:  BEGIN				;INTERP. IN OBSERVATION
	MINW=MIN(WOBS)
	MINW=MINW>MIN(WSS)		;MIN. OUTPUT WAVELENGTH
	MAXW=MAX(WSS)
	MAXW=MAXW<MAX(WOBS)		;MAX. OUTPUT WAVELENGTH
	GOOD=WHERE((WSS GE MINW) AND (WSS LE MAXW))
	IF !ERR LT 1 THEN GOTO,NOOVERLAP
	WAVE=WSS(GOOD)
	FSTAR=FSS(GOOD)
	LINTERP,WOBS,FOBS,WAVE,FLUX	;INTERP. IN OBSERVATION
	END; MODE 1
;
;----------------------------------------------------------------------
;
    2:	BEGIN				;INTEGRATE IN OBSERVATION
	WMAX=(SHIFT(WSS,-1)+WSS)/2.0	;UPPER INTEGRATION LIMIT
	WMIN=SHIFT(WMAX,1)		;LOWER INTEGRATION LIMIT
	WMIN(0)=WSS(0)-(WSS(1)-WSS(0))/2.0
	ILAST=N_ELEMENTS(WSS)-1
	WMAX(ILAST)=WSS(ILAST)+(WSS(ILAST)-WSS(ILAST-1))/2.0
	GOOD=WHERE((WMIN GE MIN(WOBS)) AND (WMAX LE MAX(WOBS)))
	IF !ERR LT 0 THEN GOTO,NOOVERLAP
	WMIN=WMIN(GOOD)			;USE REGION OF OVERLAP
	WMAX=WMAX(GOOD)
	WAVE=WSS(GOOD)
	FLUX=INTEGRAL(WOBS,FOBS,WMIN,WMAX)
	FLUX=FLUX/(WMAX-WMIN)
	FSTAR=FSS(GOOD)
	END; MODE 2
;
;--------------------------------------------------------------------
;
    3:	BEGIN				;INTEGRATE STANDARD STAR
	ILAST=N_ELEMENTS(WOBS)-1
	DLEFT=WOBS(1)-WOBS(0)
	DRIGHT=WOBS(ILAST)-WOBS(ILAST-1)
	CASE XSTEPS OF			;COMPUTE INTEGRATION LIMITS
	   1:	BEGIN
		WMAX=(SHIFT(WOBS,-1)+WOBS)/2.0	;UPPER LIMIT
		WMIN=SHIFT(WMAX,1)		;LOWER LIMIT
		WMIN(0)=WOBS(0)-DLEFT/2.0	;EXTRAPOLATE
		WMAX(ILAST)=WOBS(ILAST)+DRIGHT/2.0
		END
	   2:	BEGIN
		WMAX=SHIFT(WOBS,-1)		;UPPER LIMIT
		WMIN=SHIFT(WOBS,1)		;LOWER LIMIT
		WMAX(ILAST)=WOBS(ILAST)+DRIGHT
		WMIN(0)=WOBS(0)-DLEFT
		END
	   4:	BEGIN
		WMAX=SHIFT(WOBS,-2)
		WMIN=SHIFT(WOBS,2)
		WMIN(0)=WOBS(0)-2*DLEFT
		WMIN(1)=WOBS(0)-DLEFT
		WMAX(ILAST)=WOBS(ILAST)+2*DRIGHT
		WMAX(ILAST-1)=WOBS(ILAST)+DRIGHT
		END
	ELSE:	BEGIN
		PRINT,'INVALID NUMBER OF XSTEPS (MUST BE 1,2 OR 4)
		PRINT,'ABSRATIO ABORTING'
		RETALL
		END
	ENDCASE; OF XSTEPS
	GOOD=WHERE( (WMIN GE MIN(WSS)) AND (WMAX LE MAX(WSS)))
	IF !ERR LT 0 THEN GOTO,NOOVERLAP
	WMIN=WMIN(GOOD)			;USE REGION OF OVERLAP
	WMAX=WMAX(GOOD)
	WAVE=WOBS(GOOD)
	FLUX=FOBS(GOOD)
	FSTAR=INTEGRAL(WSS,FSS,WMIN,WMAX); INTEGRATE IN STAR
	FSTAR=FSTAR/(WMAX-WMIN)
	END; MODE 3
;
;	----------------------------------------------------------
;
    4:	BEGIN		;INTEGRATE BOTH SPECTRA
	MINW=MIN(WOBS)>MIN(WSS)		;MIN OVERLAPPED WAVELENGTH
	MAXW=MAX(WOBS)<MAX(WSS)		;MAX	"	    "
	IF WFIRST LE 0.0 THEN WFIRST=MINW+DELW/2.0
	NINT=long((MAXW-DELW/2.0-WFIRST)/DELW)+1	;99nov19 - rcb (was FIX)
	IF NINT LT 2 THEN GOTO,NOOVERLAP
	WAVE=FINDGEN(NINT)*DELW+WFIRST
	WMIN=WAVE-DELW/2.0
	WMAX=WAVE+DELW/2.0		;LIMITS OF INTEGRATION
; 94apr11-rcb fix
	GOOD=WHERE(WMIN Ge MINW)	;GOOD REGION IN CASE USER
					;SPECIFIED WFIRST TOO SMALL
	IF !ERR LT 0 THEN GOTO,NOOVERLAP
	WAVE=WAVE(GOOD)
	WMIN=WMIN(GOOD)
	WMAX=WMAX(GOOD)
	FLUX=INTEGRAL(WOBS,FOBS,WMIN,WMAX)
	FLUX=FLUX/(WMAX-WMIN)
	FSTAR=INTEGRAL(WSS,FSS,WMIN,WMAX)
	FSTAR=FSTAR/(WMAX-WMIN)
	END; MODE 4
;
;-----------------------------------------------------------------------
;
   ELSE: BEGIN
	PRINT,'INVALID MODE IN ABSRATIO, MUST BE 0,1,2,3 OR 4'
	PRINT,'ABORTING'
	RETALL
	END
ENDCASE
;
;----------------------------------------------------------------
;
; COMPUTE SENSITIVITY
;
;NONZERO=WHERE(FSTAR GT 0.0)
NONZERO=WHERE(FSTAR ne 0.0)		;2015oct13 keeps more pts, ie less holes
WAVE=WAVE(NONZERO)
FLUX=FLUX(NONZERO)
FSTAR=FSTAR(NONZERO)
SENS=FLUX/FSTAR
RETURN
;
; NO OVERLAP OF WAVELENGTHS
;
NOOVERLAP:
PRINT,'INSUFFICIENT OR NO OVERLAP OF WAVELENGTHS IN OBSERVATION AND'
PRINT,'STANDARD STAR,  ABORTING...'
RETALL
END

