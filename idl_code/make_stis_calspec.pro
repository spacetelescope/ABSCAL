pro make_stis_calspec,filespec,all=all
;+
;			make_stis_calspec
;
; PROCEDURE to convert STIS ascii file to CALspec (or CALobs) binary fits tables
;	1. Check that all spectra have current STISWLFIX values per nowavcal.pro
;		(or wlck.pro for WDs w/ models)
;	2. Ck for latest processing of STIS, WFC3, & NICMOS *.mrg files
;
; CALLING SEQUENCE:
;	make_stis_calspec,filespec,all=new.names
;
; INPUTS:
;	filespec - filespec for ascii merge STIS files
;		SPECIAL CASES: use 'vega' to do alph-LYR, 'sun' for SUN_ref....
;				'g191.calobs' for pure STIS g191
;				.....hd172167.mrg ok also for vega
; New stars w/ no model and no wfc3 or nicmos fall thru & need no edits here,
;	eg sdss132811
;
; OUTPUTS:
;	a bunch of .fits files with names placed in deliv/ sub-directory
;		eg: <nam>_stisnic_00x.fits 
;		and use mrdfits to read binary table output
; UPDATE: doc/new.names for new data or new output file names.
;
; RESTRICTION: Run in calspec dir (or calobs)
;
; EXAMPLES:
;	
;obso-	make_stis_calspec,'../nical/spec/*.mrg' -- anything w/ NICMOS spectra
;  lete	make_stis_calspec,'../stiscal/dat/*.mrg'  -- STIS only or WFC3 NO NICMOS
;   "	make_stis_calspec,'/internal/1/nical/spec/bd+17d4708.mrg'
; ff. is the only supported input mode:
;	make_stis_calspec,'',all='doc/new.names'  -- for everything in file.
;
; HISTORY:
;	written 00apr - rcb
; 03nov12 - go to _stis_002 versions, starting w/ vega
; 04jun7 - add bd17d4708
; 05apr  - add nicmos fluxes and name stisnic_001. make nicmos syserr=2%
; 06mar  - start w/ linearity corr nicmos additions
;06mar14- new thuillier+KZ solar fluxes.Use filespec='~/calib/sun-thuillier.txt'
; 06mar24 - rm .008 magfx corr to FOS. See FOS Modcf plots in 2006 std * folder.
;	this magfx factor was included for 2001 deliveries, eg hz4_stis_001
; 06aug3 - add all stars w/ NICMOS obs. put "nical" in filespec for multiple
;	files or for stars w/ no STIS obs
; 06aug10 - MOTE/DQ FLAGGING POLICY: as the motes are usually <2% dip, only the
;	high S/N cases seem relevant. For a lot of these set the flags to good.
;	Rarely leave the 0 flag for a hi S/N
;	dip case, eg see BD+17 comments below.  make a
;	set of stdplt plots, where all motes are dotted to verify policy and
;	decide on which 0 flags to keep. To patch these problems means making
;	hard choices of each feature's possible reality. (altho, these few
;	hi S/N cases could be patched, if ever relevant.)
; 08mar25 - zero geo-coronal Lyman-alpha in IUE data
; 08may13 - revamp logic for cases w/ stis+nicmos only.
; 08may13 - hypens not allowed in file names. Remove them.
; 09may15 - .tab tables do not read on new Intel MAC. Try the 16 .fits versions
;	from cdbs/supplemental_calspec--> NG the 1.6e38 nulls turned to -NaN !
;	Use Don's new tab_convert. See calspec/doc/tab-files.djl for details.
; 11Dec22 - Add JWST A stars to merge w/STIS.INPUT must be indiv nical mrg files
; 13jan22 - Revamp to use NEW.NAMES list to name output file and automate
;	search for input files. New keyword 'all=new.names'.
; 13Feb28-fix ck04modcor.pro to use new ck04 models per ck04blanket.pro
; 2014Oct-Should I norm models to match chifit, ie in same
;	bins as used for the chisq fits. Put normfac into vmag??? OR
;	should I trust 9000A cal & model & norm there & in chifit???
;----> 2017jan31-I should have the best model from chisq fits, so avoid
;	discont. & norm to long WL here, even tho the IR will have any long WL
;	error in the STIS (or NICMOS).
; 2017Jan31-Switch from CK04 to BOSZ models. make a new boszmodcor.pro
; 2017Mar21-Add continuum to boszmodcor lines
; 2018aug1-start mods for WFC3 grism results for NO Nicmos
; 2018oct26-start mods for WFC3 grism results for stars WITH Nicmos
;2019aug - omit IUE for new A stars, even tho 109vir & delumi are at ancient/pop
;	(See notes at calspec/doc/new.names)
;-

; 2018Nov8 - Get names of stars to process. Elim other input styles!?
readcol,all,outnam,f='(a)'		; output names, incl. version #
good=where(strpos(outnam,'#') lt 0)	; trim comments
outnam=outnam(good)

st=''
!x.style=1
!p.noclip=1
if !d.name eq 'PS' then !p.multi=[0,1,2,0,0]
!ytitle=''
wlsrc='(i5,i8,7x,a,t45,a)'			; WL cut format
if filespec eq 'sun' then begin
	target='SUN_REFERENCE'
	goto,sun	; 01jan25 - special case
	endif
filelist=findfile(filespec)

if keyword_set(all) then begin	; make filelist from ALL nic & stis files:
	filelist = findfile('../nical/spec/*.mrg')		; NICMOS files
	fdecomp,filelist,disk,dir,nicnam,ext
	tmp=findfile('../stiscal/dat/*.mrg')			; STIS files
	nstis=n_elements(tmp)
	fdecomp,tmp,disk,dir,stisnam,ext
; Start w/ all files w/ Nicmos data, then add those STIS files w/ NO Nicmos:
	for i=0,nstis-1 do begin
		ind=where(nicnam eq stisnam(i),nsame)
; odd name and bad star cases:
		if stisnam(i) eq 'agk' or stisnam(i) eq '2m003618' or	$
		   stisnam(i) eq 'bd17d4708' or stisnam(i) eq 'g191' or	$
		   stisnam(i) eq 'bpm' or stisnam(i) eq 'dbl-hd27836' 	$
		   or stisnam(i) eq 'sf1615001a' or stisnam(i) eq	$
		   					'2m055914' or	$
		   stisnam(i) eq 'wd1057_719' or			$
		   stisnam(i) eq 'wd1657_343' or			$
		   strpos(stisnam(i),'grw') ge 0 or 			$
		   strpos(stisnam(i),'m33') ge 0 or 			$
		   strpos(stisnam(i),'ngc') ge 0 or			$
		   strpos(stisnam(i),'k648') ge 0 then nsame=1
		if nsame eq 0 then filelist=[filelist,tmp(i)]	; full file list
		endfor
	endif							; END /all Case
; BAD data:
filelist=filelist(where(strpos(filelist,'snap-1b') lt 0 and 		$
		strpos(filelist,'1739431') lt 0))
if filespec eq 'vega' then filelist='../stiscal/dat/hd172167.mrg'		; 03nov12
if filelist(0) ne '' then print,'files found=',filelist,form='(a)' $
	else begin
	print,'no files found for filespec=',filespec  &  stop  &  endelse

;
; loop on files
;
; ###change
for ifile=0,n_elements(filelist)-1 do begin
;for ifile=56,n_elements(filelist)-1 do begin
	Teff=-1.			; initialize flag for no model
	!y.style=1			; wd1057 sets it to 0
	iuelo=1.			; flag for NOT adding IUE mult hist
	sun=''
    	instrum='STIS'
	fdecomp,filelist(ifile),disk,dir,nam,ext
	nictarg=nam					; mv up 2018nov8
	target=strupcase(nam)
	if strpos(target,'172167') ge 0 then target='ALPHA_LYR'
	if strpos(target,'G191') ge 0 then target='G191B2B'
	if filespec eq 'g191.calobs' then target='G191B2B_PURE'
	if target eq 'WD-0308-565' then target='WD0308-565'
	if target eq 'WD1327-083' then target='WD1327_083'
	if target eq 'WD2341+322' then target='WD2341_322'
	name=strlowcase(target)
	if name eq '2m0036+18' then name='2m003618'	; a bit inconsistent !
	if name eq '2m0559-14' then name='2m055914'	; a bit inconsistent !
	if name eq 'bd28d4211' then name='bd_28d4211'
	if name eq 'bd75' then name='bd_75d325'
        spos=strpos(name,'+')
        if spos gt 0 then strput,name,'_',spos  ; replace + with _
; 08may13 - use NO minus signs!
	if strpos(name,'snap') ge 0 then name=replace_char(name,'-','')	$
		else name=replace_char(name,'-','_')
; 2013Jan22 - Use outnam for file names
	ind=where(strpos(outnam,name+'_') eq 0,ngood)
	if ngood ne 1 then begin
		print,'Not in new.names: SKIPPING: ',name
;		read,st
		goto,nextfile
		endif
	nam=name				;for targcase select & output
	name=outnam(ind(0))			; OUTPUT file name
	targcase=target				; for case statement

; ###change - Gen. Purpose. Do NOT include special case stars, eg HD93521 w/ IUE
; JWST,etc. G & OBA stars w/o nicmos where a model is added at WL>10000A,
;				including case of WFC3 IR grisms w/ NO nicmos
	if nam eq 'hd37962' or nam eq 'hd38949' or 			$; G
	   nam eq 'hd106252' or nam eq 'hd159222' or nam eq 'hd205905'	$; G
	   or nam eq 'hd14943' or nam eq 'hd37725' or nam eq 'hd116405'	$; A
	   or nam eq 'bd60d1753' or nam eq 'hd158485' or nam eq 'hd163466' $
	   or nam eq '1757132' or nam eq '1808347' or nam eq 'hd180609'	$; A
	   or nam eq '10lac' or nam eq 'mucol' or nam eq 'ksi2ceti'	$
	   or nam eq 'bd02d3375' or nam eq 'bd21d0607' 			$;Schmid
	   or nam eq 'bd26d2606' or nam eq 'bd29d2091'			$;Bessel
	   or nam eq 'bd54d1216' or nam eq 'hd009051' or nam eq 'hd031128' $
	   or nam eq 'hd074000' or nam eq 'hd111980' or nam eq 'hd160617'  $
	   or nam eq 'hd185975' or nam eq 'hd200654' or nam eq 'lamlep'	$
	   or nam eq 'wd1327_083' or nam eq 'wd2341_322'		$
; no model no edits needed:	 or strpos(nam,'sdss') eq 0		$
	   or nam eq '109vir' or nam eq '16cygb' or nam eq '18sco'	$ ;15485
	   or nam eq 'delumi' or nam eq 'eta1dor' or nam eq 'etauma'    $
	   or nam eq 'hd101452' or nam eq 'hd115169' or nam eq 'hd128998'  $
	   or nam eq 'hd142331' or nam eq 'hd167060' or nam eq 'hd2811' $
	   or nam eq 'hd55677'						$
	   						then targcase='gstis'
; clump of JWST mostly A stars w/ STIS and Nicmos-2011Dec22. + some WFC3-2018
; Exclude C26202 w/ only WFC3 G141. Put under targcase='c26202'
; Exclude P330e w/ FOS. Put under targcase='p330e':
; Exclude g191 w/ IUE @ short WL. Put under targcase='g191b2b'
; ###change
	if nam eq 'hd165459' or nam eq '1732526' or nam eq '1812095' or	$
	   nam eq '1740346' or nam eq '1812524' or nam eq 'kf06t2' or	$
	   nam eq '1743045' or nam eq '1802271' or nam eq '1805292' or	$
	   nam eq 'kf08t3' or nam eq 'gd153' or nam eq 'gd71' or	$ ;18nov
	   nam eq '2m003618' or nam eq '2m055914' or			$ ;18nov
	   nam eq 'grw_70d5824' or nam eq 'snap2' or			$ ;18nov
	   nam eq 'vb8' or nam eq 'wd1657_343'				$ ;18nov
	   						then targcase='stisnic'

	nichd=''  &  hder=''  &  nicfile=''
	file=filelist(ifile)
	if strpos(dir,'nical') ge 0 then begin			; nicmos data
		nicfile=file
		tmp=replace_char(nam,'+','_')
; del?		if strpos(tmp,'wd') lt 0 then tmp=replace_char(tmp,'_','')
; STIS file:
		if strpos(nicfile,'snap') ge 0 then fdecomp,nicfile,disk,dir,tmp
		if tmp eq 'g191b2b' then tmp='g191'
		file=findfile('../stiscal/dat/'+tmp+'.mrg')  &  file=file(0)
; file='' means no STIS, NICMOS only. 2011Dec-only true for 1812524,etc.
		if nam eq 'bd_17d4708' then file='../stiscal/dat/bd17d4708.mrg'
		endif
; Read Nicmos input file
	if nicfile ne '' then begin
		instrum='NICMOS'
		print,'NICMOS file=',nicfile
		rdfhdr,nicfile,0,nic,nichd
		nichd=nichd(where(strpos(nichd,'WAVELENGTH') lt 0))
		gd1=where(strpos(nichd,'nicreduce') ge 0)
		nichd=[nichd(gd1(0)),nichd(where(strpos(nichd,'.pro') lt 0))]
		wold=nic(*,0)*1e4 
		fold=nic(*,2)
		errold=nic(*,3)
		sysold=fold*0.02
		exold=nic(*,8)
		epold=fold*0+1
		npts=n_elements(wold)
		fwold=(wold(1:npts-1)-wold(0:npts-2))*4 	;/double
		fwold=[fwold(0),fwold]
		if file eq '' then goto,sun	; NO STIS, eg NICMOS only
		endif
		
; Read STIS input file
;
	print,'STIS file=',file
	rdfhdr,file,0,x,header
;remove dup lines (rem_dup does not take first occurance, as advertised)
	header=header(where(header ne ''))
	nhd=n_elements(header)  &  flag=nhd-indgen(nhd)
	good=rem_dup(strmid(header,0,22))
	hder=header(good(sort(good)))
	good=where(strpos(hder,'WAVELENGTH') lt 0 and strpos(hder,	$
			'=    0.0') lt 0)	; remove WL & zero merge pt
	hder=hder(good)
	good=where(strpos(hder,'G750L') ge 0)  &  good=good(0)
	if filespec eq 'vega' then hder=hder(0:good-1)	;G750L not used for vega

	if strpos(target,'SUN-TH') ge 0 then goto,sun
	wave=x(*,0)
	flux=x(*,2)
; trim noise off end of G230LB when flux is low:
	good=indgen(n_elements(wave))
	if min(wave) gt 1660 and min(wave) lt 1700 then begin
		if avg(flux(0:20)) lt 1e-12 then good=where(wave ge 1710)
;		plot,wave,flux,xr=[1650,2000]
;		read,st
		endif
	if target eq '2M0036+18' then good=where(wave gt 5262)	; ELIM bad pt
	if target eq '2M0559-14' then good=where(wave gt 5300)	; ELIM noise
	wave=x(good,0)
	flux=x(good,2)
	sterr=x(good,3)
	syerr=x(good,4)
	exptime=x(good,6)
	dataqual=x(good,7)
	nwav=n_elements(wave)
	fwhm=wave(2:nwav-1)-wave(0:nwav-3)
	fwhm=[fwhm(0),fwhm,fwhm(nwav-3)]	; stis resol=2px
; Vband avg flux
	vstis=0
	if wave(0) lt 5000 and max(wave) gt 6000 then begin
		Vstis=tin(wave,flux,5000,6000)
		n5000=fix(ws(wave,5000))	; fix for stars w/ gap
		if wave(n5000) ge 4990 then 				$
			print,'Mean 5000-6000A STIS flux=',vstis
		endif
; IR avg flux
	if wave(0) lt 7000 and max(wave) gt 8000 then begin	; 00dec27
		Istis=tin(wave,flux,7000,8000)
		print,'Mean 7000-8000A STIS flux=',Istis
		endif
;
; create binary .fits files (ref: rampfits.pro & abscorsig.pro)
;
	wcutlo=0.			; initialize for HD93521
	wcut=fix(min(wave))		; for cases of STIS only
	fdecomp,file,disk,dir,dumnam,ext

sun:					; Sun or NO STIS
	hd = ['END     ']
	sxaddpar,hd,'simple','T'
	sxaddpar,hd,'bitpix',16
	sxaddpar,hd,'naxis',0
	sxaddpar,hd,'extend','T','FITS extensions present?'
; 10feb9-new rules! See http://www.stsci.edu/hst/observatory/crds/documents
;		/TIR-CDBS-2009-01A.pdf, ie 67 char and 53 w/i ticks:
        sxaddpar,hd,'targetid',target
	if strpos(target,'SUN') ge 0 then stop	; & fix to 67 char:
;			sxaddpar,hd,'descrip',target+' Solar Flux w/'
        sxaddpar,hd,'dbtable','CRSPECTRUM'
	sxaddpar,hd,'mapkey','calspec'		; 2014Jul21 for Rossy
 	sxaddpar,hd,'airmass',0.0,'Mean airmass of the observation'
	sxaddpar,hd,'source','Flux scale of Bohlin, et al.2014, PASP, 126, 711'
	sxaddpar,hd,'USEAFTER','Jan 01 2000 00:00:00'
	sxaddpar,hd,'comment',						$
		"= 'HST Flux scale is based on Rauch WD NLTE MODELS' /"
;	sxaddpar,hd,'PEDIGREE','INFLIGHT 30/06/2003 23/08/2003'	; vega
	sxaddpar,hd,'PEDIGREE','INFLIGHT 18/05/1997 31/12/2019'	;STIS brth-death
;	sxaddpar,hd,'PEDIGREE','INFLIGHT 13/07/2001 27/12/2002'		; LDS
;	sxaddpar,hd,'PEDIGREE','INFLIGHT 22/11/2010 23/11/2010'		; wd-308
;	sxaddpar,hd,'PEDIGREE','INFLIGHT 13/02/1998 13/02/1998'	; eta UMa	
	
; add old history
;
	if target ne 'SUN_REFERENCE' then sxaddhist,[hder,nichd],hd
;
; add some more keyword information
	if nichd(0) ne '' then sxaddhist,'',hd			; blank line
	sxaddhist,'Units: Angstroms(A) and erg s-1 cm-2 A-1',hd
        sxaddhist,' All wavelengths are in vacuum.',hd
	sxaddhist,' Written by MAKE_STIS_CALSPEC.pro  '+strmid(!stime,0,11),hd
	sxaddhist,' Sources for this spectrum:',hd
	sxaddhist,'----------------   ----------------------   ----------',hd
	sxaddhist,'WAVELENGTH RANGE         SOURCE                FILE',hd
        sxaddhist,'----------------   ----------------------   ----------',hd
; MAKE NICMOS only cases:
	if file eq '' then begin		; NO STIS
;1812524 is a dbl star & the only A* w/ just NICMOS
		wave=wold  &  flux=fold  &  sterr=errold
		syerr=sysold  &  exptime=exold
		dataqual=epold  &  fwhm=fwold
	      	sxaddhist,string(min(wave),max(wave),instrum,  $
					nam+'.'+ext,form=wlsrc),hd

; skip this section, unless I want to add a model to NICMOS only SED.
		goto, nicnorm				;Nicmos only-rarely used

		modl='../calspec/'+nam+'_mod_001.fits'
		print,'Reading Model file:',modl
		ssreadfits,modl,modhd,wave,flux		;NICMOS only 
		modhd=modhd[where(strpos(modhd,'Model') ge 0)]
		modhd=sxpar(modhd,'history')
		good=where(wave ge 912)
		wave=wave(good)  &  flux=flux(good)
		syerr=.05*flux				; 5% model error
		bad=where(wave lt 3700)
		syerr(bad)=flux(bad)*.8			;80% ERR @ >3700A
		sterr=flux*0
		exptime=flux*0
		dataqual=exptime+1
		nwav=n_elements(wave)
		fwhm=wave(1:nwav-1)-wave(0:nwav-2)
		fwhm=[fwhm(0),fwhm]
		wcut=8020
stop	;revise as needed for BOSZ models
		sxaddhist,string(min(wave),wcut,'CK04 Model',	$
				nam+'_mod_001.fits',form=wlsrc),hd
		plot,wave,flux,xr=[.95*wcut,1.05*wcut]
		oplot,wold,fold,thic=2
		oplot,[wcut,wcut],[0,1000]
		read,st 		       
; NICMOS + CK04 short WLs
		pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,  $
		       		fwhm,wold,fold,errold,sysold,exold,epold,fwold
		wcut=24700
		sxaddhist,string(8020,wcut,'NICMOS', $
						nictarg+'.mrg',form=wlsrc),hd
		plot,wave,flux,xr=[.95*wcut,1.05*wcut]
		oplot,wold,fold,thic=2
		oplot,[wcut,wcut],[0,1000]
		read,st 		       
; Cohen short WLs + NICMOS + CK04 long WLs:
		pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
		sterr=float(sterr)
			sxaddhist,string(wcut,max(wave),'CK04 Model', $
			nam+'_mod_001.fits',form=wlsrc),hd
		sxaddhist,modhd,hd
		goto,nicnorm			
		endif

; ########################### end NICMOS only  ####################
; make spectra. If there is NO targcase Match, then goto ELSE endcase near bott.
	help,nam,name,target,targcase
; ##################################################################

	case targcase of
		'SUN-THUILLIER': begin
			wold=x(*,0)*10			; nm ---> Ang
			fold=x(*,1)/10			; mWt ---> erg
			epold=fold*0+1
			sysold=fold*.02			; per ref.
			errold=fold*0
			exold=fold*0
			fwold=fold*0+10.
			rdf,'../calib/sun/fsunallp.1000resam251',1,d
			wave=d(*,0)*10
stop ; change to 40mic to match P*s and  hd209458?
			good=where(wave le 300000.)	; trim at 30microns
			wave=wave(good)  &  d=d(good,*)
			flux=d(*,1)
; norm model to Thuil data
			wcut=12500
			wcut=23840			; end of Thuillier
			norfac=2.71752e-05
			norfac=2.71752e-05*1.03		; norm at 2.4mic

			flux=flux*norfac
		stop	; & fix to 67 char:
;	        	sxaddpar,hd,'descrip','Measured Sun with '+	$;Thuill
;				string(wcut/1e4,'(f3.1)')+' to 30 '+	$
;				'micron model extension'
		       sxaddhist,string(min(wold),wcut,'Thuillier et al. 2003',$
				filespec,form=wlsrc),hd
			sxaddhist,string(wcut,300000,'Kurucz 2004 Model',  $
				'fsunallp.1000resam251',form=wlsrc),hd
			sxaddhist,!mtitle,hd
			sxaddhist,'Kz Model normalized to obs by '+	$
				string(norfac,'(e10.3)'),hd
			sxaddhist,'Systematic Error set to 2%',hd
plot,wave,flux,xr=[.95*wcut,1.05*wcut]
oplot,wold,fold,thic=2
oplot,[wcut,wcut],[0,1000]
plotdate,'make_stis_calspec'
read,st			
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			fwhm=wave/1000			; R=1000 smoothed model
			dataqual=flux*0+1
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			name='sun_thuil+kz'+string(wcut/10,'(i4)')+'_001.fits'
			goto,sunskip
			end
			
		'SUN_REFERENCE': begin
stop ; 05jan5 & fix wl scale of solar data, at least the 8A error in the 
;		4100-8700A segment as doc in the Nicmos (red) book (w/o plot.)
			rdf,'DISK$DATA11:[BOHLIN.NICMOS]SUN_REFERENCE.ASCII', $
; 09mar24-above file seems lost but is ~same as new Kurucz (2004) over the
;	9600-26950A range in sun_reference_stis_001.fits
								1,d
			wave=d(*,0)  &  flux=d(*,1)
			airtovac,wave  &  wave=float(wave)	;dbl prec - NG
			dataqual=flux*0+1
			syerr=flux*.04			; gross simplification
			sterr=flux*0+!values.f_nan	; Nulls
			exptime=flux*0+!values.f_nan	; Nulls
			fwhm=flux*0+10.
			indx=where(wave gt 8700)  &  fwhm(indx)=20.
			indx=where(wave gt 25000.)  &  fwhm(indx)=100.
			sxaddpar,hd,'source',				$
			    'Bohlin, Dickinson, & Calzetti 2001, AJ, 122, 2118'
			sxaddpar,hd,'comment',	$
			    "= 'Colina, Bohlin, & Castelli 1996,AJ,112,307' /"
			sxaddhist,string(1195,4100,'Woods et al. 1996',	$
				'SUN_UV',form=wlsrc),hd
			sxaddhist,string(4100,8700,'Neckel & Labs 1984',$
				'SUN_NL84',form=wlsrc),hd
			sxaddhist,string(8700,9600,'Arvesen et al. 1969',$
				'SUN_ARVESEN',form=wlsrc),hd
			sxaddhist,string(9600,26950,'Model',		$
				'SUN_CASTELLI',form=wlsrc),hd
			goto,sunskip
			end

		'ALPHA_LYR': begin
; 2012Apr3-ff .tab file is the same as /grp/hst/cdbs/calspec/alpha_lyr_004.fits,
;	so I could just use the CDBS one. Sim for calobs, where my .tab files
;	are NOT converted & will not read.
			ssread,'alpha_lyr_004.tab',wold,fold,errold, $
					hdold,fwold,sysold,epold,exold,/epsfx
; 2013sep21 - 1.05 --> 1.06
; 2014feb25 - compute factor norm
			norm=tin(wave,flux,1680,1800)/			$
					tin(wold,fold,1680,1800) ; IUE fix
			fold=fold*norm		;norm iue to stis
			sysold=sysold*norm	;norm iue to stis
			errold=errold*norm	;norm iue to stis
			bad=where(wold lt 1230 and wold gt 1200)
			fold(bad)=0.				; Ly-alpha
			wcut=1675				; 03jan6
			sxaddpar,hd,'source2',				$ ; vega
			    'Bohlin & Gilliland 2004, AJ, 127, 3508',	$
			    after='source'
;			sxaddpar,hd,'source3',				$
;			    'Bohlin 2007, ASP Conf. Series 364, p.315,'+$
;			    ' ed. C. Sterken',after='source2'	; new vega
			sxaddhist,'  900    1152       9550K Model    '+ $
				'         vegamod_r500.344kur9550',hd
			sxaddhist,string(1152,wcut,'IUE',	$
				'ALPHA_LYR_004.tab',form=wlsrc),hd
			sxaddhist,string(wcut,10200,'STIS',	$
				'hd172167.mrg',form=wlsrc),hd
; 09jan7 - fix WMAX in WL range list to actual value:
; 2019jan		sxaddhist,string(5350,2999537,'9400K Model',+ 	$
;				'vegamod_r500.05kur9400',form=wlsrc),hd
			sxaddhist,string(10200,2993861,'9550K Model',+ 	$
				'vegamod_r500.344kur9550',form=wlsrc),hd
			sxaddhist,' IUE fluxes increased by'+		$
				string(norm,'(f5.2)')+' in '+		$
				'MAKE_STIS_CALSPEC.pro  '+strmid(!stime,0,11),hd
			sxaddhist,'Kz Model Normalized to 3.44e-9 at 5556A',hd
plot,wold,fold,xr=[1600,1900],thic=2+5*(!d.name eq 'PS'),yr=[4e-9,8e-9]	; IUE
oplot,wave,flux,thic=0							; stis
oplot,[wcut,wcut],[0,1e-8]
read,st
; 06aug10 - 1. NO eps=0 flags at motes. 
;	    2. Should be ~no mote dips, in wide saturated spectra.
; IUE+STIS:
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
; ff model norm to Meggessier 3.46e-9 @ 5545-5570A vac WL
;			rdf,'../calib/vega/vegamod_r500.05kur9400',1,dkur
;			wold=dkur(*,0)
;			fold=dkur(*,1)
; 2014 feb - ff Kz special 9400K model norm to STIS at 5300-5400A to avoid
;	discont at5350A cutoff. 6800-7700A norm makes 0.5% too low for vegadust.
; ###change, if Vega changes:
			ssreadfits,'deliv/alpha_lyr_mod_004.fits',h,wold,fold
; 2014dec31 - change from 5300-5400 to 5556A norm:
			mnwl=5557.54-12.5  &  mxwl=5557.54+12.5
			norm=3.44e-9/tin(wold,fold,mnwl,mxwl)
			fold=fold*norm		;norm model to 3.44e-9
			errold=fold*0
			sysold=fold*0.01
			exold=fold*0
			epold=fold*0+1
			fwold=wold/500.
			wcut=10200			; 19jan - was 5350
plot,wold,fold,xr=[.96*wcut,1.04*wcut]				; Model
oplot,wave,flux,thic=2						; Stis
oplot,[wcut,wcut],[0,1e-8]
;plotdate,'make_stis_calspec'
read,st
; IUE + STIS + Model
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wold,fold,errold,sysold,exold,epold,fwold
; 04feb24 - add model below where IUE is NG. 9400k model NG. use hotter 9550K:
; 2019jan22 - could use above alpha_lyr_mod_003, which is now 9550K
			rdf,'../calib/vega/vegamod_r500.344kur9550',1,dkur
			norm=tin(wold,fold,1300,1400)/			$
				tin(dkur(*,0),dkur(*,1),1300,1400) ; IUE fix
			wave=dkur(*,0)
			flux=dkur(*,1)*norm
			sterr=flux*0
			syerr=flux*0.01
			exptime=flux*0
			dataqual=flux*0+1
			fwhm=wave/500.
			wcut=1152
plot,wold,fold,xr=[.96*wcut,1400]			; iue
oplot,wave,flux,thic=2					; model
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
read,st
;hprint,hd
; Model + IUE + STIS + Model
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wold,fold,errold,sysold,exold,epold,fwold
; Reverse names for case w/ old data used at longest WL
			wave=wold  &  flux=fold  &  sterr=errold  & syerr=sysold
			exptime=exold  &  dataqual=epold  &  fwhm=fwold
			end
		'AGK+81D266': begin
			ssread,'agk_81d266_005.tab',wiue,fiue,erriue, $
					hdiue,fwiue,sysiue,epiue,exiue,	      $
; /epsfx converts to dataqual, good=1; and erriue to flux instead of frac.
					/epsfx		;,magfx=0.008
			wcut=1685		; from stdstis.pro
; IUE + STIS
			sxaddhist,string(min(wiue),wcut,'IUE',		$
				'AGK_81D266_005',form=wlsrc),hd
			pastem,wcut,wiue,fiue,erriue,sysiue,exiue,epiue,fwiue, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			wcut=10187
			sxaddhist,string(1685,wcut,'STIS', $
				nam+'.mrg',form=wlsrc),hd
			goto,iuestisnic
			end
		'BD+17D4708': begin
; IUE flux=0 at 1700A and below, so STIS must have some red leak. cut at 1701A:
			good=where(wave ge 1701)
			wold=wave(good)  &  fold=flux(good)
			errold=sterr(good)  &  sysold=syerr(good)
			exold=exptime(good)  & epold=dataqual(good)
			fwold=fwhm(good)
; set 3 of 4 bad DQ regions to good, (tho @1965, there is a bump)
; @6335A, there is a suspicious ~2% dip, but might be real, Vega model has a
;	nearby feature. Leave 6335A as flagged.
			good=where((wold lt 6000) or wold gt 8000)
			epold(good)=1
; STIS + NICMOS
			instrum='NICMOS'  &  nam='bd+17d4708'
			rdf,'../nical/spec/bd+17d4708.mrg',1,d
; trim suspicious plateau from 2.482-2.499mic
			good=where(d(*,0) le 2.482)  &  d=d(good,*)
			wave=d(*,0)*1e4  &  flux=d(*,2)  &  sterr=d(*,3)
			syerr=flux*0.02  &  exptime=d(*,8)  &  dataqual=flux*0+1
			npts=n_elements(wave)
			fwhm=(wave(1:npts-1)-wave(0:npts-2))*4		;/double
			fwhm=[fwhm(0),fwhm]
			wcut=10160
plot,wold,fold,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
		sxaddpar,hd,'source2','Bohlin & Gilliland 2004, AJ, 128, 3053'
		sxaddhist,string(1701,wcut,'STIS', $
				'bd17d4708.mrg',form=wlsrc),hd
			end
		'BD28D4211': begin
			ssread,'bd_28d4211_fos_003.tab',wold,	$
				fold,errold,hdold,fwold,sysold,epold,exold,   $
					/epsfx,/okefx		;,magfx=0.008
		indx=where(wold ge 4664.3 and wold le 4749.3)	;vac
			epold(indx)=1		; no problem at oke red-blu join
			wcut=5322		; from blowup plot
; FOS,Oke + STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
; Process header
; get 3 lines of old data sources
		        ndx=where(strmid(hdold,0,7) eq 'HISTORY',numhist)
		        if numhist gt 0 then hdold(ndx)=strmid(hdold(ndx),8,71)
			ndx=where(strpos(hdold,'WAVELENGTH RANGE') ge 0)
			ndx=ndx(0)
			for i=ndx+1,ndx+3 do sxaddhist,			$
				string([strtrim(hdold(i),2),		$
				'BD_28D4211_fos_003'],'(1x,a,t45,a)'),hd
			sxaddhist,string(3875,wcut,'OKE CORR TO FOS FLUX',    $
				 'BD_28D4211_fos_003',form=wlsrc),hd
			end
		'BD75': begin
			ssread,'bd_75d325_fos_003.tab',wold,	$
				fold,errold,hdold,fwold,sysold,epold,exold,   $
					/epsfx		;,magfx=0.008
			wcut=1785
			sxaddhist,string(min(wold),wcut,'FOS BLUE',	$
				'BD_75D325_FOS_003',form=wlsrc),hd
; FOS + STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			end
		'BPM16274': begin
			ssread,'disk$data11:[BOHLIN.CALOBS]bpm16274_004.tab',  $
				wold,fold,errold,hdold,fwold,sysold,epold,     $
				exold,/epsfx		;,magfx=0.008
			wcut=1950
			sxaddhist,string(min(wold),wcut,'IUE',	$
				'BPM16274_004',form=wlsrc),hd
; IUE + STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			end
		'ETAUMA': begin
			ssreadfits,'/grp/hst/cdbs/calobs/eta_uma_015.fits',  $
				hdiue,wiue,fiue,erriue,sysiue,epiue,exiue,fwiue
			epiue=epiue*0+1.	;good=1, orig. all epiue=100
			wcut=1670
			sxaddhist,string(1148,wcut,'IUE',		$
				'eta_uma_015.fits',form=wlsrc),hd
plot,wiue,fiue,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2,psym=-4
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
; IUE + STIS
			pastem,wcut,wiue,fiue,erriue,sysiue,exiue,epiue,fwiue, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			good=where(wave ge 1148)
			wave=wave(good)
			flux=flux(good)
			sterr=sterr(good)
			syerr=syerr(good)
			exptime=exptime(good)
			dataqual=dataqual(good)
			fwhm=fwhm(good)
			end
		'FEIGE110': begin
			ssread,'feige110_005.tab',wtab,	$
				ftab,errtab,hdtab,fwtab,systab,eptab,extab,   $
					/epsfx		;,/okefx,magfx=0.008
			wcut=1670
			sxaddhist,string(min(wtab),wcut,'IUE',	$
				'feige110_005',form=wlsrc),hd
; (IUE + STIS)
plot,wave,flux,xr=[.95*wcut,1.05*wcut],psym=-4		; stis
oplot,wtab,ftab,th=2,psym=-6				; square IUE
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			pastem,wcut,wtab,ftab,errtab,systab,extab,eptab,fwtab, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			wcut=10000
			sxaddhist,string(1670,wcut,'STIS', $
				nam+'.mrg',form=wlsrc),hd
			goto,iuestisnic
			end
		'FEIGE34': begin
			ssread,'feige34_005.tab',wold,			$
				fold,errold,hdold,fwold,sysold,epold,exold,   $
					/epsfx		;,/okefx,magfx=0.008
; scale up IUE:
			iuefix=tin(wave,flux,1680,1800)/		$
						tin(wold,fold,1680,1800)
			fold=fold*iuefix
			print,'IUE scale factor=',iuefix
			wcut=1670
			sxaddhist,string(min(wold),wcut,'IUE',		$
				'feige34_005',form=wlsrc),hd
plot,wave,flux,xr=[.95*wcut,1.05*wcut],psym=-4		; stis
oplot,wold,fold,th=2,psym=-6				; square IUE
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
; IUE + STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			end
		'G191B2B': begin		; 00jul31
;FOS needs -.5A shift at 1216 & 1140-2085 is FOS blue. MgII 2800 (red) ok to 1A.
			ssread,'g191b2b_fos_003.tab',wold,		$
				fold,errold,hdold,fwold,sysold,epold,exold,   $
					/epsfx		; 06mar24 ,magfx=0.008
			bad=where(wold le 2085)
			wold(bad)=wold(bad)-0.5			; 06mar27
; but this WL shift makes FOS flux too low, so renorm.
			corfac=tin(wave,flux,1700,2050)/tin(wold,fold,1700,2050)
			fold(bad)=fold(bad)*corfac
			wcut=1674		; 18nov was 1680
			sxaddhist,string(min(wold),wcut,'FOS',	$
				'G191B2B_FOS_003',form=wlsrc),hd
; FOS + STIS
plot,wold,fold,xr=[.95*wcut,1.05*wcut]		; FOS
oplot,wave,flux,thic=2				; STIS
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			wcut=8400		; WFC3 2018nov was 10180
			sxaddhist,string(1674,wcut,'STIS','G191.MRG',	$
								form=wlsrc),hd
; +WFC3:
			rdf,'../wfc3/spec/g191b2b.mrg',1,d
			wwfc=d(*,0)
			fwfc=d(*,2)
			stwfc=d(*,3)
			sywfc=d(*,4)
			exwfc=d(*,6)
			dqwfc=d(*,7)
			fwwfc=wwfc(2:-1)-wwfc(0:-3)
			fwwfc=[fwwfc(0),fwwfc,fwwfc(-1)]	; 2px
plot,wave,flux,xr=[.95*wcut,1.05*wcut],psym=-4		; stis
oplot,wwfc,fwfc,thic=2,psym=-6				; square WFC3
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wwfc,fwfc,stwfc,sywfc,exwfc,dqwfc,fwwfc
			wcut1=16590
			sxaddhist,string(wcut,wcut1,'WFC3',nam+'.'+ext,   $
				form=wlsrc),hd
			
; FOS + STIS +wfc3 + NICMOS:
			rdf,'../nical/spec/g191b2b.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;/double
			fwold=[fwold(0),fwold]
plot,wold,fold,xr=[.95*wcut1,1.05*wcut1],psym=-6		;nic
oplot,wwfc,fwfc,psym=-4						;wfc3
oplot,[wcut1,wcut1],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
		       pastem,wcut1,wwfc,fwfc,stwfc,sywfc,exwfc,dqwfc,fwwfc, $
				   wold,fold,errold,sysold,exold,epold,fwold
			good=where(epold ge 1 or wold lt 3450 or 	$
				wold gt 7000 or (wold gt 4750 and wold lt 4850))
			epold(good)=1
; Reverse names for case w/ old data used at longest WL & elim bad for 3 WDs:
			wcut=wcut1			; sxaddhist below
			wave=wold &  flux=fold
			sterr=errold  & syerr=sysold
			exptime=exold  &  dataqual=epold
			fwhm=fwold
			teff=0
			end
		'GJ7541A': begin
			wcut=10115
			sxaddhist,string(min(wave),wcut,'STIS','GJ7541A.MRG', $
								form=wlsrc),hd
			wold=wave  &  fold=flux  &  errold=sterr  & sysold=syerr
			exold=exptime  &  epold=dataqual  &  fwold=fwhm
; STIS + Koester Model
			readcol,'../calib/bessell/models/EG131_RB.dk',wave,flux
; normalize model to stis from 7000-8000A:
			norfac=tin(wold,fold,7000,8000)/tin(wave,flux,7000,8000)
			print,'Koester model mult by ',norfac
			flux=flux*norfac
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			dataqual=flux*0+1
			npts=n_elements(wave)
			fwhm=(wave(1:npts-1)-wave(0:npts-2))
			fwhm=[fwhm(0),fwhm]
plot,wold,fold,xr=[.96*wcut,1.04*wcut]				; Stis
oplot,wave,flux,thic=2						; Model
oplot,[wcut,wcut],[0,9e-8]
if !d.name eq 'X' then read,st
			sxaddhist,string(wcut,max(wave),'Koester Special '+   $
				'Model','EG131_RB.dk',form=wlsrc),hd
			sxaddhist,'Normalized to Obs. Flux at 7000-8000A',hd
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			dataqual=dataqual*0+1		; all motes w/i noise
			wcut=-1				; flag to omit below
			end
		'HD209458': begin
			wcut=10140
			wcut2=24920
			sxaddhist,string(min(wave),wcut,'STIS','HD209458.MRG', $
								form=wlsrc),hd
			sxaddhist,string(wcut,wcut2,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
; STIS + NICMOS
			instrum='NICMOS'  &  nam='hd209458'
			rdf,'../nical/spec/hd209458.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;/double
			fwold=[fwold(0),fwold]
plot,wold,fold,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				   wold,fold,errold,sysold,exold,epold,fwold
			wcut=wcut2
; STIS + Nicmos + Model
			rdf,'../rocket/stds/hd209458-500.kz',1,k  ; kurucz
			wave=k(*,0)*10			; nm-->Ang
			flux=k(*,1)
; normalize model to stis from 7000-8000A:
			norfac=tin(wold,fold,7000,8000)/tin(wave,flux,7000,8000)
			print,'Kurucz model mult by ',norfac
			flux=flux*norfac
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			dataqual=flux*0+1
			fwhm=wave/500.
plot,wold,fold,xr=[.96*wcut,1.04*wcut],yr=[6e-14,9e-14]	; Stis
oplot,wave,flux,thic=2						; Model
oplot,[wcut,wcut],[0,9e-8]
if !d.name eq 'X' then read,st
			sxaddhist,string(wcut,max(wave),'Kurucz Special '+   $
				'Model','hd209458-500.kz',form=wlsrc),hd
			sxaddhist,'Normalized to Obs. Flux at 7000-8000A',hd
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			indx=where(wave ge 8590 and wave le 8675)	;vac
			dataqual(indx)=1		; Line at dust mote
			wcut=-1				; flag to omit below
			end
		'HD60753': begin
			ssreadfits,'/grp/hst/cdbs/calobs/hd60753_004.fits',  $
				hdiue,wiue,fiue,erriue,sysiue,epiue,exiue,fwiue
			epiue=epiue*0+1.	;good=1, orig. all epiue=100
			wcut=1672
			sxaddhist,string(1148,wcut,'IUE',		$
				'hd60753_004.fits',form=wlsrc),hd
plot,wiue,fiue,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
; IUE + STIS
			pastem,wcut,wiue,fiue,erriue,sysiue,exiue,epiue,fwiue, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			good=where(wave ge 1148)
			wave=wave(good)
			flux=flux(good)
			sterr=sterr(good)
			syerr=syerr(good)
			exptime=exptime(good)
			dataqual=dataqual(good)
			fwhm=fwhm(good)
			end
		'HD93521': begin		; 00jul31
			ssread,'hd93521_005.tab',wold,	$
				fold,errold,hdold,fwold,sysold,epold,exold,   $
					/epsfx		;,magfx=0.008
; Fix the problem w/ the IUE LWP+LWR errold:
			rdf,'../iueupdate/iue3',0,lwp
			rdf,'../iueupdate/iue8',0,lwr
			err1=lwp(*,7)>.03  &  err2=lwr(*,7)>.03
			exptim1=lwp(*,6)  &  exptim2=lwr(*,6)
			sig1=err1/((74*exptim1/max(exptim1))^.25)  ; err in mean
			sig2=err2/((118*exptim2/max(exptim2))^.25) ; err in mean
			w1=1/sig1^2  &  w2=1/sig2^2  &  wtot=w1+w2
			erravg=(w1*err1+w2*err2)/wtot
			good=where(lwp(*,0) gt 1970 and lwp(*,0) le 3200)
			bad=where(wold gt 1970 and wold le 3200)
			errold(bad)=erravg(good)/(74+118.)^.25		;fixed

; scale up IUE:
			iuefix=tin(wave,flux,1680,1800)/		$
						tin(wold,fold,1680,1800)
			fold=fold*iuefix
			print,'IUE scale factor=',iuefix
			wcut=1680.			; IUE monitor star
; (IUE + STIS)
plot,wave,flux,xr=[.95*wcut,1.05*wcut],psym=-4		; stis
oplot,wold,fold,th=2,psym=-6				; square IUE
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			sxaddhist,string(min(wold),wcut,'IUE',	$
				'HD93521_005',form=wlsrc),hd
; IUE + STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			indx=where(wave ge 8601 and wave le 8680)	;vac
			dataqual(indx)=1		; Line at dust mote
			wcutlo=wcut
			goto,gstis			; to add model
			end
		'HZ43': begin		; 00Oct10
			ssread,'hz43_fos_003.tab',wold,	$alpha_lyr_stis_006
				fold,errold,hdold,fwold,sysold,epold,exold,   $
					/epsfx		;,magfx=0.008
			wcut=5450		; G750L only
			wcut=1700		; 2012Aug27
			sxaddhist,string(min(wold),wcut,'FOS',	$
				'HZ43_FOS_003',form=wlsrc),hd
; remove irrelevant header lines about G230LB & 430L:
;			nhd=n_elements(hd)-1
;			indx=where(strpos(hd,'G230LB:') gt 0)  &  indx=indx(0)
;			hd=[hd(0:indx-1),hd(indx+2:nhd)]
;			nhd=n_elements(hd)-1
;			indx=where(strpos(hd,'G430L:') gt 0)  &  indx=indx(0)
;			hd=[hd(0:indx-1),hd(indx+4:nhd)]
; FOS + STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			end
		'HZ44': begin
			ssread,'hz44_fos_003.tab',wold,	$
				fold,errold,hdold,fwold,sysold,epold,exold,    $
				/epsfx	;,/okefx		; 1140-9292A
			wcut=1670
plot,wold,fold,xr=[.9*wcut,1.1*wcut]
oplot,wave,flux,thic=2,psym=-4
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			sxaddhist,string(1140,wcut,'FOS BLUE',	$
				'HZ44_FOS_003',form=wlsrc),hd
; FOS+ STIS
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			end
		'LAMLEP': begin
			ssreadfits,'/grp/hst/cdbs/calobs/lam_lep_003.fits',  $
				hdiue,wiue,fiue,erriue,sysiue,epiue,exiue,fwiue
			epiue=epiue*0+1.	;good=1, orig. all epiue=100
			wcut=1698
			sxaddhist,string(1148,wcut,'IUE',		$
				'lam_lep_003.fits',form=wlsrc),hd
plot,wiue,fiue,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
; IUE + STIS
			pastem,wcut,wiue,fiue,erriue,sysiue,exiue,epiue,fwiue, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			good=where(wave ge 1148)
			wave=wave(good)
			flux=flux(good)
			sterr=sterr(good)
			syerr=syerr(good)
			exptime=exptime(good)
			dataqual=dataqual(good)
			fwhm=fwhm(good)
			end
		'MUCOL': begin
			ssreadfits,'/grp/hst/cdbs/calobs/mu_col_006.fits',  $
				hdiue,wiue,fiue,erriue,sysiue,epiue,exiue,fwiue
			epiue=epiue*0+1.	;good=1, orig. all epiue=100
			wcut=1670
			sxaddhist,string(1148,wcut,'IUE',		$
				'mu_col_006.fits',form=wlsrc),hd
plot,wiue,fiue,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
; IUE + STIS
			pastem,wcut,wiue,fiue,erriue,sysiue,exiue,epiue,fwiue, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			good=where(wave ge 1148)
			wave=wave(good)
			flux=flux(good)
			sterr=sterr(good)
			syerr=syerr(good)
			exptime=exptime(good)
			dataqual=dataqual(good)
			fwhm=fwhm(good)
			end

; Stis (wave, etc) & Nicmos (wold, etc) initialized near top
; JWST stars w/ STIS and NICMOS wold-nicmos, wave-STIS & wfc3

		'stisnic': begin
			print,'stisnic case'
			wcut1=10160			; for NO wfc3
			instrum='NICMOS'  &  teff=0	; initialize
; mv up 2018nov7 - to cf. w. data;
			modl=1				; there is a model
			if strmid(nam,0,2) eq 'gd' or 			$
			   strmid(nam,0,3) eq 'grw' or strmid(nam,0,2) eq 'wd' $
				then modl=0	; NO model, but teff ne 0
			if modl then begin
				boszmodcor,nam,wave,flux,wmod,fmod,	$
						cont,ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
				wmod=wmod*(1+starvel(target)/3e5)
				endif
;
; INSERT WFC3 IR Grism SEDs HERE
;
			if strpos(name,'wfc') gt 0 then begin
				rdf,'~/wfc3/spec/'+nam+'.mrg',1,d
				wwfc=d(*,0)
				fwfc=d(*,2)
				stwfc=d(*,3)
				sywfc=d(*,4)
				exwfc=d(*,6)
				dqwfc=d(*,7)
				fwwfc=wwfc(2:-1)-wwfc(0:-3)
				fwwfc=[fwwfc(0),fwwfc,fwwfc(-1)]	; 2px
				wcut=9610	;1802271
				if target eq 'KF06T2' then wcut=9425
				if target eq 'SNAP-2' then wcut=9169
				if teff eq 0 then begin		; no model
; All Flagged GD71 & GD153 are OK: (others OK?)
				     dataqual=dataqual*0+1
				     wcut=8400		;gd153,gd71,grw
				     if target eq 'VB8' then wcut=10069
				     if target eq '2M0036+18' then wcut=10082
				     if target eq '2M0559-14' then wcut=9935
				     if target eq 'WD1657+343' then wcut=8000
				     endif		; end no model
plot,wave,flux,xr=[.95*wcut,1.05*wcut],psym=-4		; diam STIS
oplot,wwfc,fwfc,thic=2,psym=-6				; square WFC3
oplot,wold,fold,lin=1					; nic
if teff ne 0 then oplot,wmod,fmod,lin=2,th=4		; model
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
				sxaddhist,string(min(wave),wcut,'STIS',$
; 2018nov15 - odd names for some STIS & Nicmos, eg. snap-2 (was nam):
					strlowcase(target)+'.mrg',form=wlsrc),hd
; STIS+WFC3:
				pastem,wcut,wave,flux,sterr,syerr,exptime, $
					dataqual,fwhm,wwfc,fwfc,stwfc,	$
					sywfc,exwfc,dqwfc,fwwfc
				wcut1=16680		;1802271,vb8
				if target eq 'KF06T2' then wcut1=16570
				if target eq '2M0036+18' then wcut1=16420
				if target eq '2M0559-14' then wcut1=17095
				if target eq 'GD153' then wcut1=16900
				if target eq 'GD71' then wcut1=16570
				if target eq 'GRW+70D5824' then wcut1=16530
				if target eq 'SNAP-2' then wcut1=16440
				if target eq 'WD1657+343' then wcut1=16540
				sxaddhist,string(wcut,wcut1,'WFC3',	$
						nam+'.mrg',form=wlsrc),hd
				wave=wwfc &  flux=fwfc
				sterr=stwfc  & syerr=sywfc
				exptime=exwfc  &  dataqual=dqwfc
				fwhm=fwfc
			     end else 			$		;no-WFC3
				sxaddhist,string(min(wave),wcut1,'STIS',$
; 2018nov15 - odd names for some STIS & Nicmos, eg. snap-2 (was nam):
					strlowcase(target)+'.mrg',form=wlsrc),hd
; No Model case gets Nicmos WL range added after endcases.
			wcut=wcut1			; for teff=0 cases
			if teff eq 0 then goto,iuestisnic	$ ;No cool*model
					else instrum=''		; has a model
plot,wave,flux,xr=[.95*wcut1,1.05*wcut1],psym=-4	; diam STIS or WFC3
oplot,wold,fold,thic=2,psym=-6				; square nic
if teff ne 0 then oplot,wmod,fmod,lin=2,th=4		; model
oplot,[wcut1,wcut1],[0,1e-8]
if !d.name eq 'X' then read,st
; STIS+WFC3+Nicmos:
		      pastem,wcut1,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wold,fold,errold,sysold,exold,epold,fwold
			if teff eq 0 then goto,skipmod

			print,'A-STAR W/ STIS & NICMOS. TEFF,LOG g, LOG z,'+ $
				'E(B-V)= ',teff,logg,logz,ebv
			stmod=fmod*0
			symod=fmod*0.02
			expmod=fmod*0
			npts=n_elements(wmod)
; fwhm @ >10mic sort of OK because of Kz04 correction
			fwmod=(wmod(1:npts-1)-wmod(0:npts-2))
			fwmod=[fwmod(0),fwmod]
			qualmod=fmod*0+1
			wcut=24200		;1802271
; cannot cut shorter than 24000 because of findmin fitting bin ending there.
;			if strmid(target,0,2) eq 'KF' then wcut=22900
;			if target eq 'SNAP-2' then wcut=20580
			sxaddhist,string(wcut1,wcut,'NICMOS',		$
; 2018nov15 - odd names for some STIS & Nicmos, eg. snap-2 (was nam):
					strlowcase(target)+'.mrg',form=wlsrc),hd
			sxaddhist,string(wcut,max(wmod+1),		$
			  'Bohlin et al. 2017','BOSZ R=500 Model',form=wlsrc),hd
			sun='sun'			; flag used below
			sxaddhist,'BOSZ Model with Teff,log g,log z,E(B-V)='+  $
			    string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
			print,'Model to ',max(wmod),' for ',teff,logg,logz,ebv
plot,wmod,fmod,xr=[.95*wcut,1.05*wcut],psym=-6		; model sq
oplot,wold,fold,psym=-4					; wfc3 or nicmos diam
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st		; +model
		        pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wmod,fmod,stmod,symod,expmod,qualmod,fwmod
			wave=wmod
			flux=fmod
			sterr=stmod
			syerr=symod
			exptime=expmod
			dataqual=qualmod
			fwhm=fwmod
			indx=where(wave ge 8590 and wave le 8675)	;vac
			dataqual(indx)=1		; Line at dust mote
skipmod:
			end		; case of stisnic
		'gstis': begin		;G & OBA stars w/ no NICMOS, just STIS:
gstis:				; entry point for no wfc3 or nic, eg hd93521
			print,'gstis case'
			wcut=10120
; ###change
			if target eq '1808347' then wcut=10114
			if target eq 'WD2341_322' then wcut=9700
			if target eq 'BD02D3375' then wcut=10050
			if target eq 'BD21D0607' then wcut=10075
			if target eq 'BD29D2091' then wcut=10070
			if target eq 'BD54D1216' then wcut=10070
			if target eq 'HD031128' then wcut=10070
			if target eq 'HD074000' then wcut=10080
			if target eq 'HD160617' then wcut=10070
			wcutlo=max([min(wave),wcutlo])	    ; 2019aug eg hd93521
			print,'WCUTLO,WCUT=',wcutlo,wcut
			sxaddhist,string(wcutlo,wcut,'STIS',		$
					nam+'.mrg',form=wlsrc),hd
; STIS + Model
			if nam eq '10lac' or nam eq 'lamlep' or 	$
; 2018aug4-typo, stop & ck mucol change	nam eq '10lac' then begin
					nam eq 'mucol' then begin
stop ; ck mucol
			   lanzmodcor,nam,wave,flux,wmod,fmod,ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
			   wmod=wmod*(1+starvel(target)/3e5)
			   sxaddhist,string(wcut,max(wmod+1),		$
				'Lanz Model','Lanz grid',form=wlsrc),hd
			 end else begin
; cases to insert WFC3 data between stis and the model (if any):
			   if nam eq 'hd37725' or nam eq 'bd60d1753'	$
	   		   	or nam eq '1757132' or nam eq '1808347' $
	   		   	or nam eq 'wd1327_083' or nam eq 'wd2341_322' $
				then begin
				wfcfil=strlowcase(target)+'.mrg'
				rdf,'../wfc3/spec/'+wfcfil,1,d
				wwfc=d(*,0)
				fwfc=d(*,2)
				stwfc=d(*,3)
				sywfc=d(*,4)
				expwfc=d(*,6)
				dqwfc=d(*,7)
				fwwfc=2*(wwfc(1:-1)-wwfc(0:-2))
				fwwfc=[fwwfc,fwwfc(-1)]
plot,wwfc,fwfc,xr=[.95*wcut,1.05*wcut],psym=-6		;wfc3
oplot,wave,flux,psym=-4					;stis
oplot,[wcut,wcut],[0,1e-8]
		        	pastem,wcut,wave,flux,sterr,syerr,exptime,$
					dataqual,fwhm,wwfc,fwfc,stwfc,	$
					sywfc,expwfc,dqwfc,fwwfc
				wcutshrt=wcut
				wave=wwfc
				flux=fwfc
				sterr=stwfc
				syerr=sywfc
				exptime=expwfc
				dataqual=dqwfc
				fwhm=fwwfc
				oplot,wave,flux,th=3
				wcut=17160
				if target eq '1757132' then wcut=17080
				if target eq '1808347' then wcut=17127
				if target eq 'BD60D1753' then wcut=16910
				if target eq 'HD37725' then wcut=11350
				if !d.name eq 'X' then read,st
				endif
			   if strpos(nam,'wd') eq 0 then begin;WFC3 but no model
			   	wcut=17000			; ~safe good lim
			   	good=where(wave lt wcut)
				wave=wave(good)
				flux=flux(good)
				sterr=sterr(good)
				syerr=syerr(good)
				exptime=exptime(good)
				dataqual=dataqual(good)
				fwhm=fwhm(good)
				wcut=max(wave)
			   	sxaddhist,string(wcutshrt,wcut,		$
			  		'WFC3 IR grisms',wfcfil,form=wlsrc),hd
				goto,skipout			; no model
			     end else begin
			   	boszmodcor,nam,wave,flux,wmod,fmod,cont,$
			   				ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
				wmod=wmod*(1+starvel(target)/3e5)
;---- add to all model calls.
; 2019may31 - only add wfc3 history, if there are WFC3 data:
				if n_elements(wfcfil) gt 0 then 	$
			   	      sxaddhist,string(wcutshrt,wcut,	$
			  		'WFC3 IR grisms',wfcfil,form=wlsrc),hd
			   	sxaddhist,string(wcut,max(wmod),	$
			  		'Bohlin et al. 2017',		$
					'BOSZ R=500 Model',form=wlsrc),hd
				endelse			; end non-WDs
			   endelse			; end Lanz models
			print,nam,' W/ STIS only or STIS+WFC3. TEFF,LOG'+$
				' g, LOG z, E(B-V)= ',teff,logg,logz,ebv
			stmod=fmod*0
			symod=fmod*0.02
			expmod=fmod*0
			npts=n_elements(wmod)
			fwmod=(wmod(1:npts-1)-wmod(0:npts-2))
			fwmod=[fwmod(0),fwmod]
			qualmod=fmod*0+1
			sun='sun'			; flag used below
			sxaddhist,'Model with Teff,log g,log z,E(B-V)='+  $
			    string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
			print,'Model to ',max(wmod),' for ',teff,logg,logz,ebv
plot,wmod,fmod,xr=[.95*wcut,1.05*wcut],psym=-6			; model
oplot,wave,flux,psym=-4						; stis+wfc3
oplot,[wcut,wcut],[0,1e-8]
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wmod,fmod,stmod,symod,expmod,qualmod,fwmod
			wave=wmod
			flux=fmod
			sterr=stmod
			syerr=symod
			exptime=expmod
			dataqual=qualmod
			fwhm=fwmod
			indx=where(wave ge 8590 and wave le 8675)	;vac
			dataqual(indx)=1		; Line at dust mote
			oplot,wave,flux,thic=3
			if !d.name eq 'X' then read,st
			end				; case of gstis
; Faint Solar analogs 09oct6:
		'C26202': begin
; Do not make Stis cutoff <9400 when replacing w/ NICMOS, too many bins must be
;	excluded in findmin fitting. Nic is low, so cut at 10000, not 9400A
			wcut=10000  &  wcutlast=wcut	; 9400-10000 bin OK
			sxaddhist,string(min(wave),wcut,'STIS','C26202.MRG', $
								form=wlsrc),hd
; STIS + NICMOS
			instrum='NICMOS'
			rdf,'../nical/spec/'+nam+'.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;FWHM
			fwold=[fwold(0),fwold]
			boszmodcor,'c26202',wave,flux,wmod,fmod,cont,	$
							ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
			wmod=wmod*(1+starvel(target)/3e5)
plot,wave,flux,xr=[.95*wcut,1.05*wcut],psym=-4		; stis diam
oplot,wold,fold,psym=-6,th=2+5*(!d.name eq 'PS') 	; nicmos sq
oplot,wmod,fmod,lin=2,th=4				; model
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st		; stis+nicmos:
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				   wold,fold,errold,sysold,exold,epold,fwold

; insert WFC3 G141 here to make the stiswfcnic file:				   ; cut wfc3 G141 @ 10880-16190
;assume mod 10930A is real but weak & 50A off. Yes, P330E has sim. feature:
			wcut=10880 
			sxaddhist,string(wcutlast,wcut,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
			rdf,'../wfc3/spec/c26202.mrg',1,d
			wwfc=d(*,0)
			fwfc=d(*,2)
			stwfc=d(*,3)
			sywfc=d(*,4)
			exwfc=d(*,6)
			dqwfc=d(*,7)
			fwwfc=wwfc(2:-1)-wwfc(0:-3)
			fwwfc=[fwwfc(0),fwwfc,fwwfc(-1)]	; 2px
plot,wold,fold,xr=[.95*wcut,1.05*wcut],psym=-4		; nic
oplot,wwfc,fwfc,thic=2,psym=-6				; square WFC3
oplot,wmod,fmod,lin=2,th=4				; model
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st		;nic+wfc3:
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold,$
				wwfc,fwfc,stwfc,sywfc,exwfc,dqwfc,fwwfc
			wcut1=17060			; wold still has nicmos
			sxaddhist,string(wcut,wcut1,'WFC3',nam+'.'+ext,   $
				form=wlsrc),hd
plot,wold,fold,xr=[.95*wcut1,1.05*wcut1],psym=-6	; square nic
oplot,wwfc,fwfc,psym=-4					; diam WFC3
oplot,wmod,fmod,lin=2,th=4				; model
oplot,[wcut1,wcut1],[0,1e-8]
if !d.name eq 'X' then read,st		;nic+wfc3+nic:
			pastem,wcut1,wwfc,fwfc,stwfc,sywfc,exwfc,dqwfc,fwwfc,$
				wold,fold,errold,sysold,exold,epold,fwold
; STIS + nic+wfc3+Nicmos + Model:
			wcut=23980
			sxaddhist,string(wcut1,wcut,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
			boszmodcor,'c26202',wold,fold,wave,flux,cont,	$
						ebv,teff,logg,logz	; again
; 2019jun3 - Correct wave to stellar radial velocity:
			wave=wave*(1+starvel(target)/3e5)
			sxaddhist,string(wcut,max(wave),		$
			  'Bohlin et al. 2017','BOSZ R=500 Model',form=wlsrc),hd
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			npts=n_elements(wave)
; fwhm @ >10mic sort of OK because of Kz04 correction
			fwhm=(wave(1:npts-1)-wave(0:npts-2))
			fwhm=[fwhm(0),fwhm]
			dataqual=flux*0+1
			sun='sun'			; flag used below
			sxaddhist,'BOSZ Model with Teff,log g,log z,E(B-V)='+  $
			    string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
			print,'BOSZ Mod to',max(wmod),' for ',teff,logg,logz,ebv
plot,wave,flux,xr=[.95*wcut,1.05*wcut],thic=2
oplot,wold,fold,psym=-4
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			indx=where(wave ge 8590 and wave le 8675)	;vac
			dataqual(indx)=1		; Line at dust mote
			end
		'SF1615+001A': begin
			wcut=9680  &  wcutlast=wcut
			sxaddhist,string(min(wave),wcut,'STIS',	$
					'SF1615001A.MRG',form=wlsrc),hd
; STIS + NICMOS
			instrum='NICMOS'
			rdf,'../nical/spec/sf1615+001a.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;/double
			fwold=[fwold(0),fwold]
plot,wold,fold,xr=[.95*wcut,1.05*wcut]
oplot,wave,flux,thic=2
oplot,wmod,fmod,lin=2,th=4				; model
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				   wold,fold,errold,sysold,exold,epold,fwold
			wcut=23000
			sxaddhist,string(wcutlast,wcut,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
; STIS + Nicmos + Model
			boszmodcor,'sf1615',wold,fold,wave,flux,cont,	$
		      					ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
			wave=wave*(1+starvel(target)/3e5)
			sxaddhist,string(wcut,max(wave),		$
			'Bohlin et al. 2017','BOSZ R=500 Model',form=wlsrc),hd
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			npts=n_elements(wave)
; fwhm @ >10mic sort of OK because of Kz04 correction
			fwhm=(wave(1:npts-1)-wave(0:npts-2))
			fwhm=[fwhm(0),fwhm]
			dataqual=flux*0+1
			sun='sun'			; flag used below
			sxaddhist,'BOSZ Model with Teff,log g,log z,E(B-V)='+  $
			  string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
			print,'BOSZ Mod to',max(wmod),' for ',teff,logg,logz,ebv
plot,wave,flux,xr=[.95*wcut,1.05*wcut],thic=2
oplot,wold,fold,psym=-4
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			indx=where(wave ge 8590 and wave le 8675)	;vac
			dataqual(indx)=1		; Line at dust mote

			end
		'SIRIUS': begin
			rdfhdr,'../ancient/pop/sirius.txt',1,iue,hdold
			wold=iue(*,0)-2.		; 2Ang WL correction
			good=where(wold gt 1150)
			wold=wold(good)
			fold=iue(good,5)
			fwold=fold*0+6.			; IUE 6Ang resol
			errold=fold*iue(good,7)/100	; IUE err in % (I guess)
			sysold=fold*.1			;10% sys err-fast trail
			epold=fold*0+1			; integer DQ
			exold=iue(good,6)
			norm=tin(wave,flux,1680,1800)/			$
					tin(wold,fold,1680,1800) ; IUE fix
			fold=fold*norm		;norm iue to stis
			sysold=sysold*norm      ;norm iue to stis
			errold=errold*norm      ;norm iue to stis
			print,'IUE normalization factor=',norm
			wcut=1675				; 03jan6
			sxaddhist,' 1150    '+string(wcut,'(i4)')+	$
				'       IUE            '+ 		$
				'     ancient/pop/sirius.txt',hd
			sxaddhist,string(wcut,10200,'STIS',	$
				'sirius.mrg',form=wlsrc),hd
			sxaddhist,string(10200,2996860,'Kurucz Special Model',+$
				'sirallpr16.500resam501',form=wlsrc),hd
			sxaddhist,' IUE fluxes increased by '+		$
				string(norm,'(f5.3)')+' by '+      	$
				'MAKE_STIS_CALSPEC.pro  '+strmid(!stime,0,11),hd
plot,wold,fold,xr=[1600,1900],thic=2+5*(!d.name eq 'PS'),yr=[1.9e-8,3e-8]; IUE
oplot,wave,flux,psym=-4							; stis
oplot,[wcut,wcut],[0,9e-8]
if !d.name eq 'X' then read,st
; IUE+STIS:
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
; Reverse names:
			wold=wave  &  fold=flux  &  errold=sterr  & sysold=syerr
			exold=exptime  &  epold=dataqual  &  fwold=fwhm
			rdf,'../rocket/stds/sirallpr16.500resam501',1,k  ; kz
			wave=k(*,0)*10			; nm-->Ang
			flux=k(*,1)
; normalize model to stis from 6800-7700A, 2014 Feb25
			norfac=tin(wold,fold,6800,7700)/tin(wave,flux,6800,7700)
			print,'Kurucz model mult by ',norfac
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6800-7700A',hd
			flux=flux*norfac
			sterr=flux*0
			syerr=flux*0.01
			exptime=flux*0
			dataqual=flux*0+1
			fwhm=wave/500.
;;;			wcut=10222
			wcut=10200		;2020jan17-smoother transition
plot,wold,fold,xr=[.96*wcut,1.04*wcut],psym=-4			; Stis
oplot,wave,flux,thic=2						; Model
oplot,[wcut,wcut],[0,9e-8]
read,st
; IUE + STIS + Model
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			wcut=-1				; flag to omit below
			end
		'P041C': begin
			ssread,'p041c_001.tab',wold,	$
				fold,errold,hdold,fwold,sysold,epold,exold,    $
				/epsfx		;,magfx=0.008
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*2
			fwold=[fwold(0),fwold]
			sysold=0.03*fold	; set systematic error
			wcut=2907
			sxaddhist,string(min(wold),wcut,'FOS','P041C_001', $
				form=wlsrc),hd
; (FOS + STIS)
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			sxaddhist,string(wcut,10180,'STIS',nam+'.'+ext,   $
				form=wlsrc),hd
; FOS + STIS + NICMOS
			instrum='NICMOS'  &  nam='p041c'
			rdf,'../nical/spec/p041c.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;/double
			fwold=[fwold(0),fwold]
			wcut=10140
			wcut2=24920
			sxaddhist,string(wcut,wcut2,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
plot,wold,fold,xr=[.95*wcut,1.05*wcut],psym=-4
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
read,st
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				   wold,fold,errold,sysold,exold,epold,fwold
; FOS + STIS + NICMOS + Model:
			boszmodcor,nam,wold,fold,wave,flux,cont,	$
							ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
			wave=wave*(1+starvel(target)/3e5)
		        sxaddhist,string(wcut2,max(wave),		$
			  'Bohlin et al. 2017','BOSZ R=500 Model',form=wlsrc),hd
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			npts=n_elements(wave)
; fwhm @ >10mic sort of OK because of Kz04 correction
			fwhm=(wave(1:npts-1)-wave(0:npts-2))
			fwhm=[fwhm(0),fwhm]
			dataqual=flux*0+1
			wcut=wcut2
			sun='sun'			; flag used below
			sxaddhist,'BOSZ Model with Teff,log g,log z,E(B-V)='+  $
			    string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
			print,'BOSZ Mod to',max(wmod),' for ',teff,logg,logz,ebv
plot,wave,flux,xr=[.95*wcut,1.05*wcut],thic=2
oplot,wold,fold,psym=-4
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			indx=where(wave ge 8604 and wave le 8678)	;vac
			dataqual(indx)=1		; Line at dust mote
			end
		'P177D': begin
;09nov16-new G430L (G750L-bad CTE) obs. Use FOS only from 2222-2935,
;							instead of to 5304
			ssread,'p177d_001.tab',wold,    $
			   fold,errold,hdold,fwold,sysold,epold,exold,	 $
			   /epsfx	  ;,magfx=0.008
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*2
			fwold=[fwold(0),fwold]
			sysold=0.03*fold	; set systematic error
; Vband avg flux
			Vold=tin(wold,fold,5000,6000)
	print,'STIS/FOS at 5000-6000A info only =',vstis/vold
			wcut=2935	; STIS spike at 2930A
; (FOS + STIS)
plot,wold,fold,xr=[.95*wcut,1.05*wcut],psym=-4
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			sxaddhist,string(min(wold),wcut,'FOS','P177D_001', $
				form=wlsrc),hd
; FOS + STIS + NICMOS
			instrum='NICMOS'  &  nam='p177d'
			rdf,'../nical/spec/p177d.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;/double
			fwold=[fwold(0),fwold]
			sxaddhist,string(wcut,10180,'STIS',nam+'.'+ext,   $
				form=wlsrc),hd
			wcut=10180
			wcut2=24920
			sxaddhist,string(wcut,wcut2,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
plot,wold,fold,xr=[.95*wcut,1.05*wcut],psym=-4
oplot,wave,flux,thic=2
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				   wold,fold,errold,sysold,exold,epold,fwold
			wcut=wcut2
; FOS + STIS + Nicmos + Model
			boszmodcor,nam,wold,fold,wave,flux,cont,	$
							ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
			wave=wave*(1+starvel(target)/3e5)
		        sxaddhist,string(wcut,max(wave),		$
			  'Bohlin et al. 2017','BOSZ R=500 Model',form=wlsrc),hd
			sterr=flux*0
			syerr=flux*0.02
			exptime=flux*0
			npts=n_elements(wave)
; fwhm @ >10mic sort of OK because of Kz04 correction
			fwhm=(wave(1:npts-1)-wave(0:npts-2))
			fwhm=[fwhm(0),fwhm]
			dataqual=flux*0+1
			sun='sun'			; flag used below
			sxaddhist,'BOSZ Model with Teff,log g,log z,E(B-V)='+  $
			    string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
plot,wave,flux,xr=[.95*wcut,1.05*wcut],thic=2
oplot,wold,fold,psym=-4
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			indx=where(wave ge 8604 and wave le 8683)	;vac
			dataqual(indx)=1		; Line at dust mote
			end
		'P330E': begin
;09sep30-new G430L (& G750L) obs. Use FOS only from 2222-2917,instead of to 5304
;	I could use the lower res STIS from 2222-2917, but keep FOS for better
;	match to P041C and P177D that do not have STIS G230L.
			ssread,'p330e_001.tab',wold,	$
				fold,errold,hdold,fwold,sysold,epold,exold,    $
				/epsfx		;,magfx=0.008
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*2
			fwold=[fwold(0),fwold]
			sysold=0.03*fold	; set systematic error
; Vband avg flux
			Vold=tin(wold,fold,5000,6000)
	print,'STIS/FOS 5000-6000 flux, info only =',vstis/vold
; IR avg flux
			Iold=tin(wold,fold,7000,8000)
		print,'STIS/FOS 7000-8000 flux info only ,=',istis/iold
			wcut=2222
			sxaddhist,string(2000,wcut,'STIS',nam+'.'+ext,        $
				form=wlsrc),hd
			indx=where(wave ge 1999)	; 1 more pt 2015feb4
			wave=wave(indx)			;truncate STISbelow 2000
			flux=flux(indx)>1e-18		; elim one neg point
			sterr=sterr(indx)
			syerr=syerr(indx)
			exptime=exptime(indx)
			dataqual=dataqual(indx)
			fwhm=fwhm(indx)

; (STIS + FOS)
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wold,fold,errold,sysold,exold,epold,fwold
			wcut=2917			; 09sep28-was 5304
			sxaddhist,string(2222,wcut,'FOS','P330E_001', $
				form=wlsrc),hd
plot,wold,fold,xr=[.96*wcut,1.04*wcut],psym=-4		; fos
oplot,wave,flux,psym=-6					; stis
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st
; (STIS + FOS + STIS)
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wave,flux,sterr,syerr,exptime,dataqual,fwhm
			wcut1=10080
			sxaddhist,string(wcut,wcut1,'STIS',nam+'.'+ext,   $
				form=wlsrc),hd
			boszmodcor,nam,wave,flux,wmod,fmod,cont,	$
						ebv,teff,logg,logz
; 2019jun3 - Correct wave to stellar radial velocity:
			wmod=wmod*(1+starvel(target)/3e5)
; +WFC3:
			rdf,'../wfc3/spec/p330e.mrg',1,d
			wwfc=d(*,0)
			fwfc=d(*,2)
			stwfc=d(*,3)
			sywfc=d(*,4)
			exwfc=d(*,6)
			dqwfc=d(*,7)
			fwwfc=wwfc(2:-1)-wwfc(0:-3)
			fwwfc=[fwwfc(0),fwwfc,fwwfc(-1)]	; 2px
plot,wwfc,fwfc,thic=2,xr=[.95*wcut1,1.05*wcut1],psym=-6		; square WFC3
oplot,wave,flux,psym=-4						; stis
oplot,wmod,fmod,lin=2,th=4					; model
oplot,[wcut1,wcut1],[0,1e-8]
if !d.name eq 'X' then read,st
		      pastem,wcut1,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wwfc,fwfc,stwfc,sywfc,exwfc,dqwfc,fwwfc
			wcut=wcut1  &  wcut1=16680
			sxaddhist,string(wcut,wcut1,'WFC3',nam+'.'+ext,   $
				form=wlsrc),hd
			
; FOS + STIS +wfc3 + NICMOS:
			instrum='NICMOS'
			rdf,'../nical/spec/p330e.mrg',1,d
			wold=d(*,0)*1e4  &  fold=d(*,2)  &  errold=d(*,3)
			sysold=fold*0.02  &  exold=d(*,8)  &  epold=fold*0+1
			npts=n_elements(wold)
			fwold=(wold(1:npts-1)-wold(0:npts-2))*4		;/double
			fwold=[fwold(0),fwold]
			wcut=16680
			wcut1=24560
			sxaddhist,string(wcut,wcut1,'NICMOS',nam+'.'+ext,   $
				form=wlsrc),hd
plot,wold,fold,xr=[.95*wcut,1.05*wcut],psym=-6			; nic
oplot,wwfc,fwfc,psym=-4						; wfc3
oplot,wmod,fmod,lin=2,th=4					; model
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
		       pastem,wcut,wwfc,fwfc,stwfc,sywfc,exwfc,dqwfc,fwwfc, $
				   wold,fold,errold,sysold,exold,epold,fwold
			wcut=wcut1
; FOS + STIS + Nicmos + Model
		        sxaddhist,string(wcut,max(wmod),		$
			  'Bohlin et al. 2017','BOSZ R=500 Model',form=wlsrc),hd
			sterr=fmod*0
			syerr=fmod*0.02
			exptime=fmod*0
			npts=n_elements(wmod)
; fwhm @ >10mic sort of OK because of Kz04 correction
			fwhm=(wmod(1:npts-1)-wmod(0:npts-2))
			fwhm=[fwhm(0),fwhm]
			dataqual=fmod*0+1
			sun='sun'			; flag used below
			sxaddhist,'BOSZ Model with Teff,log g,log z,E(B-V)='+  $
			    string(teff,logg,logz,ebv,form='(i5,2f6.2,f6.3)'),hd
			sxaddhist,'     Bohlin, et al. 2017, AJ, 153, 234',hd
			sxaddhist,'Model Normalized to Observed '+	$
					'Flux at 6000-9000A',hd
			print,'BOSZ Mod to',max(wmod),' for ',teff,logg,logz,ebv
plot,wmod,fmod,xr=[.95*wcut,1.05*wcut],psym=-6		; model sq
oplot,wold,fold,psym=-4					; nic
oplot,[wcut,wcut],[0,1e-8]
plotdate,'make_stis_calspec'
if !d.name eq 'X' then read,st
			pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
				wmod,fmod,sterr,syerr,exptime,dataqual,fwhm
			wave=wmod
			flux=fmod
			indx=where(wave ge 8603 and wave le 8682)	;vac
			dataqual(indx)=1		; Line at dust mote
			end				; P330E
; STIS+NICMOS:
;	LDS,Snap1,VB8,WD1057?,WD1657? w/ no model
;	 lds749b_mod.dk goes to 30mic???
		'LDS749B': begin
			wcut=9480
			sxaddpar,hd,'source2',				$
					'Bohlin & Koester 2008, AJ, 135, 1092'
	stop		; add concatenation of model 2017jan12
			goto,stisniconly
			end
		'SNAP-1': begin
			wcut=10100			; get STIS P-delta 10050
			goto,stisniconly
			end
		'WD1057+719': begin
			wcut=5695
			!y.style=0
; STIS+NICMOS only:
stisniconly:
			sxaddhist,string(min(wave),wcut,'STIS', $
				nam+'.mrg',form=wlsrc),hd
iuestisnic:						;No model: AGK, 2M*,etc
plot,wave,flux,xr=[wcut*.95,wcut*1.05],psym=-4		; stis (or +wfc3)
;plot,wave,flux,xr=[8200,10300],psym=-2
oplot,wold,fold,thic=2,psym=-6				; nic
oplot,[wcut,wcut],[0,1e-8]
if !d.name eq 'X' then read,st 		       
; Trim noise:
; ff lines seem misplaced??? 2019aug
			if target eq 'WD1657+343' then begin
			   good=where(wold le 19270.)
			   wold=wold(good) & fold=fold(good) & fwold=fwold(good)
			   errold=errold(good)  &  sysold=sysold(good)
			   exold=exold(good)  &  epold=epold(good)
			   print,target,minmax(wold)
			   endif
			if strpos(nam,'wd1057') eq 0 then wcut=8000	;lv gap
			sxaddhist,string(wcut,max(wold),'NICMOS', $
						nictarg+'.mrg',form=wlsrc),hd
; STIS+(wfc)+NICMOS
		       pastem,wcut,wave,flux,sterr,syerr,exptime,dataqual,fwhm,$
				wold,fold,errold,sysold,exold,epold,fwold
			wave=wold  &  flux=fold  &  sterr=errold  & syerr=sysold
			exptime=exold  &  dataqual=epold  &  fwhm=fwold
			goto,nicnorm
			end
		'WD-0308-565': begin
			good=where(wave le 10100)
			wave=wave(good)
			flux=flux(good)
			sterr=sterr(good)
			syerr=syerr(good)
			exptime=exptime(good)
			dataqual=dataqual(good)
			fwhm=fwhm(good)
			end
		  else:		print,'STIS only case'		
; STIS ONLY comes here
;		'G191B2B_PURE'			; pure stis for calobs
;		'HZ43B':
;		'HS2027+0651':
		endcase				; end of star specific process.
		
; Vega is only star that writes full pedigree above:
	if sun ne 'sun' and filespec ne 'vega' and wcut gt 0 and	$
		strpos(file,'172167') lt 0 and instrum ne '' then	$
	      sxaddhist,string(wcut,max(wave),instrum,nam+'.'+ext,form=wlsrc),hd
nicnorm:
	if instrum eq 'NICMOS' then sxaddhist,'NICMOS flux cal per '+	$
			'Bohlin, Riess, & de Jong 2006, NICISR 2006-002',hd
sunskip:
	if iuelo ne 1. then sxaddhist,iuehist,hd
	iuelo=1.
	if teff gt 26000 then						$
	   sxaddhist,'Lanz NLTE  model grid with good sampling in the IR',hd $
	 else								$
	  if teff gt 0	then					$ ;0 is no model
	   sxaddhist,'BOSZ model with good sampling in the IR',hd
; ###change
; 10feb9-New HISTORY STORY required:
skipout:
	if strpos(name,'_001') lt 0 then begin	; no change for 001 ver.
;	if strpos(name,'wfc') ge 0 then begin
	 sxaddhist,'CHANGES from previous version:',hd
;	 sxaddhist,'  New WFC3 IR grism Data',hd
;	 sxaddhist,'  The HST flux scale is now based on Rauch NLTE WD ',hd
;	 sxaddhist,'  models for G191B2B, GD71, & GD153. Previously, Hubeny',hd
;	 sxaddhist,'  TLusty models were used for these three stars.',hd
;	 sxaddhist,'  The HST flux scale is now ~0.6% fainter because of ',hd
;	 sxaddhist,'  the reconciliation of absolute visible and IR fluxes',hd
;	 sxaddhist,'  (Bohlin 2014, AJ, in press)',hd
;	 sxaddhist,'  The STIS G230LB and G430L flux changes because of new',hd
;	 sxaddhist,'  CCD gwidth=11 calibrations (Bohlin etal 2019,158,211),',hd
;	 sxaddhist,'  and models are now concatenated.)',hd
	 sxaddhist,'  New models for 3 prime WDs (Bohlin etal 2020, in prep)',hd
	 sxaddhist,'  For details see:',hd
         sxaddhist,'  http://www.stsci.edu/hst/instrumentation/reference-',hd
	      sxaddhist,'    data-for-calibration-and-tools/astronomical-',hd
	      sxaddhist,'    catalogs/calspec',hd
	 end else sxaddhist,'  New Star',hd

;	if target eq 'WD0308-565' then begin
;	   sxaddhist,'The primary motivation for establishing WD0308-565',hd
;	   sxaddhist,'  as a standard star was for use as a COS calibrator.',hd
;	   sxaddhist,'  The well calibrated STIS instrumentation was',hd
;	   sxaddhist,'  used to measure the SED of this star.',hd
;	   endif
	if target eq 'SDSS132811' then begin
	  sxaddhist,'The primary motivation for establishing SDSS132811',hd
	  sxaddhist,'  as a standard star is for an ACS/SBC calibrator.',hd
	  sxaddhist,'  The well calibrated STIS instrumentation was',hd
	  sxaddhist,'  used to measure the SED of this star.',hd
	  endif
	if target eq 'SDSSJ151421' then begin
	  sxaddhist,'The primary motivation for establishing SDSSJ151421',hd
	  sxaddhist,'  as a WD standard is to confirm its suitablity',hd
	  sxaddhist,'  according to Narayan et al. 2019, ApJS, 241, 20.',hd
	  sxaddhist,'  The well calibrated STIS instrumentation was',hd
	  sxaddhist,'  used to measure the SED of this star.',hd
	  endif
	
	sxaddpar,hd,'filename',name
	sxaddpar,hd,'wmin',min(wave),'Minimum Wavelength'
	sxaddpar,hd,'wmax',max(wave),'Maximum Wavelength'
	if strpos(sxpar(hd,'source2'),'   ') eq 0 then sxdelpar,hd,'source2'
; for delivery (53 char btwn tick marks)
	sxaddpar,hd,'descrip','Standard star flux with an HST/STIS '+  $ ;36char
				'calibration------',before='source'	;17 char

	mn=min(flux)  &  if mn le 0 then mn=max(flux)*1e-4
	!mtitle=target+' Flux, syst-err, stat-err=dots'
	plot_oo,wave,flux,yr=[0.9*min(flux(100:-1))>5e-20,1.1*max(flux)],  $
			xr=[min(wave),max(wave)]
	oplot,wave,syerr,thic=2
	oplot,wave,(sterr<1),lines=1
	
	print,'FILENAME='+name+' for ifile=',ifile
	if !d.name eq 'X' then read,st
;	hprint,hd
; ###change
	name='deliv/'+name
	fxwrite,name,hd				; create output file+primary hdr
	hd = ['END     ']			; re-init for extension header
	nwav=n_elements(wave)
	fxbhmake,hd,nwav
        sxaddpar,hd,'extname','SCI'
        sxaddpar,hd,'extver',1
        sxaddpar,hd,'inherit','T'
; set up col headers: (2014oct13-add 0.D below)
	fxbaddcol,1,hd,0.D,'WAVELENGTH',tunit='ANGSTROMS',tdisp='G10.4'
	fxbaddcol,2,hd,0.,'FLUX','Absolutely calibrated net spectrum',  $
		tunit='FLAM',tdisp='E12.4'
	fxbaddcol,3,hd,0.,'STATERROR','Statistical flux error',		$
		tunit='FLAM',tdisp='E12.4'
	fxbaddcol,4,hd,0.,'SYSERROR','Systematic flux error=0.01*FLAM', $
		tunit='FLAM',tdisp='E12.4'
	fxbaddcol,5,hd,0.,'FWHM','FWHM spectral resolution',		$
		tunit='ANGSTROMS',tdisp='G6.2'
	fxbaddcol,6,hd,0,'DATAQUAL','Data quality: 1=good, 0=bad',	$
		tunit='NONE',tdisp='I2'
	fxbaddcol,7,hd,0.,'TOTEXP','Total exposure time',		$
		tunit='SEC',tdisp='G10.2'
;
; write table
;
; fix old tnull=1.6e38 in exptimes: & 06aug1-in errors
	bad=where(exptime eq 1.6e38,nbad)
	if nbad gt 0 then exptime(bad)=0
	bad=where(sterr eq 1.6e38,nbad)
	if nbad gt 0 then sterr(bad)=0
        fxbcreate,unit,name,hd			; unit must be auto assigned
        row=0
	flux=float(flux)
	sterr=float(sterr)
	syerr=float(syerr)
	fwhm=float(fwhm)
	exptime=float(exptime)
        for irow=0L,nwav-1 do begin		; no. of rows
                row=row+1
                fxbwrite,unit,wave(irow),1,row
                fxbwrite,unit,flux(irow),2,row
                fxbwrite,unit,sterr(irow),3,row
                fxbwrite,unit,syerr(irow),4,row
                fxbwrite,unit,fwhm(irow),5,row
                fxbwrite,unit,fix(dataqual(irow)),6,row
                fxbwrite,unit,exptime(irow),7,row
		endfor
	fxbfinish,unit

if filespec eq 'vega' or filespec eq 'sun' then return	; avoid loop error msg.
nextfile:
;    read,st
    end
return
end
