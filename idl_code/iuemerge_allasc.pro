pro iuemerge_allasc,filespec,outname,NOUT
;
;+
;			iuemerge_all
;
; Merge a bunch of iue ascii spectra.  This routine only works with
; files containing single spectra. (I.E. those created by IUEBREAK, which breaks
;	multiple object rdf files w/ many diff stars)
;
; CALLING SEQUENCE:
;	iuemerge_allasc,filespec,outname,NOUT
;	eg:............,'ly*.opt','ly',71
;
; INPUTS:
;
;	filespec - file specification for the input file headers.
;		(eg 'disk$data:ly*.opt')
;	outname - root name of the output files.  They
;		will have form <outname><seq. number>.MRG
;	NOUT    - FIRST SEQUENTIAL NUMBER OF OUTPUT NAMES-1 (DEFAULT IS 0)
;
; HISTORY:
;	version 1  D. Lindler April 11, 1991
;	NOUT OPTIONAL PARAMETER ADDED 91NOV21-RCB
;-
;-----------------------------------------------------------------------------
;
; get file names to process and remove version number
;
	files = findfile(filespec)
	nfiles = n_elements(files)
	for i=0,nfiles-1 do $
		files(i)=strmid(files(i),0,strpos(files(i),';'))
;
; get target and wavelength range for each object
;
	objects = strarr(nfiles)
	longwave = intarr(nfiles)
	for i=0,nfiles-1 do begin
		close,1 & openr,1,files(i)
		st = ''
		while strmid(st,1,3) ne '###' do readf,1,st
		readf,1,st
		objects(i) =strtrim(st,2)
		wmin=0.0 & readf,1,wmin
		if wmin gt 1500 then longwave(i) = 1
		print,files(i)+' '+st+'  wmin ='+strtrim(wmin,2) 
       	end
;
; sort by object
;
	sub = sort(objects)
	objects = objects(sub)
	longwave = longwave(sub)
	files = files(sub)
;
; loop on files and merge ones of same object
;
	IF N_PARAMS(0) LE 2 THEN nout = 0	;counter of output files
	i1 = 0			;first input file for object being processed
	i2 = 0			;last input file for the object
;
; find range of files for the object
;
next_i2: if i2 eq (nfiles-1) then goto,last_one
	if objects(i2+1) ne objects(i1) then goto,last_one
	i2 = i2 + 1
	goto,next_i2
;
; object now goes from i1 to i2
;
last_one: nout = nout+1
	outfile = strtrim(outname)+strtrim(nout,2)+'.mrg'
	print,outfile+' '+objects(i1)+string(i2-i1+1)+' files'
	if i1 eq i2 then begin
;
; single file (just copy it)
;
		close,1 & openr,1,files(i1)
		close,2 & openw,2,outfile
		st = ''
		while not eof(1) do begin
			readf,1,st
			if strmid(st,1,3) eq '###' $
				then printf,2,' ###'+string(nout,'(i5)') $
				else printf,2,st
		end
	   end else begin
;
; multiple files (must be one short and one long)
;
		if (i2-i1) ne 1 then begin
		    print,'ERROR - two many files for object'+objects(i1)
		    print,files(i1:i2)
		    retall
		endif

 		if longwave(i1) eq longwave(i2) then begin
		    print,'ERROR - both files same wavelength range for '+ $
				objects(i1)
		    print,files(i1+i2)
		endif
		file1 = strtrim(files(i1))
		file2 = strtrim(files(i2))
		if longwave(i2) then iuemergeasc,file1,file2,outfile,nout $
			        else iuemergeasc,file2,file1,outfile,nout
	end
	i1 = i2+1
	i2 = i1
	if i1 lt nfiles then goto,next_i2

	close,1,2
	return
	end
