pro calwfc_imagepos,file,xc,yc,crval1,crval2,xerr,yerr,			$
	display=display,xstar=xstar,ystar=ystar,target=target
;+
;			calwfc_imagepos
;
; Routine to find star position in the imagefile
;
; INPUTS:
;	file - name of the calibrated image file
;
; OUTPUTS:
;	xc, yc - x and y centroid of the star
;	xerr,yerr - error in pointing
;
; OPTIONAL INPUTS:
;	crval1 - crval1 from the header (ra at center of image)
;	crval2 - crval2 from the header (dec at center of image)
;	/display - display image and star position
;	/xstar - approximate x position of the star
;	/ystar - approximate y position of the star
;	/target - name for the target that is in dir log file. 2020feb4
;
; HISTORY
;	version 1, D. Lindler, Oct 2003
;	version 2, D. Lindler, July 2004, added xstar/ystar keyword
;			inputs, /DISPLAY now shows original image
;			instead of the clipped image.
;	12Apr10 - RCB - use astrometry to find initial estim of star position.
;	15may6  - RCB - compute and return pointing error xerr,yerr in px
;	18Apr - for subarr, xc,yc are in subarr px ref frame.
;	18May - Try increasing search box from 25 to 35px=+/-4.5" for some GRW
;	20feb - Add target name to input & call wfcread instead of fits_read
;		to do coord corr. & replace that func in wfcdir for multiple
;		targets on an image.
;-
;-------------------------------------------------------
	st=''
	if n_params(0) lt 1 then begin
		print,'CALLING SEQUENCE: calwfc_imagepos,file,xc,yc, [/display]
		return
	end
	
;2020feb4-replace reading of header w/ wfcread, which will corr coord, as needed
;	fits_read,file,image,h
	wfcread,file,target,image,h

;
; set bad data to zeros
;
	
	fits_read,file,dq,extname='DQ'
	bad = where((dq and 32) gt 0,nbad)
	if nbad gt 0 then image(bad) = 0
	s = size(image) & ns = s(1) & nl = s(2)
	crval1 = sxpar(h,'crval1')
	crval2 = sxpar(h,'crval2')
	orig = image
	image(*,0:20)=0  &  image(*,nl-31:nl-1)=0	; top & bottom
	image(0:10,*)=0  &  image(ns-11:ns-1,*)=0	; left & right
	extast,h,astr				; astr includes postargs
	ra=sxpar(h,'RA_TARG')
	dec=sxpar(h,'DEC_TARG')
	ad2xy,ra,dec,astr,xastr,yastr
	print,'calwfc_imagepos target Astrometry position=',xastr,yastr
	xappr=xastr  &  yappr=yastr			; use astrometry
	if xstar eq 0 and ystar eq 0 and (xappr le 3 or xappr ge ns-4)	$
								then begin
		xc=0  &  yc=0
		xerr=0  &  yerr=0				; 2018apr23
		print,'Target at edge. calwfc_imagepos set xc=yc=0'
		return
		endif
	if xstar ne 0 or ystar ne 0 then begin 
		xappr=xstar  &  yappr=ystar  &  endif	; use input keywords
	image(0:(xappr-35)>0,*) = 0	; use astrometry pos +/- 35px
	image((xappr+35)<(ns-1):*,*) = 0
	image(*,0:(yappr-35)>0) = 0
	image(*,(yappr+35)<(nl-1):*) = 0
	imax = max(median(image,3),position)
	xpos = position mod ns
	ypos = position/ns
	x1 = (xpos-10) > 0
	y1 = (ypos-10) > 0
	x2 = (x1 + 21) < (ns-1)
	y2 = (y1 + 21) < (nl-1)
	subimage = image(x1:x2,y1:y2)
	subimage = subimage - median(subimage)
	subimage = (subimage - max(subimage)/5)>0
	x = findgen(x2-x1+1) + x1
	xprofile = total(subimage,2)
	xc = total(xprofile*x)/total(xprofile)
	y = findgen(y2-y1+1) + y1
	yprofile = total(subimage,1)
	yc = total(yprofile*y)/total(yprofile)
; 2015May6-add pointing error
	xerr=xc-xastr  &  yerr=yc-yastr				; in pixels
	print,file,' calwfc_imagepos star at',xc,yc,' w/ err=',xerr,yerr
	if keyword_set(display) then begin
		window,1,xsize=ns,ysize=nl
		tvscl,alog10(orig>1)
		plots,[xc,xc],[-8,-18]+yc,/dev
		plots,[xc,xc],[8,18]+yc,/dev
		plots,[-8,-18]+xc,[yc,yc],/dev
		plots,[8,18]+xc,[yc,yc],/dev
		read,st
	end
end		
