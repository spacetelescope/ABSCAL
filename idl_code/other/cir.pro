function cir,image,xc,yc,r
;+
;			cir
; Compute total flux in a circular aperture
;	From:	STFOSC::LINDLER       5-AUG-1993 16:16:35.68
;  slightly more precise than cirflx, but slower-- see the computer doc file-rcb
;
; CALLING SEQUENCE:
;	results = cir(image,xc,yc,r)
;
; INPUTS:
;	image - 2 dimensional image
;	xc,yc - center of the circle
;	r - radius of the circle in pixels
;
; OUTPUTS:
;	total flux within the circle is returned as the function value
;
; METHOD:
;	the flux of each pixel is added to the total using the area of
;	the pixel within the circle as the weight.
;	If part of the circle is outside of the image, only the portion
;	within the image is totalled.
;
; RESTRICTIONS:
;	The radius of the circle must be greater than 1.0/sqrt(2).
;
; HISTORY:
;	Version 1  D. Lindler   July, 1993
;-
;-------------------------------------------------------------------------
	r2 = r*r
	area_per_radian = r^2/2.0
;
; compute the range of x,y to consider
;
	s = size(image) & ns=s(1) & nl=s(2)
	x1 = fix(xc-r)>0
	x2 = (fix(xc+r)+1)<(ns-1)
	y1 = fix(yc-r)>0
	y2 = (fix(yc+r)+1)<(nl-1)
;
; loop on possible x,y values
;
	flux = 0.0				;total flux
	area = 0.0				;total area

	for y=y1,y2 do begin
	  for x=x1,x2 do begin
;
; compute which of the four corners are within circle
;
	   xcorner = [-0.5,0.5,0.5,-0.5]+x
	   ycorner = [0.5,0.5,-0.5,-0.5]+y
	   dist2 = (xcorner-xc)^2 + (ycorner-yc)^2  ; distance sqaured for 4
						    ;	corners
	   inside = dist2 le r2
	   inpos = where(inside,number)
;
; if all corners inside circle (weight = 1) or all outside circle (weight=0)
;
	   if number eq 0 then goto,next_x	;all outside circle
	   if number eq 4 then begin		;all inside circle
		flux = flux+image(x,y)
		area = area + 1
		goto,next_x
	   end
;
; find points outside circle
;
	   outside = dist2 gt r2
	   outpos = where(outside)
;
; compute area of circle within the pixel
;	
	   case number of
;
; single corner within circle ------------------------------------------
;
		1: begin			;single corner in
;
; find clockwise intercept of point within circle
;

			in = inpos(0)			
			out = (in+1) mod 4	;clockwise corner
			xin = xcorner(in)
			yin = ycorner(in)
			xout = xcorner(out)
			yout = ycorner(out)
			if xin eq xout then begin
				xint1 = xin
				t = sqrt(r2 - (xint1-xc)^2)
				yint1 = yc+t
				if (abs(yint1-y) gt 0.5) then yint1 = yc-t
			    end else begin
				yint1 = yin
				t = sqrt(r2 - (yint1-yc)^2)
				xint1 = xc+t
				if (abs(xint1-x) gt 0.5) then xint1 = xc-t
			end
;
; find counter clockwise intercept
;
			out = (in+3) mod 4
			xout = xcorner(out)
			yout = ycorner(out)
			if xin eq xout then begin
				xint2 = xin
				t = sqrt(r2 - (xint2-xc)^2)
				yint2 = yc+t
				if (abs(yint2-y) gt 0.5) then yint2 = yc-t
			    end else begin
				yint2 = yin
				t = sqrt(r2 - (yint2-yc)^2)
				xint2 = xc+t
				if (abs(xint2-x) gt 0.5) then xint2 = xc-t
			end
;
; compute area or triangle
;
			side1 = max([abs(xint1-xin),abs(yint1-yin)])
			side2 = max([abs(xint2-xin),abs(yint2-yin)])
			weight = side1*side2/2.0
		   end
;
; 3 points inside circle -----------------------------------------------------
;
		3: begin
;
; find clockwise intercept for point outside circle
;

			out = outpos(0)			
			in = (out+1) mod 4	;clockwise corner
			xout = xcorner(out)
			yout = ycorner(out)
			xin = xcorner(in)
			yin = ycorner(in)
			if xin eq xout then begin
				xint1 = xin
				t = sqrt(r2 - (xint1-xc)^2)
				yint1 = yc+t
				if (abs(yint1-y) gt 0.5) then yint1 = yc-t
			    end else begin
				yint1 = yin
				t = sqrt(r2 - (yint1-yc)^2)
				xint1 = xc+t
				if (abs(xint1-x) gt 0.5) then xint1 = xc-t
			end
;
; find counter clockwise intercept
;
			in = (out+3) mod 4
			xin = xcorner(in)
			yin = ycorner(in)
			if xin eq xout then begin
				xint2 = xin
				t = sqrt(r2 - (xint2-xc)^2)
				yint2 = yc+t
				if (abs(yint2-y) gt 0.5) then yint2 = yc-t
			    end else begin
				yint2 = yin
				t = sqrt(r2 - (yint2-yc)^2)
				xint2 = xc+t
				if (abs(xint2-x) gt 0.5) then xint2 = xc-t
			end
;
; compute area of pixel minus the area of triangle
;
			side1 = max([abs(xint1-xout),abs(yint1-yout)])
			side2 = max([abs(xint2-xout),abs(yint2-yout)])
			weight = 1.0-side1*side2/2.0
		   end
;
; two corners within circle ---------------------------------------------------
;
		2: begin
;
; match inside pixels to neighboring outside pixels
;
		   if ((inpos(0)+1) mod 4) ne outpos(0) and $
		      ((inpos(0)+3) mod 4) ne outpos(0) then $
			 outpos = [outpos(1),outpos(0)]	;reverse them
;
; find intercept between the first two in/out combination
;

			in = inpos(0)			
			out = outpos(0)	
			xin1 = xcorner(in)
			yin1 = ycorner(in)
			xout = xcorner(out)
			yout = ycorner(out)
			if xin1 eq xout then begin
				xint1 = xin1
				t = sqrt(r2 - (xint1-xc)^2)
				yint1 = yc+t
				if (abs(yint1-y) gt 0.5) then yint1 = yc-t
			    end else begin
				yint1 = yin1
				t = sqrt(r2 - (yint1-yc)^2)
				xint1 = xc+t
				if (abs(xint1-x) gt 0.5) then xint1 = xc-t
			end

;
; find intercept between the second two in/out combination
;

			in = inpos(1)			
			out = outpos(1)	
			xin2 = xcorner(in)
			yin2 = ycorner(in)
			xout = xcorner(out)
			yout = ycorner(out)
			if xin2 eq xout then begin
				xint2 = xin2
				t = sqrt(r2 - (xint2-xc)^2)
				yint2 = yc+t
				if (abs(yint2-y) gt 0.5) then yint2 = yc-t
			    end else begin
				yint2 = yin2
				t = sqrt(r2 - (yint2-yc)^2)
				xint2 = xc+t
				if (abs(xint2-x) gt 0.5) then xint2 = xc-t
			end
;
; compute area of trapezoid
;
			side1 = max([abs(xint1-xin1),abs(yint1-yin1)])
			side2 = max([abs(xint2-xin2),abs(yint2-yin2)])
			weight = (side1+side2)/2.0
		   end
	   endcase
;
; compute area of arc between circle and the line connecting the two
; intercepts
;
	   angle1 = atan(yint1-yc,xint1-xc)
	   angle2 = atan(yint2-yc,xint2-xc)
	   theta = abs(angle1-angle2)
	   if theta gt !pi then theta = 2*!pi-theta
	   d = sqrt((xint1-xint2)^2 + (yint1-yint2)^2)
	   area_of_pie_slice = theta * area_per_radian
	   area_of_triangle = r*cos(theta/2.0)*d/2.0
	   area_of_arc = area_of_pie_slice - area_of_triangle
	   weight = weight+area_of_arc
	   area = area + weight
	   flux = flux + weight*image(x,y)
next_x:
	  end; for x
	end; for y
return,flux
end
