pro make_iue_calobs,filespec
;+
;			make_iue_calobs
;
; procedure to convert iue ascii file to CALOBS machine indep. binary fits files
;	 with WD correction applied (FLXCOR)
;
; CALLING SEQUENCE:
;	make_iue_calobs,filespec
;
; INPUTS:
;	filespec - filespec for ascii merge files
;
; OUTPUTS:
;	a bunch of .fits files with names placed in current directory
;		<starname>_IUE.fits
;
; 
; EXAMPLE:
;	
;	make_iue_calobs,'merge*.mrg' 
;
; HISTORY:
;	Aug 26, 1988 changed wavelengths from air to vacuum.
;		Hartig wants FOS to be vacuum and Turnshek says
;		that is the modern astronomical standard.
;
;	MAR 23, 1989 put a lower limit of 3% on ralphs sigmas
;		and changed computation of sigma for average from
;		sqrt to fourth root.
;	Feb 22, 1990 changed to new table format, added air to vacumm
;		wavelength correction
;	May22,90 changed to leave wavelengths in air above 2000A for consistency
;	Jun, 1, 1995 Modified from IUETAB
;			Changed to read ascii files instead of SDAS images
;			added flxcor and modified to use new merge header
;			formats.
;	Oct 5, 1995 added date keyword
;	00oct5 - the latest calobs .tab files are 1995-nov 
;	99jul13 - fix extra HISTORY word added when input is from sdas_ascii
;	99jul13 - why i wanted air WL on 90may22? - see: .doc]VAC.AIR-WL
;	99jul19 - convert output from ancient SUN format .tab files to machine
;		independent IEEE binary fits files. To read new files, use 
;		mrdfits to read output, instead of ssread to read .tab sdas 
;		files. use sSTAR_ascii to read & convert .tab sdas files
;		See old version MAKE_IUE_CALOBS.OLD-SDAS-TABS that made .tab's
;		(use SDAS_ascii to read & convert .hhh & .hhd sdas files)
;	03nov17-remove old tnull and 1.6e38 flagging & replace w/ !values.f_nan
;	11jul19-looks like the .fits file are only in CDBS:/grp/hst/cdbs/calobs
;		ck. hd60753_004.fits vs my calobs/hd60753_004.tab-ssread fails
;		but works for calspec/hd60753_002.tab--I must need to do the
;		.tab 'little endion' fix for calspec. Just use the CDBS .fits.
;		See calspec  hd60753_004.txt & .etc for examples.
;-
;-----------------------------------------------------------------------------
;
; find files to process
;
    filelist = findfile(filespec)
;
; loop on files
;
    for ifile=0,n_elements(filelist)-1 do begin
	file = filelist(ifile)

;
; read input file
;
	rd,file,0,x
;
; get header
;
        st = ''
        header = strarr(1000)
        nheader = 0
        close,1 & openr,1,file
        readf,1,st
;
; lines to delete from input ascii header
;
	badst = ['OBS DATE=','NET/TIME','RECORDS FOUND','EXP. TIME(sec)', $
		 'POSITION IUE TAPE','POINTS IN SPECTRUM']
	nbadst = n_elements(badst)

        while strmid(st,1,3) ne '###' do begin
;
; should we ignore it
;
		for k=0,nbadst-1 do if strpos(st,badst(k)) ge 0 then goto,nextl
		header(nheader) = strmid(st,0,71)
		if (strmid(st,0,7) eq 'HISTORY') then 			$
                        header(nheader) = strmid(st,8,71)	; 99jul13
		nheader = nheader+1
nextl:
                readf,1,st
        end
;
; read target name
;
        target='' & readf,1,target              ;target name
	target = strtrim(target,2)
	target = gettok(target,' ')		; 99jul13 - rcb
        close,1
;
; extract information from header
;
	nspeclw = 0
	nspecsw = 0
	wmerge = 0
	for i=0,nheader-1 do begin
;		if strmid(header(i),0,7) eq ' SUM OF' then begin
		if strmid(header(i),0,6) eq 'SUM OF' then begin	; 99jul13
			pos = strpos(header(i),'CAMERA')
			if pos lt 0 then begin
				print,'ERROR - CAMERA Not Found *************'
				goto,nextfile
			end

			camera = fix(strtrim(strmid(header(i),pos+6,3)))
			nspec = fix(strmid(header(i),7,3)) + $
				fix(strmid(header(i),17,4))
			if camera le 2  then nspeclw = nspeclw+nspec $
					else nspecsw = nspecsw+nspec
		end
		if strmid(header(i),0,11) eq 'MERGE POINT' then $
				wmerge = float(strmid(header(i),13,7))
	end
	if wmerge le 0 then wmerge=sxpar(header,'wmerge')	; 99jul13
	if wmerge le 0 then stop				; idiot ck.
;
; read data
;
	wave=x(*,0)
	dataqual=x(*,1)
	gross=x(*,2)
	back=x(*,3)
	netrate=x(*,4)
	flux=x(*,5)
	exptime=x(*,6)
	error=x(*,7)>0.03		;23-mar-89 per BOHLIN (min. 3% error)
;
; apply WD corrections
;
	flux = flxcor(wave,flux)
;
; determine wmerge for case of no lw or sw spectra
;
	if nspeclw eq 0 then wmerge = max(wave)+0.1
	if nspecsw eq 0 then wmerge = min(wave)-0.1
;
; use null values outside calibrated wavelength range added 3/23/89
; also change crap to null values
;
	maxwave=3350
	null=where((wave le 1147.5) or (wave ge 3350) or (flux lt 0) ,n_null)


;
; compute statistical error
;
	error=error*flux
	syserror=flux*0.03
	isw=where(wave lt wmerge,nsw)
	maxexpsw = 0.0
	if nsw gt 0 then begin
		maxexpsw=max(exptime(isw))
		error(isw)=error(isw)/(((nspecsw*exptime(isw)/maxexpsw)>1)^0.25)
	end
	ilw=where(wave ge wmerge,nlw)
	maxexplw = 0.0
	if nlw gt 0 then begin	
		maxexplw=max(exptime(ilw))
		error(ilw)=error(ilw)/(((nspeclw*exptime(ilw)/maxexplw)>1)^0.25)
	end
;
; insert nulls
;
	if n_null gt 0 then begin
		flux(null)=!values.f_nan
		error(null)=!values.f_nan
		syserror(null)=!values.f_nan
	end
;
; create binary .fits files (ref: rampfits.pro & abscorsig.pro)
;
	nwav=n_elements(wave)
	hd = ['END     ']
	sxaddpar,hd,'simple','T'
	sxaddpar,hd,'bitpix',16
	sxaddpar,hd,'naxis',0
	sxaddpar,hd,'extend','T','FITS extensions present?'
	name = target
        spos=strpos(name,'+')
        if spos gt 0 then strput,name,'_',spos  ; replace + with _
        spos=strpos(name,'-')
        if spos gt 0 then strput,name,'_',spos  ; replace - with _
	name = name + '_IUE'+'.fits'	; non-IUE should be named _obs = calobs
        sxaddpar,hd,'filename',strlowcase(name)
	sxaddpar,hd,'descrip','IUE Spectrophotometry on WD flux scale'
	sxaddpar,hd,'dbtable','CRSPECOBS','IDM table name'
	sxaddpar,hd,'targetid',target,'standard STScI name of target'
	sxaddpar,hd,'obsmode','IUE','instrument'
	sxaddpar,hd,'airmass',0.0,'mean airmass of the observation'
	sxaddpar,hd,'source', $
		'Bohlin, et al (1990),ApJS, 73, 413'
	stime = strmid(!stime,0,11)
;	sxaddpar,hd,'date',stime wrong format. need: 99-10-01
	
; add old history
;
	sxaddhist,header(0:nheader-1),hd
;
; add some more keyword information
;
	sxaddpar,hd,'wmin',min(wave),'Minumum Wavelength'
	sxaddpar,hd,'wmax',max(wave),'Maximum Wavelength'
	sxaddpar,hd,'nspecsw',nspecsw,'Number of SWP spectra averaged'
	sxaddpar,hd,'nspeclw',nspeclw,'Number of LW spectra averaged'
	sxaddpar,hd,'maxexpsw',maxexpsw,'Maximum exposure time for SWP'
	sxaddpar,hd,'maxexplw',maxexplw,'Maximum exposure time for LW'
	sxaddpar,hd,'wmerge',wmerge,'LW/SW merge point'
;
; add some more garbage to header
;
	sxaddhist,' Statistical error computed as:',hd
	sxaddhist,'     sig / ( n * t / maxt)**0.25',hd
	sxaddhist,'   where: sig - standard deviation of average with',hd
	sxaddhist,'              a lower limit of 3% of the flux',hd
	sxaddhist,'        n - number of spectra averaged',hd
	sxaddhist,'        t - total exposure time for the data point',hd
	sxaddhist,'        maxt - maximum exposure time (all data points)',hd
	sxaddhist,' Systematic error set to FLUX*0.03',hd
	sxaddhist,' FWHM set to 6 Angstroms for all points',hd
	sxaddhist,' All wavelengths are in air above 2000 Angstroms',hd
	sxaddhist,' IUE Fluxes corrected to WD scale with FLXCOR.PRO: '+STIME,hd
	sxaddhist,' Written by MAKE_IUE_CALOBS.pro  '+STIME,hd

	fxwrite,name,hd

	hd = ['END     ']			; restart for extension header
	fxbhmake,hd,nwav
        sxaddpar,hd,'extname','SCI'
        sxaddpar,hd,'extver',1
        sxaddpar,hd,'inherit','T'
; set up col headers:
	fxbaddcol,1,hd,0.,'WAVELENGTH',tunit='ANGSTROMS',	$
		tdisp='G10.4'
	fxbaddcol,2,hd,0.,'FLUX','Absolutely calibrated net spectrum',	$
		tunit='FLAM',tdisp='E12.4'
	fxbaddcol,3,hd,0.,'STATERROR',			$
		'Statistical error of flux measurement (FLAM)',		$
		tunit='FLAM',tdisp='E12.4'
	fxbaddcol,4,hd,0.,'SYSERROR',				$
		'Systematic error of flux measurements (FLAM)',		$
		tunit='FLAM',tdisp='E12.4'
	fxbaddcol,5,hd,0.,'FWHM',					$
		'FWHM spectral resolution',				$
		tunit='ANGSTROMS',tdisp='G6.2'
	fxbaddcol,6,hd,0.,'DATAQUAL',					$
		'IUE data quality (epsilon) flag',			$
		tunit='none',tdisp='G8.0'
	fxbaddcol,7,hd,0.,'GROSS',					$
		'Gross spectrum in IUE flux numbers (FN)',		$
		tunit='FN',tdisp='G10.0'
	fxbaddcol,8,hd,0.,'BACK',					$
		'Background spectrum in IUE flux numbers (FN)',		$
		tunit='FN',tdisp='G10.0'
	fxbaddcol,9,hd,0.,'NETRATE',					$
		'Net spectrum in IUE flux numbers (FN) per second',	$
		tunit='FN/SEC',tdisp='G10.2'
	fxbaddcol,10,hd,0.,'TOTEXP','Total exposure time',		$
		tunit='SEC',tdisp='G10.2'

;
; write table
;
        fxbcreate,unit,name,hd
        row=0
        for irow=0,nwav-1 do begin			; no. of rows
                row=row+1
                fxbwrite,unit,wave(irow),1,row
                fxbwrite,unit,flux(irow),2,row
                fxbwrite,unit,error(irow),3,row
                fxbwrite,unit,syserror(irow),4,row
                fxbwrite,unit,6.0,5,row			; ~FWHM
                fxbwrite,unit,dataqual(irow),6,row
                fxbwrite,unit,gross(irow),7,row
                fxbwrite,unit,back(irow),8,row
                fxbwrite,unit,netrate(irow),9,row
                fxbwrite,unit,exptime(irow),10,row
		endfor
	fxbfinish,unit
nextfile:
    end
return
end
