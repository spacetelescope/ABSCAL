pro calnic_imagepos,file,xc,yc,crval1,crval2, $
	display=display,xstar=xstar,ystar=ystar
;+
;			calnic_imagepos
;
; Routine to find star position in the imagefile
;
; CALLING SEQUENCE:
;	calnic_imagepos,file,xc,yc
;
; INPUTS:
;	file - name of the calibrated image file
;
; OUTPUTS:
;	xc, yc - x and y centroid of the star
;
; OPTIONAL KEYWORD INPUTS:
;	/display - display image and star position
;	xstar - approximate x position of the star
;	ystar - approximate y position of the star
;	crval1 - crval1 from the header (ra at center of image)
;	crval2 - crval2 from the header (dec at center of image)
;
; HISTORY
;	version 1, D. Lindler, Oct 2003
;	version 2, D. Lindler, July 2004, added xstar/ystar keyword
;			inputs, /DISPLAY now shows original image
;			instead of the clipped image.
;	Jan 31, 2005, added crval1 and crval2 outputs
;	Feb 3, 2005, decrease the search size of the region around
;			xstar, ystar to 5 pixels
;	08Oct21 - P330-E R. Thompson data requires some border to be zeroed. RCB
;       08Nov12 - DJL - modified to zero out data flagged as bad
;			(needed for new CALNICA outputs).
;	
;-
;-------------------------------------------------------

	if n_params(0) lt 1 then begin
		print,'CALLING SEQUENCE: calnic_imagepos,file,xc,yc, [/display]
		return
	end
	
	fits_read,file,image,h
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
; 08jun3 - also skip over for Nor's P330E na5105 all over the detector.
	if strtrim(sxpar(h,'targname'),2) ne 'P330-E' and	$
					strpos(file,'na5105') lt 0 then begin
		if n_elements(xstar) gt 0 then begin
			image(0:(xstar-5)>0,*) = 0
			image((xstar+5)<255:*,*) = 0
		    end else begin
			image(0:70,*) = 0
			image(140:*,0) = 0
		end
		if n_elements(ystar) gt 0 then begin
			image(*,0:(ystar-5)>0) = 0
			image(*,(ystar+5)<255:*) = 0
		    end else begin
			image(*,0:40) = 0
			image(*,120:*) = 0
		end
	    end else begin
; even for these 2 cases, some border must be zeroed for new calnicA - RCB 08Oct
		image(*,0:20)=0  &  image(*,225:255)=0	; top & bottom
		image(0:10,*)=0  &  image(245:255,*)=0	; left & right
	end
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
	if keyword_set(display) then begin
		window,2,xsize=256,ysize=256
		tvscl,alog10(orig>1)
		plots,[xc,xc],[-8,-18]+yc,/dev
		plots,[xc,xc],[8,18]+yc,/dev
		plots,[-8,-18]+xc,[yc,yc],/dev
		plots,[8,18]+xc,[yc,yc],/dev
		wait,0.25
	end
end		
