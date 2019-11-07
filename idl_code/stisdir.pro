pro stisdir,filespec
;+
;			stisdir
;
; generate listing of stis observations in file dir.log
;
; INPUTS:
;	filespec - file specification of input files. If not spec use current
;		dir *raw.fits,  eg.  'DISK$DATA2:[bohlin.7096]O*raw.fits'
;
; OUTPUTS:
;	file 'dirtemp.log' is created
;
; EXAMPLES
;	stisdir
;	stisdir,'/data/rcbsun3/9876/*spt.fits'
;	stisdir,'~/data/spec/nic/n*cal.fits'
; HISTORY
;	97may20 - converted from djl hrsdir.pro
;	99jan15 - update to take max of nrptexp & cr-split; & sclamp for no targ
;	00may23 - output moffset1 and moffset2, if postarg=0
;	01mar8 - ........ +-3" G140 position, if ...........
;	02aug4 - add ck for 9611 amp B CTE tests.
;	03may  - add nicmos capability
;	06jan  - add ACS for checking 10557 - faith & amanda data
;	14dec - trim Massa GSC names to fit in 12 char
;	16aug - Add secondary time sort per dirwfc.pro for NICMOS HD189733 
;-
;--------------------------------------------------------------------------

;
; find files to process
;
	if N_PARAMS(0) EQ 0 THEN filespec='*raw.fits'
	lst = findfile(filespec,count=n)
	if n lt 1 then begin
		print,'stisDIR - no files found for given filespec'
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
		fits_open,lst(i),fcb
		extnames = strtrim(fcb.extname)
		crsplit = long(total(extnames eq 'SCI'))
		fits_close,fcb
		fits_read,lst(i),im,hd
;
; extract header info
;
		grating = sxpar(hd,'OPT_ELEM')
		aperture = sxpar(hd,'propaper')	; new E1 name @ CCD row 900
		if strtrim(aperture,2) eq '' then aperture =		$
			sxpar(hd,'aperture')	; 2019may5-old data eg O3YX11P2M
		subarr=sxpar(hd,'subarray') eq 1

;FSW-lab:
		if strtrim(grating,2) eq '0' then grating=sxpar(hd,'optmode')
		if strtrim(aperture,2) eq '0' then aperture=sxpar(hd,'slitsize')
		targname=sxpar(hd,'targname')
		if strpos(targname,'6822-HV') ge 0 then targname=	$
			       replace_char(targname,'-','')   ; n6822 shorten
; fix Massa long names:
		if strpos(targname,'GSC') eq 0 then targname=		$
				replace_char(targname,'-0','')
		if strpos(targname,'MFH2007-SMC5') eq 0 then targname=	$
			'MFHSMC5'+strmid(targname,13,5)
;04jul21 fix typo:
		if strpos(targname,'SNAP7') ge 0 then targname='SNAP-1      '
		if strpos(targname,'VB-8') ge 0 then targname='VB8         '

		if strpos(targname,'GJ-894.3') ge 0 then targname='FEIGE110    '
		if strpos(targname,'HD120315') ge 0 then targname='ETAUMA      '
		if strpos(targname,'SDSSJ151') ge 0 then targname='SDSSJ151421 '
		if strpos(targname,'NONE') ge 0 then 			$
; 01mar8. sclamp has been shortened to 9 char in ~2001 !
			targname=sxpar(hd,'sclamp')+'   '
		minwave = string(fix(sxpar(hd,'minwave')+0.5),'(i5)')
		maxwave = string(fix(sxpar(hd,'maxwave')+0.5),'(i5)')
		obsmode = sxpar(hd,'obsmode')
		instr=strtrim(sxpar(hd,'instrume'),2)	; 06jan-try for ACS

; fix bug in 7805 headers:
;		if crsplit eq 3 and strtrim(sxpar(hd,'PROPOSID'),2)    $
;					eq '7805' then crsplit=2
; idiot ck:
		if crsplit*3 ne sxpar(hd,'NEXTEND') and strpos(obsmode,'ACQ') $
				lt 0 and strpos(lst(i),'FSW') lt 0 and	      $
				instr ne 'NICMOS' and			      $
				strpos(lst(i),'/x1/') lt 0 and		      $
; trans/readout screwup, stisfix:
				strpos(lst(i),'O49X01010') lt 0 	      $
				and strpos(lst(i),'x1d') lt 0 then begin
			print,'Stop in stisdir. crsplit ck: nextend,crsplit=', $
					sxpar(hd,'NEXTEND'),crsplit
			stop
			endif
		crsplit = string(crsplit,'(i3)')
		exptime = sxpar(hd,'texptime')		
		if exptime eq 0 then exptime=sxpar(hd,'exptime')	; nicmos
; 2018dec28 - mirvis always has wrong value for texptime????
;	texptime is total exp time, while exptime is for single exp of CR-split
;John Debes says texptime accounts for initial, lamp, and confirmation images 
;	which are all present in the extensions. So Leave it as is-rcb.
		date = sxpar(hd,'date-obs')
		if strpos(date,'-') gt 0 then date=strmid(date,2,8)	;y2k
		time = sxpar(hd,'time-obs')
		propid = string(sxpar(hd,'proposid'),'(i5)')
		det =strtrim(sxpar(hd,'detector'),2)+' '
		mglobal='      0'
		if strpos(det,'MAMA') ge 0 then	 			$
				mglobal=string(total(im)/exptime,'(i7)')
		exptime = string(exptime,'(F8.1)')
		gain = string(sxpar(hd,'ccdgain'),'(i1)')
; lab FSW data, assuming amp D corresponds to ccdgain4
		if gain eq '0' then gain = string(sxpar(hd,'ccdgain4'),'(i1)')
		amp=' '
		if strpos(det,'CCD') ge 0 then begin
			det='CCDgain'+gain+' '
			amp=strtrim(sxpar(hd,'ccdamp'),2)
			if amp eq 'D' then amp=' '	; default amp
			endif
		cenwav = string(fix(sxpar(hd,'cenwave')+.5),'(i5)')
		postarg=string(sxpar(hd,'postarg2'),'(f6.1)')
		if float(postarg) eq 0 then begin		; 02nov14
			postarg='   0.0'		; eliminate -0.0
			m1=sxpar(hd,'moffset1')
			m2=sxpar(hd,'moffset2')
			if m1 ne 0 and m2 ne 0 then begin
				postarg=string([m1,m2],'(i3,",",i3,"px")')
				if m1 lt -99 or m2 lt -99 then		$
				    postarg=string([m1,m2],'(i4,",",i4,"px")')
				endif
; no FUV MAMA position info for x1 dir of stsci pipeline x1 files:
			if strpos(grating,'G140L') ge 0 and postarg eq 0  $
				     and strpos(lst(i),'/x1/') lt 0 then begin
				stpos=strpos(lst(i),'.fits')
				filspt=lst(i)  &  strput,filspt,'spt',stpos-3
				filspt=strmid(filspt,0,stpos+5)
				fits_read,filspt,dum,hdspt
			        msmpos=sxpar(hdspt,'OMSCYL1P')    ;MSM cyl 1 pos
				if msmpos lt 800 then postarg=' -3pos' else    $
								postarg=' +3pos'
				endif
			endif
		if instr eq 'NICMOS' or instr eq 'ACS' then begin
			crx=sxpar(hd,'crval1')  &  cry=sxpar(hd,'crval2')
			nicid=strmid(root,0,6)
			if nicid ne niclast then begin
				crxlast=crx  &  crylast=cry
				nicount=0	; reset counter
				end
			niclast=nicid
			dx=(crx-crxlast)*3600*cos(cry/!radeg)
			dy=(cry-crylast)*3600
			if abs(dx) lt .01 then dx=0
			if abs(dy) lt .01 then dy=0
			postarg=string(dx,dy,'(f5.1,",",f5.1)')
			if postarg ne poslast then nicount=nicount+1
			poslast=postarg
			crsplit=string(nicount,'(i3)')
			grating=sxpar(hd,'filter',count=count)
			det='   '+strtrim(sxpar(hd,'camera'),2)+'      '
			aperture=strtrim(sxpar(hd,'aperture'),2)
			if count eq 0 then begin			; ACS
				grating=sxpar(hd,'filter1')
				cenwav='      '
				det=aperture+'       '
				aperture=sxpar(hd,'filter2')
				crsplit=string(sxpar(hd,'crsplit'),'(i3)')
				if strmid(targname,0,3) eq 'AST' then	$
					targname='ASTRD'+strmid(targname,8,5)
				postarg=string([sxpar(hd,'postarg1'),	$
				  sxpar(hd,'postarg2')],'(f6.3,",",f6.3)')
				minwave='   '  &  maxwave=minwave
				endif
			endif			
		if i eq 0 then begin
			if dir eq '' then dir=propid
			PRINTF,UNIT,'STISDIR '+!stime
			printf,unit,'SEARCH FOR '+filespec
			printf,unit,'  ROOT      MODE    APER  CENWAV'+        $
			   ' DETECTOR'+ $
			   '  TARGET     OBSMODE MGLOBAL   DATE     TIME'+     $
			   '  PROPID  EXPTIME CR  MINW  MAXW POSTARG'
			endif
;
; format and print to text file
;
		st = root+amp+' '+strmid(grating,0,7)+' '+ 	$
		     strmid(aperture,0,8)+ 				$
		     strmid(cenwav,0,6)+' '+strmid(det,0,9)+     	$
		     strmid(targname,0,12)+' '+strmid(obsmode,0,7)+	$
		     mglobal+' '+					$
		     strmid(date,0,8)+ ' '+strmid(time,0,8)+' '+	$
		     strmid(propid,0,5)+' '+exptime+			$
		     crsplit+' '+minwave+' '+maxwave+postarg
		if subarr and strpos(obsmode,'ACQ') lt 0 then strput,st,'#',9
		strout(i)=st

	end
;do not sort STIS, because the 1999 yrs follow 2000 !!
if strpos(filespec,'/nic') ge 0 then begin
	targsort=strmid(strout,42,12)
	timesort=strmid(strout,70,17)
	indx=sort(targsort+timesort)
	strout=strout(indx)
	endif					; comment 2019jun4
printf,unit,strout
printf,unit,' # - Subarray.   A,B,C - non std CCD Amp'
free_lun,unit

return
end
