function nicwlfix,root
;+
;
; Name:  nicwlfix
; PURPOSE:
;	Return the correction in microns to be *added to* the wavelengths
;	enter don's px shifts as he has them in /nical/doc.new, originally. Or
;	now from wl.offsets*.
; **REMINDER** REMEMBER radial vel. if ever measuring WL shifts w/ lines instead
; 		of the normal nicmos fringe pattern.
;			
; CALLING SEQUNCE:
;	offset=nicwlfix(root)
; Inputs:
;	root - first 6 char of observation rootname OR starname, not beg w/ 'n'
; OUTPUT:
;	The wavelength correction in microns. A 3-d vector for [G096,G141,G206]
; HISTORY
;	04JUL23 - Written by r. bohlin
;	Initial values for offset are from DJL nical/doc.new of ~04jul30 and
;		are wrt G191B2B. The DJL pixels are converted via:
;		Ang/px=53.7,79.9,115.2 for 3 gratings-- old nicmoslook
;		      =55.2,80.2,113.5 - r. thompson 02nov. changed 04aug31
;	04aug12 - change to new shifts relative to orig. BD17
;	04nov22 - interactive absratio. shifts vs. orig bd17. Acc. is ~0.1px
;	05jan25 - .................. ........ for 4 new stars
;	05mar10 - .............................new GD71 & G191 wrt orig 71 & 191
;	05jul28 - .............................new GD153 & wd1653 wrt origs
;	06nov-try wloffset.pro-->NG??? try all interactive wrt orig bd+17-ng for
;		cool stars.
;	06dec7 - see results of wl.offsets: a) shifts are stable only @ ~0.1 px
;		level. b) 2m0559,g206 does not work, use zero shift. c) shifts 
;		are rarely above 0.3px. Does 0.3px shift really make a sig. dif?
;		Put in all new shifts per wl.offsets11-15 w/ glances at other 2
;		13-15 and 11-5
;	absratio,n(*,0)+.0007,n(*,3),o(*,0),o(*,3),4,0,0,.001,wr,rat
;	06dec8 - use wloffset.pro to find WL offsets. Discover sign err here
;		& fix. Previous years, i had some wrong corr. probably.
;	06dec18 - tweak GD153
;	08nov7 - update for new calnic-A
;	09may12 - update for new Disp constants.
;-
offset=fltarr(3)
if strlowcase(strmid(root,0,1)) eq 'n' then root=strlowcase(strmid(root,0,6))

case root of
; below: px to be converted to mic and *(-1)
	'n8br01': offset=[0.1,0.05,0.2]			; P330-E thompson
	'n8u406': offset=[0.15,0.15,0.10]		; P330E
	'n9u212': offset=[0.05,0.18,0.07]		; P330E 07feb
	'n8i8b1': offset=[0.5,0.1,0.0]			; hd209458 06dec
	'n8u401': offset=[0.04,-0.05]			; GD71 - 2004
	'n94a01': offset=[-.04,-.04]			; GD71 - 2005
	'n9u202': offset=[-.03,0.04,0.2]		; GD71   06nov
	'n9u205': offset=[-.15,-.11,-.18]		; GD71   07sep
	'na5302': offset=[-.17,-.27,-0.07]		; GD71
	'n8u402': offset=[-0.29,-0.26]			; GD153
	'n94a02': offset=[0.09,0.12]			; GD153 - jul2005
	'n9u203': offset=[0.10,0.22,0.12]		; GD153   06nov
	'n9u206': offset=[-.25,-.20,0.15]		; GD153   07dec 40% fail
	'na5303': offset=[-.14,-.25,0]			; GD153
	'n8u403': offset=[-0.15,0.05]			; P041C 
	'p041caft-n9jj02': offset=[0.2,0.25,0]		; after lamp on
	'p041cbef-n9jj02': offset=[0.25,0.20,0]		; before lamp on
	'p041con-n9jj02': offset=[0.3,0.05,0]		; during lamp on
	'p041caft-n9vo06': offset=[0.0,0.25,0.30]	; after lamp on
	'p041cbef-n9vo06': offset=[0.20,0.10,0.15]	; before lamp on
	'p041con-n9vo06' : offset=[0.25,0.15,0]		; during lamp on
	'n8u404': offset=[-.05,-0.1]			; P177D.r 
	'n9u213': offset=[-0.1,0.05,-.05]		; P177D   06nov
	'n8u405': offset=[-.15,-0.3,-0.15]		; G191B2B - 2003
	'n94a03': offset=[-.05,-0.1,-.05]		; G191B2B - 2005 cked
	'n9u201': offset=[0.05,0.10,0.10]		; G191B2B 06nov
	'n9u204': offset=[-.05,-.1,-.1]			; G191B2B 07...
	'na5301': offset=[0,0.05,0.05]			; G191
	'n8u407': offset=[-0.33,-0.25,0]		; SNAP-1
	'n9u218': offset=[-0.10,0,-.20]			; SNAP-1  06nov
	'snap1b-n8u407': offset=[-.05,.1,.20]		; SNAP-1B 
	'snap1b-n9u218': offset=[0.15,.20,0]		; SNAP-1B
	'n8vj01': offset=[0.10,0.25]			; C26202
	'n9u216': offset=[-0.15,-.05,-0.25]		; C26202  06nov
	'n8vj02': offset=[-0.10,0]			; SF1615+001A
	'n9u217': offset=[-.05,0.1,0.3]		; SF1615+001A 07feb
	'n8vj03': offset=[-0.30,0.]			; WD1657+343
	'n97u54': offset=[0.05,0]			; WD1657+343
	'n9u207': offset=[0,0,0]			;WD1657+343-NG(bad)
	'n9u208': offset=[0.05,0.0,0]			;WD1657+343 07mar
	'n9u257': offset=[-.05,-0.10,0]			;WD1657+343-repeat of 07
	'n8vj04': offset=[-0.25,-0.25]			; WD1057+719
	'n9g501': offset=[0.15,-.05]			; WD1057+719 - 05jun
	'n9u209': offset=[0.05,0.0,-0.15]		; WD1057  06nov
	'n8vj05': offset=[0.2,-0.15]			; 2M0036+18
	'n9u211': offset=[0.05,-0.20,-0.3]		; 2M0036  06nov
; 2m0559 has such strong spectral features that the xcorrel w/ BD17 is suspect:
	'n8vj06': offset=[-0.05,0]			; 2M0559-14
	'n9u214': offset=[0.20,0.35,0]			; 2M0059  06nov
	'n8vj07': offset=[0,0,0]			; BD+17D4708 (ref.)
	'n94701': offset=[0.13,0.10,0.16]		; BD+17D4708 (new #1)
	'n94702': offset=[0.11,0.03,0.10]		; BD+17D4708 (new #2)
	'n8vj08': offset=[0.40,0.3,0.05]		; VB8
	'n9u210': offset=[0.25,0.1,0]			; VB8 07feb
	'n8vj09': offset=[0.0,-.05,-0.20]		; SNAP-2
	'n9u215': offset=[-.05,0.05,-.1]		; SNAP-2  06nov
	'g191b2ba': offset=[0,0,0]			; g191b2b-a
	'g191b2bb-n8u405': offset=[-.09,0,0]		; g191b2b-b
	'g191b2bb-n94a03': offset=[+.18,0,0]		; g191b2b-b
	'g191b2bc': offset=[0,0,0]			; g191b2b-c
	'g191b2bd': offset=[0,0,0]			; g191b2b-d
	'gd71a-n8u401': offset=[+.18,0,0]		; gd71a
	'gd71a-n94a01': offset=[-.09,0,0]		; gd71a
	'n9iu02': offset=[0.05,0.0,0]			; 1812095 06may
	'n9iu03': offset=[-0.15,-0.1,0.05]		; 1740346 06aug
	'n9iu05': offset=[-0.25,-0.15,-.10]		; 1805292 06aug
	'n9iu14': offset=[-0.2,-0.1,-.15]		; 1743045 06jun
	'n9uc01': offset=[-0.10,-0.25,-.15]		; 1732526 07jan
	'n9uc02': offset=[-0.30,-0.4,-0.5]		; 1739431 06nov
	'n9uc03': offset=[0.10,0.20,0.20]		; 1802271
	'n9uc14': offset=[-.15,-.15,-.25]		; 1812524
	'n9iu06': offset=[-0.15,0.0,-.10]		; kf08t3  06may
	'n9iu07': offset=[0.05,0.2,0.05]		; kf01t5 06may
	'n9iu08': offset=[-0.15,-0.05,-0.05]		; kf06t1  06may
	'n9iu09': offset=[-0.05,-0.1,-0.05]		; KF06T2 06mar
	'na5105': offset=[-.05,-.10,-.05]	; P330E - Nor special
	'na5304': offset=[-.1,0,-.05]		; P330E
	'na5305': offset=[-.25,-.15,-.30]	; AGK
	'na5306': offset=[0.15,0.25,0.2]	; Feige110
	'na5307': offset=[0,0,.1]		; GRW
	'na5308': offset=[.2,.15,.1]		; LDS749B
	'na5359': offset=[0.30,0.10,0.25]	; HD209458 (na5309 Bad, no GS)
	'na5310': offset=[.20,.30,.15]		;    "
	'na5311': offset=[0.15,0.30,0.15]	; HD165459
	'na5312': offset=[0.05,-.1,-.05]		;     "
	'na5313': offset=[0.15,0.1,0]		; VB8
	'na5314': offset=[0.05,-.2,-.35]	; 2M0036
	'na5315': offset=[0.35,0.35,0]		; 2M0559
; ###change:
	'n9nqa1': offset=[0.,0,.15]		; hd189733
	'n9nqa2': offset=[0.,0,.10]		; hd189733
	'n9nqb1': offset=[0.,0,.14]		; hd189733
	'n9nqb2': offset=[0.,0,.11]		; hd189733
	'n9nqc1': offset=[0.,0,.11]		; hd189733
	'n9nqc2': offset=[0.,0,.09]		; hd189733

	endcase
offset=offset*[.00562,.007993,.01144]		; 09jun9 Nor Pirzkal mic/px
;offset=offset*[.00552,.008016,.011353]			; 06dec7
; 07jun5-Wolfram sent his values 07mar9. See Nicmos #2 folder-front:
;offset=offset*[.005481,007993,not-sent], which makes +/- 0.3 px diff at ends
; wrt to the middle for G096 & less for G141. Implement when he has a writeup.
if abs(max(offset)) ne 0 then print,'NICWLFIX returned a WL offset=',offset,	$
		' microns'
return,offset
end
