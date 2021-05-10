pro ctecorr,hd,z,epsf,netcor,errf,calstis=calstis
;+
;
;  ctecorr,hd,z,epsf,netcor
;
; 01Apr6 - to correct STIS CCD spectra for CTE losses per cyc10 ph2 Update
; INPUT:
;	z  - structure containing STIS spectrum w/ gross and net in ELECT/SEC
; INPUT/output:
;	hd - STIS header
;	epsf - data quality flags to be updated to 170 for CTE corr out of range
;	errf - (optional) propagated errors for the net spectrum
; OUTPUT:
;	netcor - net spectrum corrected for CTI
; OPTIONAL INPUT KEYWORD PARAMETER
;	/calstis - routine is being called by calstis
; REFERENCES
;	A. Cycle 10 Phase II update of 01Apr, Table 1 - Paul Goudfrooij
; 	     baseline is average of 2 epochs measured for baseline @ 3yr=2000.26
;	B. Randy Kimble - private comm. Much better than stellar photom 
; HISTORY
;	01Apr6 - rcb. implement A
;	01May7 - try B, which should be better, but has only ~ZERO sky.
;	01may15- B' = Kimble line segments + Bohlin pts @ ~20,000electrons.
;	02Jul31 - too much cte corr at 9-10,000A. Roll off as exp(-600B/G)
;	02aug13- Got a good halo solution for wl>8000A & lds749 right @ 17-1800A
;	02aug22 - add 5 elect more elect & sky for spurious charge at G=4 (or 8)
;	02sep - use rolloff of exp(-a/G^b), indep of Sky bkg.
;	03Mar17 - Paul's new formulation w/o halo for G750L
;	03apr2 - time change for dark rate.
;	03May15 - (DJL) added optional errf input/output parameter, works
;			with non-standard gwidth/bwidth, added calstis
;			keyword parameter for use by calstis.
;	03jul8 - change to power law for row dependence
;	03aug4 - ISR 03R coefficients from Paul for above pwr law,
; for example row 512 is  1-(1-CTI)^512 and not CTI*512:
;; orig ISR 03-03R where fhalo=0
;cticor=0.0355*elect^(-0.750)		; 03aug4 pwr law @ B=0 ISR 03-03R
;cticorfin=cticor*exp(-2.97*((skybkg+net*fhalo*exptime/crsplit)/elect)^.21) ;isr
;	03dec8 - put in spurious charge vs. row equations
;	03dec9 - use new MEANDARK instead of avg dark rate
;	03dec31- gross=net+bkg(7px) for G750L, so elim special g750L section
; CTI is determined only for standard default 7 rows in gross, 
; 	04jan2 - but assume for saturated Vega data that the total net signal 
;		is really all in the 7px hgt.
;	04feb16 - allow approx CTE corr for hgt=5 or 6.
; 	05may13 - Turn off CTE corr of G750L, because of Halo & to fix Snap 
;	     faint star long WL fluxes. NG-makes discont g430--g750L for WD1657.
;	05may18 - put G750L halo rolloff from 0 to 1 from 6000-10200A (again)
;halo=((10200.-wl)/4200)>0<1		
;	05may18 - arbitrary. * ctecorfin below
;	05sep29 - put in new time constant 0.218 to replace 0.243
;	05oct4 - remove above arbitray halo and put in the right one per abscor
;		via halofrac.pro
;	05oct20 - paul's new eq. from 05Oct14
;	05dec20 - fix /crsplit error for meandark & put in Paul's WD1657 fit
;	05oct21 - paul's tweak from 05Oct20
;	2006 - algorithm per ISR 2006-03 of 06jun9
;	2009oct1-new gain=1 spurious charge & new .216 time constant.
;	2014Aug-allow corr for all hgt (=gwidth). See abscor.pct
;	2017may4 - return on PIXELCTE=YES IN HD
;	2017may12 - Add OCCDHTAV corr for CTE per Biretta etal STIS ISR 2015-03
;	2017MAY13 - OCCDHTAV corr for CTE does NOT reduce scatter in make-tchang
;		REMOVE here & see stiscal/plots/17mayctetemp-make-tchang.ps
;	2019Apr - see stis/doc/cte.2019tweak testing.
;-
netcor=z.net
mode=strtrim(sxpar(hd,'opt_elem'),2)
pxcor=strtrim(sxpar(hd,'pixelcte'),2)

; 05may18 - idiot check for wrong modes:
if (strpos(mode,'B') lt 0 and (strpos(mode,'G140') ge 0 or		$
		strpos(mode,'G230') ge 0)) or pxcor eq 'YES' then begin
	print,'NO CTE CORR for Mode='+mode+' PIXELCTE='+pxcor
	return
	endif

aper=strtrim(sxpar(hd,'aperture'),2)			; Use same abscor at E1
amp=strtrim(sxpar(hd,'ccdamp'),2)
crsplit=sxpar(hd,'crsplit')  &  if crsplit le 1 then crsplit=sxpar(hd,'nrptexp')
; 09jan12-add stisdir.pro style of finding CRSPLIT in the odd case,eg:o6n3a30a0,
;	where nextend=192 & is retained by DJL from orig HD209458 image.
nextend=sxpar(hd,'nextend')/3				; sets of sci,err,dq
if nextend ne crsplit and nextend ne 0 then begin	; 0 for stsci pipeline
	help,crsplit,nextend
;	if crsplit gt nextend then stop	; idiot check. =1 & fails for stsci SX1
	crsplit=nextend
	endif
exptime=sxpar(hd,'exptime')
gain=sxpar(hd,'ccdgain')
star=strtrim(sxpar(hd,'targname'),2)
root=strtrim(sxpar(hd,'rootname'),2)
temp=sxpar(hd,'OCCDHTAV')
if strpos(star,'HD172167') ge 0 then star='HD172167'	; bad name in 2nd visit
; meandark computed by IDL CALSTIS as a median; STScI pipeline has ADU=elect/G.
meandark=sxpar(hd,'meandark')/crsplit
hgt=sxpar(hd,'gwidth')
; hz43B is above hz43 --> no cticorr for G750L, where HZ43B is bright.
; if root eq 'o69u07030' HZ43B faint,but in slit
; 2020mar16 - do CTE corr for o69u07030
if mode eq 'G750L' and star eq 'HZ43' and root ne 'o69u07030' then begin
;or strpos(star,'NGC6681') ge 0 then begin
	sxaddhist,'Crowded field. No CCD CTE Loss Correction.',hd
	print,'No CTE correction for ',star
	return
	endif
if hgt eq 0 then hgt=7			; STSCI pipeline
; 2014aug4-always do CTE corr. for hgt=7 algorithm. Larger widths should pick up
;	more of the lost charge and should have less corr, which is partially
;	accounted by the larger Gross & Net in the wider gwidth.
;if (hgt gt 11 or hgt lt 5) and star ne 'HD172167' and star ne 'SIRIUS'	$
;						and star ne 'NONE' then begin
;	print,'*** WARNING: NO ctecorr FOR Large HGT=',HGT
;	return
;	endif
;& Consider what to do for extreme hgts. NONE is for Vega fringe flat, where
;	making CTECORR makes NO difference, because DJL does NOT corr the NET.
if hgt ne 7 then print,'*** WARNING: ctecorr APPROX FOR NON-STANDARD HGT=',HGT 
time=absdate(sxpar(hd,'pstrtime'))  &  time=time(0)
if time lt 1995. then begin ;use MJD from EXPSTART   ; STsci pstrtime is missing
	exptime=sxpar(hd,'texptime')
        mjd = sxpar(hd,'texpstrt')			;02jun18 - was expstart
        caldat,mjd+2400000.5d0,month,day,year,hour
        time = year + (ymd2dn(year,month,day)+hour/24.0)/365.25d0
	endif

; get spectrum position
good = where(tag_names(z) eq 'POSITION',ngood)
if ngood gt 0 then ypos=1023-avg(z.position)		$	; IDT col. name
	else ypos=1024-z.a2center				; stsci col name
; 02aug22-DON'T include dark rate in gross! (gross-net) is in the result at bott
gross=z.gross  &  net=z.net  &  cticor=gross*0	; elect/sec

; for G750L, the gross has fringes, which SHOULD be removed AFTER cte corr! 
;	BUT charge ahead w/ approx corr based on defringed net & gross
if (mode eq 'G750L') then print,'G750L gross spectrum is approx. in CTECORR'
; 02aug22-include spurious charge in elect, so that sky also increases:
; 03dec8 - spurious charge vs ypos is from bias files:
yrow=1023-ypos			; i want orig row, while ypos is dist from top
spuri=(1.1-.0012*yrow)>.5
if time ge 2009. then spuri=(spuri*2)>1.2		;09oct1 - bad approx
if gain ne 1 then spuri=(15-.019*yrow)>5.3

print,'Time Row, gain, meandark, spur chrg, crsplit=',time,yrow,string(	$
	gain,'(i2)'),string(meandark,'(f5.1)'),string(spuri,'(f5.1)'),crsplit
elect=gross*exptime/crsplit+meandark*hgt+spuri*hgt

; CTI determined only for standard default 7 rows in gross
;  >0 required for the odd px because of larger than avg dark or bad overscan.
skybkg=((elect-net*exptime/crsplit)/hgt)>0	; elect/px sky+spurious+dark

; 09sep11 - for truncation at G=4. Analog noise populates the full 0-3.9999
;	range that goes to 0 at G=4, so add the avg=0.5*gain for CTECOR, not net
;	The net is OK as N=G-B and both G & B are truncated equally.
; 	skybkg is also OK as both elect & net are equally low above.
elect=(elect+0.5*gain*hgt)>3	; 07apr4 - only a few pts <3 for VB8 g430L	

if strpos(star,'NGC6681') ge 0 then skybkg=11.6	; avg value. again best 03aug4
; 10x extrap from min meas of 30elect. & would give a corr factor of 10x for
;	min sky=0.5 spurious charge.
;	A 10X corr would be v. uncert. CTE might even goto zero near sky.

wl=z.wavelength
hsky=0
if mode eq 'G750L' then begin
	halofrac,mode,aper,wl,fhalo
	hsky=(1.3*(fhalo-.060))>0	; final of 05dec21 good for wd1657
; ###change
; test****************
;	hsky=(0.2*(fhalo-.060))>0	;Good!
; test****************
;;	hsky=(0.1*(fhalo-.12))>0	; paul of 05dec20 good for g191b2b 70s
	endif
; 09jan9 - tested to see if 2m0036 etc change is due to ff line: NO, just a
;	couple of pts change. One was NaN, so i expect ff to be for elim NaNs.

;compute CTI for time=2000.6, the mean date of last 2 sets of kimble data.
cticor=0.0562*elect^(-0.82)		; 05dec21 per Paul wd1657 fit
;;cticor=0.0562*elect^(-0.81) 		;; beta tweak test not much help.

; 2018jul21 - add >0 on net to avoid NaNs
cticorfin=cticor*exp(-3*((skybkg+hsky*(net>0)*exptime/crsplit)/elect)^.18)

; ###change
; test**************** zeta=0.20
;cticorfin=cticor*exp(-3*((skybkg+hsky*(net>0)*exptime/crsplit)/elect)^.21)
; test****************

; 09jan10 - looks like i rm the corr of 0 for neg gross in 2007. Neg gross
;	can arise from subtr of bias and mean dark. Now, i make neg signal more
;	neg and get lower nets, eg 2M*s calspec _002/_001.fits. But ~symmetric
;	corr btwn small pos and neg gross is maintained. Still, the gross is so
;	rarely neg, this does NOT explain the 002/001 change. BUT if i had net
;	instead gross used to ck for citcorfin=0, that does NOT explain either?!
; 09jan11-and even setting cticorfin=0 for elect<10 does not reprod _001
;	for the 06jul31 _001 runs, i must have had an undoc change!
; 07apr4-rm ff --> .001 lower bkg on ~0.000 for vb8 g430l & <1% @ 1mic wd1657
; 07apr4: poor idea -->bad=where(gross le 0,nbad)-hot col in bias. eg o8v204030
;	16s exp
;  .....  ...if nbad gt 0 then cticorfin(bad)=0	; don't make neg noise more neg.
;...BUT these v. low elect values have bigger corr, making the neg noise too neg

; No problem for large # of electrons, as for satur data: corr ---> 0 OK
indx=where(elect lt 10,ndx)
if ndx gt 0 then begin
	epsf(indx)=epsf(indx)>170	; CTE corr uncertain. fixed 04jan21.
	endif

; corr for time diff from 2000.6 @ 21.6 %/yr. Zero ~1yr before launch @ 1995.97
delta=(time-2000.6)*.216+1	; for launch at 1997.16
; 2017may12 - adjust for temp dependent CTE of 2.6% per 1 deg C:
;; no help: tmpcorr=1.	; early hdrs have no temp keywords (see ttcorr.pro)
; Mean OCCDHTAV is ~20, rather than the 19C used in ttcorr.
; ISR215-03 seems to discuss a local CTE, rather than total for 1024 Y
;	transfers, so raise the effect by the number of Y transfers in the CCD.
;;if temp gt 0 and time gt 2001.5 then tmpcorr=1+.026*(temp-20) ; zerr corr @20C
	
; 07apr5 - makes no sense to corr bkg: diff Y val & const field-->0 charge loss
;;netcor=gross/((1-tmpcorr*delta*cticorfin)^ypos)-(gross-net)

netcor=gross/((1-delta*cticorfin)^ypos)-(gross-net)	; corr gross & subtr bkg

if n_elements(errf) gt 1 then errf = errf/(1-delta*cticorfin)
sxaddhist,'CTECORR corrected NET for flux calc.',hd
print,star,' CTECORR @ time=',time,' Tot. exptime=',exptime,' amp=',amp
if gain gt 4 or amp ne 'D' then stop		; idiot check
;02jul19 - 1-->.1 arbitrary low Signal in ct/sec cutoff to avoid ~0 in denom.
; 09jan11 - add exptime to mult net, so 0.1 limit is electrons:
good=where(net*exptime gt 0.1)  &  netrat=netcor(good)/net(good)
hist= '    min,max CTE corr factor='+string(min(netrat),'(F7.3)')+	$
	string(max(netrat),'(F7.3)')+' skybkg='+string(avg(skybkg),'(f7.2)')
print,hist
sxaddhist,hist,hd
; ###change
;print,'CTECORR TEST VERSION
;print,'CTECORR TEST VERSION
;print,'CTECORR TEST VERSION
;stop	       ; AND run ctetst.pro
return
end
