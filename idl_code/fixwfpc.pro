pro fixwfpc,filespec,noq0h=noq0h
; +
;			fixwfpc
;
; Routine to convert 32 bit wfpc files to 16 bit files.
;
; CALLING SEQUENCE:
;		fixwfpc,filespec
;		fixwfpc,filespec,/noq0h	;do only d0h files
; INPUTS:
;	file spec of input file files (with no extension)
;
; OUTPUTS:
;	all .d0h and .q0h files are changed from 32 bit to 16 bit.
;	Output files are placed in the current default directory which
;	may or may not be in the same directory as the input files.
;	Group parameters BIASEVEN and BIASODD are added to the files
;	if not already in them.
;	Set DOSATMAP=NO to avoid getting .c3 files. RCB
;	Files that are already 16 bit and do not need the new group
;	parameters are left unchanged.
;
; EXAMPLES:
;	fixwfpc,'w*'
;	fixwfpc,'disk$data2:[bohlin]w*'
;	fixwfpc,'disk$data2:[bohlin]w*',/noq0h
;
;-
;------------------------------------------------------------------------
	if n_params(0) lt 1 then begin
		print,'CALLING SEQUENCE: fixwfpc,filespec'
		print,'	Optional keyword parameter:  /noq0h'
		return
	endif
;
; get list of files
;
	if n_elements(noq0h) eq 0 then noq0h=0
	files = findfile(filespec+'.d0h',count=n)
	if noq0h eq 0 then begin
		files2 = findfile(filespec+'.q0h',count=n2)
		if n2 gt 0 then begin
			if n eq 0 then begin
				n = n2
				files = files2
			    end else begin
				n = n + n2
				files = [files,files2]
			end
		end
	end

	if n eq 0 then begin
		print,'FIXWFPC-- No files found for input filespec'
		retall
	endif
;
; convert each file
;
	for i=0,n-1 do begin
;
; open input file
;
	    print,files(i)
	    fdecomp,files(i),disk,dir,name,ext
	    sxopen,1,disk+dir+name+'.'+ext,h
	    bitpix = sxpar(h,'bitpix')
	    psize = sxpar(h,'psize')
	    if psize eq 0 then begin
		print,'FIXWFPC -- invalid input file PSIZE=0, file skipped'
		goto,nexti
	    end
;
; do we need to add BIASEVEN and BIASODD group parameters?
;
	    addgpar = 0
	    value = sxgpar(h,bytarr(psize/8),'BIASEVEN')
	    if !err lt 0 then addgpar = 1
	    sxaddpar,h,'dosatmap','NO'

;
; is the file OK the way it is?
;
	    if (bitpix eq 16) and (addgpar eq 0) then begin
		print,'	No changes required, file left unchanged'
		goto,nexti
	    endif
	    gcount = sxpar(h,'gcount')
;
; add new group parameter descriptions to header if required
;
	   if addgpar then begin
		pcount = sxpar(h,'pcount')
;
; find where to add new keywords
;
		pos = 0
		keyword = 'PSIZE'+strtrim(pcount,2)
		while strtrim(strmid(h(pos),0,8)) ne keyword do pos=pos+1
		keyword = strtrim(strmid(h(pos+1),0,8))	;add before this one
		gparnum = strtrim(pcount+1,2)
		sxaddpar,h,'ptype'+gparnum,'BIASEVEN','',keyword
		sxaddpar,h,'pdtype'+gparnum,'REAL*4  ','',keyword
		sxaddpar,h,'psize'+gparnum,32,'',keyword
		gparnum = strtrim(pcount+2,2)
		sxaddpar,h,'ptype'+gparnum,'BIASODD ','',keyword
		sxaddpar,h,'pdtype'+gparnum,'REAL*4  ','',keyword
		sxaddpar,h,'psize'+gparnum,32,'',keyword
		sxaddpar,h,'psize',psize+64
		sxaddpar,h,'pcount',pcount+2
	    end
;
; open output file
;
	    sxaddpar,h,'bitpix',16
	    sxaddpar,h,'datatype','INTEGER*2'
	    sxaddhist,'File processed with FIXWFPC.PRO',h
	    sxopen,2,name+'.'+ext,h,'','W'
;
; loop on groups
;
	    for j=0,gcount-1 do begin
		x = fix(sxread(1,j,par)+0.5)
		if addgpar then par=[par,bytarr(8)]
		sxwrite,2,x,par
	    end
	    close,1,2
nexti:
	end
	return
end
