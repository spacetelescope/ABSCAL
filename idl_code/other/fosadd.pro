PRO FOSADD,LIST,HEAD,GPAR,TITLE,EXP,WL,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL,      $
			sctval=sctval,scterr=scterr
;+
; NAME:
;       FOSADD
; PURPOSE:
;	FOS READING AND COADDING PROGRAM TO CORRESPOND TO IUE MRGPT
; CALLING SEQUENCE:
;	FOSADD,LIST,HEAD,GPAR,TITLE,EXP,WL,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL,  $
;			sctval=sctval,scterr=scterr
; INPUT:
;	LIST-ASCII LIST OF ROOTNAMES TO BE COADDED
; OUTPUT:
;	HEAD-HEADER FOR LAST OBS SET
;	GPAR-GROUP PARAMETER FOR LAST OBS SET
;	TITLE-CONSTRUCTED FROM HEAD
;	EXP-TOTAL EXPOSURE TIME OF COADDED DATA
;	WL-WAVELENGTH FROM .C0H FILES
;	CTRATE-AVERAGED COUNTRATE weighted by exposure time
;	FLUX-AVERAGE FLUX weighted by exposure time
;	FLXERR-PROGAGATED FLUX STATISTICAL UNCERTAINTY
;	NPTS-ARRAY OF TOTAL POINTS COADDED
;	TIME-ARRAY OF TOTAL EXP TIME PER POINT
;	QUAL-(1=GOOD, 0=BAD), BASED ON ALL DATA QUALITY FLAG GE 180 IS BAD.
;	sctval-value of any scattered light subtraction (counts/sec)-scalar
;	scterr-uncertainty in sctval-a scalar
; HISTORY:
; 93MAR29-WRITTEN BY R. C. BOHLIN
; 93aug12-transparent changes to generalize fosrd and remove some code here
; 93aug26-change above qual limit to 180 from 200 per fosrd fix for bad wl's
; 93oct27-read flux from .c1 files instead of using fosflx
; 93oct27-add sctval and scterr keywords
; 93NOV12-OOPS...FORGOT TO AVG FLUX ON OCT27! ADD NOW W/ EXP TIME WGT.
; 93dec16-trim all output data arrays to elim pts w/ zero integ time.
; 94feb15-change bad qual from 700 to 500 to omit djl noisy diode 'hand' patches
; 94apr7-change from exp time wgt to proper 1/sigma^2 wgts and incl 1% FF 
;			statistical uncertainty.
; 96jan30-bug in flux wgt for flxer=0 for 0 cts causing high fluxes for low cnts
; 96jan30-this fix now gives neg. flux for 0 counts on avg, so go to exp time
;	weighting of flux for coadds!
;-
IF N_PARAMS(0) EQ 0 THEN BEGIN
PRINT,'FOSADD,LIST,HEAD,GPAR,TITLE,EXP,WL,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL',  $
		',sctval=sctval,scterr=scterr'
RETALL
ENDIF

list=[list]		;in case list is not input as a vector
SIZ=SIZE(LIST)
NUM=SIZ(1)
;PRINT,NUM,'=NUMBER OF SPECTRA TO COADD'

;INITIALIZE COADDED QUANTITIES
EXP=0
sctval=0
scterr=0
CTRATE=FLTARR(2064)
FLXERR=CTRATE
NPTS=FIX(CTRATE)
TIME=CTRATE
QUAL=BYTE(CTRATE)
flux=ctrate

;MAIN LOOP

	FOR I=0,NUM-1 DO BEGIN
		FOSRD,LIST(I),HEAD,GPAR,WL,CT,QL,MASK,FLXER,BKG,flux=flx,     $
			sctval=sctvl,scterr=scter,/TRIM		; 93NOV8-TRIM
		EX=SXGPAR(HEAD,GPAR,'EXPOSURE')
;OLD STYLE KEYWD
		IF !ERR EQ -1 THEN EX=SXGPAR(HEAD,GPAR,'EXPTIME')
		EXP=EXP+EX
		sctval=sctval+sctvl
		IF SCTER GT 0 THEN scterr=scterr+1./(scter^2)

; ##############################################################################
; 96jan30-BIG problem for low flux and flxer=0 for zero cts;
;	a) many pts omitted from co-add, leading to net flux in cases of 0 flux
;	   from 2nd condition below. So, set flxer for 0 ct = flxer for 1 ct.
;	b) First term must be deleted, to keep 0 count points (and should have 
;	   had been ct+bkg+sctvl, anyhow!
;	c) Third term could result in more flux pts getting the boot than the 
;	   ctrate,npts, & time above. Flux is the only real product, so
;	   elim use of separate findex, so npts, etc show which data makes flux.
;patch for pipeline roundoff error...93aug26 update flxer lim from 0 to 1.e-19
;          to avoid float div by 0 for sn87 Y0WY0304T.c5h
;		fINDEX=WHERE(((ct+bkg)*ex gt .5) and (flxer gt 1.e-19)  $
;		  AND (QL LT 180)) ;OMIT MORE BAD DATA P.4-17 STSDAS CAL GUIDE
;		flxer(findex)=1./(FLXER(fINDEX)^2+(.01*flx(findex))^2)
;		FLXERR(fINDEX)=flxer(findex)+FLXERR(fINDEX)
;		FLUX(fINDEX)=FLX(fINDEX)*FLXER(fINDEX)+FLUX(fINDEX)
; ##############################################################################
; Keep all arrays at 2064. Fix bad (0) flxer values to be same as for 1 ct:
; cannot fix pts w/ ct=0, but no need as they are GIM fill, eg.
		ztst=where(ct ne 0)
		sens=flx*0
		sens(ztst)=flx(ztst)/ct(ztst)
		zfix=where(((flxer le 1.e-19) and (ct ne 0)),znum)
		if znum ne 0 then flxer(zfix)=sens(zfix)/ex	;error for 1 ct
;OMIT DATA FILL, GIM FILL, djl noisy diodes patch of 500
		tINDEX=WHERE((ql LT 180)  $ ;700 befor 94feb15,500 befor 96jan30
			and (flxer gt 0))	;still omit zero sens pts.
		CTRATE(tINDEX)=CT(tINDEX)*EX+CTRATE(tINDEX)	;wgt by exp time
		NPTS(tINDEX)=NPTS(tINDEX)+1
		TIME(tINDEX)=TIME(tINDEX)+EX
; see Bevington p. 73 for proper formula and include 1% Flat field stat err
		flxer(tindex)=1./(FLXER(tINDEX)^2+(.01*flx(tindex))^2) ;invert
		FLXERR(tINDEX)=flxer(tindex)+FLXERR(tINDEX)
; fails at low cts	FLUX(tINDEX)=FLX(tINDEX)*FLXER(tINDEX)+FLUX(tINDEX)
		FLUX(tINDEX)=FLX(tINDEX)*ex+FLUX(tINDEX)
;MAKE QUAL=1, IF EVER HIT ANY "GOOD" DATA:
		QUAL(WHERE(QL LT 180))=1
		ENDFOR			; END MAIN LOOP
;MAKE TITLE
targnam=strtrim(SXPAR(HEAD,'TARGNAM1'),2)
if !err lt 0 then targnam=strtrim(SXPAR(HEAD,'TARGNAME'),2)
SIDE=STRUPCASE(STRTRIM(SXPAR(HEAD,'DETECTOR'),2))
IF SIDE EQ 'AMBER' THEN SIDE='RED'
GRAT=STRUPCASE(STRTRIM(SXPAR(HEAD,'FGWA_ID'),2))
TITLE=TARGNAM+' '+SIDE+' '+GRAT+' '+STRTRIM(SXPAR(HEAD,'APER_ID'),2)  $
 +' TOTAL T(SEC) OF '+STRING(NUM,'(I2)')+' OBS='+STRTRIM(STRING(EXP),2)+'/XSTEP'

;COMPUTE AVERAGES

sctval=sctval/num
IF SCTERR GT 0 THEN scterr=SQRT(1./SCTERR)
; trim outputs to the size of good data, i.e where time>0 AND flxerr>0
INDEX=WHERE((time GT 0) and (FLXERR GT 0))
wl=wl(index)
npts=npts(index)
time=time(index)
qual=qual(index)
flxerr=flxerr(index)
; caution-DJL does not do time corr for counts.
CTRATE=CTRATE(INDEX)/TIME
FLUX=FLUX(INDEX)/time
FLXERR=1./SQRT(FLXERR)
; fails at low cts		FLUX=FLUX(INDEX)/flxerr
RETURN
END
