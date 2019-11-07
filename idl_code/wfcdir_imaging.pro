pro wfcdir_imaging,filespec
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
; 2018May18-added SPT directory for the GRW+70 work.  assumes spt.fits files are in subdirectory called SPT
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
	if n lt 1 then begin
		print,'wfcdir - no files found for given filespec'
		return
		end
niclast=''				; last nicmos observation ID
poslast=''				; last nicmos offset
strout=strarr(n)			; output string array for sorting
;
; open output file
;
	openw,unit,'dirtemp.log',/get_lun
;
; loop on files
;
	for i=0,n-1 do begin
		fdecomp,lst(i),disk,dir,root,ext     ;disk is always '' in Unix
		root = strmid(root+'          ',0,9)
;
; read header
;
;;del?		fits_open,lst(i),fcb
;; "  2017		extnames = strtrim(fcb.extname)
;; " apr4??		fits_close,fcb
;if strpos(lst(i),'icmd71kdq') ge 0 then stop
		fits_read,lst(i),im,hd,header_only,/NO_ABORT,message=message
		if message ne '' then time='BAD FILE'
;
; extract header info
;
		grating = sxpar(hd,'filter')
; aperture = G102 for iab904mfq, ans should be G141-REF BUT no problem.
		aperture = sxpar(hd,'aperture')

		targname=sxpar(hd,'targname')
		if strpos(targname,'6822-HV') ge 0 then targname=	$
			       replace_char(targname,'-','')   ; n6822 shorten
;fix typos:
		if strpos(targname,'VB-8') ge 0 then   targname='VB8         '
		if strpos(targname,'GD-153') ge 0 then targname='GD153       '
		if strpos(targname,'GD-71') ge 0 then  targname= 'GD71        '
		if strpos(targname, 'EGGR-247') ge 0 then targname= 'G191B2B     '
		if strpos(targname,'NONE') ge 0 then 			$
; 01mar8. sclamp has been shortened to 9 char in ~2001 !
			targname=sxpar(hd,'sclamp')+'   '
		naxis1=string(sxpar(hd,'naxis1'),'(i4)')
		naxis2=string(sxpar(hd,'naxis2'),'(i4)')
		instr=strtrim(sxpar(hd,'instrume'),2)	; 06jan-try for ACS
		exptime = sxpar(hd,'texptime')
		if exptime eq 0 then exptime=sxpar(hd,'exptime')	; nicmos
		date = sxpar(hd,'date-obs')
		if strpos(date,'-') gt 0 then date=strmid(date,2,8)	;y2k
		if message eq '' then time = sxpar(hd,'time-obs')
		propid = string(sxpar(hd,'proposid'),'(i5)')
;2012jun6	det =strtrim(sxpar(hd,'detector'),2)+' '
		imtype=sxpar(hd,'imagetyp')
		exptime = string(exptime,'(F8.1)')
		gain = string(sxpar(hd,'ccdgain'),'(i1)')
; lab FSW data, assuming amp D corresponds to ccdgain4
		if gain eq '0' then gain = string(sxpar(hd,'ccdgain4'),'(i1)')
		amp=' '
;		if strpos(det,'CCD') ge 0 then begin
;			det='CCDgain'+gain+' '
;			amp=strtrim(sxpar(hd,'ccdamp'),2)
;			if amp eq 'D' then amp=' '	; default amp
;			endif
		m1=sxpar(hd,'postarg1')
		m2=sxpar(hd,'postarg2')
		postarg=string([m1,m2],'(f7.1,",",f7.1)')
		if i eq 0 then begin
			if dir eq '' then dir=propid
			PRINTF,UNIT,'WFCDIR '+!stime
			printf,unit,'SEARCH FOR '+filespec
			printf,unit,'  ROOT      MODE    APER  '+        $
			   '  TYPE '+ $
			   '  TARGET       IMG SIZE   DATE     TIME'+    $
			   '   PROPID EXPTIME   POSTARG X,Y SCAN_RAT'
			endif
; Read SPT file to get trail rate.
		fil=lst(i)
		posn=strpos(fil,'.fits')
		strput,fil,'spt',posn-3
		fil=findfile('SPT/'+fil)
		if fil eq '' then scnrat=99 else begin		; 2013nov6
			fits_read,fil,im,hspt
			scnrat=sxpar(hspt,'SCAN_RAT')
;			help,scnrat & stop
			endelse
		rate=string(scnrat,'(f7.4)')
;
; format and print to text file
;
		strout(i) = root+amp+' '+strmid(grating,0,7)+' '+ 	$
		     strmid(aperture,0,8)+' '+strmid(imtype,0,6)+	$
		     strmid(targname,0,12)+' '+naxis1+'x'+naxis2+	$
		     ' '+strmid(date,0,9)+ ' '+strmid(time,0,8)+' '+	$
		     strmid(propid,0,5)+' '+exptime+' '+postarg+' '+rate
;		print,i,' done of',n-1
skipbad:
		endfor
targsort=strmid(strout,34,12)
timesort=strmid(strout,56,17)
indx=sort(targsort+timesort)
strsort=strout(indx)

printf,unit,strsort
		
free_lun,unit
;stop
return
end
