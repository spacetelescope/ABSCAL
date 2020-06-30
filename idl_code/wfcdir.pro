pro wfcdir,filespec
;+
;			wfcdir
;
; generate listing of wfc3 observations in file dir.log
;
; INPUTS:
;	filespec - file specification of input files. If not spec use current
;		dir *raw.fits
; OUTPUTS:
;	file 'dirtemp.log' is created
;
; EXAMPLES
;	wfcdir,'/user/deustua/data/i*flt.fits'
; HISTORY
; 2012Feb-converted from stisdir.pro
; 2012Jun6-do trailed log w/ new SCAN_RAT col.
; 2013Jun6-add sort by target name
; 2015Jan9-and do secondary sort by date,time-obs. Add image size.
; 2017May18-add more typos and alternative names. (SED)
; 2018Apr10-Sort by filter does not work for pairing grism w/ direct image. RM.
; 2018apr12-Policy for fetching IR grism data from MAST, for ea star:
;	- get all g102 & g141 Filters (un-ck dark, tungsten, etc.) and
;	   filter=f0*,f1* (un-ck dark, tungsten, etc.)-->Lots of excess photom
;	(- NG: get aper=IR*,g102*,g141* to be sure of getting all direct images,
;		as there are a few grism* apers, eg for GD153,GD71.)
;	Mod this pro to output only dir img photom for output
; 2018apr19 - Correct targ coord for Proper Motion
; 2020Apr22 - Mod to work for UVIS photometry
;
; DOC:
;There is no flag that tells you the data is trailed. you need to look in the 
;spt headers for keywords SCAN_RAT, SCAN_LEN, ANG_SIDE,SCAN_WID
;-
;--------------------------------------------------------------------------

;
; find files to process
;
if N_PARAMS(0) EQ 0 THEN filespec='*raw.fits'
lst = findfile(filespec,count=n)
print,n,' wfcdir - files found for given filespec'

niclast=''				; last nicmos observation ID
poslast=''				; last nicmos offset
blank='            '			; for padding short targnames 2020jan
strout=strarr(n)			; output string array for sorting
;
; open output file
;
openw,unit,'dirtemp.log',/get_lun
PRINTF,UNIT,'WFCDIR '+!stime
printf,unit,'SEARCH FOR '+filespec
printf,unit,'  ROOT	  MODE	      APER     TYPE '+			$
	'    TARGET	    IMG SIZE   DATE     TIME'+			$
	'   PROPID   EXPTIME      POSTARG X,Y SCAN_RAT'
;
; loop on files
;
for i=0,n-1 do begin
;for i=0,500 do begin				; test
	fdecomp,lst(i),disk,dir,root,ext     ;disk is always '' in Unix
	root = strmid(root+'          ',0,9)
;
; read header
;
;if strpos(lst(i),'icmd71kdq') ge 0 then stop
	fits_read,lst(i),im,hd,header_only,/NO_ABORT,message=message
	if message ne '' then time='BAD FILE'
;
; extract header info
;
	grating = sxpar(hd,'filter')
; aperture = G102 for iab904mfq, ans should be G141-REF BUT no problem.
	aperture = sxpar(hd,'aperture')
; 2020feb3 - Get orig target name from SPT file to fix Gaia name screwup
; Read SPT file to get trail rate & orig targname.
	fil=lst(i)
	posn=strpos(fil,'.fits')
	strput,fil,'spt',posn-3
	fil=findfile(fil)
	if fil eq '' then scnrat=0 else begin		; 2013nov6
			fits_read,fil,im,hspt,/header_only,exten_no=1
			scnrat=sxpar(hspt,'SCAN_RAT')
;			help,scnrat & stop
			endelse

	targname=sxpar(hspt,'targname')			; 2020feb3 was hd
	if strpos(targname,'6822-HV') ge 0 then targname=	$
			       replace_char(targname,'-','')   ; n6822 shorten
;fix typos and alternate names:
	if strpos(targname,'GD-153') ge 0 then targname=   'GD153       '
	if strpos(targname,'GD-71') ge 0 then targname=    'GD71        '
        if strpos(targname,'BD+52-913') ge 0 then targname='G191B2B     '
        if strpos(targname,'G 191-B2B') ge 0 then targname='G191B2B     '
        if strpos(targname,'EGGR-247') ge 0  then targname='G191B2B     '
        if strpos(targname,'HIP66578') ge 0 then targname= 'GRW_70D5824 '
        if strpos(targname,'HIP-66578') ge 0 then targname='GRW_70D5824 '
        if strpos(targname,'EGGR-102') ge 0 then targname= 'GRW_70D5824 '
        if strpos(targname,'70D5824') ge 0 then targname=  'GRW_70D5824 '
        if strpos(targname,'GSC-02581-02323') ge 0 then targname='P330E       '
        if strpos(targname,'J17583798+6646522') ge 0 		$
					then targname='KF06T2      '
        if strpos(targname,'KF06T2') ge 0 		$
					then targname='KF06T2      '
	if strpos(targname,'VB8') ge 0 then   targname='VB8         '
        if strpos(targname,'GJ644C') ge 0 then targname='VB8         '
        if strpos(targname,'18022716') ge 0 then targname='1802271     '
        if strpos(targname,'180227') ge 0 then targname='1802271     '
        if strpos(targname,'WD1657') ge 0 then targname='WD1657_343  '
        if strpos(targname,'116405') ge 0 then targname='HD116405    '
        if strpos(targname,'205905') ge 0 then targname='HD205905    '
        if strpos(targname,'37725') ge 0 then targname='HD37725     '
        if strpos(targname,'38949') ge 0 then targname='HD38949     '
        if strpos(targname,'60753') ge 0 then targname='HD60753     '
        if strpos(targname,'93521') ge 0 then targname='HD93521     '
	if strpos(targname,'J00361') ge 0 then targname='2M003618    '
	if strpos(targname,'J05591') ge 0 then targname='2M055914    '
	if strpos(targname,'J17571') ge 0 then targname='1757132     '
	if strpos(targname,'LTT-2351') ge 0 then targname='HD37962     ';nostare
	if strpos(targname,'BD+60-1753')  ge 0 then targname='BD60D1753   '
	if strpos(targname,'J18083') ge 0 then targname='1808347     '
	if strpos(targname,'180609') ge 0 then targname='HD180609    '
	if strpos(targname,'SNAP-2') ge 0 then targname='SNAP2       '
	if strpos(targname, 'GOODS-S')  ge 0 then targname='C26202      '
	if strpos(targname,'NONE') ge 0 then 				$
				targname=sxpar(hd,'sclamp')+'   '
	if strmid(targname,0,4) eq 'GAIA' then targname='GAIA'+		$
		strmid(targname,9,3)+'_'+strmid(targname,24,4)
	naxis1=string(sxpar(hd,'naxis1'),'(i4)')
	naxis2=string(sxpar(hd,'naxis2'),'(i4)')
	instr=strtrim(sxpar(hd,'instrume'),2)	; 06jan-try for ACS
	exptime = sxpar(hd,'texptime')
	if exptime eq 0 then exptime=sxpar(hd,'exptime')	; nicmos
	date = sxpar(hd,'date-obs')
	if strpos(date,'-') gt 0 then date=strmid(date,2,8)	;y2k
	if message eq '' then time = sxpar(hd,'time-obs')
	propid = string(sxpar(hd,'proposid'),'(i5)')
	imtype=sxpar(hd,'imagetyp')
	exptime = string(exptime,'(F8.1)')
	gain = string(sxpar(hd,'ccdgain'),'(i1)')
	if gain eq '0' then gain = string(sxpar(hd,'ccdgain4'),'(i1)')
	amp=' '
	m1=sxpar(hd,'postarg1')
	m2=sxpar(hd,'postarg2')
	postarg=string([m1,m2],'(f7.1,",",f7.1)')
; ###change - 2nd below for scanned log, 1st (ne 0) for stare:
	if scnrat ne 0 then goto,skipit			; for stare obs
;	if scnrat eq 0 and strmid(grating,0,1) 	eq 'G' then goto,skipit
	rate=string(scnrat,'(f7.4)')
;
; format for printing to text file. amp is just a ' ' dummy placeholder 
;
	len=strlen(targname)
	if len lt 12 then targname=targname+strmid(blank,0,12-len)
	strout(i) = root+amp+' '+strmid(grating,0,7)+' '+ 	$
		     strmid(aperture,0,15)+' '+strmid(imtype,0,6)+	$
		     strmid(targname,0,12)+' '+naxis1+'x'+naxis2+	$
		     ' '+strmid(date,0,9)+ ' '+strmid(time,0,8)+' '+	$
		     strmid(propid,0,5)+' '+exptime+postarg+rate
;	print,i,' done of',n-1
	fxhmodify,lst(i),'targname',targname,'Updated by wfcdir.pro-rcb'

skipit:
	endfor				; # of files. All obs read and formatted
		
; 2018Apr19 - Correct for lazy WFC3 IS, who omit the PM!
;	list of stars w/ P.M. > ~4px = ~0.5" in 25 yrs-->i.e. 20milli-arcsec/yr:
fastar=['G191B2B','GD153','GD71','GRW_70D5824','HD37725','HD205905',	     $
'HD38949','LDS749B','VB8','WD1657_343','WD1327_083','WD2341_322','2M003618', $
	'2M055914']
; use ten(hr,mn,sc)*15, ck w/ sixty.pro
; Use Simbad coord, but some are specified differently, eg WD2341+322
;	and astrom is based on specified star coord.
rafast= [76.377553d,194.25974,88.115058,204.71032,85.476546,324.79230,	     $
	 87.083579,323.06767,253.89705,254.71300,202.55683,355.96136,9.0674, $
	 89.829762]
decfast=[52.831100d,22.031300,15.887153,70.285461,29.297478,-27.306575,	     $
-24.463850,0.25400000,-8.394475,34.314803,-8.5748601,32.546293,18.352908,    $
	-14.080244]
; mas/yr: 2020jun5 update per CALSPEC page.
rapm=[  12.6,-38.4,76.8, -402, 15.0,384.1,-30.4,413.2,-813.4,  8.8,-1111.1,  $
	-215.8,901.6,570.2]
decpm=[-93.5, -203,-173,-24.6,-26.9,-84.0,-35.4, 27.3,-870.6,-31.2, -472.4,  $
	 -59.7,124.0,-337.6]
; ###change: 2018apr12 - keep only adjacent direct images (F*) for grism cases
;	must go star-by-star. Mod here to make photom, etc. logs

good=where(strpos(strout,'DARK') lt 0 and strpos(strout,'TUNGSTEN')	$
		lt 0 and strout ne '')
strout=strout(good)						; elim trash

target=strmid(strout,41,12)
times=strmid(strout,64,17)
indx=sort(target+times)
strout=strout(indx)					;sort by targ,time

target=strmid(strout,41,12)
targsort=target(sort(target))				; sort targets for uniq
star=uniq(targsort)					; indices for uniq stars
nstar=n_elements(star)
for istr=0,nstar-1 do begin
	targ=strtrim(targsort(star(istr)),2)
	indstr=where(strpos(strout,targ) ge 0)			; same star
	strsort=strout(indstr)					;subset per star

; 2020apr22 - skip grating sorting:
	if strpos(filespec,'UVIS') gt 0 then begin
		filter=strmid(strsort,11,7)		;sorted by targ,time
		times=strmid(strsort,64,17)
		strsort=strsort(sort(filter+times))
		uv=where(strpos(strsort,'UVIS') ge 0)
		ir=where(strpos(strsort,'UVIS') lt 0)
		strsort=[strsort(uv),strsort(ir)]
		indx=where(strpos(strout,targ) ge 0)
		goto,skipgrat
		endif

	filt=strmid(strsort,11,7)				; filters
; expand by one in the index (per IUE reso flagging)
	shftp=shift(filt,1)  &   shftp(0)='xxx'
	shftm=shift(filt,-1)  &   shftm(-1)='xxx'
	ind=where(filt eq 'G102   ' or filt eq 'G141   ' or		$
		shftp eq 'G102   ' or shftp eq 'G141   ' or		$
		shftm eq 'G102   ' or shftm eq 'G141   ')
	filt=filt(ind)						;elim index
	strsort=strsort(ind)
	len=strlen(strsort(0))
	strsort=strmid(strsort,0,11)+filt+strmid(strsort,18,len-1)
; 2018apr14-elim orphan image filters w/o a grism w/ same root assoc:
	filtyp=strmid(filt,0,1)
	dum=where(filtyp eq 'G',ngrat)
	if ngrat eq 0 then goto,nograt

	root=strmid(strsort,0,6)
	imfilt=where(filtyp eq 'F',nfilt)		; img filt obs
	indx=indgen(n_elements(strsort))		; indx of all obs of *
	if nfilt gt 0 then for ifilt=0,nfilt-1 do begin ;elim filt w/ no grating
	       good=where(filtyp eq 'G' and root(imfilt(ifilt)) eq root,ngd)
	       if ngd eq 0 then indx=indx(where(indx ne imfilt(ifilt)))	; rm bad
	       endfor
; THE LOG:
skipgrat:
	printf,unit,strsort(indx)		;ea obs. set (1st 6 char root)
; ******************************************************

; Correct the coord below:
	root=strmid(strsort(indx),0,9)
	fils=dir+root+'_flt.fits
	nfils=n_elements(root)
	for ifil=0,nfils-1 do begin		; do all stars to add pstrtime
	    sptfil=fils(ifil)
	    pos=strpos(sptfil,'.fits')
	    strput,sptfil,'spt',pos-3
	    dum=findfile(sptfil)
	    fracyr=0.
	    pstrtime=0.
	    if dum ne '' then begin
		fits_read,sptfil,dum,hdspt
		pstrtime=sxpar(hdspt,'pstrtime')
		fracyr=absdate(pstrtime)-2000
		endif
	    indx=where(targ eq fastar)  &  indx=indx(0)
	    if indx lt 0 then goto,nopm		; skip PM computation & addition
; make a PM correction:
; 2018apr19 - Correct target coord for missing Proper Motion for ea obs set:
;if J2000 coord are wrong in Ph2, these wrong coord are still used for astrom.
	    tra=rafast(indx)			; new J2000 coord
	    tdec=decfast(indx)
;corr for pm
	    delra=fracyr*rapm(indx)/1000.d  ; arcsec
	    deldec=fracyr*decpm(indx)/1000.d
;	    print,'PM corr for '+targ+' at',tra,tdec,fracyr,delra,deldec, $
;	    	    '	  for '+fils(ifil),form='(a,2f11.6,3f8.2/a)'
	    tra=tra+delra/3600.d		    ;degree coord of ref. px
	    tdec=tdec+deldec/3600.d
	    fxhmodify,fils(ifil),'RA_TARG',tra(0),		    $
	    		    'PM included by wfcdir.pro-rcb'
	    fxhmodify,fils(ifil),'DEC_TARG',tdec(0),		    $
	    		    'PM included by wfcdir.pro-rcb'
nopm:
	    fxhmodify,fils(ifil),'pstrtime',pstrtime,		    $
	    		    'Added by wfcdir.pro-rcb'
	    endfor						; coord update
nograt:								; no grat in obs
	endfor							; ea star
		
free_lun,unit
;stop
return
end
