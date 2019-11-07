pro hrsdir,filespec
;+
;			hrsdir
;
; generate listing of hrs observations in file dir.log
;
; INPUTS:
;	filespec - file specification of input files
;		(eg.  'DISK$DATA1:[HRSDATA.1234]z*.c1h')
;
; OUTPUTS:
;	file 'dirhrs.log' is created
;
; EXAMPLES
;	hrsdir,'z*.c1h'
;	hrsdir,'disk$data1:[hrs.data.9876]z*.c1h'
; HISTORY
;	96FEB-DJL
;	96APR1-RCB TAKE OVER AND ADD DETECTOR AND DISK
; 96jul30-lengthen targname field from 13 to 14 char for NGC6822-OB13-9
;-
;--------------------------------------------------------------------------

;
; find files to process
;
	list = findfile(filespec,count=n)
	if n lt 1 then begin
		print,'HRSDIR - no files found for given filespec'
		return
	end
;
; open output file
;
	openw,unit,'dirhrs.log',/get_lun
	FDECOMP,LIST(0),DISK,DIR,ROOT,EXT
	PRINTF,UNIT,disk+dir
	printf,unit,'SEARCH FOR '+filespec
;
; loop on files
;
	for i=0,n-1 do begin
		fdecomp,list(i),disk,dir,root,ext
		root = strmid(root+'          ',0,9)
;
; read header
;
		sxhread,list(i),h
;
; extract header info
;
		DET=strtrim(sxpar(h,'DETECTOR'),2)
		grating = strtrim(sxpar(h,'grating'))
		aperture = sxpar(h,'aperture')
		targname = sxpar(h,'targname')
		minwave = string(fix(sxpar(h,'minwave')+0.5),'(i4)')
		maxwave = string(fix(sxpar(h,'maxwave')+0.5),'(i4)')
		obsmode = sxpar(h,'obsmode')
		gcount = string(sxpar(h,'gcount'),'(I4)')
		exptime = string(sxpar(h,'exptime'),'(F8.1)')
		date = sxpar(h,'date-obs')
		time = sxpar(h,'time-obs')
		propid = strtrim(sxpar(h,'proposid'),2)+'            '
;
; format and print to text file
;
		st = root+'  '+DET+'  '+strmid(grating,0,7)+' '+ $
		     strmid(aperture,0,4)+ ' ' +$
		     strmid(targname,0,14)+' '+strmid(obsmode,0,6)+' ' + $
		     minwave+' '+maxwave+' '+ gcount+' '+ $
		     strmid(date,0,8)+ ' '+ $
		     strmid(time,0,8)+' '+strmid(propid,0,5)+' '+exptime

		printf,unit,st
	end

free_lun,unit
return
end
