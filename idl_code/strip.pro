pro strip,image,rmask,theta,radius,flux,indices,width=width,display=display
;+
;			strip
;
; Routine to extract a strip from an image and sort in by
; ellipse radius.
;
; CALLING SEQUENCE:
;	strip,image,rmask,theta,RADIUS,FLUX
;
; INPUTS:
;	image - your image
;	rmask - image containing the ellipse radius for each pixel
;	theta - angle of the strip to extract in degrees from 0 to 90.0
;		where 0 is horizontal and 90 is verticle.
;
; OPTIONAL KEYWORD INPUTS:
;	width = r :width of the strip to extract (default = 3)
;	/display  :to draw strip on previously displayed image
; OUTPUTS:
;	radius - radius vector (minus radius for left/lower side of strip)
;	flux - vector of flux values
;
; HISTORY:
;	version 1  D. Lindler  Nov. 21, 1991
;-
;----------------------------------------------------------------------------
;
; set default parameters
;
	if n_params(0) lt 1 then begin
		print,'CALLING SEQUENCE: strip,image,rmask,theta,RADIUS,FLUX
		return
	end
	if n_elements(width) eq 0 then width = 3
;
; get sizes
;
	s = size(image) & ns=s(1) & nl=s(2)
;
; find the center of the ellipse
;
	minval = min(rmask)
	x0 = !c mod ns
	y0 = !c/ns
	print,x0,y0
;
; compute end points of a line going through the center of the strip
; which extend to the image boundaries
;
	sint = sin(theta/!radeg)
	cost = cos(theta/!radeg)
	if theta lt 90.0 then d1 = x0/cost else d1=1e10	;distance to x=0
	if theta ne 0.0 then d2 = y0/sint  else d2=1e10	;distance to y=0
	d = (d2<d1)-1
	x1 = x0 - d*cost
	y1 = y0 - d*sint

	if theta lt 90.0 then d1 = (ns-x0)/cost else d1=1e10 ;distance to x=ns
	if theta ne 0.0 then d2 = (nl-y0)/sint  else d2=1e10 ;distance to y=nl
	d = (d2<d1)-2
	x2 = x0 + d*cost
	y2 = y0 + d*sint
;
; compute box with corners (xa,ya), (xb,yb), (xc,yc), (xd, yd) which
; has the specified width.
;
	dels = width/2.0*sint
	dell = width/2.0*cost
	xa = x1 + dels
	xb = x2 + dels
	xc = x2 - dels
	xd = x1 - dels
	ya = y1 - dell
	yb = y2 - dell
	yc = y2 + dell
	yd = y1 + dell
;
; get indices of data points in the image within the box and extract the
; radius and flux values
;

	if keyword_set(display) then $
		plots,[xa,xb,xc,xd,xa],[ya,yb,yc,yd,ya],/device
	indices = polyfillv([xa,xb,xc,xd,xa],[ya,yb,yc,yd,ya],ns,nl)
	radius = rmask(indices)
	flux = image(indices)
;
; set positions to the lower/left of the center to negative radius
;
	if theta lt 45.0 then begin
		x = (indices mod ns) - x0
		negative = where(x lt 0)
	   end else begin
		y = (indices/ns) - y0
		negative = where(y lt 0)
	end
	radius(negative) = - radius(negative)
;
; sort on radius
;
	sub = sort(radius)
	radius = radius(sub)
	flux = flux(sub)
return
end
