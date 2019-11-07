PRO PLTACQ,ROOT,OUTPUT=OUTPUT
;+
; NAME:
;	PLTACQ
; PURPOSE:
;	Plot FOS peakup target aquisition data 
; CALLING SEQUENCE:
;	PLTACQ,ROOT
; INPUTS:
;	root - rootname of target acquisition observation
; KEYWORDS:
;	output - if present write data to file <root>.acq
; OUTPUTS:
; HISTORY:
;	Written Apr, 1992, JDN
; 93feb5-copied from disk$data5:[neill.tacq] and slightly generalized-rcb
; 93apr15-mod to permit use of output keyword file name
; 93APR20-FIX 2X6 BOUSTROPHEDON AND ADD EXP TIME TO MTITLE
;         GEO SAYS THE 2X6 IS THE SAME AS THE REST, WHICH START IN -X
;	  AT UPPER RIGHT PT AND COULD BE CKED BY CRVAL GROUP RA AND DEC's
; 93aug19-This program reverses the first line (# 0) and all even # lines,
;		including the single set of 3 A1 data!!!!
;-
; print documentation
;
if n_params(0) eq 0 then begin
	print,'PLTACQ,ROOT,/OUTPUT'
	retall
endif
;
fmt = '(1x,i5,10f10.1)'
;
; get list of files to process
;
;flist = findfile(root+'*.D0H',count=nf)	;COUNT RESULT
flist = findfile(root+'*.C5H',count=nf)		;COUNT/SEC RESULT
if nf le 0 then begin
	print,'PLTACQ - no files found for root: ',root
	return
endif
;
; open output file
;
if keyword_set(output) then begin
	filenam=root
	if output ne 1 then filenam=output
	openw,lun,filenam+'.acq',/get_lun
	endif
;
; process each file
;
for i=0,nf-1 do begin
;
; read in data
	fdecomp,flist(i),disk,dir,rt,ext
	sxhread,disk+dir+rt+'.shh',h
	date = sxpar(h,'pstrtime')
	date = absdate(date)
	sxopen,1,disk+dir+rt+'.'+ext,h
	IF SXPAR(H,'GRNDMODE') NE 'TARGET ACQUISITION' THEN GOTO,SKIP
	gc = sxpar(h,'gcount')
	ns = sxpar(h,'naxis1')
	ap = strtrim(sxpar(h,'aper_id'),2)
	det= strtrim(sxpar(h,'detector'),2)
	fg = strtrim(sxpar(h,'fgwa_id'),2)
	tg = strtrim(sxpar(h,'targname'),2)
	if tg eq '0' then tg = strtrim(sxpar(h,'targnam1'),2)
;GROUP EXP TIME SEEMS TO BE SCREWED UP BY PIPELINE FOR 4211 T/A DATA. BUT IS 
;	OK BY THE TIME I GOT THE HARRY F. T/A DATA.
	EX = strtrim(STRING(sxpar(h,'EXPTIME')/GC),2)
	d = fltarr(ns,gc)
	for ig=0,gc-1 do d(0,ig) = sxread(1,ig)
;
; set up plot
	!mtitle = 'TARG ACQ '+strupcase(rt) + ' ' + det + ' ' + fg + ' ' + $
			ap + ' ' + tg + ' ' + string(date,'(f7.2)')+       $
			' EXP(sec)/STEP='+EX
;	!ytitle = 'TOTAL COUNTS'
	!ytitle = 'COUNTS/SEC'
	!xtitle = ''
;
; print file header
	if keyword_set(output) then begin
		printf,lun,' '
		printf,lun,!mtitle
		printf,lun,!ytitle
	endif
;
; set up x-y vars
	case gc of
	25: begin	& nx = 5	& ny = 5	& end
	16: begin	& nx = 4	& ny = 4	& end
	14: begin	& nx = 7	& ny = 2	& end
	12: begin	& nx = 6	& ny = 2	& end
	 3: begin	& nx = 3	& ny = 1	& end
	 7: begin	& nx = 7	& ny = 1	& end
	else: begin
		print,'PLTACQ - non-standard number of groups: ',gc
		if keyword_set(output) then free_lun,lun
		return
	end
	endcase
	tot = fltarr(nx,ny)
;
; insert total in boustrophedon pattern
	gp = 0
	for iy=0,ny-1 do begin
		if (iy mod 2) EQ 0 then begin	;EVEN # LINES (1ST IS # 0)
			for ix = nx-1,0,-1 do begin	;reverse order
				tot(ix,iy) = total( d(*,gp) )
				gp = gp + 1
			endfor
		endif else begin		;ODD # LINES
			for ix = 0,nx-1 do begin
				tot(ix,iy) = total( d(*,gp) )
				gp = gp + 1
			endfor
		endelse
	endfor
;
; set up plot
	!xmin = 1
	!ymin = 0
	!ymax = max(tot)
	!p.multi = [0,1,ny]
	!xmax = nx
	!xticks = nx-1
	xdat = indgen(nx) + 1
		for iy = 0, ny-1 do begin
;			if iy gt 0 then !mtitle=''
			if iy ge ny-1 then !xtitle = 'X POSITION'
			plot,xdat,tot(*,iy),xstyle=1
			print,ny-iy,tot(*,iy),format=fmt
			if keyword_set(output) then $
				printf,lun,ny-iy,tot(*,iy),format=fmt
			endfor
		if keyword_set(output) then begin
			printf,lun,'     Y X -->'
			printf,lun,0,findgen(nx)+1,format=fmt
			endif
;
; date plot
	plotdate,'PLTACQ'
;
; end loop over files
SKIP:
endfor
;
; close file
;
if keyword_set(output) then free_lun,lun
;
return
end	; pltacq.pro
