function wfcwlfix,root,targ
;+
;
; Name:  wfcwlfix
; PURPOSE:
;	Return the correction in Angstroms to be *added to* the wavelengths
;			
; CALLING SEQUNCE:
;	offset=wfcwlfix(root)
; Inputs:
;	root - observation rootname
;	targ - target name (optional), as not added to AXE calls in
;		CALWFC_SPEC_WAVE (which is in CALWFC_SPEC.pro)
;	The wavelength correction in Ang. A vector for [G102,G141]
;	(Disp is Ang/px=24.5, 46.5, respectively.)
; HISTORY
;	2018may14-First use for ic6903
;	paschen gamma,beta=10941.1, 12821.6 (10938.1, 12818.1-air)
; 8752.86 8865.32 9017.8 9232.2 9548.8 10052.6 10941.082 12821.578 18756.4 vac
;	2020feb4 - add targ to param for 15816 w/ 2 targ/image. 
;-
offset=0.
case root of
        'ibcf51ibq': offset=   6.			;18Jul-G191B G102
        'ic6903y4q': offset= -18.			;18Jun-G191B G102
        'ic6903y5q': offset= -13.			;18Jun-G191B G102
        'iab901emq': offset=   8.			;18Jul-GD153 G102
        'iab901esq': offset=  -6.			;18Jul-GD153 G102
        'ibwq1asgq': offset=  -6.			;18Jul-GD153 G102
        'ibwq1aswq': offset=  -5.			;18Jul-GD153 G102
        'ibwq1aszq': offset=  -6.			;18Jul-GD153 G102
        'ibwq1at2q': offset= -11.			;18Jun-GD153 G102
        'ibwq1at9q': offset= -12.			;18Jun-GD153 G102
        'ibwq1atmq': offset=  -5.			;18Jul-GD153 G102
        'ich402avq': offset=   5.			;18Jul-GD153 G102
        'ich402awq': offset=   6.			;18Jul-GD153 G102
        'ich402azq': offset=  -6.			;18Jul-GD153 G102
        'ich402b0q': offset=  -6.			;18Jul-GD153 G102
        'idco01rzq': offset=  -5.			;18Jul-GD153 G102
        'idpo02p2q': offset=  -6.			;18Jul-GD153 G102
        'idpo02p8q': offset=  -6.			;18Jul-GD153 G102
        'ibbt01p1q': offset=  -6.			;18Jul-GD71 G102
        'ibbt01p2q': offset=  -9.			;18Jul-GD71 G102
        'ibbt01peq': offset=  -6.			;18Jul-GD71 G102
        'ibbt01plq': offset=  -7.			;18Jul-GD71 G102
        'ibbt01p8q': offset= -15.			;18Jun-GD71 G102
        'ibbt03efq': offset=  -6.			;18Jul-GD71 G102
        'ibbt03ehq': offset=  -7.			;18Jul-GD71 G102
        'ibbt03emq': offset=  -7.			;18Jul-GD71 G102
        'ibbt03epq': offset=  -7.			;18Jul-GD71 G102
        'ibbt03esq': offset=  -7.			;18Jul-GD71 G102
        'ibbt03f6q': offset=  -9.			;18Jul-GD71 G102
        'ibll14tgq': offset=  -6.			;18Jul-GD71 G102
        'ibll14thq': offset= -10.			;18Jun-GD71 G102
        'ibll14tiq': offset=  -6.			;18Jul-GD71 G102
        'ibll14tkq': offset=  -7.			;18Jul-GD71 G102
        'iblf01ckq': offset=  -6.			;18Jul-GD71 G102
        'iblf01d9q': offset=  -5.			;18Jul-GD71 G102
        'icqw01z1q': offset= -18.			;18Jun-GD71 G102
        'icqw01zjq': offset= -84.			;18Jun-GD71 G102
        'icqw01zrq': offset= -85.			;18Jun-GD71 G102
        'icqw01zvq': offset= -86.			;18Jun-GD71 G102
        'icqw01zyq': offset= -86.			;18Jun-GD71 G102
        'icqw01auq': offset= -87.			;18Jun-GD71 G102
        'icqw01ayq': offset= -90.			;18Jun-GD71 G102
        'icqw01b1q': offset= -91.			;18Jun-GD71 G102
        'icqw01b5q': offset= -19.			;18Jun-GD71 G102
        'icqw01b9q': offset= -19.			;18Jun-GD71 G102
        'icqw01bcq': offset= -17.			;18Jun-GD71 G102
        'ibwl81x1q': offset= -4.6			;18Jul-17571 G102 merge
        'ibwl81x8q': offset= -5.8			;18Jul-17571 G102 merge
        'id2i01egq': offset= -21.			;18Jul-18022 G102
        'id2i01ehq': offset= -16.			;18Jul-18022 G102
        'id2i01ejq': offset= -16.			;18Jul-18022 G102
        'id2i01emq': offset= -18.			;18Jul-18022 G102
        'id2i01eoq': offset= -23.			;18Jul-18022 G102
        'id2i01erq': offset= -15.			;18Jul-18022 G102
        'ibwl82o8q': offset= -6.0			;18Jul-18083 G102 merge
        'ibwl82o9q': offset= -2.2			;18Jul-18083 G102 merge
        'ibwl82obq': offset= -12.6			;18Jul-18083 G102 merge
        'ibwl82oeq': offset= -4.1			;18Jul-18083 G102 merge
        'ibwl82ofq': offset= -7.			;18Jul-18083 G102

        'icsf23bbq': offset=  12.			;18Jul-2M003 G102
        'icsf02j4q': offset=  13.			;18Jul-2M055 G102
        'icsf02j9q': offset=  14.			;18Jul-2M055 G102
        'ibwl88acq': offset=  32.			;18Jul-BD60D G102
        'ibwl88adq': offset=  32.			;18Jul-BD60D G102
        'ibwl88aeq': offset=  33.			;18Jul-BD60D G102
        'ibwl88afq': offset=  31.			;18Jul-BD60D G102
        'ibwl88agq': offset=  33.			;18Jul-BD60D G102
        'ibwl88ahq': offset=  36.			;18Jul-BD60D G102
        'ibwl88aiq': offset=  32.			;18Jul-BD60D G102
        'ibwl88ajq': offset=  32.			;18Jul-BD60D G102
;20jan-Gaia G102 Eye vs STIS
	'ie3f10c1qGAIA593_1968': offset=+15.
	'ie3f10c2qGAIA593_1968': offset=+15.
	'ie3f10c3qGAIA593_1968': offset=+15.
	'ie3f10c8qGAIA593_1968': offset=+15.
	'ie3f10c9qGAIA593_1968': offset=+15.
; G141: line up w/ G102 at ~11500A feature
	'ie3f10caqGAIA593_1968': offset=-50.
	'ie3f10cbqGAIA593_1968': offset=-50.
	'ie3f10ciqGAIA593_1968': offset=-50.
	'ie3f10cjqGAIA593_1968': offset=-50.
	'ie3f10ckqGAIA593_1968': offset=-50.
;20jan-Gaia G102 Eye vs kf06t2 Model at ~8600A Cr?
	'ie3f10c1qGAIA593_9680': offset=-1.
	'ie3f10c2qGAIA593_9680': offset=-1.
	'ie3f10c3qGAIA593_9680': offset=-1.
	'ie3f10c8qGAIA593_9680': offset=-1.
	'ie3f10c9qGAIA593_9680': offset=-1.
	
        'ibll92fqq': offset=   7.			;18Jul-GRW_7 G102
        'ic5z10ogq': offset=  10.			;18Jul-GRW_7 G102
        'ibwl89tnq': offset=  -8.			;18Oct-hd37725 G102 eye
        'ibwib6m8q': offset= -23.			;18Jul-P330E G102
        'ibwib6m9q': offset= -18.			;18Jul-P330E G102
        'ibwib6mbq': offset= -22.			;18Jul-P330E G102
        'ibwib6mdq': offset= -26.			;18Jul-P330E G102
        'ibwib6mfq': offset= -15.			;18Jul-P330E G102
        'ibwi05t1q': offset= -15.			;18Jul-snap2G102 stiscf
        'icrw12l8q': offset= -20.			;18Jul-VB8 G102
        'icwg01geq': offset= -65.			;18Jul-WD132 G102
        'icwg01gfq': offset= -70.			;18Jun-WD132 G102
        'icwg02xvq': offset=  69.			;18Jul-WD234 G102
        'icwg02xwq': offset=  69.			;18Jul-WD234 G102

        'ibwl84hwq': offset=  17.			;18Jul-G191B G141
        'ibwl84i0q': offset=  15.			;18Jul-G191B G141
        'ibwl84i3q': offset=  12.			;18Jul-G191B G141
;??? cannot arb. change WL of pts of prime WDs, as the sens will be screwy!:
        'ic6901wvq': offset= -20.			;18Jul-G191 G141 mrg
        'ic6901wwq': offset= -20.			;18Jul-G191 G141 mrg
        'ic6901x1q': offset= -20.			;18Jul-G191 G141 mrg
        'ic6901x2q': offset= -10.			;18Jul-G191 G141 mrg eye
        'ic6901x5q': offset= -20.			;18Jul-G191 G141 mrg eye
;actual        'ic6901x5q': offset=  -7.		;18Jul-G191 G141 mrg
        'ichg01dwq': offset=  17.			;18Jul-G191B G141
        'ichg01dyq': offset=  10.			;18Jul-G191B G141
        'ichg01dzq': offset=  12.			;18Jul-G191B G141

        'iab9a4muq': offset= -30.			;18Jun-GD153 G141
        'ibwq1bl3q': offset= -10.			;18Jul-GD153 G141
        'ibwq1bl6q': offset= -28.			;18Jun-GD153 G141
        'ibwq1blaq': offset= -36.			;18Jun-GD153 G141
        'ibwq1bldq': offset= -33.			;18Jun-GD153 G141
        'ibwq1blhq': offset= -10.			;18Jul-GD153 G141
        'ibwq1blvq': offset=  11.			;18Jul-GD153 G141
        'ibwq1bm2q': offset=  16.			;18Jul-GD153 G141
        'ibwq1bmcq': offset=  12.			;18Jul-GD153 G141
        'ic461ahdq': offset=  13.			;18Jul-GD153 G141
        'ic461aheq': offset=  11.			;18Jul-GD153 G141
        'ich401hwq': offset=  13.			;18Jul-GD153 G141
        'ich401i3q': offset=  12.			;18Jul-GD153 G141
        'ich402b4q': offset= -23.			;18Jun-GD153 G141
        'ich402b5q': offset= -23.			;18Jun-GD153 G141
        'ich402b6q': offset= -22.			;18Jun-GD153 G141
        'ich402b7q': offset= -23.			;18Jun-GD153 G141
        'ich402bbq': offset= -10.			;18Jul-GD153 G141
        'ich402bcq': offset= -16.			;18Jul-GD153 G141
        'ich402bfq': offset= -23.			;18Jun-GD153 G141
        'ich402bhq': offset= -23.			;18Jun-GD153 G141
        'id2q02p1q': offset= -29.			;18Jun-GD153 G141
        'id2q02peq': offset= -30.			;18Jun-GD153 G141
        'id2q02qgq': offset= -25.			;18Jun-GD153 G141
        'id2q02qoq': offset= -22.			;18Jun-GD153 G141
        'id2q02qsq': offset= -25.			;18Jun-GD153 G141
        'id2q02qvq': offset=  14.			;18Jul-GD153 G141
        'id2q02qzq': offset=  11.			;18Jul-GD153 G141
        'idco02pkq': offset= -29.			;18Jun-GD153 G141
        'idco02poq': offset= -29.			;18Jun-GD153 G141
        'idco02prq': offset=  19.			;18Jun-GD153 G141
        'idco02pyq': offset= -33.			;18Jun-GD153 G141
        'idco02q5q': offset= -27.			;18Jun-GD153 G141
        'idco02q9q': offset= -32.			;18Jun-GD153 G141

        'ibbt02b7q': offset= -47.			;18Jun-GD71 G141
        'ibbt02bkq': offset= -34.			;18Jun-GD71 G141
        'ibbt02byq': offset= -27.			;18Jun-GD71 G141
        'ibbt04gfq': offset= -35.			;18Jun-GD71 G141
        'ibbt04hiq': offset= -39.			;18Jun-GD71 G141
        'ibbt04hqq': offset= -27.			;18Jun-GD71 G141
        'ibbt04hwq': offset= -15.			;18Jul-GD71 G141
        'ibll14ttq': offset= -16.			;18Jul-GD71 G141
        'iblf02c7q': offset= -32.			;18Jun-GD71 G141
        'iblf02ceq': offset=  12.			;18Jul-GD71 G141
        'iblf02ciq': offset= -40.			;18Jun-GD71 G141
        'iblf02csq': offset= -26.			;18Jun-GD71 G141
        'iblf02cwq': offset= -11.			;18Jul-GD71 G141
        'iblf02d4q': offset= -34.			;18Jun-GD71 G141
        'icqw02haq': offset=-117.			;18Jun-GD71 G141
        'icqw02heq': offset=-123.			;18Jun-GD71 G141
        'icqw02i2q': offset=-137.			;18Jun-GD71 G141
        'icqw02i5q': offset=-140.			;18Jun-GD71 G141
        'icqw02i9q': offset=-138.			;18Jun-GD71 G141
        'icqw02icq': offset=-139.			;18Jun-GD71 G141
        'icqw02igq': offset=-139.			;18Jun-GD71 G141
        'icqw02ijq': offset= -19.			;18Jun-GD71 G141
        'icqw02inq': offset= -34.			;18Jun-GD71 G141
        'icqw02iqq': offset= -25.			;18Jun-GD71 G141
        'ibwl81xfq': offset=  21.			;18Jul-17571 G141mrg
        'ibwl81xkq': offset=  11.			;18Jul-17571 G141mrg
        'ibwl81xlq': offset=  29.			;18Jul-17571 G141mrg
        'ibwl81xmq': offset=  31.			;18Jul-17571 G141mrg
        'ibwl81xnq': offset=  20.			;18Jul-17571 G141mrg eye
        'id2i02dvq': offset=  6.                        ;18Jul-18022 G141 eye
        'id2i02dwq': offset= -15.			;18Jul-18022 G141
        'ibwl82ohq': offset=  11.			;18Jul-18083 G141 mrg
        'ibwl82oiq': offset=  5.                        ;18Jul-18083 G141 mrg
        'ibwl82ojq': offset=  10.                        ;18Jul-18083 G141 mrg
        'icsf23agq': offset= +30.		        ;18Jul-2m003618 G141 mrg
        'icsf23amq': offset= +30.		        ;18Jul-2m003618 G141 mrg
        'icsf02j7q': offset= 30.			;18Jul-2M055 G141 eye
        'icsf02jhq': offset= 30.			;18Jul-2M055 G141 eye
	'ibwl88a4q': offset=  42.			;18Jul-BD60D G141 mrg
        'ibwl88a5q': offset=  36.			;18Jul-BD60D G141
        'ibwl88a6q': offset=  30.			;18Jul-BD60D G141
        'ibwl88a7q': offset=  40.			;18Jul-BD60D G141
        'ibwl88a8q': offset=  46.			;18Jul-BD60D G141
        'ibwl88a9q': offset=  48.			;18Jul-BD60D G141 mrg
        'ibwl88aaq': offset=  39.			;18Jul-BD60D G141 eye
        'ibwl88abq': offset=  29.			;18Jul-BD60D G141
; C26202 - 2018oct23 noisy, but make ends @ 1.1,1.7mic match. 
;	Old mystery shifts were ~-22 and said mrg?
	'ibhj10vfq': offset= -10.			; 18oct-c26202 G141
	'ibhj10vmq': offset= -10.			; 18oct-c26202 G141
	'ibhj10vtq': offset= -10.			; 18oct-c26202 G141
	'ibhj10w0q': offset= -10.			; 18oct-c26202 G141

        'ibll42v1q': offset=   7.                       ;18Jul-GRW_7 G141
        'ibll92fpq': offset=  20.                       ;18Jul-GRW_7 G141 eye
        'iblla2x6q': offset=  10.		;18Jul-GRW_7 G141 0-tchang rms
        'ibuc05awq': offset=  10.			;18Jul-GRW_7 G141
        'ibuc12isq': offset=  24.			;18Jul-GRW_7 G141
        'ibuc15acq': offset=  10.	;18Jul-GRW_7 G141 eye, unstable X-correl
        'ibuc54skq': offset=  30.			;18Jul-GRW_7 G141 eye
        'ibuc42lsq': offset=  18.			;18Jul-GRW_7 G141
        'ic5z03grq': offset= -13.			;18Jul-GRW_7 G141
        'ic5z05ilq': offset=  22.			;18Jul-GRW_7 G141
        'ic5z06dqq': offset=  15.			;18Jul-GRW_7 G141
        'ic5z10ofq': offset=  31.                       ;18Jul-GRW_7 G141
        'ich316lpq': offset=  11.                       ;18Jul-GRW_7 G141

        'ibwi07mnq': offset= +30.                       ;18Jul-kf06t2 G141 mrg
        'ibwi07mwq': offset= +30.                       ;18Jul-kf06t2 G141 mrg
        'ibtwb4bdq': offset= +15.                       ;18Jul-p330e G141 mrg
        'ibtwb4bgq': offset= +15.                       ;18Jul-p330e G141 mrg
        'ibtwb4bjq': offset= +15.                       ;18Jul-p330e G141 mrg
        'ibtwb4bmq': offset= +15.                       ;18Jul-p330e G141 mrg
        'ibtwb4bpq': offset= +15.                       ;18Jul-p330e G141 mrg
        'ibwi05szq': offset= +20.		        ;18Jul-snap2 G141 mrg
        'ibwi05t9q': offset= +20.		        ;18Jul-snap2 G141 mrg
        'icrw12l9q': offset= +22.		        ;18Jul-vb8 G141 mrg
        'icrw12laq': offset= +22.		        ;18Jul-vb8 G141 mrg
        'icwg01gcq': offset=  15.                       ;18Jul-wd1327 G141
        'icwg01gdq': offset=  -8.                       ;18Jul-wd1327 G141
        'ibwi08mkq': offset=  16.                       ;18Jul-wd1657 G141
        'icwg02xtq': offset=  14.			;18Jul-WD234 G141 eye
        'icwg02xuq': offset=  13.			;18Jul-WD234 G141

	else: begin   &  endelse  &  endcase
; 169 67.3s G141 obs of 2m055914, where preproc shows all sim shifts:
if strmid(root,0,6) eq 'ica701' then offset=-30         ;18jul 2m055914 G141 mrg
if abs(offset) ne 0 then print,'WFCWLFIX returned a WL offset=',offset,	$
		' Angstr'
return,offset
end
