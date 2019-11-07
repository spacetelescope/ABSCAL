pro iuefits,name
;+
;			iuefits
;
; Routine to convert Bohlin IUE/SDAS file to FITS table file.
;
; Inputs:
;	name - input IUE/SDAS file name
;
; Output:
;	Fits file with the same name as the input but with an extension of
;	.FITS
;
; Examples:
;	iuefits,'mrg1.hhh'
;
;	list = findfile('mrg*.hhh')
;	for i=0,n_elements(list)-1 do iuefits,list(i)
;
; History:
;	version 1  D. Lindler March 13, 1992
;-
;-------------------------------------------------------------------------
;
; decode name
;
	fdecomp,name,disk,dir,root,ext
	if strtrim(ext) eq '' then ext='hhh'
;
; read input iue/sdas file
;
	sxopen,1,disk+dir+root+'.'+ext,header
	data = sxread(1)
	s = size(data) & ns=s(1) & nl=s(2)
;
; create fits table
;
	ftcreate,60,ns,h,tab
	iuefits_format,h,tab,'WAVE',data(*,0),1,'F'
	iuefits_format,h,tab,'EPS',fix(data(*,1)),0,'I'
	iuefits_format,h,tab,'GROSS',data(*,2),0,'F'
	iuefits_format,h,tab,'BKG',data(*,3),0,'F'
	iuefits_format,h,tab,'NETRATE',data(*,4),2,'F'
	ftaddcol,h,tab,'ABNET',4,'E10.3'
	ftput,h,tab,'ABNET',0,data(*,5)
	iuefits_format,h,tab,'TIME',data(*,6),2,'F'
	iuefits_format,h,tab,'SIGMA',data(*,7),4,'F'
	ftsize,h,tab,ncols,nrows		;table size
	tab = tab(0:ncols-1,0:nrows-1)		;trim off fat
;
; Add input history information to output table header
;
	sxdelpar,header,['SIMPLE','BITPIX','NAXIS','NAXIS1','NAXIS2', $
		    	 'DATATYPE','GROUPS','GCOUNT']
	end1 = 0
	while strtrim(strmid(header(end1),0,8)) ne 'END' do end1 = end1+1
	end2 = 0
	while strtrim(strmid(h(end2),0,8)) ne 'END' do end2 = end2+1
	header = [h(0:end2-1),header(0:end1)]
;
; create null image header for output fits file
;
	null_h = string(replicate(32B,80,36))
	null_h(0) = 'END'+string(replicate(32B,77))
	sxaddpar,null_h,'SIMPLE','T'
	sxaddpar,null_h,'BITPIX',8
	sxaddpar,null_h,'NAXIS',0,'No image data present'
	sxaddpar,null_h,'EXTEND','T','Table extension exists'
	null_h = byte(null_h)
;
; open output fits file
;
	get_lun, ounit
	openw, ounit,root+'.fits',2880,/fixed,/none
;
; write null header
;
	writeu,ounit,null_h(0:79,0:35)		;2880 bytes
;
; write header in units of 2880 bytes
;
	nlines = n_elements(header)
	header = [header,string(replicate(32B,80,36))] ; pad with blanks
	nrecs = (nlines+35)/36			;number of 2880 records
	header = byte(header)
	for i=0,nrecs-1 do writeu,ounit,header(0:79,i*36:i*36+35)
;
; write table in 2880 byte blocks
;
	n = n_elements(tab)		;number of bytes in table
	nrecs = (n+2879)/2880		;number of records required
	for i=0L,nrecs-1 do begin
	    first = i*2880		;first byte to write
	    last = first+2879	;last byte to write
	    if last ge n then begin	;do we need to pad last record
		data = tab(first:n-1)
		data = [data,replicate(0b,2880-n_elements(data))]
		writeu,ounit,data
	    end else writeu,ounit,tab(first:last)
	endfor
	free_lun,ounit	
return
end
