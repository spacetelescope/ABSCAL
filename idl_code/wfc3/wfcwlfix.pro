function wfcwlfix,root,targ,silent=silent
;+
;
; Name:  wfcwlfix
; PURPOSE:
;	Return the correction in Angstroms to be *added to* the wavelengths
;			
; CALLING SEQUNCE:
;	offset=wfcwlfix(root,targ)
; Inputs:
;	root - observation rootname
;	targ - target name+filter (optional), as not? added to AXE calls in
;		CALWFC_SPEC_WAVE (which is in calwfc_spec.pro)
;	silent - for example, just to add to header info in CALWFC_SPEC

;	The wavelength correction in Ang. A vector for [G102,G141]
;	(Disp is Ang/px=24.5, 46.5, respectively.)
;	   wl.fixes for formatted shifts for >0.4px or >0.2px for 2GD prime WDs,
;		I.E. 10 & 18A (OR 5 & 9A FOR PRIME WDs)
; HISTORY
;	2018may14-First use for ic6903
;	paschen gamma,beta=10941.1, 12821.6 (10938.1, 12818.1-air)
; 8752.86 8865.32 9017.8 9232.2 9548.8 10052.6 10941.082 12821.578 18756.4 vac
;	2020feb4 - add targ to param for 15816 w/ 2 targ/image.
; 2020oct7 - make use of targ, which now becomes targ+filter in calwfc_spec, etc
; 2020Oct15 - merge or mrg means matching at the G102-141 overlap for kf*,
;	2m*,p330e,etc OR fixing long & short WL flux from matching short WL G141
;	to G102 on mrgall plots, while cking that the long WL G141L on the 
;	stiscf plots is reasonable.
;	Use new wl.fixes cards.
;-
offset=0.
case root of
        'ic6904b4q': offset=  -6.			;20Oct-G191B G102
        'ibwl84hqq': offset=  -6.			;20Oct-G191B G102
        'ibwl84hrq': offset=  -6.			;20Oct-G191B G102
        'ibwl84hvq': offset=  -7.			;20Oct-G191B G102
        'ic6903y4q': offset= -24.			;20Oct-G191B G102
        'ic6903y5q': offset= -29.			;20Oct-G191B G102 mrg-10
        'ichg01e6q': offset= -19.			;20Oct-G191B G102 mrg-10
        'ichg01e7q': offset= -19.			;20Oct-G191B G102 mrg-10
        'ichg01e9q': offset= -18.			;20Oct-G191B G102 mrg-10
        'ichg01eaq': offset= -19.			;20Oct-G191B G102 mrg-10

        'iab901ekq': offset=  -6.			;20Oct-GD153 G102
        'iab901elq': offset=  -7.			;20Oct-GD153 G102
;? glitch        'iab901emq': offset=   6.			;20Oct-GD153 G102
        'iab901enq': offset=  -6.			;20Oct-GD153 G102
        'iab901esq': offset= -12.			;20Oct-GD153 G102
        'iab9a1eyq': offset= -11.			;20Oct-GD153 G102
        'ibwq1asfq': offset=  -9.			;20Oct-GD153 G102
        'ibwq1asgq': offset= -10.			;20Oct-GD153 G102
        'ibwq1ashq': offset=  -6.			;20Oct-GD153 G102
        'ibwq1asiq': offset=  -9.			;20Oct-GD153 G102
        'ibwq1aspq': offset=  -5.			;20Oct-GD153 G102
        'ibwq1aswq': offset= -12.			;20Oct-GD153 G102
        'ibwq1aszq': offset=  -9.			;20Oct-GD153 G102
        'ibwq1at2q': offset= -13.			;20Oct-GD153 G102
        'ibwq1at9q': offset= -15.			;20Oct-GD153 G102
        'ibwq1atcq': offset=  -7.			;20Oct-GD153 G102
        'ibwq1atgq': offset=  -8.			;20Oct-GD153 G102
        'ibwq1atmq': offset= -11.			;20Oct-GD153 G102
        'ibwq1atqq': offset= -11.			;20Oct-GD153 G102
        'ibwq1attq': offset=  -8.			;20Oct-GD153 G102
        'ibwqaatwq': offset=  -9.			;20Oct-GD153 G102
        'ic461aglq': offset=  -5.			;20Oct-GD153 G102
        'ic461agmq': offset=  -8.			;20Oct-GD153 G102
        'ic461agsq': offset=  -5.			;20Oct-GD153 G102
        'ic461agvq': offset=  -9.			;20Oct-GD153 G102
        'ic461agwq': offset=  -9.			;20Oct-GD153 G102
        'ich318bsq': offset=  -9.			;20Oct-GD153 G102
        'ich401hhq': offset=  -8.			;20Oct-GD153 G102
        'ich401hqq': offset=  -6.			;20Oct-GD153 G102
        'ich402anq': offset= -18.			;22sep-GD153 G102
        'ich402aoq': offset= -19.			;22sep-GD153 G102
        'ich402aqq': offset= -18.			;22sep-GD153 G102
        'ich402arq': offset= -17.			;22sep-GD153 G102
        'ich402avq': offset= -13.			;22sep-GD153 G102
        'ich402awq': offset= -13.			;22sep-GD153 G102
        'ich402azq': offset= -24.			;22sep-GD153 G102 disp?
        'ich402b0q': offset= -24.			;22sep-GD153 G102 disp?
        'id2q01fpq': offset=  -9.			;20Oct-GD153 G102
        'id2q01fsq': offset=  -6.			;20Oct-GD153 G102
        'id2q01fzq': offset=  -8.			;20Oct-GD153 G102
        'id2q01g2q': offset=  -7.			;20Oct-GD153 G102
        'id2q01g9q': offset=  -6.			;20Oct-GD153 G102
        'id2q01gcq': offset=  -6.			;20Oct-GD153 G102
        'id2q01ggq': offset=  -6.			;20Oct-GD153 G102
        'id2q01gjq': offset=  -7.			;20Oct-GD153 G102
        'id2q01gmq': offset=  -8.			;20Oct-GD153 G102
        'idco01rpq': offset=  -9.			;20Oct-GD153 G102
        'idco01rsq': offset=  -7.			;20Oct-GD153 G102
        'idco01rwq': offset=  -9.			;20Oct-GD153 G102
        'idco01rzq': offset= -10.			;20Oct-GD153 G102
        'idco01s2q': offset=  -6.			;20Oct-GD153 G102
        'idco01s6q': offset=  -7.			;20Oct-GD153 G102
        'idco01scq': offset=  -9.			;20Oct-GD153 G102
        'idco01sgq': offset=  -7.			;20Oct-GD153 G102
        'idco01sjq': offset=  -6.			;20Oct-GD153 G102
        'idco01smq': offset=  -7.			;20Oct-GD153 G102
        'idpo02p2q': offset=  -9.			;20Oct-GD153 G102
        'idpo02p5q': offset=  -5.			;20Oct-GD153 G102
        'idpo02p8q': offset=  -9.			;20Oct-GD153 G102
        'idvj01p5q': offset= -10.			;20Oct-GD153 G102
        'ie0v01nrq': offset=  -6.			;20Oct-GD153 G102
        'ie0v01nuq': offset=  -7.			;20Oct-GD153 G102
        'iegi01hkq': offset=  -5.			;21mar-GD153 G102
        'iegi01hnq': offset=  -8.			;21mar-GD153 G102
        'iegi01hnq': offset=  -8.			;21mar-GD153 G102
        'iele01lbq': offset=  -6.			;22Sep-GD153 G102
        'iele01leq': offset=  -7.			;22Sep-GD153 G102
        'iepb07mtq': offset=  -5.			;22Sep-GD153 G102
        'iepb07muq': offset=  -8.			;22Sep-GD153 G102

        'ibbt01p0q': offset=  -6.			;20Oct-GD71 G102
        'ibbt01p1q': offset= -10.			;20Oct-GD71 G102
        'ibbt01p2q': offset= -14.			;20Oct-GD71 G102
        'ibbt01p3q': offset=  -8.			;20Oct-GD71 G102
        'ibbt01p8q': offset= -21.			;20Oct-GD71 G102 disp?
        'ibbt01pbq': offset=  -5.			;20Oct-GD71 G102
        'ibbt01peq': offset= -11.			;20Oct-GD71 G102
        'ibbt01piq': offset=  -8.			;20Oct-GD71 G102
        'ibbt01plq': offset= -12.			;20Oct-GD71 G102
        'ibbt01pvq': offset=  -8.			;20Oct-GD71 G102
        'ibbt03efq': offset= -11.			;20Oct-GD71 G102
        'ibbt03egq': offset=  -6.			;20Oct-GD71 G102
        'ibbt03ehq': offset= -11.			;20Oct-GD71 G102
        'ibbt03eiq': offset=  -5.			;20Oct-GD71 G102
;        'ibbt03emq': offset= -14.			;20Oct-GD71 G102 mrg+14
        'ibbt03epq': offset= -10.			;20Oct-GD71 G102
        'ibbt03esq': offset= -13.			;20Oct-GD71 G102
        'ibbt03ewq': offset=  -9.			;20Oct-GD71 G102
        'ibbt03ezq': offset= -11.			;20Oct-GD71 G102
        'ibbt03f6q': offset= -13.			;20Oct-GD71 G102
        'ibbt03f9q': offset= -10.			;20Oct-GD71 G102
        'ibll14teq': offset=  +7.			;20Oct-GD71 G102 mrg+15
        'ibll14tgq': offset= -10.			;20Oct-GD71 G102
        'ibll14thq': offset= -14.			;20Oct-GD71 G102
        'ibll14tiq': offset= -10.			;20Oct-GD71 G102
;        'ibll14tkq': offset= -13.			;20Oct-GD71 G102 mrg+13
        'iblf01cjq': offset=  -6.			;20Oct-GD71 G102
        'iblf01ckq': offset=  -8.			;20Oct-GD71 G102
        'iblf01clq': offset=  -6.			;20Oct-GD71 G102 to -5
        'iblf01cpq': offset= -11.			;20Oct-GD71 G102
        'iblf01cvq': offset= -10.			;20Oct-GD71 G102
        'iblf01czq': offset=  -8.			;20Oct-GD71 G102
        'iblf01d2q': offset= -11.			;20Oct-GD71 G102
        'iblf01d5q': offset=  -7.			;20Oct-GD71 G102
        'iblf01d9q': offset= -11.			;20Oct-GD71 G102
        'iblf01dcq': offset= -11.			;20Oct-GD71 G102
        'iblf01deq': offset=  -7.			;20Oct-GD71 G102
        'iblf01dgq': offset= -11.			;20Oct-GD71 G102
        'ibwq02jnq': offset=  -7.			;20Oct-GD71 G102
        'ibwq02jpq': offset=  -9.			;20Oct-GD71 G102
        'ibwq02jqq': offset=  -7.			;20Oct-GD71 G102
; 2020Oct20 ff icqw01* have bad offsets because of contam @ long wl.
;	Keep w/ zero offset. Net is low because of time change losses.
;	FIXED w/ 11000A cutoff in wavoff.pro
	'icqw01z1q': offset=  -7.		     ;20Oct-GD71 G102 contam OK
	'icqw01zjq': offset= -65.		     ;22sep-GD71 G102 contam OK
	'icqw01zrq': offset= -67.		     ;22sep-GD71 G102 contam OK
	'icqw01zvq': offset= -72.		     ;22sep-GD71 G102 contam OK
	'icqw01zyq': offset= -74.		     ;22sep-GD71 G102 contam OK
	'icqw01auq': offset= -70.		     ;22sep-GD71 G102 contam OK
	'icqw01ayq': offset= -78.		     ;22sep-GD71 G102 contam OK
	'icqw01b1q': offset= -76.		     ;22sep-GD71 G102
	'icqw01b9q': offset=  -6.		     ;20Oct-GD71 G102 contam OK
	'iegi02qcq': offset=  -7.		     ;21Jan-GD71 G102
	'iegi02qiq': offset= -41.		     ;22sep-GD71 G102
        'iele02l5q': offset= -14.			;22Sep-GD71 G102

        'id2i01egq': offset= -16.			;20Oct-18022 G102  -15
        'id2i01ehq': offset= -13.			;20Oct-18022 G102  -14
        'id2i01ejq': offset= -13.			;20Oct-18022 G102
        'id2i01emq': offset= -12.			;20Oct-18022 G102
        'id2i01eoq': offset= -18.			;20Oct-18022 G102  -16
        'id2i01erq': offset= -16.			;20Oct-18022 G102

;        'ibwl82o8q': offset= -6.0			;18Jul-18083 G102 merge
;        'ibwl82o9q': offset= -2.2			;18Jul-18083 G102 merge
;        'ibwl82obq': offset= -12.6			;18Jul-18083 G102 merge
;        'ibwl82oeq': offset= -4.1			;18Jul-18083 G102 merge

        'icsf23ajq': offset=  11.			;20Oct-2M003 G102
        'icsf23bbq': offset=  13.			;20Oct-2M003 G102
        'icsf02j4q': offset=  15.			;20Oct-2M055 G102
        'icsf02j9q': offset=  15.			;20Oct-2M055 G102

        'ibwl88acq': offset=  35.			;20Oct-BD60D G102  36
        'ibwl88adq': offset=  35.			;20Oct-BD60D G102 unstbl
        'ibwl88aeq': offset=  35.			;20Oct-BD60D G102  36
        'ibwl88afq': offset=  32.			;20Oct-BD60D G102  33
        'ibwl88agq': offset=  31.			;20Oct-BD60D G102  33
        'ibwl88ahq': offset=  35.			;20Oct-BD60D G102  37
        'ibwl88aiq': offset=  36.			;20Oct-BD60D G102
        'ibwl88ajq': offset=  36.			;20Oct-BD60D G102
	
; 2021may19 - Gaia & see at bottom, i.e. do in clumps of 8 merged files.

;20jan-Gaia G102 Eye vs STIS _1968 + _9680 all sat & BAD.
;	'ie3f10c1qGAIA593_1968': offset=+15.
;	'ie3f10c2qGAIA593_1968': offset=+15.
;	'ie3f10c3qGAIA593_1968': offset=+15.
;	'ie3f10c8qGAIA593_1968': offset=+15.
;	'ie3f10c9qGAIA593_1968': offset=+15.
; G141: line up w/ G102 at ~11500A feature by eye
;	'ie3f10caqGAIA593_1968': offset=-50.
;	'ie3f10cbqGAIA593_1968': offset=-50.
;	'ie3f10ciqGAIA593_1968': offset=-50.
;	'ie3f10cjqGAIA593_1968': offset=-50.
;	'ie3f10ckqGAIA593_1968': offset=-50.
;20jan-Gaia G102 Eye vs kf06t2 Model at ~8600A Cr?
;	'ie3f10c1qGAIA593_9680': offset=-1.
;	'ie3f10c2qGAIA593_9680': offset=-1.
;	'ie3f10c3qGAIA593_9680': offset=-1.
;	'ie3f10c8qGAIA593_9680': offset=-1.
;	'ie3f10c9qGAIA593_9680': offset=-1.

;2020sep29 - Lennon LS-V-+22-25 vs. 10052A STIS ALL by eye -->-15 all (orig)
        'ie9l03b0q': offset= -11.			;20Oct G102
        'ie9l03b3q': offset=  -8.			;20Oct-LS-V- G102 eye
        'ie9l03b7q': offset=  -7.			;20Oct G102
        'ie9l03baq': offset= -12.			;20Oct-LS-V- G102
        'ie9l03bdq': offset= -15.			;20Oct-LS-V- G102 eye
        'ie9l03bgq': offset= -11.			;20Oct-LS-V- G102  -10
; to fix 16800 bump 12821.8 could be say -30, instead of 1st cut -18A, in agree-
;	ment w/ gd71 net offset  LS-V-+22-25 G141 All em @12822A eye:
        'ie9l03avq': offset= -20. 		   	; G141-em @12822A eye
        'ie9l03ayq': offset= -20.
        'ie9l03b1q': offset= -20.			; orig: all 8 of g141
        'ie9l03b4q': offset= -20.			;  were -30
        'ie9l03b8q': offset= -30.
        'ie9l03bbq': offset= -70.			; noisy
        'ie9l03beq': offset= -30.
        'ie9l03bhq': offset= -55.			; mrg-15
	
        'ibuc42ltq': offset= -12.			;20Oct-GRW_7 G102  -11
        'ibuc52bxq': offset= -10.			;20Oct-GRW_7 G102  -9
        'ic5z07dpq': offset= -12.			;20Oct-GRW_7 G102  -11
        'ic5z08iuq': offset= -16.			;20Oct-GRW_7 G102  -15
        'ic5z09hkq': offset= -11.			;20Oct-GRW_7 G102  -9
        'ich316lqq': offset= -12.			;20Oct-GRW_7 G102
	'iegi03vnq': offset= -40.			;22sep-GRW G102
        'iele03g5q': offset= -16.			;22Sep-GRW_7 G102

        'ibwl89tnq': offset= -4.			;20Oct-HD377 G102 mrg-4
        'ibwib6m8q': offset= -20.			;20Oct-P330E G102  -19
        'ibwib6m9q': offset= -20.			;20Oct-P330E G102  -19
        'ibwib6mbq': offset= -21.			;20Oct-P330E G102
        'ibwib6mdq': offset= -25.			;20Oct-P330E G102
        'ibwib6mfq': offset= -21.			;20Oct-P330E G102
;        'ibwi05t1q': offset= -10.			;29Oct-snap2 G102stis+10
        'icrw12l8q': offset= -21.			;20Oct-VB8 G102
        'icwg01geq': offset= -67.			;20Oct-WD132 G102
        'icwg01gfq': offset= -74.			;20Oct-WD132 G102
        'icwg02xvq': offset=  66.			;20Oct-WD234 G102stis+2
        'icwg02xwq': offset=  70.			;20Oct-WD234 G102stis+3
; 16249 Tremblay:
        'iebo3aanq': offset= -18.			;21Aug-WD014 G102
        'iebo3aaoq': offset= -16.			;21Aug-WD014 G102
        'iebo3aapq': offset= -13.			;21Aug-WD014 G102
        'iebocahfq': offset= -31.			;21Aug-WD110 G102
        'iebocahgq': offset= -30.			;21Aug-WD110 G102
        'iebocahhq': offset= -30.			;21Aug-WD110 G102
        'iebo6ab2q': offset= -54.			;21Aug-WD120 G102
        'iebo6ab3q': offset=  17.			;21Aug-WD120 G102
        'iebo2au7q': offset= -13.			;21Aug-WD191 G102
        'iebo2au9q': offset= -18.			;21Aug-WD191 G102
        'iebodaknq': offset= -39.			;21Aug-WD203 G102
        'iebodakoq': offset= -32.			;21Aug-WD203 G102
        'iebodakpq': offset= -28.			;21sep-WD203 "  29unstbl
        'ieboeae1q': offset= -26.			;21Aug-WD211 G102
        'iebozaqhq': offset=  17.			;22Sep-WD211 G102
        'iebozaqiq': offset=  15.			;22Sep-WD211 G102
        'iebozaqjq': offset=  16.			;22Sep-WD211 G102
        'iebo8ah8q': offset=  12.			;21Aug-WD212 G102
        'iebo4afcq': offset= -14.			;21Aug-WD214 G102
        'iebo4afdq': offset= -14.			;21Aug-WD214 G102
        'iebo4afeq': offset= -13.			;21Aug-WD214 G102
        'ieboz9mgq': offset= -20.			;21Sep-WD191+145 G102
	'ieboz9mhq': offset= -16.			;21Sep-WD191+145 G102
        'ieboz9miq': offset= -20.			;21Sep-WD191+145 G102
        '': offset= -20.			;21Sep-WD191+145 G102
; 16702 Appleton
;noise        'iepb01luq': offset=  15.			;22Sep-WDJ040 G102
        'iepb01moq': offset=  23.			;22Sep-WDJ040 G102
        'iepb01mpq': offset= -24.			;22Sep-WDJ040 G102
        'iepb05o8q': offset= -15.		      ;22Sep-WDJ042 G102plt16702
;noise        'iepb02beq': offset=  25.			;22Sep-WDJ18 G102
        'iepb04aqq': offset= -12.			;22Sep-WDJ174 G102 mrg
        'iepb04asq': offset= -12.			;22Sep-WDJ174 G102 mrg
        'iepb09evq': offset= -10.			;22Sep-WDJ175 G102 mrg
        'iepb10hgq': offset= -10.			;22Sep-WDJ175 G102 mrg
	'iepb02beq': offset= -7.			;22Sep-WDJ181 G102 mrg
	'iepb02boq': offset= -7.			;22Sep-WDJ181 G102 mrg
	'iepb02bqq': offset= -7.			;22Sep-WDJ181 G102 mrg


; G141  below
;??? cannot arb. change WL of pts of prime WDs, as the sens will be screwy!:
        'ibwl84hwq': offset=  12.			;20Oct-G191B G141
        'ibwl84i0q': offset=  10.			;20Oct-G191B G141
        'ic6901x2q': offset= -15.			;20Oct-G191B G141 mrg-15
        'ic6901x5q': offset= -24.			;20Oct-G191B G141 mrg-15
        'ichg01dwq': offset=  10.			;20Oct-G191B G141
        'iab9a4muq': offset= -32.			;20Oct-GD153 G141
        'ibwq1bl3q': offset= -12.			;20Oct-GD153 G141
        'ibwq1bl6q': offset= -30.			;20Oct-GD153 G141
        'ibwq1blaq': offset= -38.			;20Oct-GD153 G141
        'ibwq1bldq': offset= -35.			;20Oct-GD153 G141
        'ibwq1blhq': offset= -12.			;20Oct-GD153 G141
        'ibwq1bm2q': offset=  10.			;20Oct-GD153 G141
        'ich401hwq': offset=  12.			;20Oct-GD153 G141
        'ich402b4q': offset= -48.			;22sep-GD153 G141
        'ich402b5q': offset= -47.			;22sep-GD153 G141
        'ich402b6q': offset= -47.			;22sep-GD153 G141
        'ich402b7q': offset= -47.			;22sep-GD153 G141
        'ich402bbq': offset= -35.			;22sep-GD153 G141
        'ich402bcq': offset= -42.			;22sep-GD153 G141
        'ich402bfq': offset= -47.			;22sep-GD153 G141
        'ich402bhq': offset= -47.			;22sep-GD153 G141
        'id2q02p1q': offset= -31.			;20Oct-GD153 G141
        'id2q02peq': offset= -32.			;20Oct-GD153 G141
        'id2q02qgq': offset= -27.			;20Oct-GD153 G141
        'id2q02qoq': offset= -24.			;20Oct-GD153 G141
        'id2q02qsq': offset= -27.			;20Oct-GD153 G141
        'idco02pkq': offset= -31.			;20Oct-GD153 G141
        'idco02poq': offset= -31.			;20Oct-GD153 G141
        'idco02prq': offset=  14.			;20Oct-GD153 G141
        'idco02pyq': offset= -35.			;20Oct-GD153 G141
        'idco02q5q': offset= -29.			;20Oct-GD153 G141
        'idco02q9q': offset= -34.			;20Oct-GD153 G141

        'ibbt02ayq': offset= -10.			;20Oct-GD71 G141
; match GD71 to gd153.g141-ich401 at short WL cutoff?
        'ibbt02b7q': offset= -29.		        ;20Oct-GD71 G141 mrg+20
        'ibbt02bkq': offset= -36.			;20Oct-GD71 G141
        'ibbt02byq': offset= -19.			;20Oct-GD71 G141 mrg+10
        'ibbt04gfq': offset= -27.			;20Oct-GD71 G141 mrg+10
        'ibbt04hiq': offset= -41.			;20Oct-GD71 G141
        'ibbt04hqq': offset= -28.			;20Oct-GD71 G141
        'ibbt04hwq': offset= -16.			;20Oct-GD71 G141
;        'ibll14ttq': offset= -17.			;20Oct-GD71 G141 mrg+17
        'iblf02c7q': offset= -24.			;20Oct-GD71 G141 mrg+10
        'iblf02ciq': offset= -41.			;20Oct-GD71 G141
        'iblf02csq': offset= -28.			;20Oct-GD71 G141
        'iblf02cwq': offset= -12.			;20Oct-GD71 G141
        'iblf02d4q': offset= -36.			;20Oct-GD71 G141
; 2020Oct20 - G141 icqw02 are contam past ~16600A
	'icqw02haq': offset=-108.		        ;20Oct-GD71 G141 mrg+10
	'icqw02heq': offset=-123.		       ;20Oct-GD71 G141
	'icqw02i2q': offset=-138.		        ;20Oct-GD71 G141
	'icqw02i5q': offset=-141.		        ;20Oct-GD71 G141
	'icqw02i9q': offset=-138.		        ;20Oct-GD71 G141
	'icqw02icq': offset=-129.		        ;20Oct-GD71 G141 mrg+10
	'icqw02igq': offset=-129.		        ;20Oct-GD71 G141 mrg+10
	'icqw02ijq': offset= -20.		        ;20Oct-GD71 G141
	'icqw02inq': offset= -36.		        ;20Oct-GD71 G141
	'icqw02iqq': offset= -17.			;20Oct-GD71 G141 mrg+10
	'iegi02qsq': offset= -23.			;21Jan-GD71 G141
        'iele02lfq': offset= -21.			;22Sep-GD71 G141
	
        'ibwl81xfq': offset=  17.			;22sep-17571 G141
        'ibwl81xgq': offset=  14.			;20Oct-17571 G141 mrg-10
        'ibwl81xhq': offset=  12.			;20Oct-17571 G141 eye-10
        'ibwl81xkq': offset=  13.			;20Oct-17571 G141 eye-10
        'ibwl81xlq': offset=   9.			;20Oct-17571 G141 mrg-10
        'ibwl81xmq': offset=   7.			;20Oct-17571 G141 mrg-10
        'ibwl81xnq': offset=   6.			;20Oct-17571 G141 mrg-10
        'ibwl81xoq': offset=   7.			;20Oct-17571 G141 mrg-10

;        'id2i02dvq': offset=  +5.			;20Oct-18022 G141 mrg
;        'id2i02e4q': offset=  11.			;20Oct-18022 G141 mrg
        'id2i02e6q': offset=  -10.			;20Oct-18022 G141 mrg

        'ibwl82ohq': offset=  13.			;20Oct-18083 G141
        'ibwl82oiq': offset=  10.                       ;20Oct-18083 G141
; merge or mrg means mrgall match at the G102-141 overlap for kf*,2m*,p330e,etc
        'icsf23agq': offset= +15.		        ;20Oct-2m003618 G141 mrg
        'icsf23amq': offset= +15.		        ;20Oct-2m003618 G141 mrg
        'icsf02j7q': offset= 30.			;20Oct-2M055 G141 eye
        'icsf02jhq': offset= 30.			;20Oct-2M055 G141 eye

	'ibwl88a4q': offset=  31.			;20Oct-BD60D G141 mrg-10
        'ibwl88a5q': offset=  35.			;20Oct-BD60D G141 mrg-10
        'ibwl88a6q': offset=  36.			;20Oct-BD60D G141 mrg-10
        'ibwl88a7q': offset=  31.			;20Oct-BD60D G141 mrg-10
        'ibwl88a8q': offset=  29.			;20Oct-BD60D G141 mrg-10 eye
        'ibwl88a9q': offset=  29.			;20Oct-BD60D G141 mrg-10
        'ibwl88aaq': offset=  33.			;20Oct-BD60D G141 mrg-10
        'ibwl88abq': offset=  38.			;20Oct-BD60D G141 mrg-10
; C26202-2018oct28-try Paschen beta 12821. Good, but -5A to MATCH model @ 10880A
        'ibhj10vfq': offset= -32.			;20Oct-C2620 G141 MATCH
        'ibhj10vmq': offset= -30.			;20Oct-C2620 G141 MATCH
        'ibhj10vtq': offset= -22.			;20Oct-C2620 G141
        'ibhj10w0q': offset= -25.			;20Oct-C2620 G141

;       'ibll12wlq': offset=  10.                       ;20Oct-GRW_7 G141 mrg
;       'ibll32hfq': offset=  12.                       ;20Oct-GRW_7 G141 mrg
;	'ibll42v1q': offset=  14.                       ;20Oct-GRW_7 G141 mrg
;	'ibll62nkq': offset=  12.                       ;20Oct-GRW_7 G141 mrg
;       'ibll72noq': offset=  13.                       ;20Oct-GRW_7 G141 mrg
;       'ibll82ouq': offset=  15.                       ;20Oct-GRW_7 G141 mrg
        'ibll92fpq': offset=  12.                       ;20Oct-GRW_7 G141
        'iblla2x6q': offset=  8.			;20Oct-GRW_7 G141 mrg-10
        'ibuc02qgq': offset=  11.			;20Oct-GRW_7 G141
        'ibuc12isq': offset=  16.			;20Oct-GRW_7 G141
        'ibuc15acq': offset=   8.			;20Oct-GRW_7 G141 mrg-10
;        'ibuc22h6q': offset=  11.			;20Oct-GRW_7 G141 mrg-11
;        'ibuc25eeq': offset=  14.			;20Oct-GRW_7 G141 mrg-14
        'ibuc54skq': offset=  15.			;20Oct-GRW_7 G141
;        'ibuc42lsq': offset=   9.			;20Oct-GRW_7 G141 mrg-9
        'ic5z03grq': offset=  15.			;20Oct-GRW_7 G141
        'ic5z05ilq': offset=  13.			;20Oct-GRW_7 G141
;        'ic5z06dqq': offset=   9.			;20Oct-GRW_7 G141 mrg-9
;        'ic5z07doq': offset=  11.			;20Oct-GRW_7 G141 mrg-11
        'ic5z09hjq': offset=  10.			;20Oct-GRW_7 G141
        'ic5z10ofq': offset=  16.			;20Oct-GRW_7 G141
; ic5z11m8q 15 wavoff shift worse than 0
        'ich316lpq': offset=  12.			;20Oct-GRW_7 G141 mrg-10
	'iegi03vwq': offset= +13.			;21Jan-Grw G141
        'iele03g9q': offset=  20.			;22Sep-GRW_7 G141

	'ibwi07mnq': offset= +17.			;18Jul-kf06t2 G141mrg+17
	'ibwi07mwq': offset= +17.			;18Jul-kf06t2 G141mrg+17
	'ibtwb4bdq': offset= +15.			;18Jul-p330e G141 mrg
	'ibtwb4bgq': offset= +15.			;18Jul-p330e G141 mrg
	'ibtwb4bjq': offset= +15.			;18Jul-p330e G141 mrg
	'ibtwb4bmq': offset= +15.			;18Jul-p330e G141 mrg
	'ibtwb4bpq': offset= +15.			;18Jul-p330e G141 mrg
	'ibwi05szq': offset= +10.		        ;18Jul-snap2 G141 mrg
	'ibwi05t9q': offset= +10.		        ;18Jul-snap2 G141 mrg
	'icrw12l9q': offset= +22.		        ;18Jul-vb8 G141 mrg
	'icrw12laq': offset= +22.		        ;18Jul-vb8 G141 mrg
        'icwg01gcq': offset=  10.                       ;20Oct-wd1327 G141mrg-10
        'ibwi08mkq': offset=  10.                       ;20Oct-wd1657 G141
;        'icwg02xtq': offset=  12.			;20Oct-WD234 G141 mrg
        'icwg02xuq': offset=  11.			;20Oct-WD234 G141 mrg-10
; 16249 Tremblay:
        'iebo3aaqq': offset=  19.			;21Aug-WD014 G141
        'iebo3aasq': offset=  18.			;21Aug-WD014 G141
        'iebo6ab5q': offset=  19.			;21Aug-WD120 G141
        'iebo6ab6q': offset=  21.			;21Aug-WD120 G141
        'iebo6ab7q': offset=  16.			;21Aug-WD120 G141
        'iebodakqq': offset=  14.			;21Aug-WD203 G141 unstbl
        'iebodakyq': offset=  13.			;21Aug-WD203 G141 unstbl
        'iebo8ahdq': offset=  18.			;21Aug-WD212 G141
        'iebobafqq': offset=  20.			;22Sep-WD080 G141
        'iebobafrq': offset=  20.			;22Sep-WD080 G141
        'iebo1arcq': offset=  18.			;22Sep-WD110 G141
        'iebo1ardq': offset=  23.			;22Sep-WD110 G141
        'iebo1areq': offset=  15.			;22Sep-WD110 G141
        'iebox5abq': offset=  13.			;22Sep-WD154 G141
        'iebox5acq': offset=  12.			;22Sep-WD154 G141
        'iebox5adq': offset=  10.			;22Sep-WD154 G141 eye
; 16702 Appleton
;noise        'iepb05o4q': offset=-182.			;22Sep-WDJ042 G141
;noise        'iepb05o6q': offset=-156.			;22Sep-WDJ042 G141
        'iepb04anq': offset=  20.			;22Sep-WDJ174 G141
        'iepb02brq': offset=  34.			;22Sep-WDJ18 G141
; set wmerge=11135  'iepb01lrq': offset=-25.		;22Sep-WDJ040 G141 mrg
; NG for shape	'iepb01meq': offset=-25.		;22Sep-WDJ040 G141 mrg
;& tiny flx dif	'iepb01mfq': offset=-25.		;22Sep-WDJ040 G141 mrg
; no	'iepb05o4q': offset=25.			        ;22Sep-WDJ042 G141 mrg
; help	'iepb05o6q': offset=25.				;22Sep-WDJ042 G141 mrg
        'iepb09exq': offset=-15.			;22Sep-WDJ175 G141 mrg
        'iepb10heq': offset=  21.			;22Sep-WDJ175 G141
	else: begin   &  endelse  &  endcase

; do 8 Gaia obs using the merged spectra. (wavoff gives nonsense)
; G141: line up w/ G102 at ~11000A feature by eye or just matching the 11300A
;		cont flux, & elim any 1700A bump using mrgall.pro & iterating

if targ eq 'GAIA405_1056G102' then begin	
      offset=-22.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA405_1056G141' then begin
      offset=-40.				; 2021may mrgall 11000A by eye
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif
if targ eq 'GAIA405_6912G102' then begin	
      offset=-13.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA405_6912G141' then begin
      offset=-40.				; 2021may mrgall 11000A by eye
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif

if targ eq 'GAIA587_3008G102' then begin	
      offset=-10.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA587_3008G141' then begin
      offset=-40.				; -25 shows ~6% hi
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif
if targ eq 'GAIA587_7024G102' then begin
      offset=-20.				; stiscf.pro 2020Oct20
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA587_7024G141' then begin
      offset=-40.				; 2021may was -35
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif

if targ eq 'GAIA587_0224G102' then begin	
      offset=-20.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA587_0224G141' then begin
      offset=-40.				; 2021may mrgall 11000A by eye
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif
if targ eq 'GAIA587_8560G102' then begin
      offset=-16.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA587_8560G141' then begin
      offset=-38.				; 2021may mrgall
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif

if targ eq 'GAIA588_7632G102' then begin
      offset=-25.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA588_7632G141' then begin
      offset=-35.				; 2021may mrgall
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif
if targ eq 'GAIA588_7712G102' then begin
      offset=-30.				; stiscf.pro 2021may19
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G102 '+targ
      endif
if targ eq 'GAIA588_7712G141' then begin
      offset=-82.				; 2021may mrgall
      if not keyword_set(silent) then print,string(offset,'(i3)')+	$
      						'A added to all G141 '+targ
      endif

; 2020Oct13 - Updated above.
;;if targ eq 'GD71G141' then begin				; 2020oct7
;;	offset=offset+2.
;;	if not keyword_set(silent) then print,'2A added to all G141 '+targ
;;	endif
; 169 67.3s G141 obs of 2m055914, where prewfc shows all sim shifts:
; 2m055914 is one of ~7 cool stars where G141 is skipped in wavoff.pro
if strmid(root,0,6) eq 'ica701' then offset=-30         ;18jul 2m055914 G141 mrg
if abs(offset) ne 0 and not keyword_set(silent) then 			$
	print,'WFCWLFIX returned a WL offset=',offset,' Angstr'
return,offset
end
