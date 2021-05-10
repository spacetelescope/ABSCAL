FUNCTION FLXCOR,WAVE,FLX,iueoke=cutwl
;+
;
; PURPOSE:
;	CORRECT IUE OR OKE FLUXES TO THE WD SCALE. SEE IUECF AND OKECF PRO'S
;		& Bohlin (1996,AJ,111,1743) for derivation of the corrections
;               & discussion of the uncertainties.
;
;calling sequence:
;	CORRECTED_FLUX=FLXCOR(WAVE,FLX,iueoke=cutwl)
;
; input: WAVE-WAVELENGTH ARRAY OF FLUX VECTOR TO BE CORRECTED
;	 FLX-CORRESPONDING FLUX VECTOR TO BE CORRECTED
;        IUEOKE=CUTWL - keyword specifying the wavelength for switch between
;			iue and the oke correction. Required only if there are
;			wavelengths in the range <3200 and >3350. Otherwise,
;			iue is assumed if all wl<3350; and oke for all wl>3200.
; output-THE FLX SPECTRUM CONVERTED TO THE WD STANDARD SPECTROPHOTOMETRY SCALE.
;
; WARNINGS            ##############
; 1. COLINA AND BOHLIN 1994,AJ,108,1931. TABLE FOR OKE OFFSETS not included. 
; 2. This correction is applicable only to the original IUE extractions 
;    (old)SIPS and to IUE fluxes produced by the calibration procedure
;    summarized in Bohlin et al. 1990, ApJS, 73, 413. The NEWSIPS calibration 
;    is already on the WD scale and should *NOT* be corrected by this algorithm.
; 3. CSPLINE is an obsolete program. See [.doc]cspline.
; HISTORY - written ~1994-5
;-
; TABLE OF x spline nodes FOR IUE
iuexfit=[		        				      $
1155.0,1185.0,1195.0,1240.0,1270.0,1288.0,1300.0,1400.0,1465.0,1490.0,$
1515.0,1605.0,1625.0,1645.0,1760.0,1799.0,1821.0,1890.0,1910.0,1930.0,$
2070.0,2270.0,2450.0,2650.0,2750.0,2850.0,2950.0,3090.0,3174.0,3350.0]
; TABLE OF y spline nodes FOR IUE
iueyfit=[							      $
1.0334,1.1047,1.0894,1.0354,1.0257,1.0264,1.0187,0.9014,0.9425,0.9815,$
0.9609,0.9125,0.8831,0.8829,0.9205,0.9145,0.9123,0.8916,0.8710,0.8846,$
0.9464,0.9199,0.9619,0.9542,0.9520,0.9476,0.9490,0.9718,1.0042,1.0218]
; x spline nodes for oke
okexfit=[							      $
3200.0,3230.0,3235.0,3240.0,3290.0,3314.0,3352.0,3400.0,3470.0,3510.0,$
3550.0,3590.0,3662.0,3700.0,3743.0,3792.0,3849.0,3851.0,3900.0,4154.0,$
4168.0,4180.0,4226.0,4228.0,4234.0,4240.0,4300.0,4400.0,4470.0,4513.0,$
4542.0,4565.0,4700.0,4800.0,4900.0,5000.0,5100.0,5200.0,5300.0,5400.0,$
5500.0,5600.0,5700.0,5800.0,5900.0,6000.0,6100.0,6200.0,6300.0,6400.0,$
6500.0,6600.0,6700.0,6800.0,6900.0,7000.0,7100.0,7200.0,7300.0,7400.0,$
7500.0,7600.0,7700.0,7800.0,7900.0,8000.0,8100.0,8200.0,8300.0,8400.0]
okexfit=[okexfit,$	;to avoid IDL array definition limit!!!!????
8475.0,8502.0,8523.0,8538.0,8573.0,8590.0,8640.0,8665.0,8730.0,8745.0,$
8800.0,8815.0,8855.0,8880.0,8955.0,8975.0,9010.0,9025.0,9055.0,9080.0,$
9200.0,9205.0]
; y spline nodes for oke
okeyfit=[							      $
1.0867,1.0998,1.1103,1.0989,1.0073,1.0245,1.0161,1.0283,1.0059,1.0158,$
1.0000,1.0080,0.9817,0.9815,0.9838,0.9689,1.0019,1.0018,0.9995,0.9887,$
0.9891,0.9980,1.0130,1.0157,1.0079,1.0054,1.0041,1.0020,0.9978,0.9925,$
0.9996,1.0009,1.0031,0.9992,0.9946,1.0024,0.9970,1.0044,0.9976,1.0009,$
1.0000,1.0010,0.9992,1.0000,1.0037,1.0010,1.0024,1.0022,0.9991,1.0028,$
1.0046,0.9939,0.9955,0.9958,1.0021,0.9982,0.9985,0.9983,0.9954,0.9980,$
0.9980,0.9987,0.9979,0.9973,0.9965,0.9976,0.9990,0.9972,0.9965,0.9986]
okeyfit=[okeyfit,						      $
1.0055,1.0141,1.0149,1.0259,1.0015,1.0040,1.0019,1.0188,0.9930,1.0028,$
0.9907,0.9927,1.0021,1.0035,0.9581,0.9578,0.9667,0.9603,0.9388,0.9456,$
0.9810,0.9862]

wlend=wave(n_elements(wave)-1)
CORRFLUX=FLX
if keyword_set(cutwl) then begin
	if ((cutwl lt 3200) or (cutwl gt 3350)) then begin
	  print,'cutwl=',cutwl,' but must be in range 3200-3350. STOP in FLXCOR'
	  stop
	  endif
      end else begin
; KEYWORD CUTWL NOT SET:
	if wave(0) ge 3200 then begin
		cutwl=3200.		;ASSUME ALL DATA IS OKE
		goto,oke
		endif
	if wlend le 3350 then begin
		cutwl=3350.		;ASSUME ALL DATA IS IUE
		goto,iue
		endif
	print,'STOP in flxcor. IUEOKE keyword required.'	; logic error
	endelse

iue:
if wave(0) lt cutwl then begin
	print,'FLXCOR for IUE in range:',wave(0),cutwl
	GOOD=WHERE((WAVE GE 1140) AND (WAVE LE MAX(iuexfit)),COUNT)
	IF COUNT GT 0 							$
	       THEN CORRFLUX(GOOD)=FLX(good)/CSPLINE(iuexfit,iueyfit,WAVE(GOOD))
	if wave(0) lt 1140 then begin	    ;94mar17 to fix voyager in std stars
		GOOD=WHERE((WAVE lt 1140))
		c1140=CSPLINE(iuexfit,iueyfit,1140.)
		print, 'wl lt 1140 corrected by ',c1140(0)
		corrflux(good)=flx(good)/c1140(0)
		endif
	endif

oke:
if wlend le cutwl then RETURN,CORRFLUX else begin
	print,'FLXCOR for OKE data in range:',cutwl,wlend
	GOOD=WHERE((WAVE GE cutwl) AND (WAVE LE MAX(okexfit)),COUNT)
	IF COUNT GT 0 THEN 						$
		CORRFLUX(GOOD)=FLX(good)/CSPLINE(okexfit,okeyfit,WAVE(GOOD))
	if wlend gt MAX(okexfit) then begin
		GOOD=WHERE((WAVE gt MAX(okexfit)))
		c9200=CSPLINE(okexfit,okeyfit,MAX(okexfit))
		print, 'wl gt MAX(okexfit) corrected by ',c9200(0)
		corrflux(good)=flx(good)/c9200(0)
		endif
	endelse
RETURN,CORRFLUX

END
