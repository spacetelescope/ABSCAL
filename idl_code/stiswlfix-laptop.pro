function stiswlfix,fulroot,cenwave

;+
;
; Name:  stiswlfix
; PURPOSE:
;	Return the WL corr in px to be *added to* the wavelengths
;		of a stis obs when the wavecal is inadequate.
; THE value to enter is the same as labeled New Fix in wlck and nowavcal.pro
; ie: 	The px offset to be subtracted from the wavecal toffset in preproc
; 02aug27-Use targoffs, instead of correcting toffset, assume same sign conv.
; Generally, do not bother w/ mama shifts <0.4 or CCD shifts <0.2px
;	2014dec - OR if the 2 shfts are discrepant & HRS shift is <above.
; 2019may17 - start policy of incl. all >.1 MAMA shifts & to .03 precision
; 2019may17 -     incl. all >.09 CCD shifts & to .03 precision
; 2019jul15 - YES! fixed WLCK.pro to normalize the lines before X-correlating.

;
; **REMINDER** REMEMBER radial vel. when measuring WL shifts!
;			
; CALLING SEQUNCE:
;	offset=stiswlfix(fulroot,cenwave)
; Inputs:
;	fulroot - Full rootname of stis obs. Or ngc6681-letter
;	cenwave - central wl of stis obs. Four char string. or grating for 6681
; OUTPUT:
;	The wavelength correction in px, NOT including the slit offset.
; CUTOFF: don't bother w/ corrections of <.3px (except vega).
; Dispersions G140L, G230L, G230LB, G430L, G750L=0.584,1.545,1.37,2.73,4.9 A/px
; HISTORY
;	97jul22 - rcb
;	97jul29 - mod to return the offset for calstis, instead of fix wl vector
;	97Oct20 - new slit offset installed.
;	98jun11 - G750L updates from wlck.pro & wlerr.g750l
;	98jun22 - G140L updates from wlck.pro & wlerr.g140l
;	02mar18 - G140L fix to add .15 px to -3" & -.15px to +3" 
;	02MAR28 - ADD 9 char root section
;	02jun6 -  ngc6681 corrections
; 	02sep5 - use wlck.pro for stars w/ model or nowavcal.pro otherwise,
; 	03 may - new aperture offsets, everything can change. 
;		Lots of E1 and secondary standards not updated.worry about later
;		default offsets are for G230LB, 430, 750: -1.22,-1.73,-1.44,
;		which are hard-coded in preproc.pro. For these E1 cases, eg:
;		original wlfix=-1.73       New fix=-1.23 per wlck or nowavcal 
;		and I enter -1.23+1.73=+.50 in stiswlfix
;	05may13 - "final" agk offsets & nothing new for grw
;	06may31 - major update of E1 and CCD ;secondary standards. 
;	06may31 - above std E1 offsets removed (in preproc & here). E1=center
;		for wl offset purposes now. the positioning error in the slit
;		decreased to ~0 after ~2003nov
; 	08nov19 - switch wlck.pro to Hub07
;	2014Dec16-Should switch from avg to pure HRS-offst, which is Better,
;		esp. in line cores!
;	2014Dec29-Switch to using HRS offsets only. Massa shifts all updated.
;	2016mar4 -Add G750M for HD189733
; 2019jul15 - fixed WLCK.pro to normalize the lines before X-correlating.
;-
offset=0.0
root=strupcase(strmid(fulroot,0,6))
		case cenwave of 		; early cases of odd apertures:
			'2375': case root of			;G230LB
; use avg of g430 and g750 px shifts:
				'O3TT02': offset=+11.4	;in px 6x6
				'O3TT03': offset=+10.2  ;      6x6
				'O3TT04': offset=+9.0	;	6x6
				'O3TT20': offset=-2.5	;	6x6
                                'O3TT21': offset=-4.0    ;inferred 6x6  
                                'O3TT23': offset=+3.1    ;........ 6x6
				else: begin   &  endelse  &  endcase
			'4300': case root of			
;H-alpha=6564.6  vacuum wavelengths (air 6562.80)
;h-beta=4862.7                       ... 4861.32
;H-gamma=4341.7
;H-delta=4102.9
; 97Oct17 - the 6x6 slit offset changed from 0.1596 to 0.1549",which might
;	mean .0047/.024=.2px, which is at the level of uncert-->no change. Ie.
;	the lines are still at the right WL w/i uncert. of +-0.2px
				'O3TT02': offset=+11.4	; NO targ/acq 6x6
				'O3TT03': offset=+10.6	;@ 2.73A/px   6x6
				'O3TT04': offset=+9.2	; not used for cal 6x6
				'O3TT20': offset=-2.6	;gd153 6x6
                                'O3TT21': offset=-4.0	;from H-gam 6x6
				'O3TT23': offset=+2.9	;H-gam   6x6
				else: begin   &  endelse  &  endcase
			'7751': case root of			;h-alpha=6563
				'O3TT02': offset=+11.4	;in px  6x6
				'O3TT03': offset=+9.8	;+3px   6x6
				'O3TT04': offset=+8.7	;+3.5   6x6
				'O3TT20': offset=-2.4	;gd153  6x6
                                'O3TT21': offset=-4.1	;H-alpha 6x6
                                'O3TT23': offset=+3.25	;H-alpha 6x6
				else: begin   &  endelse  &  endcase
			else: begin  &  endelse
			endcase
root=strupcase(strmid(fulroot,0,9))	;02mar28 - precision: from nowavcal.pro
; 03may2 and from wlck.pro for WD standards. New wl scales after today.
; See wlerr.*grat*-wd & do not correct for the 0.4px shifts & 0.1 is close enuf
;	generally, do not bother w/ mama shifts <0.4 or CCD shifts <0.2px
; offsets from nowavecal.pro:wl.offsets* for agk, grw, etc

	case cenwave of 
		'1425': case root of			;G140L
			'O3ZX08HHM': offset= 1.66       ; 19Jul GD153 
			'O4A502060': offset= 0.23       ; 19Jul GD153 
			'O4VT10YRQ': offset=-0.24       ; 19Jul GD153 
			'O4VT10Z0Q': offset=-0.13       ; 19Jul GD153 
			'O6IG03T5Q': offset= 0.96       ; 19Jul GD153 
			'O6IG03THQ': offset= 1.05       ; 19Jul GD153 
			'O6IG04V7Q': offset= 0.21       ; 19Jul GD153 
			'O6IG04VJQ': offset= 0.47       ; 19Jul GD153 
			'O6IG11CXQ': offset=-0.30       ; 19Jul GD153 
			'O6IG11DJQ': offset=-0.31       ; 19Jul GD153 
			'O6IG02Y3Q': offset= 0.78       ; 19Jul GD153 
			'O6IG02YFQ': offset= 0.66       ; 19Jul GD153 
			'O8V202F7Q': offset= 0.14       ; 19Jul GD153 
			'OA8D02010': offset= 0.32       ; 19Jul GD153 
			'OA9Z05010': offset=-0.22       ; 19Jul GD153 
			'OBC402ENQ': offset= 2.10       ; 19Jul GD153 
			'OBTO10QHQ': offset= 1.16       ; 19Jul GD153 
			'OC5506RJQ': offset= 0.53       ; 19Jul GD153 
			'OCGA05EUQ': offset= 2.12       ; 19Jul GD153 
			'ODCK02P2Q': offset= 1.02       ; 19Jul GD153 
			'ODUD02FPQ': offset= 0.22       ; 19Jul GD153 
			
			'O4PG01N1Q': offset= 0.25       ; 19Jul GD71 
			'O4PG01N9Q': offset= 0.45       ; 19Jul GD71 
			'O4PG01NDQ': offset= 0.36       ; 19Jul GD71 
			'O4PG01NHQ': offset= 0.55       ; 19Jul GD71 
			'O4PG01NPQ': offset= 0.48       ; 19Jul GD71 
			'O4SP01060': offset= 0.46       ; 19Jul GD71 
			'O4A551060': offset= 0.45       ; 19Jul GD71 
			'O53001080': offset=-0.62       ; 19Jul GD71 
			'O4A520060': offset= 0.37       ; 19Jul GD71 
			'O61001070': offset= 0.63       ; 19Jul GD71 
			'O61002060': offset=-0.15       ; 19Jul GD71 
			'O61003060': offset= 0.17       ; 19Jul GD71 
			'O61004060': offset= 0.59       ; 19Jul GD71 
			'O61005060': offset= 0.50       ; 19Jul GD71 
			'O61006060': offset= 0.50       ; 19Jul GD71 
			'O5I001010': offset= 0.40       ; 19Jul GD71 
			'O5I002IWQ': offset= 0.33       ; 19Jul GD71 
			'O5I002J0Q': offset= 0.47       ; 19Jul GD71 
			'O5I002J3Q': offset= 0.32       ; 19Jul GD71 
			'O5I002J6Q': offset= 0.30       ; 19Jul GD71 
			'O5I002J9Q': offset= 0.14       ; 19Jul GD71 
			'O6IG01B7Q': offset= 0.18       ; 19Jul GD71 
			'O8V201G6Q': offset= 0.54       ; 19Jul GD71 
			'OBC401M5Q': offset= 1.06       ; 19Jul GD71 
			'OBVP06A8Q': offset= 1.15       ; 19Jul GD71 
			'OCGA04TWQ': offset= 0.64       ; 19Jul GD71 
			'ODCK01MWQ': offset= 1.19       ; 19Jul GD71 
			'ODUD01R1Q': offset= 1.61       ; 19Jul GD71 
; same slit=52x0.05 is always used for above gd71 wavecals.
; 03may2-GRW. See wl.offsets-prev file for these values:
	'O3YX14040': offset=+.94+0.4942/.584 ;2019may-new name for O3YX14HSM
; 1.32-->1.44-->1.51-->1.55:
			'O3YX14HSM': offset= 1.55       ; 19Jul GRW+70 G140L
; .92-->1.00-->1.04:
			'O3YX15QEM': offset= 1.04       ; 19Jul GRW+70 G140L
			'O3YX16KLM': offset= 0.82       ; 19Jul GRW+70 G140L
; .43-->.64-->.87-->.98: use 0
			'O45910010': offset= 0.         ; 19Jul GRW+70 G140L
			'O45911010': offset= 0.25       ; 19Jul GRW+70 G140L
; .15-->.22-->.33->.39-->.43:
			'O45912010': offset=-0.43       ; 19Jul GRW+70 G140L
			'O45913010': offset= 0.40       ; 19Jul GRW+70 G140L
; .30-->.46-->.54-->.58:
			'O45915010': offset= 0.58       ; 19Jul GRW+70 G140L
			'O45917010': offset=-0.36       ; 19Jul GRW+70 G140L
; .18-->.28-->.34:
			'O45942010': offset= 0.34       ; 19Jul GRW+70 G140L
			'O45944010': offset= 0.19       ; 19Jul GRW+70 G140L
			'O45945010': offset=-0.33       ; 19Jul GRW+70 G140L
			'O45946010': offset=-0.22       ; 19Jul GRW+70 G140L
			'O45948010': offset=-0.31       ; 19Jul GRW+70 G140L
			'O45950010': offset=0 ; 19Jul GRW+70 -.15->-.04->-.14
			'O45952010': offset=-0.28       ; 19Jul GRW+70 G140L
; .29-->.33-->46 set to 0
			'O5JJ01010': offset= 0.         ; 19Jul GRW+70 G140L
			'O5JJ03010': offset= 0.17       ; 19Jul GRW+70 G140L
			'O5JJ05010': offset=-0.55       ; 19Jul GRW+70 G140L
			'O5JJ08010': offset=-0.66       ; 19Jul GRW+70 G140L
			'O5JJ09010': offset= 0.49       ; 19Jul GRW+70 G140L
			'O5JJ10010': offset= 0.19       ; 19Jul GRW+70 G140L
			'O5JJ11010': offset=-0.21       ; 19Jul GRW+70 G140L
			'O5JJ14010': offset=-0.33       ; 19Jul GRW+70 G140L
			'O5JJ99010': offset= 0.58       ; 19Jul GRW+70 G140L
			'O69S01010': offset=-0.14       ; 19Jul GRW+70 G140L
			'O69S04010': offset= 0.25       ; 19Jul GRW+70 G140L
			'O69S05010': offset= 0.23       ; 19Jul GRW+70 G140L
			'O69S06010': offset= 0.61       ; 19Jul GRW+70 G140L
; -.15->-.22->-.15; -.18-->-.13-->.21 use .17
			'O69S09010': offset=-0.17 	; 19Jul GRW+70
			'O69S12010': offset= 0.21 ; 19Jul GRW+70 .17->.25->.17
			'O6I801010': offset=-0.29       ; 19Jul GRW+70 G140L
			'O6I803010': offset=-0.75       ; 19Jul GRW+70 G140L
			'O6I805010': offset=-0.46       ; 19Jul GRW+70 G140L
			'O6I806010': offset=-0.17       ; 19Jul GRW+70 G140L
			'O6I807010': offset= 0.58;19Jul GRW+70 .21->.30->.46->.54
			'O8AB06010': offset=-0.24       ; 19Jul GRW+70 G140L
			'O6I810010': offset= 0.42       ; 19Jul GRW+70 G140L
			'O6I812010': offset=-0.50       ; 19Jul GRW+70 G140L
			'O8IA01010': offset=-0.44       ; 19Jul GRW+70 G140L
; ff flagged BAD in dirlow.full:
			'O8IA03010': offset= 8.39       ; 19Jul GRW+70 G140L
			'O8IA05010': offset=-0.33 ; 19Jul GRW+70-.19->-.27->-.47
			'O8V501010': offset= 0.26       ; 19Jul GRW+70 G140L
			'O8V502010': offset=-0.22       ; 19Jul GRW+70 G140L
			'O8H107010': offset= 0.27 ; 19Jul LDS749 G140L .20to.35
			'O8H108010': offset=0. 		; 19Jul LDS749 0->.15->0
			'O8H109010': offset=-0.35;19Jul LDS749 G140L.32->.39->.31
			'OB87N2010': offset=-0.42       ; 19Jul GRW+70 G140L
; .22->.35->.21; .28-->.17 set to 0
			'OB8703010': offset= 0. 	; 19Jul GRW+70
			'OB8705010': offset=-0.20       ; 19Jul GRW+70 G140L
			'OBN6L2010': offset=-0.60       ; 19Jul GRW+70 G140L
			'OBW3L2010': offset=-0.30       ; 19Jul GRW+70 G140L
			'OBW3L3010': offset=-0.64       ; 19Jul GRW+70 G140L
			'OC4KL1010': offset= 0.34       ; 19Jul GRW+70 G140L
			'OC4KL3010': offset=-0.31       ; 19Jul GRW+70 G140L
			'OCETL1010': offset=-0.73       ; 19Jul GRW+70 G140L
			'OCETL3010': offset=-0.19       ; 19Jul GRW+70 G140L
			'OCQJL1040': offset=-0.60       ; 19Jul GRW+70 G140L
			'OCQJL2040': offset=-0.57       ; 19Jul GRW+70 G140L
			'OCQJL3040': offset=-0.97       ; 19Jul GRW+70 G140L
			'OD1CL1040': offset=-0.41       ; 19Jul GRW+70 G140L
			'OD1CL2040': offset=-0.36       ; 19Jul GRW+70 G140L
			'ODBUL1040': offset=-0.48       ; 19Jul GRW+70 G140L
			'ODBUL2040': offset= 0.51 ; 19Jul GRW+70  .45to.57
			'ODBUL3040': offset=-0.46 ;19Jul GRW+70 .42to.50
			'ODPCL2040': offset=-0.21       ; 19Jul GRW+70 G140L
			'ODPCL3040': offset=-0.42       ; 19Jul GRW+70 G140L
			'ODVIL1040': offset=-0.51       ; 19Jul GRW+70 G140L

;ff NOT stable .3 makes .26, .26 gives .35...   0.3 is good:
			'O8H107010': offset=0.3		;19jul LDS749 G140L
;ff NOT stable at -.27 to -.36
			'O8H109010': offset=-.31	;19jul LDS749 G140L
			'OBC408010': offset=2.88	;1743045 eye
; Bad too noisy		'OBNL04010': offset=1.9 	; 1757132

			'OBBM01010': offset=-0.18       ; 19Jul LDS749 G140L
			'OBC405010': offset= 0.53       ; 19Jul HD1654 G140L
			'OBC406010': offset=-0.13       ; 19Jul 173252 G140L
			'OBC457010': offset= 0.82       ; 19Jul 174034 G140L
			'OBC409010': offset= 1.31       ; 19Jul 180227 G140L
			'OBC410010': offset= 0.80       ; 19Jul 180529 G140L
			'OBNL02010': offset= 0.57 ; 19Jul HD3772 unstbl@.48-.67
			'OBNL03010': offset= 0.51       ; 19Jul HD1164 G140L
			'OBNL07010': offset= 0.58       ; 19Jul BD+60D G140L
			'OBTO02010': offset= 0.52       ; 19Jul HD1494 G140L
			'OBTO03010': offset= 0.46       ; 19Jul HD1584 G140L
			'OBTO04010': offset= 0.43       ; 19Jul HD1634 G140L
; too weak, noisy	'ODTA06010': offset=-1.25 	; 19Jul HD5567 G140L
; 19May-HZ21 is 90% He. See ~/wd/koester/HZ21-01.dk
;	so try HeII lines: 1215.13. No radial Vel meas. Line at
; 	1215.9 px offset needed=(1215.8-1215.13)/0.584 = -1.15 px (earlier meas)
; ck w/ (1640.42-1640.3)/0.584 = +0.21px after -0.80, Lya is spot-on &
;		so avg to final -0.7.. Ck OK.
			'ODTA16010': offset=-0.7        ; 19may21 HZ21 hand meas
; v. broad. do not iterate:
			'ODTA17010': offset=-3.6        ; 19Jul HZ4 unstbl
			'ODTB01010': offset= 0.69       ; 19Jul SDSSJ151421 g140

; MR-12,SDSS13 (too noisy), & Galex* are not in a nowavcal run.

;LCB
			'OC8C14020': offset=-.71	; GALEX-094853
			'OC8C19020': offset=5.9 	; GALEX-102254
			'OC8C20020': offset=-1.24	; GALEX-155521
			'OC8C49020': offset=0.64	; GALEX-004840
			'OC8C54020': offset=-.77	; GALEX-000152

; wd1327 & wd2341 OCWGA1050 & OCWGA2050 are too broad & noisy to believe shifts
; 04June FASTEX WDs At Lyman-alpha per wlck.pro:
			'OBNK01010': offset=-.77 	;WD0308-565 16sep15 eye
			'O5K007030': offset=-0.20       ; 19Jul WD1657 
			'O5K008030': offset=-0.33       ; 19Jul WD1657 
			'O69U04030': offset= 0.71       ; 19Jul WD1657 
			'O8H111040': offset=-0.19       ; 19Jul WD1657 
			'O5K001030': offset= 0.51       ; 19Jul WD0320 
			'O5K002030': offset=-0.34       ; 19Jul WD0320 
			'O5K003030': offset= 0.49       ; 19Jul WD0947 
			'O5K004030': offset=-1.03       ; 19Jul WD0947 
			'O69U02030': offset= 0.89       ; 19Jul WD0947 
			'O8H110040': offset=-0.39       ; 19Jul WD0947 
			'O8H104040': offset=-0.83       ; 19Jul WD1026 
			'O8H105040': offset=-1.17       ; 19Jul WD1026 
			'O8H106040': offset=-0.50       ; 19Jul WD1026 
			'O5K005030': offset= 1.09       ; 19Jul WD1057 
			'O5K006030': offset= 1.02       ; 19Jul WD1057 
			else: begin   &  endelse  &  endcase
			
		'2376':case root of			;G230L
			'O3ZX08HLM': offset=-0.7 ;gd153 02dec-fix sens @ 1650A
			'O8IA03020': offset=8.	;GRW Bad. Use 140L shft
; 06June FASTEX WDs confirmed/tweaked w/ wlabsrat.pro (from Short wl cont):
			'O5K001010': offset=-0.3 ;06jun-flat vs model wd0320
			'O5K002010': offset=-1.6 ;06jun-flat vs model wd0320
			'O69U01010': offset=-0.5 ;06jun-flatten vs mod. wd0320
			'O5K004010': offset=-1.9 ;06jun-flat vs model wd0947
			'O8H110010': offset=-0.8 ;06jun-flat vs model wd0947
			'O8H104010': offset=-1.5	;WD1026+453
			'O8H105010': offset=-1.3 	;WD1026+453
			'O8H106010': offset=-0.6 	;WD1026+453
			'O69U03010': offset=-0.5 	;WD1057+719
			'O5K007010': offset=-0.8 	;WD1657+343
			'O5K008010': offset=-0.8 	;WD1657+343
			'O8H111010': offset=-0.4 	;WD1657+343
			'O47Z01040': offset= 0.53       ; 19Jul P330E G230L
; lds offsets done using radvel=-81km/s and 1.545, 1.37 A/px 230L &LB, respect.
;	w/ 2 HeI line at 2945.96 vac WLs. vs. Model in 09Nov
			'O8H109040': offset=-0.40       ; 19Jul LDS749 G230L
			'O8H108040': offset= 0.57       ; 19Jul LDS749 G230L
			'OBBM01040': offset=+.16 	; 19jul lds749b G230L

			'OBC457020': offset= 0.83       ; 19Jul 174034 G230L
			'OBC408020': offset= 1.25       ; 19Jul 174304 G230L
			'OBC409020': offset= 0.93       ; 19Jul 180227 G230L
			'OBC410020': offset= 0.85       ; 19Jul 180529 G230L
			'OBC461020': offset= 0.59       ; 19Jul 181209 G230L
			'OBNL04020': offset= 1.24       ; 19Jul 175713 G230L
			'OBNL05020': offset= 0.11       ; 19Jul 180834 G230L

; Eye says ~0 shift		'OBNK01020': offset=-0.92 	;WD0308-565 wlck.pro
; 19May-HZ21 is 90% He, so try HeII lines:. No radial Vel meas. Line at 
;	2734.10A bit noisy, maybe assym.
; Also try 1640.42: px offset needed=(1640.42-1654.)/1.545= -8.8 px
; & ck w/ wd/koester/lines.HZ21: (2511.96-2524.7)/1.545 = -8.2 px --> avg= -8.5
			'O40901NSM': offset=-7.81  ;19jul HZ21 use 2512A
; 	(1640.42-1641.0)/1.545= -0.4 px 	Ck-OK
; & ck w/ wd/koester: (2511.96-2512.0)/1.545 = -0.03px keep at zero:
; keep 0		'ODTA16030': offset=-0.2	;19may HZ21 by hand
; GRW: 2800 line too weak in G230L. Use zero shift for these cases
;			'O3YX13TQM': offset=-0.93
;	.		'O45901020': offset= 0.67
;	.		'O45943020': offset=+0.43
;	.		'O5JJ03020': offset=-0.9
;	.		'O5JJ09020': offset=-1.10
;	.		'O69S04020': offset=-0.45
;	.		'O69S06020': offset=-0.36
;	.		'O69S07020': offset=+0.41
;	.		'O6I804020': offset=+0.46
;	.		'O8IA02020': offset=+1.08
;			'OB87N2020': offset=+1.31 ; 10may8 wl.offsets-2009
;			'OB8705020': offset=+2.28 ; 10jul10 wl.offsets-2009 grw
;			'OBW3L1020': offset=-2.33 ; 12jan10 wl.offsets-2009 grw
			else: begin   &  endelse  &  endcase

		'2375':case root of			;G230LB
			'O45A03010': offset= 0.37       ; 19Jul AGK+81 G230LB
			'O45A04010': offset= 0.61       ; 19Jul AGK+81 G230LB
			'O45A05010': offset=-0.22       ; 19Jul AGK+81 G230LB
			'O45A12010': offset= 0.16       ; 19Jul AGK+81 G230LB
			'O45A13010': offset=-0.28       ; 19Jul AGK+81 G230LB
			'O45A14010': offset=-0.12       ; 19Jul AGK+81 G230LB
			'O5IG01010': offset= 0.13       ; 19Jul AGK+81 G230LB
			'O5IG04010': offset=-0.26       ; 19Jul AGK+81 G230LB
			'O5IG05010': offset= 0.35       ; 19Jul AGK+81 G230LB
			'O69L04020': offset= 0.11       ; 19Jul AGK+81 G230LB
			'O6I901020': offset=-0.17       ; 19Jul AGK+81 G230LB
			'O6I902020': offset= 0.17       ; 19Jul AGK+81 G230LB
			'O6I903010': offset=-1.32       ; 19Jul AGK+81 G230LBE1
			'O6I903020': offset=-0.24       ; 19Jul AGK+81 G230LB
			'O6I904010': offset=-1.07       ; 19Jul AGK+81 G230LBE1
			'O6I904020': offset=-0.10       ; 19Jul AGK+81 G230LB
			'O6IL02020': offset=-2.09       ; 19Jul AGK+81 G230LB
			'O6IL02070': offset=-2.27       ; 19Jul AGK+81 G230LB
			'O6IL020C0': offset=-2.29       ; 19Jul AGK+81 G230LB

			'O6IL020H0': offset=-2.20       ; 19Jul AGK+81 G230LB
			'O8JJ01010': offset=-1.19       ; 19Jul AGK+81 G230LBE1
			'O8JJ01020': offset=-0.33       ; 19Jul AGK+81 G230LB
			'O8JJ02010': offset=-0.97       ; 19Jul AGK+81 G230LBE1
			'O8JJ03010': offset=-0.90       ; 19Jul AGK+81 G230LBE1
			'O8JJ03020': offset= 0.15       ; 19Jul AGK+81 G230LB
			'O8JJ04010': offset=-0.87       ; 19Jul AGK+81 G230LBE1
			'O8JJ04020': offset= 0.21       ; 19Jul AGK+81 G230LB
			'O8U201010': offset=-0.48       ; 19Jul AGK+81 G230LBE1
			'O8U201020': offset= 0.28       ; 19Jul AGK+81 G230LB
			'O8U203020': offset=-0.13       ; 19Jul AGK+81 G230LB
			'O8U204020': offset=-0.15       ; 19Jul AGK+81 G230LB
			'O8U205010': offset=-0.76       ; 19Jul AGK+81 G230LBE1
			'O8U206010': offset=-0.30       ; 19Jul AGK+81 G230LBE1
			'O8U206020': offset=-0.35       ; 19Jul AGK+81 G230LB
			'O8U207010': offset=-0.10       ; 19Jul AGK+81 G230LBE1
			'O8U207020': offset=-0.14       ; 19Jul AGK+81 G230LB
			'O8U208010': offset= 0.23       ; 19Jul AGK+81 G230LBE1
			'O8U208020': offset= 0.13       ; 19Jul AGK+81 G230LB

			'OA9J01050': offset=-0.30       ; 19Jul AGK+81 G230LB
			'OA9J01060': offset=-0.93       ; 19Jul AGK+81 G230LBE1
			'OBAU01010': offset=-0.84       ; 19Jul AGK+81 G230LBE1
			'OBAU01020': offset=-0.20       ; 19Jul AGK+81 G230LB
			'OBAU02010': offset=-0.68       ; 19Jul AGK+81 G230LBE1
			'OBAU03010': offset=-0.41       ; 19Jul AGK+81 G230LBE1
			'OBAU03020': offset= 0.21       ; 19Jul AGK+81 G230LB
			'OBAU04010': offset=-0.51       ; 19Jul AGK+81 G230LBE1
			'OBAU04020': offset= 0.15       ; 19Jul AGK+81 G230LB
			'OBAU05010': offset=-0.61       ; 19Jul AGK+81 G230LBE1
			'OBAU06010': offset=-0.78       ; 19Jul AGK+81 G230LBE1
			'OBAU06020': offset=-0.14       ; 19Jul AGK+81 G230LB
			'OBMZL1010': offset=-0.77       ; 19Jul AGK+81 G230LBE1
			'OBMZL3010': offset=-0.45       ; 19Jul AGK+81 G230LBE1
			'OBMZL3020': offset= 0.27       ; 19Jul AGK+81 G230LB
			'OBMZL4010': offset=-0.85       ; 19Jul AGK+81 G230LBE1
			'OBMZL4020': offset=-0.21       ; 19Jul AGK+81 G230LB
			'OBVNL1010': offset=-0.40       ; 19Jul AGK+81 G230LBE1
			'OBVNL1020': offset= 0.28       ; 19Jul AGK+81 G230LB
			'OBVNL2010': offset=-0.69       ; 19Jul AGK+81 G230LBE1
			'OBVNL3010': offset=-0.76       ; 19Jul AGK+81 G230LBE1
			'OC4IL1010': offset=-0.88       ; 19Jul AGK+81 G230LBE1
			'OC4IL2010': offset=-0.72       ; 19Jul AGK+81 G230LBE1
			'OC4IL2020': offset= 0.22       ; 19Jul AGK+81 G230LB
			'OC4IL3010': offset=-0.65       ; 19Jul AGK+81 G230LBE1
			'OCEIL1010': offset=-1.13       ; 19Jul AGK+81 G230LBE1
			'OCEIL1020': offset=-0.37       ; 19Jul AGK+81 G230LB
			'OCEIL3010': offset=-0.91       ; 19Jul AGK+81 G230LBE1
			'OCEIL4010': offset=-0.72       ; 19Jul AGK+81 G230LBE1
			'OCPKL1010': offset=-0.94       ; 19Jul AGK+81 G230LBE1
			'OCPKL2010': offset=-1.03       ; 19Jul AGK+81 G230LBE1
			'OCPKL2020': offset=-0.16       ; 19Jul AGK+81 G230LB
			'OCPKL3010': offset=-1.15       ; 19Jul AGK+81 G230LBE1
			'OCPKL3020': offset=-0.27       ; 19Jul AGK+81 G230LB
			'OD1AL1010': offset=-1.10       ; 19Jul AGK+81 G230LBE1
			'OD1AL1020': offset=-0.27       ; 19Jul AGK+81 G230LB
			'OD1AL2010': offset=-1.07       ; 19Jul AGK+81 G230LBE1
			'OD1AL4010': offset=-1.06       ; 19Jul AGK+81 G230LBE1
			'OD1AL4020': offset=-0.29       ; 19Jul AGK+81 G230LB
			'ODBVL1010': offset=-0.84       ; 19Jul AGK+81 G230LBE1
			'ODBVL2010': offset=-0.67       ; 19Jul AGK+81 G230LBE1
			'ODBVL2020': offset= 0.15       ; 19Jul AGK+81 G230LB
			'ODBVL3010': offset=-0.77       ; 19Jul AGK+81 G230LBE1
			'ODOHL1010': offset=-1.39       ; 19Jul AGK+81 G230LBE1
			'ODOHL1020': offset=-0.59       ; 19Jul AGK+81 G230LB
			'ODOHL2010': offset=-0.73       ; 19Jul AGK+81 G230LBE1
			'ODOHL3010': offset=-1.19       ; 19Jul AGK+81 G230LBE1
			'ODVKL1010': offset=-0.99       ; 19Jul AGK+81 G230LBE1
			'ODVKL1020': offset=-0.15       ; 19Jul AGK+81 G230LB
			'ODVKL2010': offset=-0.94       ; 19aug AGK+81 G230LBE1
			'ODVKL3010': offset=-1.05       ; 19aug AGK+81 G230LBE1
; END AGK			
; 06jun7-G230LB 52x2E1 prime WDs from wlabsrat.wd3-g230lb
			'O6IG10020': offset=-1.1  ; 06jun G191 Bad
			'O8V203040': offset=-1.1  ; 06jun G191
			'O8V202040': offset=-0.5  ; 06jun GD153
			'O8V204080': offset=+0.5  ; 06jun GD71
;  .08->.18->.54? :
			'O47Z01020': offset= 0.49	; 19Jul P330E G230LB
; 09jul16 ff bd75 based on MgII & ignores radial veloc. Do other g230lb relative
; 	to this O3WY02010 in nowavcal.pro. (162s exp ref spec)
			'O3WY02010': offset= 0.44       ; 19Jul BD+75D G230LB
			'O4A506010': offset= 0.21       ; 19Jul BD+75D G230LB
			'O8H201060': offset= 0.15  	;19jan bd75 bad
			'O8H201070': offset= 0.24  	;19jan bd75 bad
			'O8H201080': offset= 0.26  	;19jan bd75 bad
			'OA8B01020': offset=-0.30       ; 19Jul BD+75D G230LB
			'OA8B010I0': offset=-0.11       ; 19Jul BD+75D G230LB
			'OA8B11030': offset=-0.20       ; 19Jul BD+75D G230LB
			'OA8B11040': offset=-0.11       ; 19Jul BD+75D G230LB

			'O8H2010O0': offset=-0.76 ;19jan bd75crsplit=1 bad
			'O8H2010P0': offset=-0.72  ;19jan bd75  newl.log bad
			'O8H2010Q0': offset=-0.76  ;19jan bd75  newl.log bad
			'O8H2010R0': offset=-0.70  ;19jan bd75  newl.log bad
			'O8J501060': offset=-0.75  ;19jan bd75 newl.log bad
			'O8J501070': offset=-0.72  ;19jan bd75 newl.log bad
			'O8J501080': offset=-0.82  ;19jan bd75 newl.log bad
			'O6IL01020': offset= 0.57       ; 19Jul LDS749 G230LB
			'O6IL01060': offset= 0.65       ; 19aug LDS749 G230LB
			'O8H101030': offset= 0.30       ; 19Jul BD+17D G230LB
			'O8H102030': offset=-0.25       ; 19Jul BD+17D G230LB
			'O8I105010': offset= 0.13       ; 19Jul HD1721 G230LB
			'O8I105020': offset= 0.08 	; 19Jul HD1721 G230LB
			'O8I105030': offset= 0.14       ; 19Jul HD1721 G230LB
			'O8I105040': offset=-1.36       ; 19Jul HD1721 G230LBE1
			'O8I106020': offset= 0.43       ; 19Jul HD1721 G230LB
			'O8I106030': offset= 0.41       ; 19Jul HD1721 G230LB

			'OBC405020': offset= 0.31       ; 19Jul HD1654 G230LB
			'OBC405030': offset=-0.19       ; 19Jul HD1654 G230LBE1
			'OBNL02020': offset=-0.29       ; 19Jul HD3772 G230LBE1
			'OBNL03020': offset=-0.46       ; 19Jul HD1164 G230LBE1
			'OBNL06020': offset=-0.71       ; 19Jul HD1806 G230LBE1
			'OBNL07020': offset=-0.46       ; 19Jul BD+60D G230LBE1
			'OBNL08020': offset=-0.68       ; 19Jul HD3796 G230LBE1
			'OBNL09020': offset=-0.23       ; 19Jul HD3894 G230LBE1
			'OBNL11020': offset=-0.23       ; 19Jul HD2059 G230LBE1
			'OBTO02020': offset=-0.50       ; 19Jul HD1494 G230LBE1
			'OBTO03020': offset=-0.45       ; 19Jul HD1584 G230LBE1
			'OBTO04020': offset=-0.42       ; 19Jul HD1634 G230LBE1
			'OBTO05030': offset=-0.39       ; 19Jul LAMLEP G230LBE1
			'OBTO05040': offset= 0.19       ; 19Jul LAMLEP G230LB
			'OBTO06030': offset=-0.21       ; 19Jul 10LAC G230LBE1
			'OBTO06040': offset= 0.36       ; 19Jul 10LAC G230LB
			'OBTO07030': offset= 0.22       ; 19Jul MUCOL G230LBE1
			'OBTO07040': offset= 0.88       ; 19Jul MUCOL G230LB
			'OBTO08030': offset=-0.63       ; 19Jul KSI2CE G230LBE1
			'OBTO09030': offset=-0.35       ; 19Jul HD6075 G230LBE1
			'OBTO09040': offset= 0.36       ; 19Jul HD6075 G230LB
			'OBTO11010': offset= 0.72       ; 19Jul SIRIUS G230LB
			'OBTO11020': offset= 0.73       ; 19Jul SIRIUS G230LB
			'OBTO11030': offset= 0.76       ; 19Jul SIRIUS G230LB
			'OBTO12010': offset= 0.14       ; 19Jul SIRIUS G230LB
			'OBTO12020': offset= 0.11       ; 19Jul SIRIUS G230LB
			'OBTO12030': offset= 0.11       ; 19Jul SIRIUS G230LB
; No wave cals for 12813-Schmidt program OC3I*
			'OC3I01010': offset=-2.82 ;19Jul HD0090 G230LBE1.72-.91
			'OC3I02010': offset=-2.69       ; 19Jul HD0311 G230LBE1
			'OC3I03010': offset=-2.24       ; 19Jul HD0740 G230LBE1
			'OC3I04010': offset=-2.61       ; 19Jul HD1119 G230LBE1
			'OC3I05010': offset=-2.40       ; 19Jul HD1606 G230LBE1
			'OC3I06010': offset=-2.93       ; 19Jul HD2006 G230LBE1
			'OC3I07020': offset=-2.64       ; 19Jul HD1859 G230LBE1
			'OC3I08010': offset=-2.82       ; 19Jul BD21D0 G230LBE1
			'OC3I09010': offset=-2.20       ; 19Jul BD54D1 G230LBE1
			'OC3I10020': offset=-3.25       ; 19Jul BD29D2 G230LBE1
			'OC3I11020': offset=-2.96       ; 19Jul BD26D2 G230LBE1
			'OC3I12010': offset=-2.63       ; 19Jul BD02D3 G230LBE1
; No identifiable strong lines in GJ7541A. Fix wls by matching model at 1700A,
;	the weak 2800A would be -0.4?? HAS wavecal!
; 2013mar5-the model from Detlev has a line at 2479.3, which would mean that I
;	need to come back to ~-0.7, which DOES agree w/ 2800A result!
; 13Mar7-Switch nowavcal to use the 2479.3 line & del the -2.5 shift for 1700A:
			'OC3I13010': offset=-0.71	; 19Jul GJ7541A E1

			'O45P020G0': offset=+1.1 ; etaUMa 1.5A
			'O45P020H0': offset=+1.1 ; etaUMa 1.5A

			'O6H05W010': offset=-0.20	; 19jan HD146233 E1 bad
			'O6H05W020': offset=-0.28	; 19jan HD146233 E1 bad

			'ODTA72010': offset= 0.32       ; 19Jul ETA1DO G230LB
			'ODTA72020': offset=-0.65       ; 19Jul ETA1DO G230LBE1
			'ODTA03020': offset=-1.01       ; 19Jul HD1289 G230LBE1
			'ODTA04020': offset=-2.33       ; 19Jul HD1014 G230LBE1
			'ODTA05020': offset=-2.60       ; 19Jul HD2811 G230LBE1
			'ODTA06020': offset=-2.47       ; 19Jul HD5567 G230LBE1
			'ODTA07010': offset=-0.12       ; 19Jul 18SCO G230LBE1
			'ODTA08010': offset=-0.26       ; 19Jul 16CYGB G230LBE1
			'ODTA60010': offset=-0.56       ; 19Jul HD1670 G230LBE1
			'ODTA11010': offset=-0.46       ; 19Jul HD1151 G230LBE1
			'ODTA12020': offset= 0.45       ; 19Jul ETAUMA G230LB
			'ODTA13010': offset=-0.65       ; 19Jul FEIGE1 G230LBE1
			'ODTA14010': offset=-0.78       ; 19Jul FEIGE3 G230LBE1
			'ODTA15010': offset= 0.52       ; 19Jul HD9352 G230LB
			'ODTA15020': offset=-0.61       ; 19Jul HD9352 G230LBE1
			'ODTA18020': offset=-0.58       ; 19Jul HZ44 G230LBE1
			'ODTA19010': offset= 0.69       ; 19Jul 109VIR G230LB
			'ODTA19020': offset=-0.24       ; 19Jul 109VIR G230LBE1
			'ODTA51010': offset= 0.60       ; 19Jul DELUMI G230LB
			'ODTA51020': offset=-0.42       ; 19Jul DELUMI G230LBE1	
			else: begin   &  endelse  &  endcase

		'4300': case root of	; 02dec3 po41wl.g430l-befor from H&K
			'O40302010': offset= 1.19       ; 19Jul P041C G430L
			'O40302020': offset= 1.28       ; 19Jul P041C G430L
			'O40302030': offset= 1.19       ; 19Jul P041C G430L
			'O40302040': offset= 1.05       ; 19Jul P041C G430L
			'O40302050': offset= 0.81       ; 19Jul P041C G430L
			'O40302060': offset= 0.53       ; 19Jul P041C G430L
			'O40302070': offset= 0.17       ; 19Jul P041C G430L
			'O40302090': offset=-0.57       ; 19Jul P041C G430L
			'O403020A0': offset=-0.83       ; 19Jul P041C G430L
			'O403020B0': offset=-1.00       ; 19Jul P041C G430L
			'O403020C0': offset=-1.09       ; 19Jul P041C G430L
			
			'O8H101010': offset=-1.87       ; 19Jul BD+17D G430LE1
			'O8H101020': offset= 0.11       ; 19Jul BD+17D G430L
			'O8H102010': offset=-2.36       ; 19Jul BD+17D G430LE1
			'O8H102020': offset=-0.38       ; 19Jul BD+17D G430L
			'O8H103010': offset=-1.71       ; 19Jul BD+17D G430LE1

			'ODDG01010': offset=-0.65       ; 19Jul GRW+70 G430LE1
			'ODDG01020': offset= 0.53       ; 19Jul GRW+70 G430L
			'ODDG02010': offset=-0.75       ; 19Jul GRW+70 G430LE1
			'ODDG02020': offset= 0.37       ; 19Jul GRW+70 G430L
			'ODDG03010': offset=-0.88       ; 19Jul GRW+70 G430LE1
			'ODDG03020': offset= 0.23       ; 19Jul GRW+70 G430L
			'ODDG04010': offset=-0.73       ; 19Jul GRW+70 G430LE1
			'ODDG04020': offset= 0.44       ; 19Jul GRW+70 G430L
			'OBNF07010': offset=-0.53       ; 19Jul KF06T2 G430LE1
			'OBVP08010': offset=-0.20       ; 19Jul KF06T2 G430LE1
			'OBBC10010': offset=-0.94       ; 19Jul P330E G430LE1
			'OBC404010': offset=-0.98       ; 19Jul P330E G430LE1
			'OBNF06010': offset=-0.76       ; 19Jul P330E G430LE1
			'OBC403010': offset=-0.75       ; 19Jul P177D G430LE1

; G430L AGK
			'O45A01020': offset= 0.17       ; 19Jul AGK+81 G430L
			'O45A03020': offset= 0.62       ; 19Jul AGK+81 G430L
			'O45A04020': offset= 0.80       ; 19Jul AGK+81 G430L
			'O45A06020': offset= 0.29       ; 19Jul AGK+81 G430L
			'O45A12020': offset= 0.38       ; 19Jul AGK+81 G430L
			'O45A15020': offset= 0.25       ; 19Jul AGK+81 G430L
			'O45A16020': offset= 0.33       ; 19Jul AGK+81 G430L
			'O45A17020': offset= 0.36       ; 19Jul AGK+81 G430L
			'O45A18020': offset= 0.21       ; 19Jul AGK+81 G430L
			'O5IG01020': offset= 0.39       ; 19Jul AGK+81 G430L
			'O5IG02020': offset= 0.25       ; 19Jul AGK+81 G430L
			'O5IG03020': offset= 0.42       ; 19Jul AGK+81 G430L
			'O5IG05020': offset= 0.45       ; 19Jul AGK+81 G430L
			'O5IG06020': offset= 0.27       ; 19aug AGK+81 G430L
			'O5IG07020': offset= 0.33       ; 19Jul AGK+81 G430L
			'O69L01030': offset= 0.30       ; 19Jul AGK+81 G430L
			'O69L02030': offset= 0.37       ; 19Jul AGK+81 G430L
			'O69L03030': offset= 0.29       ; 19Jul AGK+81 G430L
			'O69L04030': offset= 0.34       ; 19Jul AGK+81 G430L
			'O6B601090': offset=-0.59       ; 19Jul AGK+81 G430L
			'O6B6010B0': offset=-0.39       ; 19Jul AGK+81 G430L
			'O6B6010D0': offset=-2.08       ; 19Jul AGK+81 G430LE1
			'O6I901030': offset= 0.27       ; 19Jul AGK+81 G430L
			'O6I902030': offset= 0.53       ; 19Jul AGK+81 G430L
			'O6I903030': offset= 0.12       ; 19Jul AGK+81 G430L
			'O6I903040': offset=-1.38       ; 19Jul AGK+81 G430LE1
			'O6I904030': offset= 0.25       ; 19Jul AGK+81 G430L
			'O6I904040': offset=-1.29       ; 19aug AGK+81 G430LE1
			'O6IL02010': offset=-2.59       ; 19Jul AGK+81 G430L
			'O6IL02030': offset=-2.45       ; 19Jul AGK+81 G430L
			'O6IL02060': offset=-2.59       ; 19Jul AGK+81 G430L
			'O6IL02080': offset=-2.61       ; 19Jul AGK+81 G430L
			'O6IL020B0': offset=-2.60       ; 19Jul AGK+81 G430L
			'O6IL020D0': offset=-2.60       ; 19Jul AGK+81 G430L
			'O6IL020G0': offset=-2.57       ; 19Jul AGK+81 G430L
			'O6IL020I0': offset=-2.52       ; 19Jul AGK+81 G430L
			'O8JJ01040': offset=-1.33       ; 19aug AGK+81 G430LE1
			'O8JJ02030': offset= 0.51       ; 19Jul AGK+81 G430L
			'O8JJ02040': offset=-1.03       ; 19Jul AGK+81 G430LE1
			'O8JJ03030': offset= 0.38       ; 19Jul AGK+81 G430L
			'O8JJ03040': offset=-0.98       ; 19Jul AGK+81 G430LE1
			'O8JJ04030': offset= 0.70       ; 19Jul AGK+81 G430L
			'O8JJ04040': offset=-0.92       ; 19Jul AGK+81 G430LE1
			'O8U201030': offset= 0.64       ; 19Jul AGK+81 G430L
			'O8U201040': offset=-0.70       ; 19Jul AGK+81 G430LE1
			'O8U202030': offset= 0.24       ; 19Jul AGK+81 G430L
			'O8U203040': offset=-0.15       ; 19Jul AGK+81 G430LE1
			'O8U204030': offset= 0.35       ; 19Jul AGK+81 G430L
			'O8U205030': offset= 0.38       ; 19Jul AGK+81 G430L
			'O8U205040': offset=-0.98       ; 19Jul AGK+81 G430LE1
			'O8U206040': offset=-0.71       ; 19Jul AGK+81 G430LE1
			'O8U207030': offset= 0.33       ; 19Jul AGK+81 G430L
			'O8U207040': offset=-0.38       ; 19Jul AGK+81 G430LE1
			'O8U208030': offset= 0.52       ; 19Jul AGK+81 G430L
			'O8U220090': offset= 0.65       ; 19Jul AGK+81 G430Lskip
			'O8U2200A0': offset= 0.23       ; 19aug AGK+81 G430Lskip
			'O8U2200B0': offset= 0.17       ; 19Jul AGK+81 G430L
			'O8U2200D0': offset=-0.33       ; 19Jul AGK+81 G430Lskip
			'O8U2200F0': offset=-0.88       ; 19Jul AGK+81 G430Lskip
; see dir2009.log for new SM4 data:
			'OA9J01070': offset=-0.82       ; 19Jul AGK+81 G430LE1
			'OA9J01080': offset=+0.31       ; 19Jul AGK+81 G430LE1
			'OA9J020A0': offset= 1.63       ; 19Jul AGK+81 G430L skip
			'OA9J020B0': offset=-1.21       ; 19Jul AGK+81 G430L skip
			'OA9J020C0': offset= 0.92       ; 19Jul AGK+81 G430L skip
			'OA9J020D0': offset=-1.14       ; 19Jul AGK+81 G430L skip
			'OA9J020E0': offset= 0.55       ; 19Jul AGK+81 G430L
			'OA9J020F0': offset=-1.25       ; 19Jul AGK+81 G430L skip
			'OA9J020G0': offset=+0.10       ; 19Jul AGK+81 G430L skip
			'OA9J020H0': offset=-1.09       ; 19Jul AGK+81 G430L skip
			'OA9J020I0': offset=-0.29       ; 19Jul AGK+81 G430LE1
			'OA9J020J0': offset=-1.18       ; 19Jul AGK+81 G430L skip
			'OA9J020K0': offset= 1.73       ; 19Jul AGK+81 G430L skip
			'OA9J020L0': offset=-1.12       ; 19Jul AGK+81 G430L skip
			'OA9J020M0': offset= 1.32       ; 19Jul AGK+81 G430L skip
			'OBAU01030': offset=+0.03       ; 19Jul AGK+81 G430L
			'OBAU01040': offset=-1.03       ; 19Jul AGK+81 G430LE1
			'OBAU02030': offset= 0.38       ; 19Jul AGK+81 G430L
			'OBAU02040': offset=-0.78       ; 19Jul AGK+81 G430LE1
			'OBAU03030': offset= 0.46       ; 19Jul AGK+81 G430L
			'OBAU03040': offset=-0.60       ; 19Jul AGK+81 G430LE1
			'OBAU04030': offset= 0.56       ; 19Jul AGK+81 G430L
			'OBAU04040': offset=-0.55       ; 19Jul AGK+81 G430LE1
			'OBAU05030': offset=+0.26       ; 19Jul AGK+81 G430LE1
			'OBAU05040': offset=-0.75       ; 19Jul AGK+81 G430LE1
			'OBAU06030': offset=+0.05       ; 19Jul AGK+81 G430L
			'OBAU06040': offset=-0.96       ; 19Jul AGK+81 G430LE1
			'OBAU21090': offset= 1.46       ; 19Jul AGK+81 G430L skip
			'OBAU210A0': offset= 0.70       ; 19Jul AGK+81 G430L skip
			'OBAU210B0': offset= 0.28       ; 19Jul AGK+81 G430L
			'OBAU210C0': offset=-0.24       ; 19Jul AGK+81 G430L skip
			'OBAU210D0': offset=-0.79       ; 19Jul AGK+81 G430L skip
			'OBAU210E0': offset=-0.72       ; 19Jul AGK+81 G430LE1
			'OBAU210F0': offset=-1.68       ; 19Jul AGK+81 G430L skip
			'OBAU22090': offset= 1.55       ; 19Jul AGK+81 G430L skip
			'OBAU220A0': offset= 0.66       ; 19Jul AGK+81 G430L skip
			'OBAU220B0': offset= 0.27       ; 19Jul AGK+81 G430L
			'OBAU220C0': offset=-0.17       ; 19Jul AGK+81 G430L skip
			'OBAU220D0': offset=-0.90       ; 19Jul AGK+81 G430L skip
			'OBAU220E0': offset=-0.87       ; 19Jul AGK+81 G430LE1
			'OBAU220F0': offset=-1.76       ; 19Jul AGK+81 G430L skip
			'OBMZL1030': offset=+0.27       ; 19Jul AGK+81 G430L
			'OBMZL1040': offset=-0.74       ; 19Jul AGK+81 G430LE1
			'OBMZM1090': offset= 0.93       ; 19Jul AGK+81 G430L skip
			'OBMZM10A0': offset=+0.12       ; 19Jul AGK+81 G430L skip
			'OBMZM10B0': offset=+0.05       ; 19Jul AGK+81 G430L
			'OBMZM10C0': offset=-0.53       ; 19Jul AGK+81 G430L skip
			'OBMZM10D0': offset=-1.14       ; 19Jul AGK+81 G430L skip
			'OBMZM10E0': offset=-1.02       ; 19Jul AGK+81 G430LE1
			'OBMZM10F0': offset=-1.97       ; 19Jul AGK+81 G430L skip
			'OBMZL3030': offset= 0.57       ; 19Jul AGK+81 G430L
			'OBMZL3040': offset=-0.53       ; 19Jul AGK+81 G430LE1
			'OBMZL4030': offset=+0.10       ; 19Jul AGK+81 G430L
			'OBMZL4040': offset=-1.16       ; 19Jul AGK+81 G430LE1
			'OBVNL1030': offset= 0.51       ; 19Jul AGK+81 G430L
			'OBVNL1040': offset=-0.67       ; 19Jul AGK+81 G430LE1
			'OBVNM1090': offset= 1.49       ; 19Jul AGK+81 G430L skip
			'OBVNM10A0': offset= 0.45       ; 19Jul AGK+81 G430L skip
			'OBVNM10B0': offset=+0.04       ; 19Jul AGK+81 G430L
			'OBVNM10C0': offset=-0.48       ; 19Jul AGK+81 G430L skip
			'OBVNM10D0': offset=-1.19       ; 19Jul AGK+81 G430L skip
			'OBVNM10E0': offset=-1.08       ; 19Jul AGK+81 G430LE1
			'OBVNM10F0': offset=-1.92       ; 19Jul AGK+81 G430L skip
			'OBVNL2030': offset= 0.40       ; 19Jul AGK+81 G430L
			'OBVNL2040': offset=-0.80       ; 19Jul AGK+81 G430LE1
			'OBVNL3030': offset= 0.44       ; 19Jul AGK+81 G430L
			'OBVNL3040': offset=-0.80       ; 19Jul AGK+81 G430LE1
			'OC4IL1030': offset=+0.09       ; 19Jul AGK+81 G430L
			'OC4IL1040': offset=-1.17       ; 19Jul AGK+81 G430LE1
			'OC4IL2030': offset= 0.53       ; 19Jul AGK+81 G430L
			'OC4IL2040': offset=-0.75       ; 19Jul AGK+81 G430LE1
			'OC4IL3030': offset= 0.39       ; 19Jul AGK+81 G430L
			'OC4IL3040': offset=-0.64       ; 19Jul AGK+81 G430LE1
			'OCEIL1030': offset=-0.16       ; 19Jul AGK+81 G430L
			'OCEIL1040': offset=-1.22       ; 19Jul AGK+81 G430LE1
			'OC4IM1090': offset= 1.51       ; 19Jul AGK+81 G430L skip
			'OC4IM10A0': offset= 0.48       ; 19Jul AGK+81 G430L skip
			'OC4IM10B0': offset=-0.01       ; 19Jul AGK+81 G430L
			'OC4IM10C0': offset=-0.59       ; 19Jul AGK+81 G430L skip
			'OC4IM10D0': offset=-1.34       ; 19Jul AGK+81 G430L skip
			'OC4IM10E0': offset=-1.12       ; 19Jul AGK+81 G430LE1
			'OC4IM10F0': offset=-2.01       ; 19Jul AGK+81 G430L skip
			'OCEIL3030': offset=+0.29       ; 19Jul AGK+81 G430L
			'OCEIL3040': offset=-1.00       ; 19Jul AGK+81 G430LE1
			'OCEIL4030': offset=+0.30       ; 19Jul AGK+81 G430L
			'OCEIL4040': offset=-0.73       ; 19Jul AGK+81 G430LE1
			'OCEIM1090': offset= 2.01       ; 19Jul AGK+81 G430L skip
			'OCEIM10A0': offset= 1.08       ; 19Jul AGK+81 G430L skip
			'OCEIM10B0': offset= 0.59       ; 19Jul AGK+81 G430L
			'OCEIM10C0': offset=+0.16       ; 19Jul AGK+81 G430L skip
			'OCEIM10D0': offset=-0.62       ; 19Jul AGK+81 G430L skip
			'OCEIM10E0': offset=-0.61       ; 19Jul AGK+81 G430LE1
			'OCEIM10F0': offset=-1.41       ; 19Jul AGK+81 G430L skip
			'OCPKL1030': offset=+0.15       ; 19Jul AGK+81 G430L
			'OCPKL1040': offset=-1.11       ; 19Jul AGK+81 G430LE1
			'OCPKL2030': offset=+0.25       ; 19Jul AGK+81 G430L
			'OCPKL2040': offset=-1.01       ; 19Jul AGK+81 G430LE1
			'OCPKM2090': offset= 1.45       ; 19Jul AGK+81 G430L skip
			'OCPKM20A0': offset= 0.39       ; 19Jul AGK+81 G430L skip
			'OCPKM20B0': offset= 0.20       ; 19Jul AGK+81 G430L
			'OCPKM20C0': offset=-0.40       ; 19Jul AGK+81 G430L skip
			'OCPKM20D0': offset=-0.82       ; 19Jul AGK+81 G430L skip
			'OCPKM20E0': offset=-0.93       ; 19Jul AGK+81 G430LE1
			'OCPKM20F0': offset=-1.73       ; 19Jul AGK+81 G430L skip
			'OCPKL3030': offset=+0.06       ; 19Jul AGK+81 G430L
			'OCPKL3040': offset=-1.20       ; 19Jul AGK+81 G430LE1
			'OD1AL1030': offset=+0.08       ; 19Jul AGK+81 G430L
			'OD1AL1040': offset=-1.11       ; 19Jul AGK+81 G430LE1
			'OD1AL2030': offset=+0.19       ; 19Jul AGK+81 G430L
			'OD1AL2040': offset=-1.22       ; 19Jul AGK+81 G430LE1
			'OD1AL4030': offset=+0.06       ; 19Jul AGK+81 G430L
			'OD1AL4040': offset=-0.94       ; 19Jul AGK+81 G430LE1
			'OD1AM1090': offset= 2.11       ; 19Jul AGK+81 G430L skip
			'OD1AM10A0': offset= 1.24       ; 19Jul AGK+81 G430L skip
			'OD1AM10B0': offset= 0.87       ; 19Jul AGK+81 G430L
			'OD1AM10C0': offset= 0.22       ; 19Jul AGK+81 G430L skip
			'OD1AM10D0': offset=-0.50       ; 19Jul AGK+81 G430L skip
			'OD1AM10E0': offset=-0.70       ; 19Jul AGK+81 G430LE1
			'OD1AM10F0': offset=-1.46       ; 19Jul AGK+81 G430L skip
			'ODBVL1030': offset=+0.11       ; 19Jul AGK+81 G430L
			'ODBVL1040': offset=-1.15       ; 19Jul AGK+81 G430LE1
			'ODBVM1090': offset= 1.61       ; 19Jul AGK+81 G430L skip
			'ODBVM10A0': offset= 0.78       ; 19Jul AGK+81 G430L skip
			'ODBVM10B0': offset= 0.28       ; 19Jul AGK+81 G430Lskip?
			'ODBVM10C0': offset=-0.37       ; 19Jul AGK+81 G430L skip
			'ODBVM10D0': offset=-0.98       ; 19Jul AGK+81 G430L skip
			'ODBVM10E0': offset=-0.96       ; 19Jul AGK+81 G430LE1
			'ODBVM10F0': offset=-1.86       ; 19Jul AGK+81 G430L skip
			'ODBVL2030': offset= 0.48       ; 19Jul AGK+81 G430L
			'ODBVL2040': offset=-0.87       ; 19Jul AGK+81 G430LE1
			'ODBVL3030': offset=+0.32       ; 19Jul AGK+81 G430L
			'ODBVL3040': offset=-0.87       ; 19Jul AGK+81 G430LE1
			'ODOHL1030': offset=-0.23       ; 19Jul AGK+81 G430L
			'ODOHL1040': offset=-1.35       ; 19Jul AGK+81 G430LE1
			'ODOHL2030': offset= 0.47       ; 19Jul AGK+81 G430L
			'ODOHL2040': offset=-0.93       ; 19Jul AGK+81 G430LE1
			'ODOHM1090': offset= 2.10       ; 19Jul AGK+81 G430L skip
			'ODOHM10A0': offset= 0.71       ; 19Jul AGK+81 G430L skip
			'ODOHM10B0': offset= 0.34       ; 19Jul AGK+81 G430L skip
			'ODOHM10C0': offset=-0.19       ; 19Jul AGK+81 G430L skip
			'ODOHM10D0': offset=-0.76       ; 19Jul AGK+81 G430L skip
			'ODOHM10E0': offset=-0.75       ; 19Jul AGK+81 G430LE1
			'ODOHM10F0': offset=-1.53       ; 19Jul AGK+81 G430L skip
			'ODOHL3030': offset=+0.20       ; 19Jul AGK+81 G430LE1
			'ODOHL3040': offset=-1.33       ; 19Jul AGK+81 G430LE1
			'ODVKL1030': offset=-0.09       ; 19Jul AGK+81 G430L
			'ODVKL1040': offset=-1.27       ; 19Jul AGK+81 G430LE1
			'ODVKL2030': offset=+0.27       ; 19Jul AGK+81 G430L
			'ODVKL2040': offset=-1.22       ; 19aug AGK+81 G430LE1
			'ODVKL3030': offset=+0.30       ; 19aug AGK+81 G430L
			'ODVKL3040': offset=-1.15       ; 19aug AGK+81 G430LE1
; END AGK
; Prime WD offsets in wlerr.g430l-wd. For Primary WDs:
			'O3TT42020': offset= 0.37       ; 19Jul GD153 
			'O3TT43020': offset= 0.38       ; 19Jul GD153 
			'O3TT44020': offset= 0.53       ; 19Jul GD153 
			'O3TT46020': offset= 0.33       ; 19Jul GD153 
			'O3TT47020': offset= 0.28       ; 19Jul GD153 
			'O3TT48020': offset= 0.18       ; 19Jul GD153 
			'O4D103020': offset= 0.49       ; 19Jul GD153 
			'O4A502030': offset= 0.17       ; 19Jul GD153 
			'O8V202050': offset=-1.15       ; 19Jul GD153 E1
			'OBC402040': offset=-0.53       ; 19Jul GD153 E1
			'OBC402050': offset= 0.22       ; 19Jul GD153 
			'OBTO10040': offset=-1.34       ; 19Jul GD153 E1
			'OBTO10050': offset= 0.10       ; 19Jul GD153 
			'OC5506040': offset=-1.51       ; 19Jul GD153 E1
			'OC5506050': offset=-0.21       ; 19Jul GD153 
			'OCGA05040': offset=-1.10       ; 19Jul GD153 E1
			'OCGA05050': offset= 0.41       ; 19Jul GD153 
			'ODCK02040': offset=-0.78       ; 19Jul GD153 E1
			'ODCK02050': offset= 0.67       ; 19Jul GD153 
			'ODUD02040': offset=-1.11       ; 19Jul GD153 E1
			'ODUD02050': offset=-0.17       ; 19Jul GD153 

			'O6IG01080': offset=-1.58       ; GD71 E1 52x0.05 10jul
			'O6IG01090': offset=-1.83       ; GD71 E1 52x0.1 10jul
			'O6IG010A0': offset=-1.53       ; GD71 E1 52x0.2 10jul
			'O6IG010B0': offset=-1.33       ; GD71 E1 52x0.5 10jul

			'O61001010': offset= 0.44       ; 19Jul GD71 
			'O61001020': offset= 0.20       ; 19Jul GD71 
			'O61002010': offset=-0.12       ; 19Jul GD71 
			'O61003010': offset= 0.23       ; 19Jul GD71 
			'O61004010': offset= 0.29       ; 19Jul GD71 
			'O61005010': offset= 0.20       ; 19Jul GD71 
			'O61006010': offset= 0.18       ; 19Jul GD71 
			'O5I001040': offset= 0.24       ; 19Jul GD71 
			'O6IG010C0': offset=-1.59       ; 19Jul GD71 E1
			'O8V201040': offset= 0.29       ; 19Jul GD71 unstable?
			'O8V201050': offset=-0.53       ; 19Jul GD71 E1
			'OBC401040': offset=-1.19       ; 19Jul GD71 E1
			'OBVP06040': offset=-0.70       ; 19Jul GD71 E1
			'OBVP06050': offset= 0.44       ; 19Jul GD71 
			'OC3I15020': offset=-3.70       ; 19Jul GD71 E1
			'OCGA04040': offset=-0.95       ; 19Jul GD71 E1
			'OCGA04050': offset= 0.25       ; 19Jul GD71 
			'ODCK01040': offset=-0.85       ; 19Jul GD71 E1
			'ODUD01040': offset=-1.19       ; 19Jul GD71 E1
			'ODUD01050': offset= 0.45       ; 19Jul GD71 
			
; G430L
			'O4D101020': offset= 0.12       ; 19Jul G191B2 
			'O4D102020': offset= 0.10       ; 19Jul G191B2 
			'O69U05020': offset= 0.22       ; 19Jul G191B2 
			'O69U06020': offset= 0.19       ; 19Jul G191B2 
			'O8V203020': offset= 0.10       ; 19Jul G191B2  unstable
			'O8V203030': offset=-0.7       ; 19Jul G191B2 E1 eye
			'OBBC07010': offset=-4.35       ; 19Jul G191B2 E1
			'OBBC07020': offset=-3.04       ; 19Jul G191B2 
			'OBNF05010': offset=-3.99       ; 19Jul G191B2 E1 unstab
			'OBNF05020': offset=-2.73       ; 19Jul G191B2 
			'OBVP07010': offset=-3.18       ; 19Jul G191B2 
			'OBVP07020': offset=-4.31       ; 19Jul G191B2 E1
			'OC3I14020': offset=-4.63       ; 19Jul G191B2 E1
			'OC3I14030': offset=-3.40       ; 19Jul G191B2 
			'OCGA06020': offset=-3.09       ; 19Jul G191B2 
			'OCGA06030': offset=-4.49       ; 19Jul G191B2 E1 unstab
			'ODCK03020': offset=-3.15       ; 19Jul G191B2 
			'ODCK03030': offset=-4.47       ; 19Jul G191B2 E1
			'ODUD03020': offset=-2.91       ; 19Jul G191B2 
			'ODUD03030': offset=-4.57       ; 19Jul G191B2 E1

			'OCWGA1030': offset=-0.87	; 19jul WD1327-083 E1
			'OCWGA2030': offset=-0.93	; 19jul WD2341+322 E1
			
			'O8I105060': offset=-0.20       ; 19Jul HD1721 G430L
			'O8I106010': offset=-0.05       ; 19Jul HD1721 G430L
			'O8I106040': offset=-0.01       ; 19Jul HD1721 G430L
			'O5JA040H0': offset= 0.27       ; 19Jul BD-11D G430L

			'O6D201070': offset=-0.63       ; 19Jul HD2094 G430L
			'O6D201080': offset=-0.67       ; 19Jul HD2094 G430L
			'O6D201090': offset=-0.69       ; 19Jul HD2094 G430L
			'O6D2010A0': offset=-0.70       ; 19Jul HD2094 G430L
			'O6D2010B0': offset=-0.65       ; 19Jul HD2094 G430L
			'O6D203070': offset=-0.74       ; 19Jul HD2094 G430L
			'O6D203080': offset=-0.74       ; 19Jul HD2094 G430L
			'O6D203090': offset=-0.72       ; 19Jul HD2094 G430L
			'O6D2030A0': offset=-0.68       ; 19Jul HD2094 G430L
			'O6D2030B0': offset=-0.66       ; 19Jul HD2094 G430L
			'O6N301010': offset=-3.54       ; 19Jul HD2094 G430L
			'O6N3A10A0': offset=-0.79       ; 19Jul HD2094 G430L
			'O6N3A10B0': offset=-0.79       ; 19Jul HD2094 G430L
			'O6N3A10C0': offset=-0.79       ; 19Jul HD2094 G430L
			'O6N3A10D0': offset=-0.80       ; 19Jul HD2094 G430L
			'O6N3A30A0': offset=-0.66       ; 19Jul HD2094 G430L
			'O6N3A30B0': offset=-0.65       ; 19Jul HD2094 G430L
			'O6N3A30C0': offset=-0.64       ; 19Jul HD2094 G430L
			'O6N3A30D0': offset=-0.64       ; 19Jul HD2094 G430L
			'O6N303010': offset=-3.47       ; 19Jul HD2094 G430L

			'OBNK01030': offset=-1.97       ; 19Jul WD0308 E1
;06June FASTEX G430L WDs confirmed/tweaked w/ wlabsrat.pro (from Line symmetry)
; old not so good	'O5K007020': offset=-0.6        ;WD1657 wlabsrat
; old			'O8V101010': offset=-0.8        ;WD1657 wlabsrat
; old			'O8V101020': offset=-0.8        ;WD1657 E1 wlabsrat
; old			'O8H111030': offset=-1.4        ;WD1657 E1 wlabsrat
; old			'O5K001020': offset=-0.2  ;06jun-flat vs model wd0320
; old			'O5K002020': offset=-0.6  ;06jun flat vs model wd0320
; old			'O69U01020': offset=-0.4  ;06jun flat vs model wd0320
; old			'O5K003020': offset=-0.4  ;06jun flatten rat. wd0947
; old			'O5K004020': offset=-0.6  ;06jun flatten rat. wd0947
; old			'O8H110020': offset=-1.0  ;06jun flatten rat. wd0947
; old			'O8H110030': offset=-2.0  ;06jun flatten wd0947 E1
; X-correl better:			
			'O5K007020': offset=-0.26       ; 19Jul WD1657 
			'O5K008020': offset= 0.40       ; 19Jul WD1657 
			'O8V101010': offset= 0.28 ; 19Jul WD1657 .27->.20->.36
			'O8V101020': offset= 0.01       ; 19Jul WD1657 E1
			'O8H111020': offset=-0.63 ; 19Jul WD1657 .65->.53->.74
			'O8H111030': offset=-0.86       ; 19Jul WD1657 E1
			'O5K002020': offset=-0.61       ; 19Jul WD0320 
			'O69U01020': offset=-0.72       ; 19Jul WD0320 
			'O5K003020': offset= 0.36       ; 19Jul WD0947 
			'O5K004020': offset=-0.30       ; 19Jul WD0947 
			'O69U02020': offset=-0.40       ; 19Jul WD0947 
			'O8H110020': offset=-1.31       ; 19Jul WD0947 
			'O8H110030': offset=-1.71       ; 19Jul WD0947 E1
			'O8H104020': offset=-0.72       ; 19Jul WD1026 
			'O8H104030': offset=-1.69       ; 19Jul WD1026 E1
			'O8H105020': offset=-0.92       ; 19Jul WD1026 
			'O8H105030': offset=-2.40       ; 19Jul WD1026 E1
			'750': offset=-0.22 ; 19Jul WD1026 .08->.36->.08
			'O8H106030': offset=-2.23       ; 19Jul WD1026 E1
			'O5K005020': offset= 0.13 ; 19Jul WD1057 .12->.16->.10
			'O5K006020': offset= 0.36       ; 19Jul WD1057 
			'O69U03020': offset= 0.29       ; 19Jul WD1057 

			'O8V102010': offset=+0.7  ;snap-1 skip
			'O8V102020': offset=-0.5  ;snap-1 E1 skip
			'O8V103010': offset=+0.7  ;snap-1 skip
			'O8V103020': offset=-0.5  ;snap-1 E1 skip
			'O3WY02030': offset= 0.81       ; 19Jul BD+75D G430L
			'O4A5050K0': offset= 0.55       ; 19Jul BD+75D G430L
			'O8h201020': offset=-.3 ; bd75 06jun
			'O8h201040': offset=-.3 ; bd75 06jun

			'O57T01010': offset=-0.07 	; 19jul HZ43
			'O57T02010': offset=+0.13 	; 19jul HZ43
			'O69U07020': offset=-0.17       ; 19Jul HZ43 G430L
			'O69U08020': offset=0.	 	; 19jul HZ43
			'O8H107020': offset=-0.15       ; 19Jul LDS749 G430L
			'O8H107030': offset=-1.22       ; 19Jul LDS749 G430LE1
			'O8H108030': offset=-1.44       ; 19Jul LDS749 G430LE1
			'O8H109020': offset=-0.42       ; 19Jul LDS749 G430L
			'O8H109030': offset=-2.19       ; 19Jul LDS749 G430LE1
			'OBBM01030': offset=-1.43       ; 19Jul LDS749 G430LE1
			'OBC405040': offset=-0.67       ; 19Jul HD1654 G430LE1
			'OBC405050': offset= 0.20       ; 19Jul HD1654 G430L
			'OBC406030': offset=-1.19       ; 19Jul 173252 G430LE1
			'OBC407030': offset=-0.85       ; 19Jul 174034 G430LE1
			'OBC457030': offset=-0.59       ; 19Jul 174034 G430LE1
			'OBC408030': offset=-0.62       ; 19Jul 174304 G430LE1
			'OBC409030': offset=-0.74       ; 19Jul 180227 G430LE1
			'OBC410030': offset=-0.82       ; 19Jul 180529 G430LE1
			'OBC411030': offset=-1.45       ; 19Jul 181209 G430LE1
			'OBC461030': offset=-1.22       ; 19Jul 181209 G430LE1
			'OBNL02030': offset=-0.85       ; 19Jul HD3772 G430LE1
			'OBNL03030': offset=-0.93       ; 19Jul HD1164 G430LE1
			'OBNL04030': offset=-0.52       ; 19Jul 175713 G430LE1
			'OBNL05030': offset=-1.32       ; 19Jul 180834 G430LE1
			'OBNL06030': offset=-1.15       ; 19Jul HD1806 G430LE1
			'OBNL07030': offset=-1.02       ; 19Jul BD+60D G430LE1
			'OBNL08010': offset=-1.10       ; 19Jul HD3796 G430LE1
			'OBNL09010': offset=-0.99       ; 19Jul HD3894 G430LE1
			'OBNL10010': offset=-0.66       ; 19Jul HD1062 G430LE1
			'OBNL11010': offset=-0.73       ; 19Jul HD2059 G430LE1
			'OBTO01010': offset=-0.77       ; 19Jul HD1592 G430LE1
			'OBTO02030': offset=-1.01       ; 19Jul HD1494 G430LE1
			'OBTO02040': offset= 0.22       ; 19Jul HD1494 G430L
			'OBTO03030': offset=-1.00       ; 19Jul HD1584 G430LE1
			'OBTO03040': offset= 0.20       ; 19Jul HD1584 G430L
			'OBTO04030': offset=-0.94       ; 19Jul HD1634 G430LE1
			'OBTO04040': offset= 0.16       ; 19Jul HD1634 G430L
			'OBTO05010': offset= 0.19       ; 19Jul LAMLEP G430L
			'OBTO05020': offset=-0.90       ; 19Jul LAMLEP G430LE1
			'OBTO06010': offset= 0.27       ; 19Jul 10LAC G430L
			'OBTO06020': offset=-0.86       ; 19Jul 10LAC G430LE1
			'OBTO07010': offset= 0.49       ; 19Jul MUCOL G430L
			'OBTO07020': offset=-0.78       ; 19Jul MUCOL G430LE1
			'OBTO08020': offset=-1.09       ; 19Jul KSI2CE G430LE1
			'OBTO09010': offset= 0.50       ; 19Jul HD6075 G430L
			'OBTO09020': offset=-0.77       ; 19Jul HD6075 G430LE1
			'OBTO11040': offset= 0.42       ; 19Jul SIRIUS G430L
			'OBTO11050': offset= 0.35       ; 19Jul SIRIUS G430L
; No wave cals for 12813-Schmidt program OC3I*
			'OC3I01020': offset=-3.79       ; 19Jul HD0090 G430LE1
			'OC3I01030': offset=-2.81       ; 19Jul HD0090 G430L
			'OC3I02020': offset=-4.26       ; 19Jul HD0311 G430LE1
			'OC3I02030': offset=-3.19       ; 19Jul HD0311 G430L
			'OC3I03020': offset=-4.04       ; 19Jul HD0740 G430LE1
			'OC3I04020': offset=-3.97       ; 19Jul HD1119 G430LE1
			'OC3I04030': offset=-2.98       ; 19Jul HD1119 G430L
			'OC3I05020': offset=-4.12       ; 19Jul HD1606 G430LE1
			'OC3I05030': offset=-2.95       ; 19Jul HD1606 G430L
			'OC3I06020': offset=-4.29       ; 19Jul HD2006 G430LE1
			'OC3I07010': offset=-3.91       ; 19Jul HD1859 G430LE1
			'OC3I07030': offset=-2.57       ; 19Jul HD1859 G430L
			'OC3I08020': offset=-4.68       ; 19Jul BD21D0 G430LE1
			'OC3I09020': offset=-3.89       ; 19Jul BD54D1 G430LE1
			'OC3I10010': offset=-4.49       ; 19Jul BD29D2 G430LE1
			'OC3I11010': offset=-4.38       ; 19Jul BD26D2 G430LE1
			'OC3I12020': offset=-4.22       ; 19Jul BD02D3 G430LE1
; No lines & NO wavecal for GJ7541A. Fix wls by matching model at 3000A, 
;	which is v. precise:
			'OC3I13020': offset=-4.30	; 19Jul GJ7541 G430LE1j
			'O8UI03010': offset=-1.4  ;vb8	hand H&K alignment E1
			'OC5507010': offset=-1.5  ;vb8  .....................
			'OC5508010': offset=-0.9  ;vb8  ......2013sep06......
			'ODD709010': offset= 0.39       ; 19Jul KF08T3 G430LE1
			
			'O8H2010K0': offset=-1.3  ;bd75 bad
			'O8H2010L0': offset=-1.5  ;bd75  bad
			'O8H2010M0': offset=-1.3  ;bd75  bad
			'O8H2010N0': offset=-1.5  ;bd75  bad
			'O8J5010F0': offset=-1.0  ;bd75  bad
			'O8J5010G0': offset=-1.0  ;bd75  bad
			'O8J5010H0': offset=-1.3  ;bd75 bad
			'O8VJ10010': offset=-1.76       ; 19Jul C26202 G430LE1
			'O8VJ11010': offset=-1.12       ; 19Jul SF1615 G430LE1
			'O8VJ12010': offset=-1.30       ; 19Jul SNAP-2 G430LE1

; Subarrays for Carlos G430L solar analogs:
			'O6H05WAXQ': offset=-1.74	; 19jan HD146233 E1 bad
			'O6H05WAYQ': offset=-1.61	; 19jan HD146233 E1 bad

			'OB1C02020': offset=-0.13       ; 19Jul HD-189 G430L
			'OB1C02030': offset=-0.18       ; 19Jul HD-189 G430L
			'OB1C02040': offset=-0.22       ; 19Jul HD-189 G430L
			'OB1C02050': offset=-0.25       ; 19Jul HD-189 G430L
			'OB1C02060': offset=-0.25       ; 19Jul HD-189 G430L
			'OB1C02070': offset=-0.31       ; 19Jul HD-189 G430L
			'OB1C02080': offset=-0.36       ; 19Jul HD-189 G430L
			'OB1C04010': offset=-0.25       ; 19Jul HD-189 G430L
			'OB1C04020': offset=-0.30       ; 19Jul HD-189 G430L
			'OB1C04030': offset=-0.36       ; 19Jul HD-189 G430L
			'OB1C04040': offset=-0.40       ; 19Jul HD-189 G430L
			'OB1C04050': offset=-0.39       ; 19Jul HD-189 G430L
			'OB1C04060': offset=-0.60       ; 19Jul HD-189 G430L
			'OB1C04070': offset=-0.98       ; 19Jul HD-189 G430L
			'OB1C04080': offset=-1.37       ; 19Jul HD-189 G430L
			'OC3301010': offset= 0.16       ; 19Jul HD-189 G430L
			'OC3301030': offset= 0.16       ; 19Jul HD-189 G430L
			'OC3301050': offset= 0.17       ; 19Jul HD-189 G430L
			'OC3301070': offset= 0.20       ; 19Jul HD-189 G430L
; 2014Nov26 -Massa: {No Lines are:OCMV0N010, AZV18,dbl is HD281159, bad:2DFS3030
;	asymm:NGC2264-VAS47, nois:OCMV1P010=BE74-422, nois:GSC-09163-00, 
;	nois:GSC-09163-01}
			'OCMV01010': offset=-0.49	; 14Nov hd29647
			'OCMV04010': offset=-0.30	; 15Feb hd62542
			'OCMV05010': offset=-0.46	; 15jun HD73882
			'OCMV0E010': offset=+0.30	; 14Dec HD303068
			'OCMV0H010': offset=-0.33	; 16sep CPD-59D2591
			'OCMV0L010': offset=-0.24	; 16dec CD-59D3300
			'OCMV0O010': offset=-0.22	; 14Dec CPD-59D2625
			'OCMV0Q010': offset=+0.28	; 15feb HD91983
; HRS:no shift		'OCMV0S010': offset=+0.7	; 14Nov hd93222
			'OCMV0V010': offset=-0.29	; 16dec HDD38087
			'OCMV0X010': offset=-0.40	; 15oct HD142165
			'OCMV10010': offset=+0.25	; 15oct HD197512 
			'OCMV11010': offset=+0.37	; 14Nov hd204827
; noisy			'OCMV1I010': offset=-1.08	; 15apr 2DFS3171 
			'OCMV15010': offset=-0.51	; 15jun HD92044
; No shft: asymm	'OCMV16010': offset=-0.56; 14Dec NGC2264-VAS4
			'OCMV18010': offset=-0.38	; 15may HD70614
			'OCMV19010': offset=-0.68	; 15feb HD110946
			'OCMV1D010': offset=-1.68	; 14Nov AZV18
			'OCMV1E010': offset=-0.55	; 14Dec AZV23 
			'OCMV1F010': offset=-1.42	; 15apr AZV214 
			'OCMV1G010': offset=-0.49	; 15feb AZV398 
			'OCMV1K010': offset=+0.53	; 15apr 2DFS0699 
			'OCMV1L010': offset=-0.71	; 16aug MFHSMC5398
			'OCMV1M010': offset=-0.63	; 15oct MFHSMC582923
			'OCMV1Q010': offset=-0.69	; 14dec GSC-09163-00731
; No shft: asymm		'OCMV1Y010': offset=+0.36 ; 14Dec AZV456
			'OCMV22010': offset=-0.42	; 16sep HD197702
			'OCMV27010': offset=-0.41	; 16sep HD292167
; HRS:no shift			'OCMV29010': offset=+0.25 ; 14Dec BD+44D1080
			'OCMV32010': offset=+0.20	; 15feb HD46660
			'OCMV34010': offset=+0.27	; 16jul BD+56D517
			'OCMV35010': offset=+0.19	; 14Dec BD+56D518
			'OCMV39010': offset=-0.40	; 15may BD+04D1299S
			'OCMV44010': offset=+0.32	; 15jul HD164865
			'OCMV45010': offset=-0.61	; 14Dec CPD-57D3523
			'OCMV46010': offset=+0.58	; 15feb GSC-03712-01
			'OCMV58010': offset=-0.54	; 15feb HD54439
			'OCMV62010': offset=-0.23	; 15oct HD193322
			'OCMV64010': offset=+0.25	; 15feb HD239722
			'OCMV74010': offset=-0.47	; 15feb HD13338
			'OCMV76010': offset=-0.36	; 16jul HD172140
			'OCMV77010': offset=-0.33	; 14Dec HD40893
			'OCMV85010': offset= 0.28	; 16jul HD217086
			'OCMV89010': offset=+0.41	; 15feb CL-NGC-457-P
			'OCMV94010': offset=+0.34       ; 14Dec HD228969
			'OCMV90010': offset=+0.23	; 16aug BD+69D1231
			'OCMV94010': offset=+0.34       ; 14Dec HD228969
			'OCMV96010': offset=+1.90	; 15feb HD99872
			'OCMV98010': offset=-0.31	; 15jun HD93028
			
			'ODTA72030': offset=-1.32       ; 19Jul ETA1DO G430LE1
			'ODTA03030': offset=-1.46       ; 19Jul HD1289 G430LE1
			'ODTA03040': offset=-0.23       ; 19Jul HD1289 G430L
			'ODTA04030': offset=-4.10       ; 19Jul HD1014 G430LE1
			'ODTA05030': offset=-4.32       ; 19Jul HD2811 G430LE1
			'ODTA06030': offset=-4.08       ; 19Jul HD5567 G430LE1
			'ODTA07020': offset=-0.96       ; 19Jul 18SCO G430LE1
			'ODTA08020': offset=-1.03       ; 19Jul 16CYGB G430LE1
			'ODTA09020': offset=-1.00       ; 19Jul HD1423 G430LE1
			'ODTA60020': offset=-1.11       ; 19Jul HD1670 G430LE1
			'ODTA11020': offset=-1.11       ; 19Jul HD1151 G430LE1
			'ODTA12030': offset=+0.48	; 19jan ETAUMA Bad
			'ODTA12040': offset= 0.51       ; 19Jul ETAUMA G430L
			'O40801010': offset= 0.36       ; 19Jul FEIGE1 G430L
			'ODTA13020': offset=-4.25       ; 19Jul FEIGE1 G430LE1
			'ODTA14020': offset=-1.35       ; 19Jul FEIGE3 G430LE1
			'ODTA15030': offset=-1.33       ; 19Jul HD9352 G430LE1
; 19May-HZ21 is 90% He, so try HeII lines:. No radial Vel meas. Line at 
; koester: 3204.022, HeI  4472.755
;	OOPs no wavecal: shift=(3204.02-3215.0meas)/2.73=-4.0
; ck w/ line used by LDS749B: (4472.755-4485.9)/2.73=-4.8 --> adopt -4.6
			'ODTA16020': offset=-4.55       ; 19Jul HZ21 G430LE1
			'ODTA17020': offset=-4.64       ; 19Jul HZ4 G430LE1
			'ODTA18010': offset=-3.63       ; 19Jul HZ44 G430LE1
			'ODTA19030': offset=-0.86       ; 19Jul 109VIR G430LE1
			'ODTA19040': offset= 0.41       ; 19Jul 109VIR G430L
			'ODTA51030': offset=-1.22       ; 19Jul DELUMI G430LE1
			'ODTB01030': offset=-1.43       ; 19Jul SDSSJ1 G430LE1
			
			else: begin   &  endelse  &  endcase
			
		'7751': case root of			;h-alpha=6563
			'O45A03030': offset= 0.47       ; 19Jul AGK+81 G750L
			'O45A04030': offset= 0.50       ; 19aug AGK+81 G750L
			'O45A05030': offset=-0.24       ; 19Jul AGK+81 G750L
			'O45A12030': offset= 0.18       ; 19Jul AGK+81 G750L
			'O45A13030': offset=-0.16       ; 19Jul AGK+81 G750L
			'O45A14030': offset=-0.21       ; 19Jul AGK+81 G750L
			'O45A16030': offset= 0.14       ; 19Jul AGK+81 G750L
			'O45A17030': offset= 0.10       ; 19Jul AGK+81 G750L
			'O5IG01030': offset=-0.21       ; 19aug AGK+81 G750L
			'O5IG03030': offset= 0.18       ; 19Jul AGK+81 G750L
			'O5IG04030': offset=-0.32       ; 19Jul AGK+81 G750L
			'O5IG05030': offset= 0.19       ; 19Jul AGK+81 G750L
			'O5IG07030': offset= 0.10       ; 19Jul AGK+81 G750L
			'O69L02040': offset= 0.11       ; 19Jul AGK+81 G750L
			'O6I902040': offset= 0.24       ; 19Jul AGK+81 G750L
			'O6I903060': offset=-0.31       ; 19Jul AGK+81 G750L
			'O6I904060': offset=-0.20       ; 19aug AGK+81 G750L
			'O6IL02040': offset=-2.21       ; 19Jul AGK+81 G750L
			'O6IL02090': offset=-2.41       ; 19Jul AGK+81 G750L
			'O6IL020E0': offset=-2.31       ; 19Jul AGK+81 G750L
			'O6IL020J0': offset=-2.22       ; 19Jul AGK+81 G750L
			'O8JJ01060': offset=-0.39       ; 19Jul AGK+81 G750L
			'O8JJ04060': offset= 0.22       ; 19Jul AGK+81 G750L
			'O8U201060': offset= 0.16       ; 19Jul AGK+81 G750L
			'O8U202060': offset=-0.27       ; 19Jul AGK+81 G750L
			'O8U203060': offset=-0.28       ; 19Jul AGK+81 G750L
			'O8U205060': offset=-0.09       ; 19aug AGK+81 G750L
			'O8U206060': offset=-0.31       ; 19Jul AGK+81 G750L
			'O8U207060': offset=-0.14       ; 19Jul AGK+81 G750L
			'O8U208060': offset= 0.14       ; 19Jul AGK+81 G750L
			'OA9J010A0': offset=-0.82	;09jul16-E1 bad
			'OBAU01060': offset=-0.30       ; 19Jul AGK+81 G750L
			'OBAU02060': offset=-0.12       ; 19Jul AGK+81 G750L
			'OBAU04060': offset= 0.28       ; 19Jul AGK+81 G750L
			'OBAU06060': offset=-0.24       ; 19Jul AGK+81 G750L
			'OBMZL3060': offset= 0.39       ; 19Jul AGK+81 G750L
			'OBMZL4060': offset=-0.38       ; 19Jul AGK+81 G750L
			'OBVNL2060': offset= 0.21       ; 19Jul AGK+81 G750L
			'OC4IL1060': offset=-0.18       ; 19Jul AGK+81 G750L
			'OC4IL2060': offset= 0.13       ; 19Jul AGK+81 G750L
			'OC4IL3060': offset= 0.14       ; 19Jul AGK+81 G750L
			'OCEIL1060': offset=-0.56       ; 19Jul AGK+81 G750L
			'OCEIL4060': offset=-0.33       ; 19Jul AGK+81 G750L
			'OCPKL1060': offset=-0.18       ; 19Jul AGK+81 G750L
			'OCPKL2060': offset=-0.18       ; 19Jul AGK+81 G750L
			'OD1AL1060': offset=-0.24       ; 19Jul AGK+81 G750L
			'OD1AL4060': offset=-0.14       ; 19Jul AGK+81 G750L
			'ODBVL1060': offset=-0.15       ; 19Jul AGK+81 G750L
			'ODOHL1060': offset=-0.52       ; 19Jul AGK+81 G750L
			'ODOHL3060': offset=-0.34       ; 19Jul AGK+81 G750L
			'ODVKL1060': offset=-0.35       ; 19Jul AGK+81 G750L
			'ODVKL2060': offset=-0.14       ; 19aug AGK+81 G750L
			'ODVKL3060': offset=+0.11       ; 19aug AGK+81 G750L
			
			'ODDG03030': offset=-0.12       ; 19Jul GRW+70 G750L
			'ODDG04030': offset= 0.17       ; 19Jul GRW+70 G750L

; now 0			'O49X01010': offset=-0.37	; 19jan BD28 nowavcal
; now 0			'O49X02010': offset=-0.41	; 19jan BD28 nowavcal

			'O49X11010': offset=-0.12       ; 19Jul GRW+70 G750L
			'O49X12010': offset= 0.13       ; 19Jul GRW+70 G750L
			'O49X25010': offset= 0.58       ; 19Jul P177D G750L
			'O49X26010': offset= 0.63       ; 19Jul P177D G750L
			'O49X27010': offset= 0.41       ; 19Jul P330E G750L
			'O57T01020': offset= 0.17       ; 19Jul HZ43 G750L
			'O57T02020': offset=-0.64       ; 19Jul HZ43 G750L
			'O403020E0': offset= 2.59       ; 19Jul P041C G750L
			'O403020F0': offset= 2.37       ; 19Jul P041C G750L
			'O403020G0': offset= 2.26       ; 19Jul P041C G750L
			'O403020H0': offset= 2.00       ; 19Jul P041C G750L
			'O403020I0': offset= 1.57       ; 19Jul P041C G750L
			'O403020J0': offset= 1.33       ; 19Jul P041C G750L
			'O403020K0': offset= 0.98       ; 19Jul P041C G750L
			'O403020L0': offset= 0.62       ; 19Jul P041C G750L
			'O403020M0': offset= 0.39       ; 19Jul P041C G750L
			'O403020O0': offset=-0.32       ; 19Jul P041C G750L
			'O403020P0': offset=-0.46       ; 19Jul P041C G750L

			'OBC404020': offset= 0.17       ; 19Jul P330E G750L
			'OBNF06020': offset= 0.23       ; 19Jul P330E G750L
			'OBC403020': offset= 0.64       ; 19Jul P177D G750L
; WD offsets in wlerr.g750l-wd. For prime WD:
			'O3TT42040': offset=+0.27       ; 19jul GD153
			'O3TT43040': offset=+0.29       ; 19jul GD153
			'O3TT44040': offset=+0.24       ; 19jul GD153
			'O3TT45040': offset=+0.16       ; 19jul GD153
			'O3TT46040': offset=+0.46       ; 19jul GD153
			'O3TT47040': offset=+0.77       ; 19jul GD153
			'O3TT48040': offset=+0.32       ; 19jul GD153
			'O4D103030': offset=+0.34       ; 19jul GD153
			'O4A502020': offset=-0.12       ; 19jul GD153
			'O8V202070': offset=+0.33       ; 19jul GD153
			'OBC402060': offset=+0.39       ; 19jul GD153
			'OBTO10060': offset=+0.14       ; 19jul GD153
			'OC5506060': offset=-0.31       ; 19jul GD153
			'OCGA05060': offset=+0.24       ; 19jul GD153
			'ODCK02060': offset=+0.32       ; 19jul GD153
			'ODUD02060': offset=+0.28       ; 19jul GD153
			'O49X09010': offset=-0.28       ; 19jul GD71
			'O49X10010': offset= 0.18       ; 19Jul GD71
			'O4A551020': offset= 0.32       ; 19Jul GD71
			'O61001040': offset= 0.19       ; 19Jul GD71
			'O61004030': offset= 0.26       ; 19Jul GD71
			'O61005030': offset= 0.12       ; 19Jul GD71
			'O61006030': offset= 0.13       ; 19Jul GD71
			'O6IG01060': offset= 0.24       ; 19Jul GD71
			'O8V201090': offset= 0.38       ; 19Jul GD71
			'OBVP06060': offset= 0.41       ; 19Jul GD71
			'OCGA04060': offset= 0.28       ; 19Jul GD71
			'ODCK01060': offset= 0.55       ; 19Jul GD71
			'ODUD01060': offset= 0.49       ; 19Jul GD71

			'O6IG100F0': offset=-0.19       ; G191 10jul E1 narrow
			'O6IG100G0': offset=-1.14	; G191 10aug E1 narrow
			'O6IG100H0': offset=-0.54	; G191 10jul E1 narrow
			'O6IG100I0': offset=-0.69	; G191 10jul E1 narrow

			'O4D101030': offset= 0.23       ; 19Jul G191B
			'O4D102030': offset= 0.45       ; 19Jul G191B
			'O49X07010': offset= 0.41       ; 19Jul G191B
			'O49X08010': offset= 0.26       ; 19Jul G191B
			'O69U06030': offset= 0.15       ; 19Jul G191B
			'O8V203060': offset=-0.28       ; 19Jul G191B
			'OBBC07040': offset= 0.27       ; 19Jul G191B
			'OBNF05040': offset= 0.37       ; 19Jul G191B
			'OBVP07040': offset= 0.25       ; 19Jul G191B
			'OCGA06040': offset= 0.17       ; 19Jul G191B
			'ODUD03040': offset= 0.06       ; 19Jul G191B

			'OCWGA1010': offset=+0.27	; 19jul WD1327-083
			'OCWGA2010': offset=+0.20	; 19jul WD2341+322

			'OBNK01040': offset=-1.23       ; 19Jul WD0308 
			'O8V101030': offset= 0.36       ; 19Jul WD1657 .16to.56
; 06June FASTEX G750L WDs confirmed/tweaked w/ wlabsrat.pro (from Line symmetry):
			'O8V102030': offset=+0.7  ;snap-1 skip
			'O8V103030': offset=+0.4  ;snap-1 skip
			'O3WY02040': offset= 0.88       ; 19Jul BD+75D G750L
			'O49X03020': offset= 0.68       ; 19Jul BD+75D G750L
			'O4A505010': offset= 0.65       ; 19Jul BD+75D G750L
			'O8H201140': offset=-1.0  ;bd75 bad
			'O8H201150': offset=-0.9  ;bd75 bad
			'O8H201160': offset=-1.0  ;bd75 bad
			'O8H201170': offset=-0.9  ;bd75 bad
			'O8J5010N0': offset=-0.9  ;bd75 bad
			'O8J5010O0': offset=-0.8  ;bd75 bad
			'O8J5010P0': offset=-1.0  ;bd75 bad
; now 0			'O69U07030': offset=-0.38	; 19jan HZ43
; now 0.10		'O69U08030': offset=-0.22	; 19jan HZ43
			'O8KH03010': offset=-1.3  ; 2M0036+18 bad

			'O8UI03020': offset=-0.7  ; vb8 2013sep align w/g430L
			'OC5507020': offset=-0.2  ; vb8 2013sep  ...........
; zero shift		'OC5508020': offset=0.    ; vb8 2013sep  at 5400-5600
			'O6I903050': offset=-1.47 ; agk E1 bad
			'O6I904050': offset=-1.35 ; agk E1 bad
			'O8JJ01050': offset=-1.43 ; agk E1 bad
			'O8JJ02050': offset=-1.13 ; agk E1 bad
			'O8JJ03050': offset=-0.94 ; agk E1 bad
			'O8JJ04050': offset=-0.94 ; agk E1 bad
			'O8U201050': offset=-0.81 ; agk E1 bad
			'O8U202050': offset=-0.27 ; agk E1 bad
			'O8U205050': offset=-0.94 ; agk E1 bad
			'O8U206050': offset=-0.66 ; agk E1 bad
			'O8U207050': offset=-0.40 ; agk E1 bad
; comment		'O6N3A4060': offset=<.1px=0.5A  ; 09jan HD209458 Ha eye
			'O6D204070': offset=-0.50       ; 19Jul HD2094 G750L
			'O6D204080': offset=-0.52       ; 19Jul HD2094 G750L
			'O6D204090': offset=-0.56       ; 19Jul HD2094 G750L
			'O6D2A4010': offset=-0.70       ; 19Jul HD2094 G750L
			'O6D2A4030': offset=-0.70       ; 19Jul HD2094 G750L
			'O6D222060': offset=-1.06       ; 19Jul HD2094 G750L
			'O6D222070': offset=-0.97       ; 19Jul HD2094 G750L
			'O6D222080': offset=-0.76       ; 19Jul HD2094 G750L
			'O6D2B2020': offset=-2.94       ; 19Jul HD2094 G750L
			'O6D2B2040': offset=-2.87       ; 19Jul HD2094 G750L
			'O6N302010': offset=-2.03       ; 19Jul HD2094 G750L
			'O6N302030': offset=-2.15       ; 19Jul HD2094 G750L
			'O6N302050': offset=-2.22       ; 19Jul HD2094 G750L
			'O6N304010': offset=-2.39       ; 19Jul HD2094 G750L
			'O6N304030': offset=-2.45       ; 19Jul HD2094 G750L
			'O6N304050': offset=-2.50       ; 19Jul HD2094 G750L
			'O8H101040': offset= 0.11       ; 19Jul BD+17D G750L
			'O8H102040': offset=-0.44       ; 19Jul BD+17D G750L
			'O8H103040': offset=-0.24       ; 19Jul BD+17D G750L
			'O8VJ10020': offset=-0.47       ; 19Jul C26202 G750L
			'O8VJ11020': offset=-0.11       ; 19Jul SF1615 G750L
			'O8VJ12020': offset=-0.18       ; 19Jul SNAP-2 G750L
			'O8I105070': offset=-0.21 ; 19jul wl.offsets-vega G750L
			'O8I106050': offset= 0.10 ; 19jul wl.offsets-vega G750L
			'O5JA040I0': offset=-0.71       ; 19Jul BD-11D G750L

			'OBNF07020': offset=-0.45       ; 19Jul KF06T2 G750L
			'ODD707020': offset= 0.30       ; 19Jul KF08T3 G750L
			'ODD709020': offset= 0.48       ; 19Jul KF08T3 G750L

			'OBC405060': offset= 0.34       ; 19Jul HD1654 G750L
			'OBC406040': offset=-0.23       ; 19Jul 173252 G750L
			'OBC457040': offset= 0.35       ; 19Jul 174034 G750L
			'OBC408040': offset= 0.47       ; 19Jul 174304 G750L
			'OBC409040': offset= 0.51       ; 19Jul 180227 G750L
			'OBC410040': offset= 0.26       ; 19Jul 180529 G750L
			'OBC411040': offset=-0.19       ; 19Jul 181209 G750L
			'OBNL02040': offset= 0.38       ; 19Jul HD3772 G750L
			'OBNL03040': offset= 0.32       ; 19Jul HD1164 G750L
			'OBNL04040': offset= 0.67       ; 19Jul 175713 G750L
			'OBNL05040': offset=-0.15       ; 19Jul 180834 G750L
			'OBNL06040': offset= 0.14       ; 19Jul HD1806 G750L
			'OBNL07040': offset= 0.34       ; 19Jul BD+60D G750L
			'OBNL09030': offset= 0.10       ; 19Jul HD3894 G750L
			'OBNL10030': offset= 0.58       ; 19Jul HD1062 G750L
			'OBNL11030': offset= 0.36       ; 19Jul HD2059 G750L
			'OBTO01030': offset= 0.38       ; 19Jul HD1592 G750L
			'OBTO02050': offset= 0.34       ; 19Jul HD1494 G750L
			'OBTO03050': offset= 0.30       ; 19Jul HD1584 G750L
			'OBTO04050': offset= 0.30       ; 19Jul HD1634 G750L
			'OBTO05050': offset= 0.16       ; 19Jul LAMLEP G750L
			'OBTO06050': offset= 0.41       ; 19Jul 10LAC G750L
			'OBTO07050': offset= 0.46       ; 19Jul MUCOL G750L
			'OBTO09050': offset= 0.36       ; 19Jul HD6075 G750L
			'OBTO11060': offset= 0.42       ; 19Jul SIRIUS G750L
; W/ wave cals for 12813-Schmidt program OC3I*
			'OC3I01040': offset= 0.54       ; 19Jul HD0090 G750L
			'OC3I02040': offset= 0.20       ; 19Jul HD0311 G750L
			'OC3I03030': offset= 0.57       ; 19Jul HD0740 G750L
			'OC3I04040': offset= 0.42       ; 19Jul HD1119 G750L
			'OC3I05040': offset= 0.37       ; 19Jul HD1606 G750L
			'OC3I06030': offset= 0.50       ; 19Jul HD2006 G750L
			'OC3I07040': offset= 0.83       ; 19Jul HD1859 G750L
			'OC3I08030': offset= 0.17       ; 19Jul BD21D0 G750L
			'OC3I09030': offset= 0.54       ; 19Jul BD54D1 G750L
			'OC3I10030': offset= 0.25       ; 19Jul BD29D2 G750L
			'OC3I11030': offset= 0.50       ; 19Jul BD26D2 G750L
			'OC3I12030': offset= 0.14       ; 19Jul BD02D3 G750L
;2013feb15-weak line gives -1.28 to -1.52 but may not be H-alpha.
;	Use the structure in the counts to get -0.08 px, which is zero shift:
;	HAS wavecal...
;info only		'OC3I13030': offset=-0.39       ; 19Jul GJ7541 G750L

; 0			'O49X14010': offset=-0.11 ; 19jan 93521 wl.offs
; 0			'O49X14020': offset=-0.16 ; 19jan 93521 wl.offs
; 0			'O49X14030': offset=-0.19 ; 19jan 93521 wl.offs
			'O49X14040': offset=-0.10 ; 19jul 93521 wl.offs
			
			'O6H05WAZQ': offset=-1.03 ;19jan HD146233 bad
			'O6H05WB0Q': offset=-1.16 ;19jan HD146233 bad
; 2014Nov26 - Massa: {BAD are:..1d020,..1g020,AZV18,AZV23,
;	NGC2244-VS32, GSC-09163-00731,CL-NGC-457-P, OCMV1F020, OCMV89020,
;	OCMV31020}
			'OCMV01020': offset=-0.45	; 14Nov hd29647
			'OCMV04020': offset=-0.44	; 15feb hd62542
			'OCMV05020': offset=-0.29	; 15jun HD73882
			'OCMV0E020': offset=+0.22	; 14dec HD303068
			'OCMV0F020': offset=-0.20	; 15jun BD+71D92
			'OCMV0H020': offset=-0.29	; 16sep CPD-59D2591
; HRS:0			'OCMV0O020': offset=+0.15	; 14Dec CPD-59D2625
			'OCMV0R020': offset=-0.55	; 16jul CPD-41D7715
			'OCMV0S020': offset=+0.16	; 15jun HD93222
			'OCMV0V020': offset=-0.32	; 16dec HD38087
			'OCMV0W020': offset=-0.24	; 15jul HD142096
			'OCMV0X020': offset=-0.35	; 15oct HD142165
			'OCMV10020': offset=+0.33	; 16jul HD197512
			'OCMV11020': offset=+0.26	; 14Dec HD204827
; HRS:0				'OCMV12020': offset=+0.39	; 14Dec HD210072
			'OCMV15020': offset=-0.31	; 15jun HD92044
			'OCMV16020': offset=-0.29	; 14Dec NGC2264-VAS4 
			'OCMV18020': offset=-0.44	; 15may HD70614 
			'OCMV19020': offset=-1.08	; 15Feb HD110946
			'OCMV1G020': offset=-0.7	;14Nov AZV398-em,eyeball
;noisy			'OCMV1I020': offset=-0.50	; 15Apr 2DFS3171
			'OCMV1L020': offset=-0.88	; 16aug MFHSMC5398
			'OCMV1M020': offset=-0.23	; 16jul MFH2007-SMC5
			'OCMV1S020': offset=-1.2	; 15Feb BE74-619-em eyeb
; HRS:0			'OCMV1Y020': offset=+0.27	; 14Dec AZV456
			'OCMV20020': offset=-0.27	; 15jul HD149452
			'OCMV25020': offset=+0.07	; 15Feb HD236960
			'OCMV26020': offset=-0.52       ; 14Dec HD281159 
; HRS:0			'OCMV29020': offset=+0.31       ; 14Dec BD+44D1080
; Bad Central em	'OCMV31020': offset=+0.         ; 16sep hd28475
; HRS:0			'OCMV32020': offset=+0.81       ; 14Dec HD46660
			'OCMV34020': offset=+0.29       ; 16jul BD+56D517
			'OCMV35020': offset=+0.18       ; 14Dec BD+56D518
			'OCMV37020': offset=+0.42       ; 16sep HD14250
			'OCMV39020': offset=-0.41       ; 15may BD+04D1299S
			'OCMV40020': offset=-0.21       ; 15jun NGC2244-VS32
			'OCMV44020': offset=+0.73	; 15jul HD164865
			'OCMV45020': offset=-0.53       ; 14Dec CPD-57D3523
			'OCMV46020': offset=+0.28	; 15Feb GSC-03712-01
			'OCMV50020': offset=-0.24	; 15Feb TRUMPLER14-2
			'OCMV51020': offset=-0.21	; 15jun TRUMPLER14-6
			'OCMV58020': offset=-0.57	; 15Feb HD54439
			'OCMV59020': offset=+0.23	; 15jul HD198781
			'OCMV60020': offset=-0.25	; 16jul HD17443
			'OCMV63020': offset=+0.19	; 16sep HD14321
			'OCMV64020': offset=-0.23	; 15jun HD239722
			'OCMV69020': offset=+0.28	; 16sep HD18352
			'OCMV74020': offset=-0.39       ; 15Feb HD13338
			'OCMV77020': offset=-0.59       ; 14Dec HD40893
			'OCMV85020': offset= 0.48       ; 16jul HD217086
			'OCMV90020': offset=+0.34	; 16aug BD+69D1231
			'OCMV92020': offset=+0.25	; 15jul HD239745
; noisy			'OCMV94020': offset=-0.21       ; 14Dec HD228969
			'OCMV96020': offset=+1.86	; 15feb HD99872
			'OCMV98020': offset=-0.21	; 15jun HD93028 
			'OCMV99020': offset=-0.17	; 14Dec HD28475

			'ODTA03050': offset=-0.21       ; 19Jul HD1289 G750L
			'ODTA03060': offset=-0.24       ; 19Jul HD1289 G750L
			'ODTA04040': offset= 0.39       ; 19Jul HD1014 G750L
			'ODTA06040': offset= 0.21       ; 19Jul HD5567 G750L
			'ODTA07030': offset= 0.46       ; 19Jul 18SCO G750L
			'ODTA07040': offset= 0.37       ; 19Jul 18SCO G750L
			'ODTA08030': offset= 0.57       ; 19Jul 16CYGB G750L
			'ODTA08040': offset= 0.38       ; 19Jul 16CYGB G750L
			'ODTA09030': offset= 0.43       ; 19Jul HD1423 G750L
			'ODTA60030': offset= 0.40       ; 19Jul HD1670 G750L
			'ODTA11030': offset= 0.20       ; 19Jul HD1151 G750L
			'ODTA12060': offset= 0.43       ; 19Jul ETAUMA G750L
			'O40801020': offset= 0.24       ; 19Jul FEIGE1 G750L
			'ODTA13030': offset=-0.11       ; 19Jul FEIGE1 G750L
			'O49X05010': offset=-0.33       ; 19Jul FEIGE3 G750L
			'O49X13010': offset=-0.41       ; 19Jul HD9352 G750L
			'O49X13020': offset=-0.45       ; 19Jul HD9352 G750L
			'O49X13030': offset=-0.48       ; 19Jul HD9352 G750L
			'O49X13040': offset=-0.49       ; 19Jul HD9352 G750L
			'O49X14040': offset=-0.10       ; 19Jul HD9352 G750L
			'ODTA15050': offset= 0.49       ; 19Jul HD9352 G750L
; 19May-HZ21 is 90% He, so try HeII lines:. No radial Vel meas. Line at 
; Koester 6561.90 {HI @ 6564.6} (6561.90-6561)/4.9=+0.18, but trust X-correl fix
			'O49X15010': offset= 0.68       ; 19Jul HZ21 G750L
;	(6561.90-6558.5)/4.9=0.69       Ck OK
			'O49X16010': offset= 0.57       ; 19Jul HZ21 G750L
			'O49X22010': offset=-0.16       ; 19Jul HZ4 G750L
			'O49X19010': offset= 0.63       ; 19Jul HZ44 G750L
			'O49X20010': offset= 0.66       ; 19Jul HZ44 G750L
			'ODTA19050': offset= 0.41       ; 19Jul 109VIR G750L
			'ODTA19060': offset= 0.31       ; 19Jul 109VIR G750L
			'ODTA51050': offset= 0.40       ; 19Jul DELUMI G750L
			'ODTA51060': offset= 0.34       ; 19Jul DELUMI G750L
			else: begin   &  endelse  &  endcase
		else: begin  &  endelse
		endcase
; 2016mar4 - add G750M for HD189733 project
if cenwave gt 4300 and cenwave ne 7751 then begin
	case root of
		'OB6H01010': offset=-2.12     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H01020': offset=-2.01     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H01030': offset=-2.06     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H01040': offset=-2.15     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H03010': offset=-1.93     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H03020': offset=-1.85     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H03030': offset=-1.89     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H03040': offset=-1.92     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H52010': offset=-2.70     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H52020': offset=-2.87     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H52030': offset=-3.09     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H52040': offset=-3.21     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H54010': offset=-1.84     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H54020': offset=-1.87     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H54030': offset=-2.04     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H54040': offset=-2.18     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H55010': offset=-3.28     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H55020': offset=-3.20     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H55030': offset=-3.18     ;16mar hd189733 G750M w/ NO wavcal
		'OB6H55040': offset=-3.16     ;16mar hd189733 G750M w/ NO wavcal
		else: begin   &  endelse  &  endcase
	endif

if strpos(fulroot,'ngc6681') eq 0 then begin
; offset in arcsec on sky from slit center per MgII G230L - see notebook: 02jun4
;	theta=[-.045,-.24,.42,-.33,-.425,.62,-.54,-.365,.17,.76,.035,-.11]
; 02jul18-revised from CCD star pos meas. See slitedge.pro.
theta=[0.0149925,  -0.176339,   0.452419,  -0.303213,  -0.393976,   0.664646, $
       -0.524075,  -0.320390,   0.227154,   0.820403,  0.0843716, -0.0719170]
	starnum=fix(strmid(fulroot,8,2))-1
; wavelength ck suggests a tweak of -0.1 ccd px  =-0.2Mama px
	offset=theta(starnum)/.0507-0.1				; G230L MgII
	if cenwave eq 'G140L' then offset=(theta(starnum))/.0246-.2
	if cenwave eq 'G230L' then offset=(theta(starnum))/.0246-.2
	print,fulroot,theta(starnum),' arcsec from slit center'
	endif

if offset ne 0 then print,'STISWLFIX returned a WL offset=',offset,	$
		' pixels for ',cenwave
return,offset
end
