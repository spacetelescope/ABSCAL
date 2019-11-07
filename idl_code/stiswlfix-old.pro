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
;-
offset=0.0
root=strupcase(strmid(fulroot,0,6))
		case cenwave of 
; 97Oct20 - new slit offset installed.
                        '1416': case root of		; 98Apr29 - echelle obs
				'O4RQ01': offset=-13
				else: begin   &  endelse  &  endcase
			'1425': case root of			;G140L
				'O3ZKA4': offset=+8/.584	;g140L early BPM
				else: begin   &  endelse  &  endcase
			'2376': case root of			;G230L
; 02jul22 - the 230L WLs got ~0.4px smaller per the slit ang fix, so
;	i could add 0.4px to ff 4 old cases, BUT do not as not much more than
;	the uncertainty, anyhow. Re-est offsets from scratch before changing.
				'O3ZKA8': offset=+7/1.545 ;g230L bpm, no wavecal
				else: begin   &  endelse  &  endcase
			'2375': case root of			;G230LB
; use avg of g430 and g750 px shifts:
				'O3TT02': offset=+11.4	;in px 6x6
				'O3TT03': offset=+10.2  ;      6x6
				'O3TT04': offset=+9.0	;	6x6
				'O3TT20': offset=-2.5	;	6x6
                                'O3TT21': offset=-4.0    ;inferred 6x6  
                                'O3TT23': offset=+3.1    ;........ 6x6
; ff are w/o wavecal for agk... see nowavcal.pro, wl.offsets-agk 03may5-ok
				'O6IL02': offset=-2.2	; 4 cases +-0.1
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
; ff are w/o wavecal for agk... see nowavcal.pro, wl.offsets-agk 03may5
				'O6IL02': offset=-2.85	;8 cases +-0.05
				else: begin   &  endelse  &  endcase
			'7751': case root of			;h-alpha=6563
				'O3TT02': offset=+11.4	;in px  6x6
				'O3TT03': offset=+9.8	;+3px   6x6
				'O3TT04': offset=+8.7	;+3.5   6x6
				'O3TT20': offset=-2.4	;gd153  6x6
                                'O3TT21': offset=-4.1	;H-alpha 6x6
                                'O3TT23': offset=+3.25	;H-alpha 6x6
; ff. is after a bad wavecal.
                                'O3TT40': offset=+ 3.8/4.92 ; too early for cal
                                'O3TT41': offset=-.4	; gd153 """""""""""""""
; ff are w/o wavecal for agk. see nowavcal.pro, wl.offsets-agk 03may5
				'O6IL02': offset=-2.33	; 4 cases +-0.1
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
			'O3ZX08HHM': offset=+1.55	; 19jan-GD153 
			'O4A502060': offset=+0.24	; 19may-GD153 
			'O4VT10YRQ': offset=-.29	; 19may-GD153 
			'O4VT10Z0Q': offset=-.34	; 19jan-GD153
			'O6IG03T5Q': offset=+.79	; 19jun was .72
			'O6IG03TDQ': offset=+.3		;....Bad @ +3"
			'O6IG03THQ': offset=+.86 	; 19jan 52x0.05
			'O6IG04VJQ': offset=+.42 	; 19jan
			'O6IG11CXQ': offset=-.39	; 19jan gd153
			'O6IG11DJQ': offset=-.28	; 19may gd153
			'O6IG11DEQ': offset=-1.0	;08nov20
			'O6IG02Y3Q': offset=+.72	; 19jun gd153 was.63
			'O6IG02YFQ': offset=+.56	; 19jan gd153
			'OA8D02010': offset=+0.23	; 19jun gd153 
			'OA9Z05010': offset=-.32	; 19jun gd153
			'OBC402ENQ': offset=+2.03	; 19may gd153 
			'OBTO10QHQ': offset=+1.16	; 19jan gd153
			'OC5506RJQ': offset=+0.51	; 19may gd153
			'OCGA05EUQ': offset=+2.00	; 19jun gd153 1.97,2.04
			'ODCK02P2Q': offset=+1.02	; 19jun gd153
			'ODUD02FPQ': offset=+0.15	; 19may gd153
			
			'O4PG01N1Q': offset=+.18	; 19jun GD71:31/03/98
			'O4PG01N9Q': offset=+.38	; 19jan GD71:31/03/98
			'O4PG01NDQ': offset=+.34	; 19jan GD71:31/03/98
			'O4PG01NHQ': offset=+.52	; 19jun GD71:31/03/98
			'O4PG01NPQ': offset=+.52 	; 19jun GD71: 31/03/98
			'O4A551060': offset=+.43	; 19jan GD71
			'O4SP01060': offset=+.45	; 19jan GD71
			'O53001080': offset=-.69 	; 19jan gd71
			'O4A520060': offset=+.28	; 19jan gd71
			'O61001070': offset=+.60	; 19jan gd71
			'O61002060': offset=-0.13	; 19may gd71
			'O61003060': offset=+0.17	; 19may gd71
			'O61004060': offset=+.55	; 19jan gd71
			'O61005060': offset=+.43	; 19jan gd71
			'O61006060': offset=+.40	; 19jan GD71
			'O5I001010': offset=+.34	; 19jan GD71
			'O5I002IWQ': offset=+.36	; 19may GD71
			'O5I002J0Q': offset=+.35	; 19jan GD71
			'O5I002J3Q': offset=+.21	; 19jan GD71
			'O5I002J6Q': offset=+.17	; 19may GD71
			'O5I002J9Q': offset=+.15	; 19may GD71
			'O6IG01B7Q': offset=+.06	; 19may GD71
			'O8V201G6Q': offset=+.39	; 19jan gd71
			'OBC401M5Q': offset=+1.03	; 19jun gd71
			'OBVP06A8Q': offset=+1.12	; 19jan gd71
			'OCGA04TWQ': offset=+0.59	; 19jun gd71
			'ODCK01MWQ': offset=+1.13	; 19jun gd71
			'ODUD01R1Q': offset=+1.47	; 19jun gd71
; same slit=52x0.05 is always used for above gd71 wavecals.
; 03may2-GRW. See wl.offsets-grw or -2009 file for these values:
			'O3YX14HSM': offset=+.94 ; grw: avg Lya
	'O3YX14040': offset=+.94+0.4942/.584 ;2019may-new name for O3YX14HSM
			'O3YX15QEM': offset=0.77
			'O3YX16KLM': offset=+.78
			'O45947010': offset=-.41
			'O6I812010': offset=-.38
			'O8IA01010': offset=-.49
; ff flagged BAD in dirlow.full:
			'O8IA03010': offset=8.0	; GRW wavcal,bad? not dirlow
			'OB87N2010': offset=+0.15	; 19Jun GRW G140L
			'OB8705010': offset=-0.16	; 19Jun GRW G140L
			'OBN6L2010': offset=-0.44	; 19jun GRW
			'OBN6L3010': offset=-0.13	; 19jun GRW  
			'OBW3L1010': offset=-0.17       ; 19Jun GRW G140L
			'OBW3L2010': offset=-0.23       ; 19Jun GRW G140L
			'OBW3L3010': offset=-0.20       ; 19Jun GRW G140L
			'OC4KL1010': offset=-0.11       ; 19Jun GRW G140L
			'OC4KL2010': offset=-0.15       ; 19Jun GRW G140L
			'OC4KL3010': offset=-0.29       ; 19Jun GRW G140L
			'OCETL1010': offset=-0.16       ; 19Jun GRW G140L
			'OCETL3010': offset=-0.11       ; 19Jun GRW G140L
			'OCQJL1040': offset=-0.31       ; 19Jun GRW G140L
			'OCQJL2040': offset=-0.41       ; 19Jun GRW G140L
			'OCQJL3040': offset=-0.70       ; 19Jun GRW G140L
			'OD1CL1040': offset=-0.31       ; 19Jun GRW G140L
			'OD1CL2040': offset=-0.18       ; 19Jun GRW G140L
			'ODBUL1040': offset=-0.24       ; 19Jun GRW G140L
			'ODBUL2040': offset=+0.22       ; 19Jun GRW G140L
			'ODBUL3040': offset=-0.42       ; 19Jun GRW
			'ODPCL1040': offset=-0.15       ; 19Jun GRW G140L
			'ODPCL2040': offset=-0.11       ; 19Jun GRW G140L
			'ODPCL3040': offset=-0.35       ; 19Jun GRW G140L
			'ODVIL1040': offset=-0.32       ; 19Jun GRW G140L

; 04June FASTEX WDs At Lyman-alpha:
			'O69U04030': offset=0.9	;04jun17 =Ly WD1657
			'O5K001030': offset=0.55	;WD0320-539
			'O5K003030': offset=0.45	;WD0947+857
			'O5K004030': offset=-0.9 	;WD0947+857
			'O69U02030': offset=0.85	;WD0947+857
			'O8H110040': offset=-.45	;WD0947+857
			'O8H104040': offset=-0.9 	;WD1026+453
			'O8H105040': offset=-1.35 	;WD1026+453
			'O8H106040': offset=-0.55 	;WD1026+453
			'O5K005030': offset=1.05 	;WD1057+719
			'O5K006030': offset=1.0 	;WD1057+719
;			'OBNK01010': offset=-.97 	;WD0308-565 16sep15
			'OBNK01010': offset=-.77 	;WD0308-565 16sep15 eye
;ff NOT stable .3 makes .26, .26 gives .35...   0.3 is good:
			'O8H107010': offset=0.3		;19jan LDS WL.OFFSETS
;ff NOT stable .31 makes .27, .27 gives .31
			'O8H109010': offset=-.29	;19jan LDS WL.OFFSETS
			'OBBM01010': offset=-0.20       ; 19Jun LDS749B G140L
			'OBC405010': offset=+0.60	;HD165459 wl.offs..-2009
			'OBC408010': offset=2.88	;1743045 wl.offs..-2009
			'OBC406010': offset=-0.12	; 19Jun 1732526
			'OBC457010': offset=0.88	; 19Jun 1740346
			'OBC409010': offset=1.42	; 1802271
			'OBC410010': offset=+0.90	; 19Jun 1805292 G140L
			'OBNL03010': offset=0.65	; HD116405
			'OBNL06010': offset=+0.26	; 19Jun HD180609 G140L
			'OBNL02010': offset=0.74	; HD37725
; Bad too noisy		'OBNL04010': offset=1.9 	; 1757132
			'OBNL07010': offset=0.61	; BD+60D1753
			'OBTO02010': offset=0.57	; HD14943
			'OBTO03010': offset=0.53	; HD158485
			'OBTO04010': offset=0.53	; HD163466
; too weak, noisy	'ODTA06010': offset=-1.75	; 19may HD55677

; 19May-HZ21 is 90% He. See ~/wd/koester/HZ21-01.dk
;	so try HeII lines: 1215.13. No radial Vel meas. Line at
; 	1215.9 px offset needed=(1215.8-1215.13)/0.584 = -1.15 px (earlier meas)
; ck w/ (1640.42-1640.3)/0.584 = +0.21px after -0.80, Lya is spot-on &
;		so avg to final -0.7.. Ck OK.
			'ODTA16010': offset=-0.7        ; 19may21 HZ21 hand ck.
; v. broad. do not iterate:
			'ODTA17010': offset=-3.52       ; 19may HZ4
			'ODTB01010': offset=-0.99       ; 19jun SDSSJ151421
;LCB
			'OC8C14020': offset=-.71	; GALEX-094853
			'OC8C19020': offset=5.9 	; GALEX-102254
			'OC8C20020': offset=-1.24	; GALEX-155521
			'OC8C49020': offset=0.64	; GALEX-004840
			'OC8C54020': offset=-.77	; GALEX-000152
; wd1327 & wd2341 OCWGA1050 & OCWGA2050 are too broad & noisy to believe shifts
			else: begin   &  endelse  &  endcase
			
		'2376':case root of			;G230L
			'O3ZX08HLM': offset=-0.7 ;gd153 02dec-fix sens @ 1650A
; lds offsets done using radvel=-81km/s and 1.545, 1.37 A/px 230L &LB, respect.
;	w/ 2 HeI line at 2945.96 vac WLs. vs. Model in 09Nov
			'O8H109040': offset=-.42	;19jan LDS WL.OFFSETS-E1
			'O8H108040': offset=+.56	;19jan LDS WL.OFFSETS-E1
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
			'OBC410020': offset=+.87 	;1805292
			'O47Z01040': offset=+.25 	; 19jan-p330
			'OBBM01040': offset=+.15 	; 19jun lds749b
			'OBC457020': offset=0.85	;11aug-1740346
			'OBC408020': offset=1.27 	;1743045
			'OBC409020': offset=0.94	;11aug-1802271
			'OBNK01020': offset=-0.87 	;WD0308-565 wlck.pro
			'OBC461020': offset=0.65	;11aug-1812095
			'OBNL04020': offset=1.28	;12jan-1757132
			'OBNL05020': offset=+.14 	; 19jun 1808347
; 19May-HZ21 is 90% He, so try HeII lines:. No radial Vel meas. Line at 
;	2734.10A bit noisy, maybe assym.
; Also try 1640.42: px offset needed=(1640.42-1654.)/1.545= -8.8 px
; & ck w/ wd/koester/lines.HZ21: (2511.96-2524.7)/1.545 = -8.2 px --> avg= -8.5
			'O40901NSM': offset=-7.8  ;19may HZ21 iterate on 2512A
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
			'O8H101030': offset=0.29 ; 19jun bd17
			'O8H102030': offset=-.24 ; 19jun bd17
			'O45P020G0': offset=+1.1 ; etaUMa 1.5A
			'O45P020H0': offset=+1.1 ; etaUMa 1.5A
			'O45A03010': offset=0.33 ; 03may5 wl.offsets-agk
			'O45A04010': offset=0.60 ; 03may5 wl.offsets-agk
			'O45A05010': offset=-.23 ; 19jun wl.offsets-7672 agk
			'O45A12010': offset=0.15 ; 19jun wl.offsets-7672 agk
			'O45A13010': offset=-.28 ; 03may5 wl.offsets-agk
			'O45A14010': offset=-.14 ; 19jun wl.offsets-7672 agk
			'O5IG01010': offset=0.14 ; 19jun wl.offsets-7672 agk
			'O5IG04010': offset=-.29 ; 03may5 wl.offsets-agk
			'O5IG05010': offset=0.36 ; 03may5 wl.offsets-agk
			'O69L04020': offset=0.12 ; 19jun wl.offsets-7672 agk
			'O6I901020': offset=-.18 ; 19jun wl.offsets-agk agk
			'O6I902020': offset=0.17 ; 19jun wl.offsets-7672 agk
			'O6I903020': offset=-.24 ; 19jun wl.offsets-agk
			'O6I903010': offset=-1.32
			'O6I904010': offset=-1.11
			'O6I904020': offset=-.12  ; 19jun wl.offsets-7672 agk
			'O6IL02020': offset=-2.10 ; 19jun wl.offsets-7672 agk
			'O6IL02070': offset=-2.29 ; 19jun wl.offsets-7672 agk
			'O6IL020C0': offset=-2.31 ; 19jun wl.offsets-7672 agk
			'O8JJ01010': offset=-1.22
			'O8JJ02010': offset=-1.00
			'O8JJ03010': offset=-0.92
			'O8JJ03020': offset=0.14 ; 19jun wl.offsets-7672 agk
			'O8JJ04010': offset=-0.85
			'O8JJ04020': offset=0.20 ; 19jun wl.offsets-7672 agk
			'O8U201010': offset=-0.48
			'O8U201020': offset=0.29 ; 19jun wl.offsets-7672 agk
			'O8U203010': offset=-.10 ; 19jun wl.offsets-7672 agk
			'O8U203020': offset=-.14 ; 19jun wl.offsets-7672 agk
			'O8U204020': offset=-.17 ; 19jun wl.offsets-7672 agk
			'O8U205010': offset=-0.80
			'O8U206010': offset=-0.32
			'O8U207010': offset=-.11 ; 19jun wl.offsets-7672 agk
			'O8U207020': offset=-.15 ; 19jun wl.offsets-7672 agk
			'O8U208010': offset=0.21 ; 19jun wl.offsets-7672 agk
			'O8U208020': offset=0.12 ; 19jun wl.offsets-7672 agk
			'O8JJ01020': offset=-0.32 ; 03may5 wl.offsets-agk
			'O8U206020': offset=-0.39 ; 05may13 wl.offsets-agk
			'OA9J01050': offset=-0.30 ; 18jun3  wl.offsets-2009
			'OA9J01060': offset=-0.94 ; 19may wl.offsets-agk
			'OBAU01010': offset=-0.85 ; 19may wl.offsets-agk E1
			'OBAU02010': offset=-0.69 ; 13feb14 wl.offsets-2009 E1
			'OBAU03010': offset=-0.42 ; 10may5 wl.offsets-2009
			'OBAU03020': offset=+0.22 ; 18jun3 wl.offsets-2009
			'OBAU04010': offset=-0.52 ; 10may5 wl.offsets-2009
			'OBAU04020': offset=+0.15 ; 19jun wl.offsets-2009 agk
			'OBAU05010': offset=-0.60 ; 19may wl.offsets-2009 agk
			'OBAU06010': offset=-.81  ; 13feb14 wl.offsets-2009 agk
			'OBAU06020': offset=-0.13 ; 19jun wl.offsets-2009 agk
			'OBMZL1010': offset=-.78  ; 19may wl.offsets-2009 agk E1
			'OBMZL1020': offset=-0.10 ; 19jun wl.offsets-2009 agk
			'OBAU01020': offset=-.20  ; 19may-....
			'OBMZL3010': offset=-.44  ;13feb14 -....
			'OBMZL3020': offset=0.26  ; 11aug-....
			'OBMZL4010': offset=-.86  ; 19may-.... E1
			'OBMZL4020': offset=-.22  ;13feb14 -....
			'OBVNL1010': offset=-.40  ; 19jun agk g230lb E1
			'OBVNL1020': offset=0.27  ; 12jan-....
			'OBVNL2010': offset=-.70  ;13feb-.... E1
			'OBVNL3010': offset=-.75  ; 19jun-.... E1
			'OC4IL1010': offset=-0.88 ; 19jun agk g230lb E1
			'OC4IL2010': offset=-0.73 ; 19may-.... E1
			'OC4IL2020': offset=+0.20 ; 19jun wl.offsets-2009 agk
			'OC4IL3010': offset=-0.65	; 13sep-.... E1
			'OCEIL1010': offset=-1.13	; 14feb-.... E1
			'OCEIL1020': offset=-0.41	; 14feb-.... E1     agk
			'OCEIL3010': offset=-0.91 ; 19jun-.... E1     agk
			'OCEIL4010': offset=-0.74	; 14aug-.... E1     agk
			'OCPKL1010': offset=-0.96	; 14dec-.... E1     agk
			'OCPKL2010': offset=-1.04	; 15may-.... E1     agk
			'OCPKL2020': offset=-0.16 ; 19jun wl.offsets-2009 agk
			'OCPKL3010': offset=-1.16	; 19may-.... E1     agk
			'OCPKL3020': offset=-0.30	; 15jul-     agk
			'OD1AL1010': offset=-1.10       ; 19may-.... E1     agk
			'OD1AL1020': offset=-0.28       ; 19may-     agk
			'OD1AL2010': offset=-1.06       ; 19jun-.... E1     agk
			'OD1AL4010': offset=-1.05       ; 19jun g230lb E1   agk
			'OD1AL4020': offset=-0.30       ; 16dec-....        agk
			'ODBVL1010': offset=-0.82       ; 19jun g230lb E1   agk
			'ODBVL2010': offset=-0.66       ; 19jun .... E1     agk
			'ODBVL2020': offset=+0.15 ; 19jun  g230lb 2009 agk
			'ODBVL3010': offset=-0.77       ; 19jun-.... E1     agk
			'ODOHL1010': offset=-1.39       ; 19may-.... E1     agk
			'ODOHL1020': offset=-0.59       ; 19jun-.... E1     agk
			'ODOHL2010': offset=-0.72       ; 19jun-.... E1     agk
			'ODOHL3010': offset=-1.18       ; 18aug-.... E1     agk
			'ODVKL1010': offset=-0.99       ; 19jun-.... E1     agk
			'ODVKL1020': offset=-0.17 ; 19jun  g230lb 2009 agk
			'ODVKL2010': offset=-0.97       ; 19may-.... E1     agk
; END AGK
			'OBNL06020': offset=-.71 	; 12jan-.... E1 HD180609
			'OBNL07020': offset=-.48 	;12jan-....E1 BD+60D1753
			
			'O8I105010': offset=+0.10 ; 19jun wl.offsets-vega
			'O8I105020': offset= 0.08 ; 19jun wl.offsets-vega
			'O8I105030': offset= 0.12 ; 19jun wl.offsets-vega
			'O8I105040': offset=-1.39 ; 19jun wl.offsets-vega E1
			'O8I106020': offset= 0.43 ; 19jun wl.offsets-vega
			'O8I106030': offset= 0.38 ; 19jun wl.offsets-vega
; 06jun7-G230LB 52x2E1 prime WDs from wlabsrat.wd3-g230lb
			'O6IG10020': offset=-1.1  ; 06jun G191
			'O8V203040': offset=-1.1  ; 06jun G191
			'O8V202040': offset=-0.5  ; 06jun GD153
			'O8V204080': offset=+0.5  ; 06jun GD71
; 09jul16 ff bd75 based on MgII & ignores radial veloc. Do other g230lb relative
; 	to this O3WY02010 in nowavcal.pro.
			'O3WY02010': offset= 0.39  ;19jan bd75 162s exp ref spec
			'O4A506010': offset= 0.17  ;19jan bd75
			'O8H201060': offset= 0.15  ;19jan bd75
			'O8H201070': offset= 0.24  ;19jan bd75
			'O8H201080': offset= 0.26  ;19jan bd75
			'OA8B01020': offset=-0.40  ;bd75 09jul
			'OA8B010I0': offset=-0.14  ;19jun bd75 G230LB
			'OA8B010K0': offset=-0.14  ;19jun bd75 G230LB
			'OA8B11030': offset=-0.24  ;19jan bd75 G230LB
			'OA8B11040': offset=-0.15  ;19jan bd75
			'O8H2010O0': offset=-0.76  ;19jan bd75crsplit=1 newl.log
			'O8H2010P0': offset=-0.72  ;19jan bd75  newl.log
			'O8H2010Q0': offset=-0.76  ;19jan bd75  newl.log
			'O8H2010R0': offset=-0.70  ;19jan bd75  newl.log
			'O8J501060': offset=-0.75  ;19jan bd75 newl.log
			'O8J501070': offset=-0.72  ;19jan bd75 newl.log
			'O8J501080': offset=-0.82  ;19jan bd75 newl.log
			'O6IL01020': offset=+0.57  ;19jan LDS749 vs model
			'O6IL01060': offset=+0.65  ;19jun LDS749 cntr
			'OBC405020': offset= 0.31  ;HD165459 wl.offs..-2009
			'OBC405030': offset=-0.17 ; 19jun  g230lb 2009 HD165459
			'OBNL09020': offset=-0.55 ;11may14HD38949 wl.offs..-2009
			'O47Z01020': offset= 0.08 ; 19jan-p330E wl.offs..-7674
			'OBNL03020': offset=-0.47	; 19jan-HD116405
			'OBNL08020': offset=-0.92	; 19jun-HD37962
			'OBNL10020': offset=-0.39	; 19jan-HD106252
			'OBNL11020': offset=-0.39	; 19jan-HD205905
			'OBNL02020': offset=-0.28	; 16apr-HD37725
			'OBNL04020': offset=1.48	; 12jan-1757132
			'OBTO01020': offset=-0.18	; 19jun-HD159222
			'OBTO02020': offset=-0.46	; 19jan HD14943
			'OBTO03020': offset=-0.43	; 19jan HD158485
			'OBTO04020': offset=-0.38	; 19jan HD163466
			'OBTO05030': offset=-0.46	; 13feb lam Lep E1
			'OBTO05040': offset=0.13	; 13feb lam Lep
			'OBTO06030': offset=-0.23	; 13feb 10 Lac E1
			'OBTO06040': offset=0.32	; 13feb 10 Lac
			'OBTO07030': offset=0.17	; 13feb mu col E1
			'OBTO07040': offset=0.84	; 13feb mu col
			'OBTO08030': offset=-.63	; 19jan ksi Cet E1
			'OBTO09030': offset=-0.37	; 13feb HD60753 E1
			'OBTO09040': offset=0.36	; 13feb HD60753
			'OBTO11010': offset=0.75	; 13feb Sirius
			'OBTO11020': offset=0.76	; 13feb Sirius
			'OBTO11030': offset=0.79	; 13feb Sirius
			'OBTO12010': offset=0.17	; 13feb Sirius
			'OBTO12020': offset=0.12	; 13feb Sirius
			'OBTO12030': offset=0.14	; 13feb Sirius
; No wave cals for 12813-Schmidt program OC3I*
			'OC3I01010': offset=-3.36	; 19jan HD009051
			'OC3I02010': offset=-3.05	; 19jan HD031128
			'OC3I03010': offset=-2.38	; 13feb HD074000
			'OC3I04010': offset=-3.23	; 13feb HD111980
			'OC3I05010': offset=-2.58	; 13feb HD160617
			'OC3I06010': offset=-3.12	; 19jan HD200654
			'OC3I07020': offset=-2.91	; 13feb HD185975
			'OC3I08010': offset=-3.21	; 13feb BD21D0607
			'OC3I09010': offset=-2.58	; 13feb BD54D1216
			'OC3I10020': offset=-3.60	; 19jan BD29D2091
			'OC3I11020': offset=-2.94	; 13jun BD26d2606
			'OC3I12010': offset=-2.61	; 13feb BD02D3375
			
			'O6H05W010': offset=-0.20	; 19jan HD146233 E1
			'O6H05W020': offset=-0.28	; 19jan HD146233 E1
			'ODTA03020': offset=-1.04	; 19jan HD128998 E1
			'ODTA04020': offset=-2.25	; 19may  HD101452 E1
			'ODTA05020': offset=-2.58	; 19may HD2811 E1
			'ODTA06020': offset=-2.46	; 19may HD55677 E1
			'ODTA07010': offset=-0.51	; 19may 18sco E1
			'ODTA08010': offset=-0.52	; 19jan 16CYGB E1
			'ODTA09010': offset=-0.29	; 19jan HD142331 E1
			'ODTA11010': offset=-0.76	; 19may HD115169 E1
			'ODTA12010': offset=+0.52	; 19jan ETAUMA Bad
			'ODTA12020': offset=+0.36	; 19jan ETAUMA
			'ODTA13010': offset=-0.72	; 19jan FEIGE110 E1
			'ODTA14010': offset=-0.83	; 19jan FEIGE34 E1
			'ODTA15010': offset=+0.49	; 19may hd93521
			'ODTA15020': offset=-0.64	; 19may hd93521 E1
			'ODTA18020': offset=-0.63	; 19may HZ44 E1
			'ODTA19010': offset=+0.69	; 19jan 109vir
			'ODTA19020': offset=-0.24	; 19may 109vir E1
			'ODTA51010': offset=+0.60	; 19jan DELUMI
			'ODTA51020': offset=-0.41	; 19jan DELUMI E1
			'ODTA72010': offset=+0.32	; 19may ETA1DOR
			'ODTA72020': offset=-0.64	; 19may ETA1DOR E1
			'ODTA60010': offset=-0.85	; 19may  HD167060 E1
			
; No identifiable strong lines in GJ7541A. Fix wls by matching model at 1700A,
;	the weak 2800A would be -0.4?? HAS wavecal!
; 2013mar5-the model from Detlev has a line at 2479.3, which would mean that I
;	need to come back to ~-0.7, which DOES agree w/ 2800A result!
; 13Mar7-Switch nowavcal to use the 2479.3 line & del the -2.5 shift for 1700A:
			'OC3I13010': offset=-0.72	; 13mar GJ7541A
			else: begin   &  endelse  &  endcase

		'4300': case root of	; 02dec3 po41wl.g430l-befor from H&K
			'O40302010': offset=0.97
			'O40302020': offset=1.08
			'O40302030': offset= .99
			'O40302040': offset= 1.15	;p041c 09sep28 nowavcal
			'O40302050': offset= 0.9	; ...............
			'O40302060': offset= 0.65	; ...............
			'O40302070': offset= 0.3	; ...............
			'OBBC10010': offset=-0.92	; 19jan p330e
			'OBC404010': offset=-0.94	; 19jan p330e 
			'OBNF06010': offset=-0.74 ;19mar wl.offsets-2009 P330E1
			'OBC403010': offset=-0.72	;p177d 09nov14 E1
			'O40302090': offset=-.83
			'O403020A0': offset=-1.10
			'O403020B0': offset=-1.29
			'O403020C0': offset=-1.33
			'O8H101020': offset=+0.15 ; 19jun bd17 wl.offsets-bd17
			'O8H102020': offset=-0.37 ; 19jun bd17 wl.offsets-bd17
			'O8H101010': offset=-1.82 ; 19jun bd17 E1	...
			'O8H102010': offset=-2.34 ; 19jun bd17 E1   "	...
			'O8H103010': offset=-1.67 ; 19jun bd17 E1   "	...
			'ODDG01010': offset=-.63 ; 16dec wl.offsets grw E1
			'ODDG01020': offset=+.50 ; 16dec wl.offsets grw
			'ODDG02010': offset=-.67 ; 16dec wl.offsets grw E1
			'ODDG02020': offset=+.35 ; 16dec wl.offsets grw
			'ODDG03010': offset=-.91 ; 17mar wl.offsets grw E1
			'ODDG03020': offset=+.22 ; 17mar wl.offsets grw
			'ODDG04010': offset=-.72 ; 17apr wl.offsets grw E1
			'ODDG04020': offset=+.41 ; 17apr wl.offsets grw
; G430L AGK
			'O45A01020': offset=-.12 ; 19jun wl.offsets-7672 agk
			'O45A03020': offset=+.36 ; 03may5 wl.offsets-agk
			'O45A04020': offset=+.50 ; 03may5 wl.offsets-agk
			'O45A05020': offset=-.20 ; 19jun wl.offsets-agk
			'O45A12020': offset=0.10 ; 19jun wl.offsets-agk
			'O45A13020': offset=-.24 ; 03may5 wl.offsets-agk
			'O45A14020': offset=-.26 ; 03may5 wl.offsets-agk
			'O5IG01020': offset=0.10 ; 19jun wl.offsets-7672 agk
			'O5IG03020': offset=0.14 ; 19jun wl.offsets-7672 agk
			'O5IG04020': offset=-.35 ; 03may5 wl.offsets-agk
			'O5IG05020': offset=0.18 ; 19jun wl.offsets-7672 agk
			'O6B601090': offset=-.87 ; 02dec10 wl.offsets-agk
			'O6B6010B0': offset=-.65 ; 06jun wl.offsets-agk
			'O6B6010D0': offset=-2.33
			'O69L02030': offset=0.10 ; 19jun wl.offsets-7672 agk
			'O6I902030': offset=0.24 ; 19jun wl.offsets-7672 agk
			'O6I903030': offset=-.19 ; 19jun wl.offsets-7672 agk
			'O6I903040': offset=-1.63
			'O6I904040': offset=-1.60
			'O6IL02030': offset=-2.73 ; 19jun wl.offsets-7672 agk
			'O6IL02080': offset=-2.90 ; 19jun wl.offsets-7672 agk
			'O6IL020D0': offset=-2.89 ; 19jun wl.offsets-7672 agk
			'O6IL020I0': offset=-2.79 ; 19jun wl.offsets-7672 agk
			'O8JJ01030': offset=-.29 ; 03may5 wl.offsets-agk
			'O8JJ01040': offset=-1.62
			'O8JJ02030': offset=0.20 ; 19jun wl.offsets-7672 agk
			'O8JJ02040': offset=-1.31
			'O8JJ03030': offset= 0.10 ; 19jun wl.offsets-7672 agk
			'O8JJ03040': offset=-1.23
			'O8JJ04030': offset= .39 ; 03dec5 wl.offsets-agk
			'O8JJ04040': offset=-1.22 ; 19jun wl.offsets-7672 agk
			'O8U201030': offset= .34  ; 19jun wl.offsets-7672 agk
			'O8U201040': offset=-0.97 ; 19jun wl.offsets-7672 agk
			'O8U202040': offset=-0.31
			'O8U203030': offset=-0.21 ; 19jun wl.offsets-7672 agk
			'O8U203040': offset=-0.41 ; 19jun wl.offsets-7672 agk
			'O8U204040': offset=-0.26
			'O8U205030': offset=+0.10 ; 19jun g430l agk
			'O8U205040': offset=-1.22 ; E1
			'O8U206030': offset=-0.24 ; 19jun g430l 7672-agk
			'O8U206040': offset=-0.98 ; 19jun wl.offsets-7672 agk
			'O8U207040': offset=-0.67
			'O8U208030': offset=0.23 ; 19jun wl.offsets-7672 agk
			'O8U208040': offset=-.16 ; 19jun wl.offsets-7672 agk
			'O8U220090': offset= .38 ; 03dec5 ; agk postarg 50s exp
			'O8U2200B0': offset=-0.12 ; 19jun wl.offsets-7672 agk
			'O8U2200C0': offset=-0.22 ; 19jun g430l-7672 agk->0??
			'O8U2200D0': offset=-.60 ; 03dec5 agk postarg 50s exp
			'O8U2200E0': offset=-.32 ; 19jun wl.offsets-7672 ag
			'O8U2200F0': offset=-1.21; 03dec5 agk postarg 50s exp
; see dir2009.log for new SM4 data:
			'OA9J01070': offset=-1.09 ; 09jul16 wl.offsets-agk
			'OA9J020A0': offset= 1.31 ; 09jul16 wl.offsets-agk
			'OA9J020B0': offset=-1.51 ; 09jul16 wl.offsets-agk
; skipped in preproc w/ postarg= -10.43:			
			'OA9J020C0': offset= 0.60 ; 19jun wl.offsets g430l agk
			'OA9J020D0': offset=-1.45 ; 09jul16 wl.offsets-agk
			'OA9J020E0': offset= 0.26 ; 19jan wl.offsets-agk
			'OA9J020F0': offset=-1.54 ; 09jul16 wl.offsets-agk
; skipped in preproc:			
			'OA9J020G0': offset=-0.19 ; 19jun wl.offsets-agk G430L
			'OA9J020H0': offset=-1.35 ; 09jul16 wl.offsets-agk
			'OA9J020I0': offset=-0.58 ; 09jul16 wl.offsets-agk
; skipped in preproc:			
			'OA9J020J0': offset=-1.47 ; 19jun wl.offsets-agk
			'OA9J020K0': offset= 1.39 ; 09jul16 wl.offsets-agk
; skipped in preproc:			
			'OA9J020L0': offset=-1.37 ; 19jun wl.offsets-agk
			'OA9J020M0': offset= 0.91 ; 09jul16 wl.offsets-agk
			'OBAU01030': offset=-0.26 ; 09aug13 wl.offsets-agk
			'OBAU01040': offset=-1.31 ; 09aug13 wl.offsets-agk
			'OBAU02040': offset=-1.08 ; 09oct1  wl.offsets-agk (E1)
			'OBAU03030': offset= 0.19 ; 19jun wl.offsets g430l agk
			'OBAU03040': offset=-0.88 ; 19jun wl.offsets-2009 (E1)
			'OBAU04030': offset= 0.29 ; 11Aug8 wl.offsets-2009
			'OBAU04040': offset=-0.80 ; 10may5 wl.offsets-2009 (E1)
			'OBAU05040': offset=-1.04 ; 10may5 wl.offsets-2009 (E1)
			'OBAU06030': offset=-0.22 ; 15jun wl.offsets-2009
			'OBAU06040': offset=-1.24 ; 10jul10 wl.offsets-2009 E1
			'OBAU21090': offset=+1.15 ; 10may5 postarg=-20.9 AGK
			'OBAU210A0': offset=+0.43 ; 10may5 wl.offsets-2009 ..
			'OBAU210C0': offset=-0.49 ; 10may5 wl.offsets-2009 ..
			'OBAU210D0': offset=-1.07 ; 13feb postarg=16.6 ..
			'OBAU210E0': offset=-1.03 ; 10may5 wl.offsets-2009 ..
			'OBAU210F0': offset=-1.93 ; 10may5 postarg=22.2 AGK
			'OBAU22090': offset= 1.31 ; 10jul10 wl.offsets-2009 agk
			'OBAU220A0': offset= 0.49 ; 10jul10 wl.offsets-2009 agk
			'OBAU220C0': offset=-0.42 ; 10jul10 wl.offsets-2009 agk
			'OBAU220D0': offset=-1.16 ; 10jul10 postarg=16.6 agk
			'OBAU220E0': offset=-1.13 ; 10jul10 wl.offsets-2009 agk
			'OBAU220F0': offset=-2.02 ; 10jul10 postarg=22.2 agk
			'OBMZL1040': offset=-1.02 ; 11mar14 wl.offsets-2009 agk
; skipped in preproc:			
			'OBMZM1090': offset=+0.67 ; 19jun wl.offsets-2009 agk
			'OBMZM10A0': offset=-0.11 ; 19jun wl.offsets g430l agk
			'OBMZM10B0': offset=-0.26 ; 11mar15 wl.offsets-2009 agk
; skipped in preproc:			
			'OBMZM10C0': offset=-0.83 ; 19jun wl.offsets-2009 agk
			'OBMZM10D0': offset=-1.36 ; 11mar15 postarg-16.6 agk
			'OBMZM10E0': offset=-1.27 ; 11mar15 wl.offsets-2009 agk
			'OBMZM10F0': offset=-2.18 ; 11mar15 agk postarg=22.2
			'OBMZL3030': offset=0.30	; 11aug-....
			'OBMZL3040': offset=-0.82	; 11aug-....E1
			'OBMZL4030': offset=-0.18 ; 19jun wl.offsets g430l agk
			'OBMZL4040': offset=-1.43	; 11aug-....E1
			'OBVNL1030': offset=0.24	; 12jan-....
			'OBVNL1040': offset=-.95	; 12jan-....E1
; skipped in preproc:			
			'OBVNM1090': offset=-1.22       ; 19jun-....
			'OBVNM10A0': offset= 0.18 ; 19jun wl.offsets g430l agk
			'OBVNM10B0': offset=-.24        ; 19jun-....
			'OBVNM10C0': offset=-.78        ; 12jan-....
			'OBVNM10D0': offset=-1.41       ; 12jan-....
			'OBVNM10E0': offset=-1.35       ; 12jan-....
			'OBVNM10F0': offset=-2.13       ; 12jan-....postarg=22.2
			'OBVNL2030': offset= 0.15 ; 19jun wl.offsets g430l agk
			'OBVNL2040': offset=-1.06       ; 12sep-....E1
			'OBVNL3030': offset= 0.17 ; 19jun wl.offsets g430l agk
			'OBVNL3040': offset=-1.07       ; 12sep-....E1
			'OC4IL1030': offset=-0.21       ; 15may 
			'OC4IL1040': offset=-1.43       ; 13jan-....E1
			'OC4IL2030': offset=0.24        ; 19jun
			'OC4IL2040': offset=-1.01       ; 13jun-....E1
			'OC4IL3040': offset=-.92        ; 13sep....E1
			'OC4IM1090': offset=1.25        ; 13jun
			'OC4IM10A0': offset=0.21        ; 13jun
			'OC4IM10B0': offset=-.28        ; 13jun
			'OC4IM10C0': offset=-.81        ; 13jun postarg=11.1
			'OC4IM10D0': offset=-1.51       ; 13jun postarg=16.6
			'OC4IM10E0': offset=-1.38       ; 19jun-....E1
			'OC4IM10F0': offset=-2.29       ; 13jun postarg=22.2
			'OCEIL1030': offset=-0.43       ; 14feb
			'OCEIL1040': offset=-1.47       ; 14feb-....E1 agk
			'OCEIL3040': offset=-1.24	; 14aug-....E1 agk
			'OCEIL4040': offset=-1.02	; 14aug     agk
			'OCEIM1090': offset=1.74	; 14aug     agk
			'OCEIM10A0': offset=0.86	; 14aug     agk
			'OCEIM10B0': offset=0.28	; 14aug     agk
; skipped in preproc:			
			'OCEIM10C0': offset=-0.15 ; 19jun wl.offsets g430l agk
			'OCEIM10D0': offset=-0.90	; 14aug     agk
			'OCEIM10E0': offset=-0.89	; 14aug-....E1 agk
			'OCEIM10F0': offset=-1.67	; 14aug postarg=22.2 agk
			'OCPKL1030': offset=-0.14 ; 19jun wl.offsets g430l agk
			'OCPKL1040': offset=-1.36	; 14Dec-....E1 agk
			'OCPKL2040': offset=-1.30	; 15may-....E1 agk
			'OCPKM2090': offset=+1.25	; 15may-agk postarg
			'OCPKM20A0': offset=+0.21	; 19jan-agk postarg
			'OCPKM20C0': offset=-0.66	; 15may-agk postarg
; skipped in preproc:
			'OCPKM20D0': offset=-1.07	; 19jun-agk postarg
			'OCPKM20E0': offset=-1.25	; 15may-agk postarg
			'OCPKM20F0': offset=-2.04	; 19jun-agk postarg
			'OCPKL3030': offset=-0.24	; 15JUL-agk 
			'OCPKL3040': offset=-1.46	; 19may-agk E1
			'OD1AL1030': offset=-0.25	; 15nov-agk 
			'OD1AL1040': offset=-1.37	; 19jun-agk E1
			'OD1AL2030': offset=-0.10 ; 19jun wl.offsets g430l agk
			'OD1AL2040': offset=-1.45	; 16apr-agk E1
			'OD1AL4030': offset=-0.22	; 16sep-agk
			'OD1AL4040': offset=-1.22	; 16sep-agk E1
			'OD1AM1090': offset=+1.88       ; 16apr-agk postarg
			'OD1AM10A0': offset=+1.02       ; 16apr-agk postarg
			'OD1AM10B0': offset=+0.62       ; 16apr-agk postarg=0
			'OD1AM10D0': offset=-0.77	; 16apr-agk postarg
			'OD1AM10E0': offset=-0.91	; 16apr-agk postarg=0 E1
			'OD1AM10F0': offset=-1.74	; 16apr-agk postarg
			'ODBVL1030': offset=-0.18 ; 19jun wl.offsets g430l agk
			'ODBVL1040': offset=-1.33	; 16dec-agk E1
			'ODBVM1090': offset=1.38	; 17jul-agk
			'ODBVM10A0': offset=0.54	; 19jul-agk
			'ODBVM10C0': offset=-0.69	; 17jul-agk
			'ODBVM10D0': offset=-1.23	; 17jul-agk
			'ODBVM10E0': offset=-1.22	; 17jul-agk E1
			'ODBVM10F0': offset=-2.17	; 19jun-agk 
			'ODBVL2030': offset=+0.19	; 17may-agk
			'ODBVL2040': offset=-1.11	; 17may-agk E1
			'ODBVL3040': offset=-1.15	; 17jul-agk E1
			'ODOHL1030': offset=-0.52	; 18jun-agk
			'ODOHL1040': offset=-1.62       ; 18jun-agk E1
			'ODOHL2030': offset=+0.20       ; 18jun-agk E1
			'ODOHL2040': offset=-1.23       ; 18jun-agk E1
			'ODOHM1090': offset=-1.78       ; 19may-agk postarg
			'ODOHM10A0': offset=+0.52       ; 18jun-agk postarg
			'ODOHM10B0': offset=+0.12       ; 19jun-agk postarg
			'ODOHM10C0': offset=-0.53       ; 18jun-agk postarg
			'ODOHM10D0': offset=-1.01       ; 18jun-agk postarg
			'ODOHM10E0': offset=-0.97       ; 18jun-agk postarg
			'ODOHM10F0': offset=-1.84       ; 18jun-agk postarg
			'ODOHL3040': offset=-1.53       ; 19jun-agk 
			'ODVKL1030': offset=-0.22       ; 19jan-agk 
			'ODVKL1040': offset=-1.50       ; 19jan-agk E1
			'ODVKL2040': offset=-1.49       ; 19jun-agk E1
; END AGK
; Prime WD offsets in wlerr.g430l-wd. For Primary WDs:
			'O3TT42020': offset=+0.31	; 19jan GD153
			'O3TT43020': offset=+0.39	; 19jan GD153
			'O3TT44020': offset=+0.45	; 19jan GD153
			'O3TT46020': offset=+0.26       ; 19jan GD153
			'O3TT47020': offset=+0.22       ; 19jan GD153
			'O3TT48020': offset=+0.17       ; 19jan GD153
			'O4D103020': offset=+0.35	; 19jan GD153
			'OBC402050': offset=+0.20	; 19jan GD153
			'O8V202050': offset=-1.14	; 19jan GD153 E1 
			'OBC402040': offset=-0.61	; 19jan GD153
			'OBTO10040': offset=-1.38       ; 19jan GD153 E1 
			'OC5506040': offset=-1.59       ; 19may GD153 E1 unstabl
			'OC5506050': offset=-0.34       ; 19may GD153 unstable
			'OCGA05040': offset=-0.96       ; 19jan GD153 E1
			'OCGA05050': offset=+0.35       ; 19jan GD153unstable
			'ODCK02040': offset=-0.72       ; 19may GD153 E1 unstabl
			'ODCK02050': offset=+0.63       ; 19jan GD153
			'O4A551030': offset=+0.13       ; 19jan GD153
			'ODUD02040': offset=-1.21       ; 19jun GD153 E1 
			'ODUD02050': offset=-0.16       ; 19may GD153 

			'O61001010': offset=+0.47	; 19jan  GD71 
			'O61001020': offset=+0.32	; 19jan  GD71 
			'O61003010': offset=+0.28       ; 19jan  GD71 
			'O61004010': offset=+0.32	; 19jan  GD71 
			'O61005010': offset=+0.32	; 19jan  GD71 
			'O61006010': offset=+0.25	; 19jan  GD71 
			'O5I001040': offset=+0.31	; 19jan  GD71 
			'O6IG01050': offset=+0.17	; 19jan  GD71 
			'O8V201040': offset=+0.34       ; 19may GD71 unstable
			'O6IG010C0': offset=-1.42       ; 19jan GD71 E1
			'O8V201050': offset=-0.42       ; 19jan GD71 E1
			'OBC401040': offset=-1.01       ; 19jan GD71 E1		
			'O6IG01080': offset=-1.58       ; GD71 E1 52x0.05 10jul
			'O6IG01090': offset=-1.83       ; GD71 E1 52x0.1 10jul
			'O6IG010A0': offset=-1.53       ; GD71 E1 52x0.2 10jul
			'O6IG010B0': offset=-1.33       ; GD71 E1 52x0.5 10jul
			'OBVP06040': offset=-0.59       ; 19jan GD71 E1
			'OBVP06050': offset=+0.53       ; 19jan GD71
			'OC3I15020': offset=-3.48	; 19jan GD71 E1
			'OCGA04040': offset=-0.79       ; 19jan GD71 E1
			'OCGA04050': offset=+0.32	; 19jan GD71 E1
			'ODCK01040': offset=-0.69       ; 19jan GD71 E1
			'ODCK01050': offset=+0.31       ; 19jan GD71
			'ODUD01040': offset=-0.98       ; 19apr GD71 E1
			'ODUD01050': offset=+0.63       ; 19jun GD71
; G430L

			'O4D101020': offset=-0.36       ; G191 16dec13
			'O4D102020': offset=-0.28       ; G191 16dec13
			'O53002030': offset=-0.51       ; 19jan G191
			'O69U05020': offset=-0.12       ; 19jan G191
			'O69U06020': offset=-0.23       ; G191 16dec13
			'O8V203020': offset=-0.34       ; G191 19may unstable
			'O8V203030': offset=-1.29       ; G191 16dec13 E1
			'O8V203010': offset=-0.45       ; G191 52x0.1 10jul
			'OBBC07020': offset=-3.49       ; G191 16dec13 no wavcal
			'OBBC07010': offset=-4.73       ; G191 ..... E1
			'OBNF05010': offset=-4.40	; 19may G191 E1 unstable
			'OBNF05020': offset=-3.24	; G191 16dec13
			'OBVP07010': offset=-3.60	; 19jan G191
			'OBVP07020': offset=-4.77	; G191 19may E1
			'OC3I14020': offset=-4.97	; 16dec13 G191 E1
			'OC3I14030': offset=-3.84	; 16dec13 G191
			'OCGA06020': offset=-3.64       ; G191 16dec13
			'OCGA06030': offset=-4.85       ; G191 19may E1 unstable
			'ODCK03020': offset=-3.55       ; G191 16dec13 nowavcal
			'ODCK03030': offset=-4.85       ; G191 19jun E1nowavcal
			'ODUD03020': offset=-3.49       ; G191 19jun nowavcal
			'ODUD03030': offset=-4.89       ; G191 19mayE1nowavcal
			'OCWGA1030': offset=-0.37	; 19jan WD1327-083 E1
			'OCWGA2030': offset=-0.50	; 19jan WD2341+322 E1
			
			'O8I105060': offset=-0.21 ; 19jun wl.offsets-vega G430L
			'O8I106010': offset=-0.07 ; 19jun wl.offsets-vega
			'O8I106040': offset=-0.03 ; 19jun wl.offsets-vega
			'O6D201070': offset=-.62 ; 09jan HD209458 nowavcal
			'O6D201080': offset=-.66 ; 09jan HD209458 nowavcal
			'O6D201090': offset=-.68 ; 09jan HD209458 nowavcal
			'O6D2010A0': offset=-.68 ; 09jan HD209458 nowavcal
			'O6D2010B0': offset=-.64 ; 09jan HD209458 nowavcal
			'O6D203070': offset=-.75 ; 09jan HD209458 nowavcal
			'O6D203080': offset=-.74 ; 09jan HD209458 nowavcal
			'O6D203090': offset=-.73 ; 09jan HD209458 nowavcal
			'O6D2030A0': offset=-.69 ; 09jan HD209458 nowavcal
			'O6D2030B0': offset=-.67 ; 09jan HD209458 nowavcal
			'O6N301010': offset=-3.55 ; 09jan HD209458 nowavcal
			'O6N3A10A0': offset=-.80 ; 19jan HD209458
			'O6N3A10B0': offset=-.80 ; 09jan HD209458 nowavcal
			'O6N3A10C0': offset=-.80 ; 09jan HD209458 nowavcal
			'O6N3A10D0': offset=-.81 ; 09jan HD209458 nowavcal
			'O6N3A30A0': offset=-.67 ; 09jan HD209458 nowavcal
			'O6N3A30B0': offset=-.65 ; 09jan HD209458 nowavcal
			'O6N3A30C0': offset=-.65 ; 09jan HD209458 nowavcal
			'O6N3A30D0': offset=-.65 ; 09jan HD209458 nowavcal
			'O6N303010': offset=-3.48 ; 09jan HD209458 nowavcal
			'OBC457030': offset=-0.54 ; 11aug-E1 1740346
			'OBC409030': offset=-0.73 ; 11aug-E1 1802271
			'OBC461030': offset=-1.14 ; 11aug-E1 1812095
			'OBNL02030': offset=-0.83 ; 12jan-E1 HD37725
			'OBNL03030': offset=-0.96 ; 19jan-E1 HD116405
			'OBNL04030': offset=-0.48 ; 12jan-E1 1757132
			'OBNL05030': offset=-1.29 ; 12jan-E1 1808347
			'OBNL06030': offset=-1.14 ; 13feb-E1 HD180609
			'OBNL07030': offset=-1.03 ; 12jan-E1 BD+60D1753
			'OBNL08010': offset=-1.06 ; 11aug-E1 HD37962
			'OBNL09010': offset=-0.97 ;13feb wl.offsets-2009HD38949
			'OBNL10010': offset=-0.61 ; 19jan-E1 HD106252
			'OBNL11010': offset=-0.69 ; 19jan-E1 HD205905
; 06June FASTEX G430L WDs confirmed/tweaked w/ wlabsrat.pro (from Line symmetry):
			'O5K001020': offset=-0.2  ;06jun-flat vs model wd0320
			'O5K002020': offset=-0.6  ;06jun flat vs model wd0320
			'O69U01020': offset=-0.4  ;06jun flat vs model wd0320
			'O5K003020': offset=-0.4  ;06jun flatten rat. wd0947
			'O5K004020': offset=-0.6  ;06jun flatten rat. wd0947
			'O8H110020': offset=-1.0  ;06jun flatten rat. wd0947
			'O8H110030': offset=-2.0  ;06jun flatten wd0947 E1
			'O8H104020': offset=-1.0	;WD1026+453
			'O8H104030': offset=-1.5	;WD1026+453 E1
			'O8H105020': offset=-0.7 	;WD1026+453
			'O8H105030': offset=-1.2 	;WD1026+453 E1
			'O8H106020': offset=+0.5	;WD1026+453
			'O8H106030': offset=-1.6	;WD1026+453 E1
			'O5K005020': offset=+0.3 	;WD1057+719
			'O69U03020': offset=+0.2 	;WD1057+719
			'O5K007020': offset=-0.6        ;WD1657
			'O8V101010': offset=-0.8        ;WD1657
			'O8V101020': offset=-0.8        ;WD1657 E1
			'O8H111030': offset=-1.4        ;WD1657 E1
			'OBNK01030': offset=-1.84       ;WD0308-565 wlck.pro
			'O8V102010': offset=+0.7  ;snap-1
			'O8V102020': offset=-0.5  ;snap-1 E1  Supercedes wl.
			'O8V103010': offset=+0.7  ;snap-1
			'O8V103020': offset=-0.5  ;snap-1 E1
			'O3WY02030': offset=+0.63	; 19jan bd75
			'O4A5050K0': offset=0.30	; 19 jan bd75
			'O8h201020': offset=-.3 ; bd75 06jun
			'O8h201040': offset=-.3 ; bd75 06jun
; unstable??
			'O69U07020': offset=-0.65 	; 19jan HZ43
			'O69U08020': offset=-0.71 	; 19jan HZ43
			'O57T01010': offset=-0.76 	; 19jan HZ43
			'O57T02010': offset=-0.69 	; 19jan HZ43
;	Fastex G430L all except WDs done here. NO G140,230L in 'snap' stars.
			'O8H107020': offset=-0.13	; 19jan LDS749
			'O8H107030': offset=-1.23	; 19jan LDS749 E1
			'O8H108020': offset=-0.12	; 19jan LDS749
			'O8H108030': offset=-1.36	; 19jan LDS749 E1
			'O8H109020': offset=-.42	; 19jun lds cntr
			'O8H109030': offset=-2.18	; 19jan LDS749 E1
			'OBBM01030': offset=-1.39	; LDS749 E1 13feb
			'O8H2010K0': offset=-1.3  ;bd75 
			'O8H2010L0': offset=-1.5  ;bd75 
			'O8H2010M0': offset=-1.3  ;bd75 
			'O8H2010N0': offset=-1.5  ;bd75 
			'O8J5010F0': offset=-1.0  ;bd75 
			'O8J5010G0': offset=-1.0  ;bd75 
			'O8J5010H0': offset=-1.3  ;bd75
			'O8UI03010': offset=-1.4  ;vb8	hand H&K alignment E1
			'OC5507010': offset=-1.5  ;vb8  .....................
			'OC5508010': offset=-0.9  ;vb8  ......2013sep06......
			'O8VJ10010': offset=-1.75 ; 19jun c26202 E1 g430l
			'O8VJ11010': offset=-1.15	; 19jan sf1615 E1
			'O8VJ12010': offset=-1.21	; 19jan snap-2 E1
			'OBC405040': offset=-.66	;HD165459 wl.offs..-2009
			'OBC405050': offset=0.24	;HD165459 wl.offs..-2009
			'OBNF07010': offset=-0.52 ;11mar15 wl.offsets-2009KF06T2
			'OBVP08010': offset=-0.20 ;12mar26 wl.offsets-2009KF06T2
			'ODD709010': offset=0.40  ;17jun13 G430 E1 KF08T3
			'OBC406030': offset=-1.15 ;11mar15 wl.offsets-2009 1732.
			'OBC407030': offset=-0.81 ;11mar15 wl.offsets-2009 1740.
			'OBC408030': offset=-0.60 ;11mar15 wl.offsets-2009 1743.
			'OBC410030': offset=-0.80 ;11mar15 wl.offsets-2009 1805.
			'OBC411030': offset=-1.39 ;11mar15 wl.offsets-2009 1812.
			'OBTO01010': offset=-.72  ;19jan wl.offsets-2009HD159222
			'OBTO02030': offset=-1.00 ;19jan E1 HD14943
			'OBTO02040': offset=+0.23 ;19jan HD14943
			'OBTO03030': offset=-1.00 ;19jan 2009 HD158485 E1
			'OBTO03040': offset=0.24  ;19jan wl.offsets-2009HD158485
			'OBTO04030': offset=-.90  ;19jan E1 HD163466
			'OBTO04040': offset=0.18  ;19jan HD163466
			'OBTO05020': offset=-1.09  ;13feb lam Lep E1
			'OBTO06010': offset=0.16  ;13feb 10 Lac
			'OBTO06020': offset=-.98  ;13feb 10 Lac E1
			'OBTO07010': offset=0.32  ;13feb mu Col
			'OBTO07020': offset=-.93  ;13feb mu Col E1
			'OBTO08020': offset=-1.11 ;13feb ksiCet E1
			'OBTO09010': offset=0.38  ;13feb wl.offsets-2009HD60753
			'OBTO09020': offset=-.88  ;13feb ... HD60753 E1
			'OBTO11040': offset=0.42  ;13feb Sirius
			'OBTO11050': offset=0.35  ;13feb Sirius
; No wave cals for 12813-Schmidt program OC3I*
			'OC3I01020': offset=-3.80	; 13feb HD009051 E1
			'OC3I01030': offset=-2.86	; 13feb HD009051
			'OC3I02020': offset=-4.31	; 13feb HD031128 E1
			'OC3I02030': offset=-3.23	; 19jan HD031128
			'OC3I03020': offset=-4.06	; 19jan HD074000 E1
			'OC3I04020': offset=-3.99	; 19jan HD111980 E1
			'OC3I04030': offset=-3.02	; 19jan HD111980
			'OC3I05020': offset=-4.18	; 13feb HD160617 E1
			'OC3I05030': offset=-3.00	; 13feb HD160617
			'OC3I06020': offset=-4.30	; 13feb HD200654 E1
			'OC3I07010': offset=-3.90	; 13feb HD185975 E1
			'OC3I07030': offset=-2.57	; 13feb HD185975
			'OC3I08020': offset=-4.72	; 13feb BD21D0607 E1
			'OC3I09020': offset=-3.90	; 19jan BD54D1216 E1
			'OC3I10010': offset=-4.50	; 19jan BD29D2091 E1
			'OC3I11010': offset=-4.30	; 13jun BD26d2606 E1
			'OC3I12020': offset=-4.16	; 13feb BD02D3375 E1
; No lines & NO wavecal for GJ7541A. Fix wls by matching model at 3000A, 
;	which is v. precise:
			'OC3I13020': offset=-4.30	; 13feb GJ7541A E1
; Subarrays for Carlos G430L solar analogs:
			'O6H05WAXQ': offset=-1.74	; 19jan HD146233 E1
			'O6H05WAYQ': offset=-1.61	; 19jan HD146233 E1
			'OB1C02040': offset=-0.19	; 16feb HD189733
			'OB1C02050': offset=-0.22       ; 16feb HD189733
			'OB1C02060': offset=-0.22       ; 16feb HD189733
			'OB1C02070': offset=-0.28       ; 16feb HD189733
			'OB1C02080': offset=-0.33       ; 16feb HD189733
			'OB1C04010': offset=-0.22       ; 16feb HD189733
			'OB1C04020': offset=-0.28       ; 16feb HD189733
			'OB1C04030': offset=-0.34       ; 16feb HD189733
			'OB1C04040': offset=-0.37       ; 16feb HD189733
			'OB1C04050': offset=-0.37       ; 16feb HD189733
			'OB1C04060': offset=-0.57       ; 16feb HD189733
			'OB1C04070': offset=-0.95       ; 16feb HD189733
			'OB1C04080': offset=-1.35       ; 16feb HD189733
			'OC3301010': offset=+0.19       ; 16feb HD189733
			'OC3301070': offset=+0.23       ; 16mar HD189733
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
			
			'O5JA040H0': offset=+0.31	; 19jan BD-11D3759
			'ODTA03030': offset=-1.46	; 19jan HD128998 E1
			'ODTA03040': offset=-0.23	; 19jan HD128998
			'ODTA04030': offset=-4.07   ; 19may HD101452 E1 nowavcal
			'ODTA05030': offset=-4.3	; 19jan HD2811 E1
			'ODTA06030': offset=-4.07   ; 19may HD55677 E1 nowavcal
			'ODTA07020': offset=-0.94   ; 19may 18sco E1
			'ODTA08020': offset=-0.95	; 19may 16CYGB E1
			'ODTA09020': offset=-0.91	; 19may HD142331 E1
			'ODTA11020': offset=-1.07	; 19jan HD115169 E1
			'ODTA12030': offset=+0.48	; 19jan ETAUMA Bad
			'ODTA12040': offset=+0.35	; 19jan ETAUMA
			'O40801010': offset=+0.24	; 19may FEIGE110
			'ODTA13020': offset=-4.37   ; 19may FEIGE110 E1 nowavcal
			'ODTA14020': offset=-1.55	; 19may FEIGE34 E1
			'ODTA15030': offset=-1.59	; 19may HD93521 E1
			'ODTA15040': offset=-0.22	; 19may HD93521
; 19May-HZ21 is 90% He, so try HeII lines:. No radial Vel meas. Line at 
; koester: 3204.022, HeI  4472.755
;	OOPs no wavecal: shift=(3204.02-3215.0meas)/2.73=-4.0
; ck w/ line used by LDS749B: (4472.755-4485.9)/2.73=-4.8 --> adopt -4.6
			'ODTA16020': offset=-4.6	; 19may HZ21 E1 nowavcal
			'ODTA17020': offset=-4.65	; 19may HZ4 E1 nowavcal
			'ODTA18010': offset=-4.00	; 19may HZ44 E1 nowavcal
			'ODTA19030': offset=-0.85	; 19may 109Vir E1
			'ODTA19040': offset=+0.39	; 19may 109Vir
			'ODTA51030': offset=-1.21	; 19jan DELUMI E1
			'ODTA60020': offset=-1.05	; 19jun HD167060 E1
			'ODTA72030': offset=-1.33	; 19may ETA1DOR E1
			'ODTB01030': offset=-1.46	; 19jun SDSSJ151421 E1
			
			else: begin   &  endelse  &  endcase
			
		'7751': case root of			;h-alpha=6563
			'ODDG01030': offset=+0.13 ; 19jun wl.offsets g750l GRW
			'ODDG03030': offset=-0.11 ; 19jun wl.offsets g750l GRW
			'ODDG04030': offset=+0.18 ; 19jun wl.offsets grw
; 03may5 - See wl.offsets-agk file:
			'O45A03030': offset=+0.46 ; AGK
			'O45A04030': offset=+0.47
			'O45A05030': offset=-0.29
			'O45A12030': offset=0.17 ; 19jun wl.offsets-7672 agk
			'O45A13030': offset=-0.17 ; 19jun wl.offsets-7672 agk
			'O45A14030': offset=-0.22 ; 19jun wl.offsets-7672 agk
			'O45A15030': offset=-0.11 ; 19jun wl.offsets-7672 agk
			'O45A16030': offset=0.15 ; 19jun wl.offsets-7672 agk
			'O5IG01030': offset=-0.25 ; 19jun wl.offsets-7672 agk
			'O5IG03030': offset=0.16 ; 19jun wl.offsets-7672 agk
			'O5IG05030': offset=0.16 ; 19jun wl.offsets-7672 agk
			'O5IG07030': offset=0.10 ; 19jun wl.offsets-7672 agk
			'O5IG04030': offset=-0.35
			'O69L02040': offset=0.10 ; 19jun wl.offsets-7672 agk
			'O6I902040': offset=0.24 ; 19jun wl.offsets-7672 agk
			'O6I903060': offset=-0.32
			'O6I904060': offset=-0.24 ; 19jun wl.offsets-7672 agk
			'O6IL02040': offset=-2.24 ; 19jun wl.offsets-7672 agk
			'O6IL02090': offset=-2.43 ; 19jun wl.offsets-7672 agk
			'O6IL020J0': offset=-2.27 ; 19jun wl.offsets-7672 agk
			'O8JJ01060': offset=-0.40
			'O8JJ04060': offset=0.22 ; 19jun wl.offsets-7672 agk
			'O8U201060': offset=0.15 ; 19jun wl.offsets-7672 agk
			'O8U202060': offset=-0.26 ; 19jun g750l
			'O8U203060': offset=-0.34 ; 19jun wl.offsets-7672 agk
			'O8U205060': offset=-0.12 ; 19jun wl.offsets-7672 agk
			'O8U206060': offset=-0.33		;05may13
			'O8U207060': offset=-0.16 ; 19jun wl.offsets-7672 agk
			'O8U208060': offset= 0.11 ; 19jun wl.offsets-7672 agk
			'OA9J010A0': offset=-0.82		;09jul16-E1
			'OBAU01050': offset=-1.00 ; 09aug13 wl.offsets-agk E1
			'OBAU01060': offset=-0.32 ; 13feb14 wl.offsets-2009
			'OBAU02060': offset=-0.12 ; 19jun wl.offsets g750l agk
			'OBAU02050': offset=-0.74 ; 09oct1  wl.offsets-agk E1
			'OBAU03050': offset=-0.76 ;10may5 wl.offsets-2009 E1 agk
			'OBAU04050': offset=-0.50 ;10may5 wl.offsets-2009 E1 agk
			'OBAU04060': offset=+0.28 ;10may5 wl.offsets-2009 E1 agk
			'OBAU05050': offset=-0.67 ;10may5 wl.offsets-2009 E1 agk
			'OBAU06050': offset=-0.90 ; 10jul10 wl.offsets-2009 agk
			'OBAU06060': offset=-0.26 ; 10jul10 wl.offsets-2009 agk
			'OBMZL1050': offset=-0.57 ; 11mar15 wl.offsets-2009 agk
			'OBMZL3060': offset= 0.40 ; 11aug wl.offsets-2009 agk
			'OBMZL4060': offset=-0.37 ; 11aug wl.offsets-2009 agk
			'OBVNL2060': offset= 0.19 ; 19jun wl.offsets g750l agk
			'OBMZL3050': offset=-0.32 ; 12mar16 wl.offsets agk E1
			'OBMZL4050': offset=-0.92 ; 12mar16 wl.offsets agk E1
			'OBVNL1050': offset=-0.71 ; 12mar16 wl.offsets agk E1
			'OBVNL2050': offset=-0.60 ; 12sep wl.offsets-2009 agk E1
			'OBVNL3050': offset=-0.73 ; 12sep wl.offsets-2009 agk E1
			'OC4IL1060': offset=-0.21 ; 13jan wl.offsets-2009 agk	
			'OC4IL3060': offset= 0.13 ; 19jun wl.offsets g750l agk
			'OCEIL1060': offset=-0.57 ; 14feb wl.offsets-2009 agk	
			'OCEIL4060': offset=-0.37 ; 15jun     agk
			'OCPKL1060': offset=-0.20 ; 15may wl.offsets-2009 agk
			'OCPKL2060': offset=-0.20 ; 15may wl.offsets-2009 agk	
			'OD1AL1060': offset=-0.26 ; 15nov wl.offsets-2009 agk	
			'OD1AL4060': offset=-0.18 ; 16sep wl.offsets-2009 agk	
			'ODBVL1060': offset=-0.20 ; 16dec wl.offsets-2009 agk	
			'ODBVL3060': offset=-0.11 ; 19jun wl.offsets g750l agk
			'ODOHL1060': offset=-0.56 ; 19may wl.offsets-2009 agk
; fails??? see patch at bottom	'ODOHL3060': offset=-0.39 ; 19may agk
			'ODVKL1060': offset=-0.39 ; 19may agk		     
			'ODVKL2060': offset=-0.17 ; 19jun wl.offsets g750l agk
; 02dec3-see p041wl.g750l-befor
			'O403020E0': offset=2.39
			'O403020F0': offset=2.27
			'O403020G0': offset=2.09
			'O403020H0': offset=1.92
			'O403020I0': offset=1.40
			'O403020J0': offset=1.11
			'O403020K0': offset= .79
			'O403020L0': offset= .41
			'O403020O0': offset=-.66
			'O403020P0': offset=-.64
			'O49X01010': offset=-0.37	; 19jan BD28 nowavcal
			'O49X02010': offset=-0.41	; 19jan BD28 nowavcal
			'O49X11010': offset=-0.13	; 19jan GRW nowavcal
			'O49X12010': offset=+0.13	; 19jan GRW nowavcal
			'O49X25010': offset=0.59	; 19jan p177d nowavcal
			'O49X26010': offset=0.64	; 19jan p177d nowavcal
			'O49X27010': offset=0.43	; 19jan p330e nowavcal
			'O49X28010': offset=0.06	; 19jan p330e  nowavcal
			'OBC403020': offset=0.64	;p177d 10may5 nowavcal
			'OBC404020': offset=0.16	; 19jan p330e nowavcal
			'OBNF06020': offset=0.25	; 19jan p330e nowavcal
			'O8H101040': offset=0.08 ; 19jan bd17 wl.offsets-bd17
			'O8H102040': offset=-.45 ; 19jan bd17 wl.offsets-bd17
			'O8H103040': offset=-.26 ; 19jan bd17 wl.offsets-bd17
			'O8VJ10020': offset=-0.48 ; 19jun c26202 g750l
			'O8VJ12020': offset=-0.17 ; 19jun snap2 g750l
; WD offsets in wlerr.g750l-wd. For prime WD:
			'O3TT42040': offset=+0.19       ; 19jan GD153
			'O3TT43040': offset=+0.24       ; 19jan GD153
			'O3TT44040': offset=+0.18       ; 19jan GD153
			'O3TT45040': offset=+0.10       ; 19may GD153
			'O3TT46040': offset=+0.42       ; 19jan GD153
			'O3TT47040': offset=+0.57       ; 19jan GD153
			'O3TT48040': offset=+0.31       ; 19jan GD153
			'O4D103030': offset=+0.28       ; 19jan GD153
			'O4A502020': offset=-0.16       ; 19jan GD153
			'O8V202070': offset=+0.19       ; 19jan GD153
			'OBC402060': offset=+0.38       ; 19jan GD153
			'OC5506060': offset=-0.44       ; 19jan GD153
			'OCGA05060': offset=+0.23       ; 19jan GD153
			'ODCK02060': offset=+0.29       ; 19jan GD153
			'O49X09010': offset=-0.20       ; 19jan GD71
			'O49X10010': offset=+0.29       ; 19jan GD71
			'O4A551020': offset=+0.27       ; 19jan GD71
			'O61001040': offset=+0.23       ; 19jan GD71
			'O61004030': offset=+0.30       ; 19jan GD71
			'O61005030': offset=+0.21       ; 19jan GD71
			'O61006030': offset=+0.18       ; 19jan GD71
			'O5I001050': offset=+0.09       ; 19jan GD71
			'O6IG01060': offset=+0.26       ; 19jan GD71
			'O8V201090': offset=+0.49       ; 19jan GD71
			'OBC401060': offset=+0.06       ; 19jan GD71
			'OBVP06060': offset=+0.49       ; 19jan GD71
			'OC3I15030': offset=+0.23       ; 19jan GD71
			'OCGA04060': offset=+0.37       ; 19jan GD71
			'ODCK01060': offset=+0.65       ; 19jan GD71
			'ODUD01060': offset=+0.54       ; 19apr GD71

			'O4D102030': offset=+0.12       ; G191 16dec13
; 16dec13- now ~0		'O49X07010': offset=+0.40   ; G191 13sep
			'O69U05030': offset=-0.25       ; G191 16dec13
			'O69U06030': offset=-0.30       ; G191 16dec13
			'O6IG100F0': offset=-0.19       ; G191 10jul E1 narrow
			'O6IG100G0': offset=-1.14	; G191 10aug E1 narrow
			'O6IG100H0': offset=-0.54	; G191 10jul E1 narrow
			'O6IG100I0': offset=-0.69	; G191 10jul E1 narrow
			'O8V203060': offset=-0.50       ; G191 16dec13
			'OBBC07040': offset=-0.11       ; 19jan G191
			'OC3I14040': offset=-0.29 	; G191 16dec13
			'OCGA06040': offset=-0.16       ; 19jan G191
			'ODCK03040': offset=-0.39 	; G191 16dec13
			'ODUD03040': offset=-0.33 	; G191 19mar12

			'OCWGA1010': offset=+0.70	; 19jan WD1327-083
			'OCWGA2010': offset=+0.67	; 19jan WD2341+322

			'O8I105070': offset=-0.21 ; 19jun wl.offsets-vega
			'O8I106050': offset= 0.10 ; 19jun wl.offsets-vega
; 06June FASTEX G750L WDs confirmed/tweaked w/ wlabsrat.pro (from Line symmetry):
			'O8V101030': offset=+0.3  ;WD1657
			'OBNK01040': offset=-1.24  ;WD0308 2016sep15
			'O8V102030': offset=+0.7  ;snap-1
			'O8V103030': offset=+0.4  ;snap-1
			'O3WY02040': offset=+0.65	; 19jan bd75 
			'O49X03020': offset=+0.48	; 19jan bd75 
			'O4A505010': offset=-0.43	; 19jan bd75 
			'O8H201140': offset=-1.0  ;bd75
			'O8H201150': offset=-0.9  ;bd75
			'O8H201160': offset=-1.0  ;bd75
			'O8H201170': offset=-0.9  ;bd75
			'O8J5010N0': offset=-0.9  ;bd75
			'O8J5010O0': offset=-0.8  ;bd75
			'O8J5010P0': offset=-1.0  ;bd75
			'O69U07030': offset=-0.38	; 19jan HZ43
			'O69U08030': offset=-0.22	; 19jan HZ43
			'O8KH03010': offset=-1.3  ; 2M0036+18
			'O8UI03020': offset=-0.7  ; vb8 2013sep align w/g430L
			'OC5507020': offset=-0.2  ; vb8 2013sep  ...........
; zero shift		'OC5508020': offset=0.    ; vb8 2013sep  at 5400-5600
			'O6I903050': offset=-1.47
			'O6I904050': offset=-1.35
			'O8JJ01050': offset=-1.43
			'O8JJ02050': offset=-1.13
			'O8JJ03050': offset=-0.94
			'O8JJ04050': offset=-0.94
			'O8U201050': offset=-0.81
			'O8U202050': offset=-0.27
			'O8U205050': offset=-0.94
			'O8U206050': offset=-0.66
			'O8U207050': offset=-0.40
; comment		'O6N3A4060': offset=<.1px=0.5A  ; 09jan HD209458 Ha eye
			'O6D204070': offset=-.51 ; 09jan HD209458 nowavcal
			'O6D204080': offset=-.52 ; 09jan HD209458 nowavcal
			'O6D204090': offset=-.56 ; 09jan HD209458 nowavcal
			'O6D2A4010': offset=-.70 ; 09jan HD209458 nowavcal
			'O6D2A4030': offset=-.70 ; 09jan HD209458 nowavcal
			'O6D222060': offset=-1.02 ; 09jan HD209458 nowavcal
			'O6D222070': offset=-.97 ; 09jan HD209458 nowavcal
			'O6D222080': offset=-.75 ; 09jan HD209458 nowavcal
			'O6D2B2020': offset=-2.90 ; 09jan HD209458 nowavcal
			'O6D2B2040': offset=-2.87 ; 09jan HD209458 nowavcal
			'O6N302010': offset=-2.02 ; 09jan HD209458 nowavcal
			'O6N302030': offset=-2.11 ; 09jan HD209458 nowavcal
			'O6N302050': offset=-2.21 ; 09jan HD209458 nowavcal
			'O6N304010': offset=-2.38 ; 09jan HD209458 nowavcal
			'O6N304030': offset=-2.45 ; 09jan HD209458 nowavcal
			'O6N304050': offset=-2.49  ; 09jan HD209458 nowavcal
			'OBC405060': offset=+0.32 ;HD165459 wl.offs..-2009
			'OBC406040': offset=-0.24 ;15may 1732526 wl.offs..-2009
			'OBNF07020': offset=-0.46 ;KF06T2 wl.offs..-2009
			'ODD707020': offset=+0.25 ; 19jun g750l KF08T3
			'ODD709020': offset=0.44  ;17jun13 G750 KF08T3
			'OBC408040': offset=+0.50 ;1743045 wl.offs..-2009
			'OBC457040': offset=0.33 ;1740346 11aug wl.offsets-2009 
			'OBC409040': offset=0.49 ;1802271 11aug wl.offsets-2009
			'OBC410040': offset=0.25 ;19jun 1805292 wl.offsets-2009
			'OBC411040': offset=-0.20 ;19jun g750l 1812095
			'OBNL03040': offset=0.28 ; 19jan HD116405wl.offsets-2009
			'OBNL02040': offset=0.40 ; 12jan HD37725
			'OBNL04040': offset=0.64 ; 12jan 1757132
			'OBNL05040': offset=-0.15 ; 19jun g750l 1808347
			'OBNL06040': offset=+0.14 ; 19jun g750l
			'OBNL07040': offset=0.33 ; 12jan BD+60D1753
			'OBNL09030': offset=+0.12 ; 19jun g750l HD38949
			'OBNL10030': offset=0.59 ; 19jan HD106252 wl.offsets
			'OBNL11030': offset=0.36 ; 19jan HD205905 wl.offsets
			'OBTO01030': offset=0.38 ; 19jan wl.offsets-2009HD159222
			'OBTO02050': offset=0.34 ; 19jan HD14943
			'OBTO03050': offset=0.29 ; 19jan HD158485
			'OBTO04050': offset=0.29 ; 19jan HD163466
			'OBTO06050': offset=0.29 ; 13feb 10 Lac
			'OBTO07050': offset=0.38 ; 13feb mu col
			'OBTO09050': offset=0.29 ; 13feb HD60753
			'OBTO11060': offset=0.39 ; 19may Sirius
; W/ wave cals for 12813-Schmidt program OC3I*
			'OC3I01040': offset=0.56	; 13feb HD009051
			'OC3I02040': offset=0.23	; 19jan HD31128
			'OC3I03030': offset=0.60	; 13feb HD074000
			'OC3I04040': offset=0.41	; 19jan HD111980
			'OC3I05040': offset=0.37	; 13feb HD160617
			'OC3I06030': offset=0.51	; 13feb HD200654
			'OC3I07040': offset=0.83	; 13feb HD185975
			'OC3I08030': offset=0.20	; 19jan BD21D0607
			'OC3I09030': offset=0.56	; 19jan BD54D1216
			'OC3I10030': offset=0.26	; 15may BD29D2091
			'OC3I11030': offset=0.48	; 13feb BD26d2606
			'OC3I12030': offset=0.17	; 13feb BD02D3375
;2013feb15-weak line gives -1.28 to -1.52 but may not be H-alpha.
;	Use the structure in the counts to get -0.08 px, which is zero shift:
;	HAS wavecal...
;info only		'OC3I13030': offset=-1.28	; 13feb GJ7541A

			'O49X13010': offset=-0.54 ; 19jan 93521 wl.offs
			'O49X13020': offset=-0.57 ; 19jan 93521 wl.offs
			'O49X13030': offset=-0.59 ; 19jan 93521 wl.offs
			'O49X13040': offset=-0.61 ; 19jan 93521 wl.offs
			'O49X14010': offset=-0.11 ; 19jan 93521 wl.offs
			'O49X14020': offset=-0.16 ; 19jan 93521 wl.offs
			'O49X14030': offset=-0.19 ; 19jan 93521 wl.offs
			'O49X14040': offset=-0.23 ; 19jan 93521 wl.offs
			
; 19May-HZ21 is 90% He, so try HeII lines:. No radial Vel meas. Line at 
; Koester 6561.90 {HI @ 6564.6} (6561.90-6561)/4.9=+0.18, but trust X-correl fix
			'O49X15010': offset=+0.48 ; 19may hz21
;	(6561.90-6558.5)/4.9=0.69       Ck OK
			'O49X16010': offset=+0.57 ; 19may hz21
			'O49X22010': offset=-0.26 ; 19may hz4 wl.offs..-7674
			'O57T01020': offset=-0.31 ; 19jan hz43 wl.offs..-7674
			'O57T02020': offset=-1.15 ; 19jan hz43 wl.offs..-7674
			'O6H05WAZQ': offset=-1.03 ;19jan HD146233
			'O6H05WB0Q': offset=-1.16 ;19jan HD146233
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
; ff unstable btwn -.37 & -.45		
			'O5JA040I0': offset=-0.41	; 19jan BD-11D3759 G750l
			'ODTA03050': offset=-0.24	; 19jan HD128998
			'ODTA03060': offset=-0.27	; 19jan HD128998
			'ODTA04040': offset=+0.38	; 19jun HD101452
			'ODTA06040': offset=+0.19	; 19may HD55677
			'ODTA07030': offset=+0.47	; 19may 18sco
			'ODTA07040': offset=+0.38	; 19may 18sco
			'ODTA08030': offset=+0.58	; 19jan 16CYGB
			'ODTA08040': offset=+0.39	; 19jan 16CYGB
			'ODTA09030': offset=+0.44	; 19jan HD142331
			'ODTA11030': offset=+0.22	; 19jan HD115169
			'ODTA12050': offset=+0.36	; 19jan etauma Bad
			'ODTA12060': offset=+0.34	; 19jan etauma
			'ODTA13030': offset=-0.28	; 19jan FEIGE110
			'ODTA15050': offset=+0.40	; 19may HD93521
			'O49X05010': offset=-0.47	; 19jan FEIGE34
			'O49X06010': offset=-0.20	; 19jan FEIGE34
			'O49X19010': offset=+0.48	; 19jan HZ44
			'O49X20010': offset=+0.52	; 19jan HZ44
			'ODTA19050': offset=+0.38	; 19jan 109Vir
			'ODTA19060': offset=+0.28	; 19jan 109Vir
			'ODTA51050': offset=+0.38	; 19jan delumi
			'ODTA51060': offset=+0.31	; 19jan delumi
			'ODTA60030': offset=+0.37	; 19may HD167060
			
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
if root eq 'ODOHL3060' then offset=-0.39

if offset ne 0 then print,'STISWLFIX returned a WL offset=',offset,	$
		' pixels for ',cenwave
return,offset
end
