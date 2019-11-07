pro ibm2ndads,filespec
;+
;			ibm2ndads
;
; Convert IBM IUE files to NDADS format.  (lab and data files are combined
; into a single file.
;
; INPUTS:
;	filespec - file spec for the input label files (default= '*.lab*')
;
; EXAMPLES:
;
;	ibm2ndads		;all *.lab* files in current directory
;	ibm2ndads,'*.labm*'	;all Melo files in current directory
;
; FILE NAMING CONVENTION
;			IBM format		NDADS format
; Melo files 	name.LABM1, name.DATM1		name.MELO1
; 		name.LABM2, name.DATM2		name.MELO2
; ELBL files 	name.LABE1, name.DATE1		name.ELBL1
; 		name.LABE2, name.DATE2		name.ELBL2
;
; If input file does not follow naming convention
;
;		name.lab*, name.dat*	--->	name.ndads
; SPECIAL CONSIDERATION:
;	FILES MUST BE COPIED UP FROM IBM AS /IMAGE: use getibm.pro
; HISTORY: djl 95apr4
;-
;------------------------------------------------------------------------------
;
; find files to process
;
    if n_params(0) lt 1 then filespec = '*.lab*'
    files = findfile(filespec)
    for ifile=0,n_elements(files)-1 do begin
;
; determine file names
;
	fdecomp,files(ifile),disk,dir,name,ext
	len = strlen(ext)	;length of file extension
	ext_out = 'ndads'	;default output extension
;print,ext,len
	if len eq 5 then begin
		dtype = strmid(ext,3,1)		;M (melo) or E (elbl)
		aper = strmid(ext,4,1)		;aperture 1 or 2
;print,dtype,aper
	        if ((aper eq '1') or (aper eq '2')) and $
		   ((dtype eq 'M') or (dtype eq 'E')) then begin
			if dtype eq 'M' then ext_out = 'MELO'+aper $
					else ext_out = 'ELBL'+aper
		end
	end
	print,name+'.'+ext+'   ----->   '+name+'.'+ext_out
;
; read label
;
	openr,unit,disk+dir+name+'.'+ext,/get_lun
	stat=fstat(unit)
	nlab = stat.size/360		;number of label lines
	lab = bytarr(360,nlab)
	readu,unit,lab
	free_lun,unit
;
; read data
;
	strput,ext,'DAT',0
	openr,unit,disk+dir+name+'.'+ext,/get_lun
	stat = fstat(unit)
	rec_len = stat.rec_len		;record length
	fsize = stat.size		;file size
	nrecs = fsize/rec_len
	data = intarr(fsize/nrecs/2,nrecs)
	readu,unit,data
	free_lun,unit
;
; write output
;
	openw,unit,name+'.'+ext_out,/get_lun
	for i=0,nlab-1 do writeu,unit,lab(*,i)
	for i=0,nrecs-1 do writeu,unit,data(*,i)
	free_lun,unit
    end
return
end
