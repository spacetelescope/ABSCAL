pro subimage,infile,outfile,ns,x,y,CHIP
;+
;		subimage
;
; Routine to extract a subimage from the input image and
; output it in a new file.
;
; CALLING SEQUENCE:
;	subimage,infile,outfile,ns,x,y,chip
;
; INPUT PARAMETERS:
;	infile - input header file name. (if no extension is given, .hhh
;		is assumed)
;	outfile - output header file name. (if no extension is given, .hhh
;		is assumed)
;
; OPTIONAL INPUTS:
;	ns - size of the output subimage (if not supplied, you will be
;		prompted for it)
;	x - center sample of the subimage 
;	y - center line of the subimage (if x or y is not supplied then
;		you will be asked to interactive point to the center
;	CHIP-WFPC CHIP-ADDED 92JAN28 BY RCB
;
; HISTORY:
;	D. Lindler Dec 4, 1991
;-
;-------------------------------------------------------------------------
	if n_params(0) lt 2 then begin
	    print,'CALLING SEQUENCE: subimage,infile,outfile,ns,x,y
	    retall
	endif
;
; read input file
;
	if n_params(0) lt 6 then 		$
		imgread,image,h,infile	else	$
		imgread,image,h,infile,CHIP
;
; determine x and y if not supplied
;
	s = size(image) & nx=s(1) & ny=s(2)
	if n_params(0) lt 5 then begin
		window,0,xsize=nx,ysize=ny
		tvscl,alog(image>0.1)
		print,'---- Position Cursor on center of subimage and click'+ $
			' mouse button'
		cursor,x,y,/device
		displayed = 1
	end else displayed = 0

	if n_params(0) lt 3 then begin
		ns = 0
		read,'Enter size of subimage? ',ns
	endif
;
; check size and center
;
	if (ns gt nx) or (ns gt ny) then begin
		ns = ns<nx<ny
		print,'SUBIMAGE- ns too large, I changed it to '+strtrim(ns,2)
	endif
	oldx = x
	oldy = y

	if (x-ns/2) lt 0 then x = ns/2
	if (x+ns/2) gt (nx-1) then x = nx-1-ns/2
	if (y-ns/2) lt 0 then y = ns/2
	if (y+ns/2) gt (ny-1) then y = ny-1-ns/2 
	if (x ne oldx) or (y ne oldy) then begin
		print,'SUBIMAGE - image center shifted from center s,l'
		print,'	('+strtrim(oldx,2)+','+strtrim(oldy,2)+') to '
		print,'	('+strtrim(x,2)+','+strtrim(y,2)+')'
	end
;
; extract subimage and fix header with mousse routine
;
	x1 = x-ns/2
	x2 = x1+ns-1
	y1 = y-ns/2
	y2 = y1+ns-1
	print,x1,x2,y1,y2
	if displayed then plots,[x1,x2,x2,x1,x1],[y1,y1,y2,y2,y1],/device
	hextract,image,h,imout,hout,x1,x2,y1,y2
;
; write new file
;
	sxmake,1,outfile,imout,0,1,hout
	sxwrite,1,imout
	close,1
	return
end
