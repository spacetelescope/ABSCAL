
STOP --- OLD VERSION. SEE MAKE_MOD_CALSPEC.PRO 07dec23



pro make_wd_calspec,filespec
;+
;			make_wd_calspec
;
; procedure to convert model ascii file to CALspec binary fits files
;
; CALLING SEQUENCE:
;	make_wd_calspec,filespec
;
; INPUTS:
;	filespec - filespec for ascii model w/ fully calib flux 
;
; OUTPUTS:
;	.fits files with names placed in current directory
;		<starname>_mod_00x.fits (read w. mrdfits)
; 
; EXAMPLE:
;	
;	make_wd_calspec,'g191.hub03-nlte' 
;
; HISTORY:
;	00apr4 - convert from make_iue_calobs
;	07sep20 - Add Input file as HISTORY
;		test of gd71_mod_005 in ~/wd is the same as copy in calspec
;		hub03-nlte are input files for current primary stds.
;-
;-----------------------------------------------------------------------------
;
; find files to process
;
    filelist = findfile(filespec)
	print,'processing:',filelist
;
; loop on files
;
    for ifile=0,n_elements(filelist)-1 do begin
	file = filelist(ifile)

;
; read input file
;
	rdfhdr,file,0,x,header
	indx=where(strpos(header,'1  =') lt 0 and strpos(header,'2  =') lt 0)
	header=header(indx)				; elim finley table stuf
	nheader=n_elements(header)
	indx=where(strmid(header,0,7) eq 'HISTORY',numhist)
	if numhist gt 0 then header(indx) = strmid(header(indx),8,71)
        target=!mtitle
	target = strtrim(target,2)
	target = gettok(target,' ')

	wave=x(*,0)
	if strpos(file,'fin') ge 0 then airtovac,wave	; vac wavelengths
	flux=x(*,1)
;
; create binary .fits files (ref: rampfits.pro & abscorsig.pro)
;
	nwav=n_elements(wave)
	hd = ['END     ']
	sxaddpar,hd,'simple','T'
	sxaddpar,hd,'bitpix',16
	sxaddpar,hd,'naxis',0
	sxaddpar,hd,'extend','T','FITS extensions present?'
	name = strlowcase(target)
	if name eq 'g191' then name='g191b2b'
        spos=strpos(name,'+')
        if spos gt 0 then strput,name,'_',spos  ; replace + with _
        spos=strpos(name,'-')
        if spos gt 0 then strput,name,'_',spos  ; replace - with _
; ###change for later versions
	sxaddpar,hd,'source', $
		'Bohlin, R. C., & Koester, D. 2008, AJ, submitted'
	sxaddpar,hd,'comment','Created by R. Bohlin: Koester HELIUM LTE MODEL'
	ver='4'
	if strpos(file,'gd71') ge 0 then ver='5'
	if strpos(file,'lds') ge 0 then ver='1'
; get pure koester header:
	frst=where(strpos(header,'MODE') eq 0)
	header=header(frst:nheader-1)
	nheader=n_elements(header)
; change end
	name = name + '_mod_00'+ver+'.fits'	; 00apr19-new names for CALSPEC
        sxaddpar,hd,'filename',name
	sxaddpar,hd,'descrip',target+' MODEL for primary flux standard'
	sxaddpar,hd,'dbtable','CRSPECTRUM'
	sxaddpar,hd,'targetid',target+'_MOD'
	sxaddpar,hd,'airmass',0.0,'mean airmass of the observation'
	stime = strmid(!stime,0,11)
; wrong format. need: 99-10-01
;	sxaddpar,hd,'date',stime,'Date this file was written'
	sxaddpar,hd,'USEAFTER','Jan 01 2000 00:00:00'
 	sxaddpar,hd,'PEDIGREE','MODEL'
	sxaddpar,hd,'wmin',min(wave),'Minumum Wavelength'
	sxaddpar,hd,'wmax',max(wave),'Maximum Wavelength'
; add old history
;
	sxaddhist,header(0:nheader-1),hd	; add orig ascii header as hist.

;
; add some history info
;
	sxaddhist,' All wavelengths are in vacuum.',hd
	sxaddhist,' INPUT FILE: '+file,hd
	sxaddhist,' Written by MAKE_WD_CALSPEC.pro  '+STIME,hd

	fxwrite,name,hd

	hd = ['END     ']			; restart for extension header
	fxbhmake,hd,nwav
        sxaddpar,hd,'extname','SCI'
        sxaddpar,hd,'extver',1
        sxaddpar,hd,'inherit','T'
; set up col headers:
	fxbaddcol,1,hd,0.,'WAVELENGTH',tunit='ANGSTROMS',tdisp='G10.4'
	fxbaddcol,2,hd,0.,'FLUX','Absolutely calibrated net spectrum',     $
		tunit='FLAM',tdisp='E12.4'
;
; write table
;
        fxbcreate,unit,name,hd
        row=0
        for irow=0L,nwav-1 do begin			; no. of rows
                row=row+1L
                fxbwrite,unit,float(wave(irow)),1,row
                fxbwrite,unit,flux(irow),2,row
		endfor
	fxbfinish,unit
	close,unit
nextfile:
	endfor
return
end
