function starvel,starin
;+
;
; Name:  starvel
; PURPOSE:
;	return the stellar radial velocity, if any. Otherwise return zero.
; CALLING SEQUNCE:
;	radial_vel=starvel('G191b2b')
; Inputs:
;	star name
; OUTPUT:
;	The radial velocity in km/s. Positive vel means star is going away.
; HISTORY
;	97dec8 - rcb
;	02may9 - wd320-539 new, gd71 changed from 80(stis guess) to 30
;	02sep23- lds749b from Simbad
;	08dec4 - generalize so that only 1st 6 char need to match, to be able to
;		use file names for star (eg in modcf). Also do not mod star case
;	2012sep6 - add Bessel/Schmidt stars (See 12813.targets):
;	12dec11-Dixon et al. 2007 has the ff WITHOUT ref: GD71:+80, 
;			GD153:+50, HZ43:+20.6, G191:none km/s
;		HOWEVER, the FUSE data handbook (2009) section 7 has diff values
;		found from the lit. or FUSE spectra GD71:+30, GD153:+20, 
;		HZ43:+20.6, G191:+26
;	18jul20-update as comments the 3 primaries per Simbad
;	19jan15 - See Villanova McCook & Sion for compilation of V-radial
; Falcon2010=Falcon et al. 2010, ApJ, 712, 585
; star=starin is targname in header & as in the *log files.
;-
starvel=0.
star=strupcase(strtrim(starin,2))		; 08dec4-change to starin
;	if strpos(star,'G191') eq 0 then starvel=22.	;1988,apj,335,953
	if strpos(star,'G191') eq 0 then starvel=22.1 ;Holberg 1994,apj,425,L105
; 18jul	if strpos(star,'G191') eq 0 then starvel=69	;Simbad D qual, no err.
; drop gd153 50km/s, which makes balmer lines discrep. L-alpha is better too but
;	now disagrees w/ GD71???? See wlerr.*grat*-wd-after - fixed w/ wl shifts
; 03may2		'GD153'     : starvel=50	; crude STIS measure
; 18jul			'GD153'     : starvel=67	; Simbad D qual, no err.
;	if strpos(star,'GD71') eq 0 then starvel=30.	;Maxted-00,mnras,319,305
; G191=WD0501+527 not in Falcon:
	if strpos(star,'GD71') eq 0 then starvel=23.4	;Falcon2010 2019jan15
	if strpos(star,'GD153') eq 0 then starvel=25.8	;Falcon2010
; 18jul	if strpos(star,'GD71') eq 0 then starvel=12.	;Simbad D qual, =/-3.4
      if strpos(star,'LDS749B') eq 0 then starvel=-81. ;greenstein67,apj,149,283
	if strpos(star,'HD165459') eq 0 then starvel=-19.2 ; 1999 A&AS,137,451G
; MgII ISM minus stellar in O4DD05050.ECH-NOVEL by keyes and bohlin(unpub) +-10
	if strpos(star,'BD+75') eq 0 or strpos(star,'BD75') eq 0 	$
							then starvel=-50.
;			'BD+75D325' : starvel=-19.	;+-11,1957PASP...69..242
;Pierre Dubath, Georges Meylan, and Michel Mayer 1997, A&A, 324, 505:
	if strpos(star,'NGC6681') eq 0 then starvel=223.4

; update Simbad values 2019jan14:
	if strpos(star,'10LAC') eq 0 then starvel=-9.7
	if strpos(star,'2M0036') eq 0 then starvel=+19.		;2019jan
	if strpos(star,'HD1721') eq 0 then starvel=-21.		;2019jan vega
	if strpos(star,'BD02D3') eq 0 then starvel=-398.
	if strpos(star,'BD17D4') eq 0 then starvel=-291.
	if strpos(star,'BD21D0') eq 0 then starvel=+340.
	if strpos(star,'BD26D2') eq 0 then starvel=+33.
	if strpos(star,'BD29D2') eq 0 then starvel=+83.
	if strpos(star,'BD33D2') eq 0 then starvel=-95.		;2019jan
	if strpos(star,'BD54D1') eq 0 then starvel=+66.
	if strpos(star,'G93-48') eq 0 then starvel=+32.		;2019jan
	if strpos(star,'GD108') eq 0 then starvel=+90.		;2019jan
	if strpos(star,'GD50') eq 0 then starvel=+87.		;2019jan
;	if strpos(star,'GJ7541') eq 0 then starvel= Not in Simbad
	if strpos(star,'GRW+70') eq 0 then starvel=+26.		;2019jan
	if strpos(star,'HD0090') eq 0 then starvel=-72.
	if strpos(star,'HD0311') eq 0 then starvel=+112.
	if strpos(star,'HD0740') eq 0 then starvel=+206.
	if strpos(star,'HD1062') eq 0 then starvel=+16.		;2019jan
	if strpos(star,'HD1119') eq 0 then starvel=+155.
	if strpos(star,'HD1164') eq 0 then starvel=-19. 	 ;2019jan
	if strpos(star,'HD1494') eq 0 then starvel=+5. 	 ;2019jan
	if strpos(star,'HD1584') eq 0 then starvel=-30. 	 ;2019jan
	if strpos(star,'HD1592') eq 0 then starvel=-52. 	 ;2019jan
	if strpos(star,'HD1606') eq 0 then starvel=+100.
	if strpos(star,'HD1634') eq 0 then starvel=-16. 	 ;2019jan
	if strpos(star,'HD1859') eq 0 then starvel=-19.
	if strpos(star,'HD2006') eq 0 then starvel=-45.
	if strpos(star,'HD2059') eq 0 then starvel=-17. 	 ;2019jan
	if strpos(star,'HD2094') eq 0 then starvel=-15. 	 ;2019jan
	if strpos(star,'HD60753') eq 0 then starvel=+20
	if strpos(star,'ETAUMA') eq 0 then starvel=-13.4	;2019jan
	if strpos(star,'HD93521') eq 0 then starvel=-14.1	;2019jan
	if strpos(star,'109VIR') eq 0 then starvel=-6.1		;2019Aug
	if strpos(star,'16CYGB') eq 0 then starvel=-27.7	;2019Aug
	if strpos(star,'18SCO') eq 0 then starvel=+11.9	  	;2019Aug
	if strpos(star,'DELUMI') eq 0 then starvel=-7.6	  	;2019Aug
	if strpos(star,'ETA1DOR') eq 0 then starvel=+17.6	;2019Aug
;	if strpos(star,'HD101452') eq 0 not in Simbad	  	;2019Aug
	if strpos(star,'HD115169') eq 0 then starvel=+21.2	;2019Aug
	if strpos(star,'HD128998') eq 0 then starvel=-3.0	;2019Aug
	if strpos(star,'HD142331') eq 0 then starvel=-70.8	;2019Aug
	if strpos(star,'HD167060') eq 0 then starvel=+15.2	;2019Aug
;	if strpos(star,'HD2811') eq 0 not in Simbad		;2019Aug
	if strpos(star,'HD55677') eq 0 then starvel=-2		;2019Aug


;	if star eq 'HZ2' then starvel=+64.			;2019jan
	if star eq 'HZ2' then starvel=+41.2			;Falcon 2019jan
;	if star eq 'HZ4' then starvel=+46.			;2019jan
	if star eq 'HZ4' then starvel=+72.1			;Falcon 2019jan
	if star eq 'HZ43' then starvel=+54.			;2019jan
	if star eq 'KF01T5' then starvel=-22.			;2019jan
	if star eq 'KF06T1' then starvel=-41.			;2019jan
	if star eq 'KF08T3' then starvel=-50.			;2019jan
	if strpos(star,'KSI2CET') eq 0 then starvel=+12
	if strpos(star,'LAMLEP') eq 0 then starvel=+20.2
	if strpos(star,'MUCOL') eq 0 then starvel=109.2
	if star eq 'NGC7293' then starvel=-15.			;2019jan
	if star eq 'P041C' then starvel=-22.		  	;2019jan
	if star eq 'P330E' then starvel=-53.		 	;2019jan
	if strpos(star,'SIRIUS') eq 0 then starvel=-6
	if strpos(star,'VB8') eq 0 then starvel=15.39		; 2013Sep6
	if strpos(star,'WD-0308') eq 0 then starvel=-68	;simbad
;	if strpos(star,'WD0320') eq 0 then starvel=+57.8;Maxted-00,mnras,319,305
	if strpos(star,'WD0320') eq 0 then starvel=+49.9	;falcon 2019jan
	if strpos(star,'WD1057') eq 0 then starvel=+76.	; Jay-1997, ApJ,484,871
	if strpos(star,'WD1327') eq 0 then starvel=+36. 	;2019jan
	if strpos(star,'WD2341') eq 0 then starvel=-16. 	;2019jan

; 2014Dec - Massa Stars from massa13760.targ. Do not bother w/ vel<10
	if strpos(star,'HD282485') eq 0 then starvel=12.1	;# 103 (0d)
	if strpos(star,'HD303068') eq 0 then starvel=46.57	;# 104 (0e)
	if strpos(star,'HD104705') eq 0 then starvel=-17.	;# 113 (0n)
	if strpos(star,'CPD-59D2625') eq 0 then starvel=-23.2	;# 114 (0o)
	if strpos(star,'HD91983') eq 0 then starvel=57.		;# 116 (0q)
	if strpos(star,'HD62542') eq 0 then starvel=18.		;# 04
	if strpos(star,'HD73882') eq 0 then starvel=21.		;# 05
	if strpos(star,'HD204827') eq 0 then starvel=20.	;# 11
	if strpos(star,'HD210072') eq 0 then starvel=-29.	;# 12
	if strpos(star,'HD92044') eq 0 then starvel=-12.	;# 15
	if strpos(star,'HD110946') eq 0 then starvel=-73.	;# 19
	if strpos(star,'AZV23') eq 0 then starvel=177.8		;# 130 (1e)
	if strpos(star,'2DFS3030') eq 0 then starvel=248.	;# 133 (1h)
	if strpos(star,'2DFS0699') eq 0 then starvel=158.	;# 133 (1k)
	if strpos(star,'AZV456') eq 0 then starvel=167.		;# 150 (1y)
	if strpos(star,'HD236960') eq 0 then starvel=-45.	;# 25
	if strpos(star,'HD281159') eq 0 then starvel=8.5	;# 26
	if strpos(star,'BD+44D1080') eq 0 then starvel=32.	;# 29
	if strpos(star,'HD46106') eq 0 then starvel=21.5	;# 38
	if strpos(star,'CPD-57D3523') eq 0 then starvel=-23.	;# 45
	if strpos(star,'HD30675') eq 0 then starvel=20.		;# 93
	if strpos(star,'HD30122') eq 0 then starvel=23.2	;# 97
	if strpos(star,'HD28475') eq 0 then starvel=22.1	;# 99
	if strpos(star,'HD210072') eq 0 then starvel=-29.	;# 12
	if strpos(star,'HD46660') eq 0 then starvel=+24.	;# 32
	if strpos(star,'CPD-57D3523') eq 0 then starvel=-23.	;# 45
	if strpos(star,'HD27778') eq 0 then starvel=7.2		;# 70
	if strpos(star,'HD30675') eq 0 then starvel=+20.	;# 93
	if strpos(star,'HD228969') eq 0 then starvel=+30.3	;# 94
	if strpos(star,'HD99872') eq 0 then starvel=+12.	;# 96
	if strpos(star,'HD30122') eq 0 then starvel=+23.2	;# 97
	if strpos(star,'HD28475') eq 0 then starvel=+22.1	;# 99
	if strpos(star,'HD13338') eq 0 then starvel=-42.	;# 74

print,'STARVEL returned a stellar radial vel: ',star,starvel
return,starvel
end
