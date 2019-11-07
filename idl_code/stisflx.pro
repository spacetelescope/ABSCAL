PRO stisflx,file,hdr,wave,flux,net,gross,blower,bupper,epsf,errf,ord,bad=bad, $
	ttcor=ttcor,notime=notime,notemp=notemp,nofile=nofile,nocte=nocte
;+
;
; DOCUMENTATION - SEE stis/doc/abscor.pct
; PURPOSE:
;  read stis data & calibrate net countrate to flux. Corr both for time &
;	temp changes. Corr flux for slit thruput via APERTAB (ST) APTTAB (IDL) &
;	corr for gwidth extr hgt w/ PCTTAB (IDL-abscor). see stis/doc/abscor.pct
; ***********************************************************************
; *** WARNING *** WARNING *** WARNING *** WARNING *** WARNING *** WARNING *** 
;     ****GROSS & BKGs are NOT corrected!
;  *** SO: BKG NOT= G(uncor)-Net(corr) !!!!!!!!!!!!!
;	Preproc uses this routine to get FLUX in output file.
;	NO CTEcorr done in preproc to NET; but GAC is applied to net by preproc.
;	{Should put GAC corr here & not in preproc. Otherwise need special 
;		preproc run to make all AGK w/o GAC corr. but: 2019mar-make-gac
;	fixed to corr the old corr, so no special preproc needed.}
; ***********************************************************************
; INPUT
;	- file-extracted spectral data file, w/ virgin, uncorr net, except GAC.
;	- /ttcor, if present make the time, temp, cte corrections & sens* from
;		/scal. Otherwise just return w/ same result as mrdfits,
;		regardless of other keyword setting.
;	- /notime, if present along with /ttcor make only temp correction
;	- /notemp, Do NOT do temp corr. for use in tcorrel.
;	- /nofile. No input file to read for K648 work. Net from geomed image.
;	- /nocte to be used w/ ttcor, but omit just the CTE correction.
; OUTPUT - hdr=header - only thing used by preproc. NO new file is written here!
;			and only the hdr & flux are written by preproc.
;	 - wave=wavelengths, corr for heliocentric vel.
;	 - FLUX If /ttcor: corr for cte,time,temp here & also
;			   aper,gwidth here via calstis_abs,_sens
;		gwidth corr uses eg: stisidl/scal/abscor-750.fits
;		halofrac.pro uses stiscal/dat/abscor-g750l, called by ctecorr.
;		BUT 2 files are the same except for added aperture by DJL. See
;		abscor.isr90-01-99update & stis/doc/abscor.pct. 
;		Cked for G750L only.
;	 - EPSF  quality flags
;	 - ERRF  uncertainties in flux units
;	 - GROSS counts/s
;	 - BLOWER lower bkg
;	 - BUPPER upper bkg
;	 - NET counts/s corr for CTE,time,temp, if /ttcor.
;		also E1 net input is already corr for GAC in preproc.pro.
;	NEVER write in PREPROC the output NET that is corr for gwidth &
;	 aperture, which are done to flux only via calstis_abs and now via this
;	 routine in preproc for the 3 CCD L modes.
;		The returned net IS corr for gwidth for gwidth>35, but preproc
;		does not write that corr net. However, a) the returned net might
;		be better w/o the gwidth corr (fixed to corr NET 2019apr)
;		AND b) preproc DOES write the returned header. 
;		So fix hdr to keep the orig wide gwidths along w/ fully
;		corrected, (CTE, etc) gross,net for output params.
;	 - ORD order number
;	- /bad, set bad='B' for late G140L @ +3", where no corr is made
;
; SUBROUTINES CALLED
;	ctecorr & ttcorr.
;	calstis_abs, which also calls calstis_sens to do the aperture corr. 
;	gwidth corrections for output flux done here for wide gwidths. The
;	7 & 11 gwidths use corresponding sens* files w/o gwidth corr.
; AUTHOR-R.C.BOHLIN
; HISTORY:
; 97aug14 - written
; 97dec10 - remove radial veloc from wavelengths before calibrating;
; 98feb13 - but radial veloc corr in orig wave array is not changed!
; 98apr13 - add echelle capability, as well as order output array
;					of 16-JAN-1998 software update.
; 98jul17 - time,temp corr for MAMA's
; 98sep10 - add sxaddpar,hdr,'pcttab','NONE' and remove my own equiv code.
; 98sep10 - oops, forgot star rad vel is no longer incl in wls, so remove here. 
; 99sep7  - move up time and temp corr to correct net, as well as flux.
; 00jan10 - turn on my good aperture corrections, as fed back from DJL
; 00jan14 - fix bug introduced for spectra processed after 99dec9 w/ new 
;		TIMECORR= 1 header param, which made calstis_abs do corr again.
; 00apr10 - updated errf to get improved error est. after time,temp corr.
; 01apr9  - add CCD CTE correction per ctecorr.pro for net and flux
; 02mar31 - turn off p3m3 corr, as L-flats and new time corr mod are implemented
; 02apr4  - Flag attempts to correct G140L after 1999.2 @ +3"
; 02apr4  - add notemp keyword
; 03jan7 - elim confusing cal keyword and replace w/ bad='B' keyword for 
;					the flagged G140L >1999.2 @+3"
; 03nov7 - add section to do special abscor for wide extract. of sat Vega obs,
; 03dec31	where gross and net get updated to 7 or 11px by abscor corr.
; 07aug17 - add /nofile flag to skip reading data and just correct net as input
; 09jul27 - add 1.5 e- for G=4 in ctecorr.pro
; 09jul28 - update G=4/1 ratio from 4.039 to 4.016
; 13feb12 - add G230LB scat lite corr here.
; 14sep29 - add gwidth=11 sens cal for G750L
; 2019jan31 - fix small bug for ttcorr to use instrum,obs. Wavelengths
; 2019feb15 - add nocte keyword
; 2019mar20 - use gwidth=11 sens cal for wide G230LB & G430L **EFFECTS FLUX calc
; 2019apr1 - fix bug that mod hdr (used by preproc) & Net (NOT used by preproc) ;	for 7 or 11 gwidth for fluxcal.
; 2019apr4 - fix returned NET & gross for wide apertures to avoid gwidth corr,
;	because that corr is only for 11 px flux cal. Retain full net for big
;	extrheight for abscor, etc. (time & temp corr are done but are smallish
;	effects).
; 2019apr18-rm corr. to 7 or 11 px gwidth for CTE corr. See stis/doc/abscor.pct.
; 2019apr23-Upgrade Vega & Sirius abscor files, because of time variability of
;	these corrections
; 2019apr29 - make a larger coef of scat lite of .000141 for gwidth=11. See 
;						stis/doc/scat.ccdmodes
;-
st=''
if keyword_set(nofile) then begin
	exptm=sxpar(hdr,'exptime')			; IDT geom file only-ok
	goto,skipreading
	endif
	
; 1. READ INPUT FILE

z=mrdfits(file,1,hdr,/silent)
indx=where(strpos(hdr,"= 'A2CENTER") ge 0)
if indx(0) gt 0 then begin		; case of reading stsci data
	dum=mrdfits(file,0,hd0,/silent)	; ST header partly in extent zero
	hdr=[hd0,hdr]		; 2019jun11 - hd0 missing things in hdr
	exptm=sxpar(hdr,'texptime')
	epsf=z.dq		; However, these have different definitions!
; stsci false Satur flag=256, esp G140L & G750L:
	nosat=where((epsf and 256) gt 0,nsat)
	if nsat gt 0 then epsf(nosat)=epsf(nosat)-256
; stsci false blemish flag=1024, esp G750L:
	nosat=where((epsf and 1024) gt 0,nsat)
	if nsat gt 0 then epsf(nosat)=epsf(nosat)-1024
	errf=z.error
	blower=z.background/2	; odd normalization, however. fix for specif app
	bupper=z.background/2
	ord=z.sporder
;2014Jul18-STSCI has pctab, while DJL has pcttab, eg:
;PCTAB   = 'oref$q541740po_pct.fits' / Photometry correction table              
;PCTTAB  = 'abscor-750.fits'    /
	sxaddpar,hdr,'pcttab','NONE'		; stsci has no pcttab 02jun17
; 2019jun11 - stsci has no pstrtime & has changed the rootname:
	root=strtrim(sxpar(hdr,'expname'),2)
; ASSUME previous processing:
	oldfil=findfile('~/stiscal/dat/spec_'+root+'.fits')	;ck for new name
	if oldfil(0) eq '' then root=strtrim(sxpar(hdr,'rootname'),2)
; STSCI old EXPNAME ERRORS:
	if root eq 'o6ig010i0' then root='o6ig01040'
	if root eq 'o6ig010h0' then root='o6ig01050'		;gd71 g230lb
	if root eq 'o6ig010g0' then root='o6ig01060'
	if root eq 'o8v2010k0' then root='o8v201040'		;gd71 g230lb
	if root eq 'o8v2010j0' then root='o8v201050'		;gd71 g230lb
	if root eq 'o8v2010i0' then root='o8v201090'
	if root eq 'o3zx080w0' then root='o3zx08hhm'
	if root eq 'o3zx080v0' then root='o3zx08hlm'
	if root eq 'o6ig03060' then root='o6ig03thq'
	if root eq 'o8v2020g0' then root='o8v202030'
	if root eq 'o8v2020f0' then root='o8v202040'
	if root eq 'o8v2020e0' then root='o8v202050'
	if root eq 'o8v2020d0' then root='o8v202060'
	if root eq 'o8v2020c0' then root='o8v202070'
	if root eq 'o3yx14040' then root='o3yx14hsm'		;GRW
	if root eq 'o3yx15040' then root='o3yx15qem'		;GRW
	if root eq 'o3yx16040' then root='o3yx16klm'		;GRW
	if root eq 'o3yx11030' then root='o3yx11p2m'		;GRW
	if root eq 'o3yx12030' then root='o3yx12utm'		;GRW
	if root eq 'o3yx13030' then root='o3yx13tqm'		;GRW
	if root eq 'o3yx16030' then root='o3yx16kpm'		;GRW
	dum=mrdfits('~/stiscal/dat/spec_'+root+'.fits',1,hd0,/silent)
	pstrtime=strtrim(sxpar(hd0,'pstrtime'),2)
	sxaddpar,hdr,'pstrtime',pstrtime
    end else begin
	exptm=sxpar(hdr,'exptime')
	epsf=z.epsf
	errf=z.errf
	blower=z.blower
	bupper=z.bupper
	ord=z.order
	endelse
; names common to IDT and STScI:
wave=z.wavelength
flux=z.flux
gross=z.gross
net=z.net				; STSCI net corr for GAC only

skipreading:

; 2. DO ALL THE CORRECTIONS, if /ttcor

if keyword_set(ttcor) then begin			; else jump to end
	optmode=strtrim(sxpar(hdr,'opt_elem'),2)
	root=strtrim(sxpar(hdr,'rootname'),2)
	msmpos=sxpar(hdr,'OMSCYL1P')	;Mode select cylinder 1 position
	det=strtrim(sxpar(hdr,'detector'),2)
	gwidth=fix(sxpar(hdr,'gwidth'))			; integer!
	targ=strtrim(sxpar(hdr,'targname'),2)
	if targ eq 'HD172167-V6' then targ='HD172167'	;08dec15 - patch

; 3. FIND THE SENSITIVITY CAL FILE & place in header senstab

	sens='sens_'
; ff for hz43, vega, new gwidth=11 CCD etc.
; INTEGER gwidths, Always use sens11 for saturated obs. w/ wide Gwidths.
	if gwidth ne 7 and (optmode eq 'G750L' or 		$
		optmode eq 'G230LB' or optmode eq 'G430L')		$
		and strpos(file,'hgt7') lt 0 then sens='sens11_'     ;2019mar20
; i.e. default for wide extractions is to use the sens11 flux cal:
	sfile=findfile('~/stisidl/scal/'+sens+strlowcase(optmode)+'.fits')
	indx=where(strpos(sfile,'PFL') lt 0,ngood)
	if ngood gt 0 then sfile=sfile(indx)
	if sfile(0) eq '' or ngood eq 0 then begin
		if sfile(0) ne '' then goto,OK
		print,'STISFLX: No sensitivity file for ',optmode
		if strpos(optmode,'L') ge 0 then stop
		return					; 98feb13
	    end else begin
OK:
		print,'STISFLX Sensitivity file='+sfile(0)
		sxaddpar,hdr,'senstab',sfile(0),' '		;for calstis_abs
		ind=where(flux ne 0)
		errf(ind)=errf(ind)/flux(ind)	; 04jan17 - frac error
		
; 4. USE INSTRUMENTAL WAVELENGTHS FOR APPLYING THE CAL.

; IDL intrumental wavelengths for calibrating. Calstis makes the corr w/ +evel
;      to heliocentic in calstis_hel.pro, while I remove that corr here w/ -evel
		winstr=wave
		helio=strtrim(sxpar(hdr,'helio'),2)
		if helio eq '1' then begin
			evel=sxpar(hdr,'earthvel')	; veloc toward star is +
		        winstr=wave+wave*(-evel)/3e5 ; corr obs to obs. wl frame
			print,root,evel,'= Heliocentric Rad. Veloc Corr removed'
			endif
; STSCI intrumental wavelengths for calibrating
		helio=strtrim(sxpar(hdr,'helcorr'),2)
		if helio eq 'COMPLETE' then begin
			indx=where(strpos(hdr,'Helio') ge 0)  &  indx=indx(0)
			pos=strpos(hdr(indx),'=')+1
			evel=-float(strmid(hdr(indx),pos,8))
		        winstr=wave+wave*(-evel)/3e5 ; corr obs to obs. wl frame
;			print,root,evel,'= Heliocentric Rad. Veloc Corr removed'
			endif

; 5. SPECIAL PROCESSING FOR HEAVILY SATURATED VEGA & SIRIUS OBS
		corr7=1  &  corr11=1  &  corr=1		; std extractions
		orignet=net				; gross is never changed
		origwid=string(gwidth,'(i3)')		; for my INTEGER gwidth
		newid=origwid
; %%% need to update NET eg. gwidth=15, ie new corr factor for range of 12-34px
		if gwidth ge 35 and (targ eq 'HD172167' or	$
				targ eq 'SIRIUS') then begin
; special abscor correction from Vega for G230LB & AGK for G430L & G750L obs.
; 2013feb-for Sirius use all AGK, as 0.3s G230LB is sat.See sirius/doc.procedure
; 2019apr23-new abscor-*Vega.fits files & *Sirius (w/ CAPS). All other 
;	abscor*vega* files are obsolete, except abscor-g230lbvega3.fits.
; Saturated Vega & Sirius special abscor files:
;	ihgt=0,1,2 for gwidth=7,11,vega or Sirius wide hgt.
			vegfil='dat/abscor-'+strlowcase(optmode)+'Vega.fits'
			if targ eq 'SIRIUS' then vegfil=		$
				'dat/abscor-'+strlowcase(optmode)+'Sirius.fits'
; 2019apr16-restore very special abscor for Vega G230LB from 'unsat' short 
;	Vega exp. See stiscal/plots/abscorck-g230lbvega.ps 
			if optmode eq 'G230LB' and targ eq 'HD172167' then begin
				vegfil='dat/abscor-g230lbvega3.fits'
				endif
			sxaddpar,hdr,'pcttab',vegfil

			zabs=mrdfits(vegfil,1,hdum)
; w/ gwidths=7,11,84(sat-Vega),206(sat-Sirius) & unity corr for 7px
			wnode=zabs.wavelength
			tnode=zabs.throughput
			ihgt=2		;extr hgt=eg 84 for the sat.Vega
			corr7=cspline(wnode(*,ihgt),tnode(*,ihgt),winstr)
			corr11=corr7/cspline(wnode(*,1),tnode(*,1),winstr)
; Always use sens11 for sat. data. Set back to orig below.
			newid='11'
			print,'Use sens11 and gwidth=11 for Saturated obs.'
			print,'STISFLX: w/ '+vegfil+' & gwidth='	$
				+string(gwidth,'(i3)')+' for calstis_abs cal'
; frac err unchanged 2019		errf=errf*sqrt(corr7)		;04jan17

; Now i have 7 or 11px net, so must update net & gross in z.structure just to
;			make ctecorr work:
; Must convert to 7px response, as the ctecorr is valid only for gwidth=7 NO!!
;	See abscor.pct. CTE corr should be LESS than for 7px hgt, as wider
;	width extractions collect more of the trailed CTE losses!!!
; NO!			newidth='7'
; NO!			sxaddpar,hdr,'gwidth',newidth	; scale to 7px for cte
; NO!			bkg=(gross-orignet)*float(newidth)/gwidth
; NO!			net=net/corr7		;net, for gwidth=7
; NO!			z.net=net		; z NOT returned
; NO!			z.gross=net+bkg		; bkg is now also per 7px
; NO!			print,'STISFLX '+targ+		$
; NO!				' CTECORR for gwidth=',origwid+'/ '+newidth
			endif			; end wide vega & sirius 
		
; 6. CTE CORRECTION

; As time corr is derived from CTE corr data, the CTE corr must preceed timecorr
; Corr z.net for CTE loss and add any epsf flags for data out of range
; 				computes net & new epsf. z-not changed.
;
; ###change
;Print,' *** CTECORR TURNED OFF IN STISFLX' 
;		Last use of z:			2019apr8 - typo, was epsf:
		if det eq 'CCD' and not keyword_set(nocte) then	begin
			ctecorr,hdr,z,epsf,netcor    ; corr of net
			net=netcor
;; NO!			net=corr7*netcor  ; corr back to wide gwidth net
			endif
; ###change end
; 02apr4 - set B flag if G140L obs at +3" after 1999.2
		time=absdate(sxpar(hdr,'pstrtime'))  &  time=time(0)
; 99sep16 - use MSM cyl 1 position to distinguish bwtn +3 and -3 arcsec 
		if msmpos gt 800 and optmode eq 'G140L' and		$
			time gt 1999.2 then begin
				print,time,' BAD time corr for late +3" '+file
				strput,file,'B',0	; flag for stisadd
				bad='B'			; flag for lowsens
				endif

; 7. TIME & TEMPERATURE CORRECTION

;2019apr	if keyword_set(ttcor) then ttcorr,hdr,wave,net,	- no 
;	make-tchange has instrumental WLs, but wave is heliocentric:
; Undefined notime,notemp are interpreted as 0:
		ttcorr,hdr,winstr,net,notime=notime,notemp=notemp

; reset nocal (251), so calstis_abs can properly update epsf.
		nosens=where(epsf eq 251,nbad)
		if nbad gt 0 then epsf(nosens)=155		; edge flag

; 8. ADJUST GAIN

; adjust NET at CCD gain=4 for 4.034+-.01 factor of walborn & bohlin
; the 4.034 is used for my 00feb23 flux cal bohlin (2000, AJ, 120, 437)
; adjust NET at CCD gain=4 for 4.039+-.006 (smith, etal. isr00-03) - 00dec26
; .............................4.016  09jul28-from gainrat.pro
; AND 4.016 is used by STScI pipeline per recent data/spec/2009 files.
; foolproof! see calstis.doc as IDL puts ATODGAIN=4.034 in all my spec_ headers!
		gain=sxpar(hdr,'ATODGAIN')
		if gain gt 3 and gain lt 5 then begin
;			print,'Adj NET (& FLUX) for 4.016 gain ratio from:',gain
; NO!! maintain IDL CALSTIS net w/ NO change & fix below
;; NO!! 2019Aug		sxaddpar,hdr,'ATODGAIN',4.016	; Corr IDL Calstis
			if gain ne 4.034 then stop	; and consider 09jul28
			net=net*4.016/gain  &  endif 	; 00dec26

; 9. G230LB SCATTERED LIGHT CORRECTION

; 2013feb11 - put G230LB scat lite corr here & rm from PREPROC.pro:
; 2013Feb11 - Scat lite corr based on CTE corr net. (Was the uncorr net before.)
;		Coef was .000125.
; Make scat increase for 12813-Schmidt obs per stisdoc/scat.ccdmodes:
; 2019apr1 - ff scat calc moved here from stisflx.
		if optmode eq 'G230LB' then begin
			coef=0.00013
			if gwidth gt 9 then coef=0.000141	; 2019apr29
			scat=coef*tin(winstr,net,2900,3050)^2/		$
				tin(winstr,net,2350,2550)
			sxaddpar,hdr,'SCATLITE',string(scat,'(e10.3)'),	$
			       'Scattered Red light corr (ct/s) for flux cal.'
			print,scat,' G230LB scat lite corr. 17-1800A net='  $
				+string(tin(winstr,net,1700,1800),'(f9.3)') $
				+' coef='+string(coef,'(f8.6)')
			net=net-scat
			endif

; 10. PREPARE HEADER FOR ABS. FLUX CAL

; 00jan14 - djl says default is to apply time/temp corr to flux (only).
; 	Since i already corrected net, turn off timecorr for calstis_abs
		origtcor=sxpar(hdr,'TIMECORR')
		sxaddpar,hdr,'TIMECORR',0
		dum=errf

; 11. CALIBRATE 7 or 11 px NET TO FLUX. calstis_abs does wide corr.
		if det ne 'CCD' then goto,skipccd
		sxaddpar,hdr,'gwidth',newid		; for flux cal
		if sens eq 'sens11_' then begin
			corr=corr11		; all CCD cases, except gwidth=7
			if newid ge 35 then stop	; 2019apr9 - eg 15 OK
		    end else begin
			corr=corr7
			if newid ne 7 then stop		; idiot ck.
			endelse
skipccd:
		print,'STISFLX: FLUX CAL w/ minmax gwidth corr=',minmax(corr)
; The flux cal:
		sxaddhist,'  **** STISFLX: OVER-RIDE CALSTIS FLUX CAL ****',hdr
		calstis_abs,hdr,1,winstr,net/corr,dum,epsf,flux	;1 for first ord
		
		sxaddpar,hdr,'TIMECORR',origtcor	; replace orig
		sxaddpar,hdr,'GWIDTH',origwid		; replace orig
		errf=errf*flux				; 04jan17
		fracerr=1./sqrt(net*exptm>0.1)		; 0.1 sec stis exp 03dec
; Estimate only the new errf values, where orig errf = 0
		if nbad gt 0 then errf(nosens)=flux(nosens)*fracerr(nosens)
		endelse				; end good sens file found.
	endif		; END ttcor=1 keyword
RETURN			; just returns input file values if ttcor is not set
END
