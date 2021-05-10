pro make_mod_calspec,filespec,modtype
;+
;			make_mod_calspec
;
; procedure to convert ascii models to CALspec binary fits files
;	Some of the CALSPEC info is added to ascii headers by newmakstd.pro
; USE for prime WDs, stars w/ special models, etc, 
;  ********* but use ~/calspec/doc/make_hires.pro for:  ***********************
;   ***R=300,000 BOSZ & WD models for Calspec *mod* files, incl hd165459****
;
; CALLING SEQUENCE:
;	make_mod_calspec,filespec,modtype=?
;****
; INPUTS:
;	filespec - filespec for ascii model w/ fully calib flux (or uncal model)
;		- or for CK04 models, specify filespec as '~/nical/spec/1*.mrg
;	modtype - ascii type of model, eg: 'mz' (required for model grids)
;
; OUTPUTS:
;	.fits files placed current dir (calpec/deliv)
;		<starname>_mod_00x.fits (read w. mrdfits)
; 
; --> Execute in calspec/deliv dir (or wherever file is to be written)
; EXAMPLEs: 
; Properly normalized files:
;	make_mod_calspec,'~/wd/dat/gd153.rauch-40204'	   1 of 3 prime
;	make_mod_calspec,'~/wd/dat/gd71.rauch-33301'	   2 of 3 prime
;	make_mod_calspec,'~/wd/dat/g191.hubeny59000-nlte'  3 of 3 prime

;	make_mod_calspec,'~/wd/dat/hz43.rauch-hyd'        4th orig prime
; Norm to latest STIS reduction: 
;	make_mod_calspec,'~/wd/dat/*.gian2013-nlte'
;obsolete make_mod_calspec,'/internal/1/calib/vega/vegamod_r500.05kur9400'
;obsolete make_mod_calspec,'../../calib/vega/vegamod_r500.344kur9550'
;  "	make_mod_calspec,'/internal/1/wd/dat/*hub07*red'	;old WD1057&1657
;	USE make-hires for WD1057&1657 w/ new std findminwd teff/grav/reddening
; 2020jan18-Streamline to make Vega processing match Sirius & skip calib/makstd:
;	make_mod_calspec,'../../calib/vega/VEGALLPR25.500RESAM501'	; 9550K
;	make_mod_calspec,'~/rocket/stds/sirallpr16-new.500resam501'
;	make_mod_calspec,'~/calib/lds749b/lds749b_mod.dk'
;	make_mod_calspec,'~/wd/dat/wd0308_mod.dk'
;	make_mod_calspec,'~/calib/bessell/models/EG131_RB.dk'		;gj7541a

; 2014may23 - Make a model .fits file for Susana w/ flag of stiscal:
;obsol:	make_mod_calspec,'/internal/1/stiscal/dat/p330e.mrg','mz' ;or marcs,ck04
;	make_mod_calspec,'/internal/1/calib/sun/fsunallp.5000resam51'
;
; HISTORY:
;	00apr4 - convert from make_iue_calobs
;	07sep20 - Add Input file as HISTORY
;		test of gd71_mod_005 in ~/wd is the same as copy in calspec
;		hub03-nlte are input files for current primary stds.
;	07dec23 - change name from make_wd_calspec to make_mod_calspec &
;		- add capability to use the Castelli & Kurucz (2004) CK04 
;			grid for the model.
;	14jan28 - add Sirius & Vega
;	14may8 - remake *009 files w/ dbl prec WLs to avoid dup WLs.
;	14may23- write model files for susana, eg mz, P330E
;	14dec19- Update for extrsize=gwidth=11 G750L ISR
;	2014dec31 - Fix Vega norm. Old alpha_lyr_mod_001.fits is wrong.
;	2017nov8 - write solar spectrum made from Kz model, incl contin, tho
;		using make_hires.pro might have been better.
;	2019Oct3 - New Rauch models for 2 GD* prime stds.
;	2020mar24 - add correction for radial vel in several places
;	2020mar24 - renormalize newmakstd files, as stis fluxes may change
;	2020mar31- change norm to ~full WL range eg to fix W1657 in make=hires
;-
;-----------------------------------------------------------------------------
;
mtitsav=''
; find files to process
;
    filelist = findfile(filespec)
;
; loop on files
;
    contcol=1						; initialize default
    for ifile=0,n_elements(filelist)-1 do begin
	file = filelist(ifile)
	print,'processing:',file
	fdecomp,file,disk,dir,star			; starvel name=star
	if star eq 'EG131_RB' then star='gj7541a'	; 2020mar12
	if strpos(star,'sir') eq 0 then star='sirius'	; 2020mar24
	if strpos(star,'VEG') eq 0 then star='HD1721'   ; 2020mar24
	if strpos(star,'0308') gt 0 then star='WD-0308'   ; 2020mar24
;
; read input file or compute model for stiscal flag:
;	2014DEC31 - 'target' in next line is a no-op?
; 2020feb looks like i never specify a stiscal file, so could simplify code:
	if strpos(file,'stiscal') ge 0 or strpos(file,'target') ge 0 then begin
	   v=vmag(star,ebv,sptyp,bvri,teff,logg,logz,model=modtype)
	   if modtype eq 'marcs' then marcsmod,teff,logg,logz,wave,flux
	   if modtype eq 'mz' then mzmod,teff,logg,logz,wave,flux
	   if modtype eq 'ck04' then ck04blanket,teff,logg,logz,	$
	   						wave,dumbl,dumco,flux
	   wave=double(wave)
	   radvel=starvel(star)
	   wave=wave*(1+radvel/3e5)
	   chiar_red,wave,flux,-(ebv),flux
	   target=star
	   header=modtype+' Model for Teff, log g, log z, E(B-V)='+  $
	   		string([teff,logg,logz,ebv],'(i5,f5.2,f6.2,f6.3)')
	   stisfil=file
	   goto,stisfil
	end else begin					; special models
	   rdfhdr,file,0,x,header
	   mtitsav=!mtitle
	   indx=where(strpos(header,'1  =') lt 0 and 			$
	   	strpos(header,'2  =') lt 0 and strpos(header,'Vacuum') lt 0)
	   header=header(indx)				;elim finley table stuff
	   indx=where(strmid(header,0,7) eq 'HISTORY',numhist)
	   if numhist gt 0 then header(indx) = strmid(header(indx),8,71)
           target=!mtitle
	   target = strtrim(target,2)
	   target = gettok(target,' ')
	   wave=x(0:-2,0)				; trim last bad pt.
	   radvel=starvel(star)
	   wave=wave*(1+radvel/3e5)		; 2020mar24
	   flux=x(0:-2,1)
	   siz=size(x)
	   ncont=siz(2)
	   if ncont ge 3 then cont=x(0:-2,2)		;wd0308 has no continuum
	   endelse					; END special Models
	   
	contcol=1				; 2019Oct - new default
	if ncont le 2 then contcol=0
	if (strpos(star,'g') ne 0 and strpos(star,'hz') ne 0	       $
		       and strpos(file,'target') lt 0) or	       $
		       star eq 'gj7541a' then header=!mtitle $; 'target' for LCB
		else header=[header,!mtitle]			; 2020mar24
	if strpos(file,'VEGA') ge 0 then target='hd172167'
	if strpos(star,'0308') ge 0 then target='wd-0308-565'
	if strpos(file,'sirallpr16-new') gt 0 then begin
		wave=wave*10				;nm->AA
		target='sirius'
		endif
	stisfil=findfile('~/stiscal/dat/'+strlowcase(target)+'.mrg')
	if target eq 'Sun' then	begin
		wave=wave*10			;nm->AA
		stisfil='/internal/1/calib/sun/sun-thuillier.txt'
		header=[header,'VTURB 1.5, VMACRO 1.5,'+	$
			     ' VROTATION  2.0, VMACRO 1.5 km/s, HE 0.089']
		endif
stisfil: if target eq 'hd172167' then goto,hd172167 else		$
			print,'NORMALIZING model to '+stisfil
	if strpos(stisfil(0),'target') ge 0 then 		$
		readcol,stisfil(0),w,f,delimiter=',' else begin ; LCB
			
		rdf,stisfil(0),1,d				; Stis cases
		w=d(*,0) 
		if target eq 'Sun' then begin
		   	f=d(*,1)/10  &  w=w*10		; --> cgs & Ang
		      end else f=d(*,2)  &  endelse
; 3 prime stds & hz43 already normalized but re-normalize here:
	mnwl=6800  &  mxwl=7700
;;	mnwl=(min(w)+100)>1350				; 2020mar31
;;	mxwl=(max(w)-100)<7700				; worse. use 68-7700A
; wave is model, w is data:
	normod=tin(w,f,mnwl,mxwl)/tin(wave,flux,mnwl,mxwl)
; 2014dec31 - old alpha_lyr_mod_001.fits is wrong.
hd172167:
	if target eq 'hd172167' then begin		; Vega
		wave=wave*10
		mnwl=5557.54-12.5  &  mxwl=5557.54+12.5
		normod=3.47e-9/tin(wave,flux,mnwl,mxwl)	;2020jan18
		print,'Vega norm. to 3.47e-9'
		header=[header,'Model Normalized to 3.47e-9 by'+	$
			string(normod,'(e12.5)')+' at '+     		$
			string([mnwl,mxwl],"(f6.1,'-',f6.1,' Ang')")]
	     end else							$
		header=[header,'Model Normalized to obs. by'+		$
			string(normod,'(e12.5)')+' at '+     		$
			string([mnwl,mxwl],"(f6.1,'-',f6.1,' Ang')")]

	flux=flux*normod
	if contcol then cont=cont*normod
		
	nheader=n_elements(header)
	if strpos(file,'fin') ge 0 then airtovac,wave	; vac wavelengths
;
; create binary .fits files (cf: rampfits.pro & abscorsig.pro)
;
	hd = ['END     ']
	sxaddpar,hd,'simple','T'
	sxaddpar,hd,'bitpix',16
	sxaddpar,hd,'naxis',0
	sxaddpar,hd,'extend','T','FITS extensions present?'
	name = strlowcase(target)
	if name eq 'hd172167' then name='alpha_lyr'
	if name eq 'g191' then name='g191b2b'
	if name eq 'wd1057' then name='wd1057_719'
	if name eq 'wd1657' then name='wd1657_343'
	if name eq 'wd-0308-565' then name='wd0308_565'
        spos=strpos(name,'+')
        if spos gt 0 then strput,name,'_',spos  ; replace + with _
        spos=strpos(name,'-')
        if spos gt 0 then strput,name,'_',spos  ; replace - with _
	help,target,star,name
; ###change for later versions
	ver='01'
;	ver='11'			; 3 recal Models 2019dec27
;	ver='04'			; 2020jan18 vega & sirius
	ver='05'
	sxaddpar,hd,'source', $
;		'Rauch, Werner, Bohlin, & Kruk 2013, A&A, 560, A106'
;		'Hubeny TLusty203: PURE HYDROGEN NLTE MODEL' ;2 wd*'s ........
;		'Gianninas et al. 2011'
;		'Bohlin, R. C. 2010, AJ, 139, 1515'   ; Solar Analogs. NO deliv
;		'Bohlin & Cohen, 2008, AJ, 136, 1171' ; A Stars................
;		'Bohlin, R. C., & Koester, D. 2008, AJ, 135, 1092'	; LDS
;		'Bohlin, R. C., & Gilliland, R. L. 2004, AJ, 128, 3054' ;oldVega
;		'Bohlin, R. C. 2014, AJ, 147, 127'	; Sirius & Vega
		'Bohlin, Hubeny, & Rauch 2020, AJ, in press'
;		'Bohlin, Meszaros, Gordon 2014, AJ, xxx'		; models
;		'Bohlin, Gordon, Tremblay 2014, PASP, 126, 711'		;WD mods
;		'http://kurucz.harvard.edu/stars/sun/fsunallp.5000resam51'
	sxaddpar,hd,'source2', 'Bohlin, Deustua, & de Rosa 2019, AJ, 158, 211'
;	sxaddpar,hd,'source2', 'Bohlin, Hubeny, & Rauch 2020, AJ, in press.'
; comments (do NOT overwrite one w/ another):
;	if target eq 'G191' then 					$
;	  sxaddpar,hd,'comment',"= 'Hubeny: METAL LINE BLANKETED NLTE MODEL' /"$
;	  else sxaddpar,hd,'comment',"= 'Hubeny: PURE HYDROGEN NLTE MODEL' /"
;	  else if strpos(strlowcase(file),'resam') lt 0 then		$
;	  else sxaddpar,hd,'comment',"= 'Rauch: PURE HYDROGEN NLTE MODEL' /"

;	sxaddpar,hd,'comment',"= 'Gianninas: PURE HYDROGEN NLTE MODEL' /"

; ###change END

	if target eq 'LDS749B' then sxaddpar,hd,			$
		'comment',"= 'Koester: HELIUM LTE MODEL w/ trace Carbon' /"
	if target eq 'GJ7541A' then sxaddpar,hd,			$
		'comment',"= 'Koester He LTE MODEL @ Teff/grav=10650/8.080' /"
; Sirius & Vega:
	if strpos(file,'500') gt 0 then sxaddpar,hd,			$
		'comment',"= 'Created by R. Bohlin from Kurucz Special Model' /"
	tst=mtitsav				; extract teff/grav
	dum=gettok(tst,'=')
	sxaddpar,hd,'teffgrav',gettok(tst,' '),'Teff/log g for model'
	if target eq 'sirius' then 					$
			sxaddpar,hd,'teffgrav','9850/4.3','Teff/log g for model'
	if strpos(file,'stiscal') ge 0 then begin		; GFABO models
		sxaddpar,hd,'comment',"= modtype+' BOSZ Model w/ Solar "+ $
					"Relative Abundance' /"
		sxaddpar,hd,'teffgrav',string([teff,logg],		$
					'(i5,"/",f4.2)'),'Teff/log g for model'
		endif
	sxaddpar,hd,'descrip','MODEL Fluxes -----------'+		$
			'-------------------------------------------'
	sxaddpar,hd,'dbtable','CRSPECTRUM'
	sxaddpar,hd,'targetid',strupcase(name)+'_MOD'
	sxaddpar,hd,'mapkey','calspec'		; 2017nov8 for Rossy
 	sxaddpar,hd,'airmass',0.0,'mean airmass of the observation'
       if target eq 'Sun' then sxaddpar,hd,'resoluti',5000,'Spectral resolution'
	sxaddpar,hd,'USEAFTER','Jan 01 2000 00:00:00'
 	sxaddpar,hd,'PEDIGREE','MODEL'
	sxaddpar,hd,'wmin',min(wave),'Minumum Wavelength'
	sxaddpar,hd,'wmax',max(wave),'Maximum Wavelength'

; SPECIAL SECTION: begin CK04 grid models. 
;  (NOT used for CALSPEC deliv. & mostly obsolete.)
	if strpos(file,'/nical/spec/1') gt 0 or name eq 'hd165459' then begin
stop	;NOT used anymore ???
		get_castkur04_wave,wave
	   	radvel=starvel(star)
	   	wave=wave*(1+radvel/3e5)
		dum=vmag(target,ebv,spty,bvri,teff,logg,logz)
		ck04_int,wave,flux,teff,logg,logz,2
; add log-log interpol ~40microns to fill in sparce CK04 sampling:
;	(cut at 40mic, instead of max WL=160mic.)
		wnew=[findgen(40)*2500+102500,findgen(40)*5000+205000]
		linterp,alog10(wave),alog10(flux),alog10(wnew),flog
		fnew=10^flog
		good=where(wave le 100200.)
		wave=[wave(good),wnew]  &  flux=[flux(good),fnew]
		
		chiar_red,wave,flux,-(ebv),flux
		wnic=x(*,0)  &  fnic=x(*,2)
		npts=n_elements(wnic)
; extend by 1 pt to match wave:
		dlam=[wnic(1:npts-1)-wnic(0:npts-2),wnic(npts-1)-wnic(npts-2)]
		dlam=median(dlam,5)		; fix jumps @ bad dust mote pts
; dlam*4 is approx R=100. (ie *2 in each of the ff lines: {was *1 before 06jul18
		wbeg=wnic-dlam*2>wnic(0)		; 2px lower WLs 
		wend=wnic+dlam*2<max(wnic)		; & higher for /double
; smooth model to 2px, non-uniform spacing of a .mrg on same WL scale:
;	(even crude C&K04 models have sharp, deep Hyd. lines)
; smoflx now at wnic points:
		smoflx=tin(wave/1e4,flux,wbeg,wend)	; numer nic-flx NOT smo
		rat=fnic/smoflx
		ind=where(wnic ge .82 and wnic le 2.4)
		normod=avg(rat(ind))
		flux=flux*normod
		plot,wnic,rat/normod,yr=[.9,1.1]	; check
		ver='01'
		header='CK04 Model with Teff, log g, log z, E(B-V)='+	$
			string([teff,logg,logz,ebv],'(i5,f5.2,f5.1,f6.3)')
		header=[header,'Model Interpolated in Grid by ck04_int.pro'+ $
			' written by W. Landsman']
		header=[header,'Model Normalized to NICMOS by'+		$
						string(normod,'(e12.5)')]
		nheader=3
		sxaddpar,hd,'source','Bohlin & Cohen 2008, AJ, 136, 1171'
		sxaddpar,hd,'comment',"= 'Created by R. Bohlin from "+	$
					"Castelli & Kurucz (2004) model grid' /"
		sxaddpar,hd,'wmin',min(wave),'Minumum Wavelength'
		sxaddpar,hd,'wmax',max(wave),'Maximum Wavelength'
		endif				; end ck04
; ###change
;	name = name + '_mod_'+modtype+'.fits'	; for CALSPEC
	name = name + '_mod_0'+ver+'.fits'	; for CALSPEC ver 10+ or '04'
	if strpos(file,'stiscal') ge 0 then name=star+'_'+modtype+	$
							'_mod_00'+ver+'.fits'
        sxaddpar,hd,'filename',name
; add old history
;
	sxaddhist,header(0:nheader-1),hd	; add orig ascii header as hist.
;
; add some history info 
;
	sxaddhist,'UNITS: Wavelength(Angstroms), Flux(erg s-1 cm-2 Ang-1)',hd
	sxaddhist,'All wavelengths are in vacuum & adjusted for '+	$
		'radial vel='+string(radvel,'(f6.1)'),hd
	sxaddhist,'CHANGES from previous version:',hd
; ###change
	sxaddhist,'  Rauch & Hubeny WD models agree much better',hd   ; not vega
	sxaddhist,'    and the 3 prime Stds have New average Teff,log g.',hd
;	sxaddhist,'  Corr for Saturated obs. changes with time',hd    ; sirius
;	sxaddhist,'  Teff increase from 9400 to 9550K',hd	;vega
;	sxaddhist,'  Use EXTRSIZE=11 for G750L',hd
	sxaddhist,'  Reconcile visible and IR absolute flux, where',hd
	sxaddhist,'    new Vega Flux(5556A-air)=3.47e-9 Bohlin,et al '+	$
							'2020, AJ,in press',hd
	sxaddhist,'INPUT FILE: '+file,hd
	sxaddhist,'Written by MAKE_MOD_CALSPEC.pro  '+!STIME,hd
	if contcol then sxaddhist,					$
		'Include continuum in same units as FLUX',hd
	fxwrite,name,hd				; write in current dir, eg deliv

	hd = ['END     ']			; restart for extension header
	nwav=n_elements(wave)
	fxbhmake,hd,nwav
        sxaddpar,hd,'extname','SCI'
        sxaddpar,hd,'extver',1
        sxaddpar,hd,'inherit','T'
; set up col headers:
	fxbaddcol,1,hd,0.D,'WAVELENGTH',tunit='ANGSTROMS',tdisp='G10.4'
	fxbaddcol,2,hd,0.,'FLUX','Absolutely calibrated net spectrum',     $
		tunit='FLAM',tdisp='E12.4'
	if contcol then fxbaddcol,3,hd,0.,'CONTINUUM',			$
		'Continuum in same units as FLUX',tunit='FLAM',tdisp='E12.4'
;
; write table
;
        fxbcreate,unit,name,hd
        row=0
        for irow=0L,nwav-1 do begin			; no. of rows
                row=row+1L
                fxbwrite,unit,wave(irow),1,row
                fxbwrite,unit,float(flux(irow)),2,row
		if contcol then fxbwrite,unit,float(cont(irow)),3,row
		endfor
	fxbfinish,unit
	close,unit
	print,name,' Written'
nextfile:
	endfor
return
end
