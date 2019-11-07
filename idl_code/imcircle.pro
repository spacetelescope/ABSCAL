function imcircle,image,rad,x,y,value
;+
; NAME:
;	IMCIRCLE
; PURPOSE:
;	To blank out the area on an image outside a circle of specified radius 
;	and specified center.
;
; CALLING SEQUENCE:
;	new = IMCIRCLE( Image, Rad, X, Y, VALUE) 
;
; INPUT:
;	Image - 2-d array for which one wants to specify an image circle
;
; OPTIONAL INPUTS:
;	RAD - radius of circle to be drawn, scalar, in pixels.  IMCIRCLE prompts
;		for a radius if not supplied
;	X - x position for circle center, numeric scalar
;	Y - y position for circle center, numeric scalar
;	If X and Y are not specified then IMCIRCLE assumes the center of the
;		image
;	VALUE - Value to be assigned to blanked out pixels - default is 0
;            Default = 0.
;
; OUTPUTS:
;	New = resulting image
;
; EXAMPLE:
;    To assign a pixel value of 0 to pixels outside of the UIT image circle,
;    in a 512 x 512 image array, IM
;
;              IM = IMCIRCLE ( IM, 256 )
; REVISON HISTORY:
;       written by B. Pfarr, STX, 1/91 from TVCIRCLE.
;       fixed header documentation, B. Pfarr, 2/91
;-
 On_error,2                             ;Blanked out pixels
 npar = N_params()

 if npar lt 1 then begin
     print,'Syntax -  new = IMCIRCLE( image, [ rad, x, y, value ])'
     return, -1
 endif

 ZPARCHECK,'IMCIRCLE',image,1,[1,2,3,4,5],2,'Image array'
 sz = size(image)
 xsize = sz(1)
 ysize = sz(2)
 image2 = image
 if npar LT 2 then read,'Enter circle radius (pixels): ',rad
 if npar lt 4 then begin 
   x = xsize/2
   y = ysize/2
 endif

 x = long(x)
 y = long(y)
 if npar lt 5 then value = 0
 yc = y+ rad 
 yc2 = y-rad
if (yc gt ysize-1) then yc = ysize-1
if (yc2 lt 0) then yc2 = 0
image2(0:xsize-1,yc:ysize-1) = value   ;blank top and bottom
image2(0:xsize-1,0:yc2) = value
rad = rad*1l
radsq = rad^2

 for j = yc2,yc do begin
   dist= fix(sqrt(radsq-(j-y)^2))
   xc = x-dist>0
   xc2 =x+dist<(xsize-1)
   image2(0:xc,j) = value
   image2(xc2:xsize-1,j) = value
 end

 return,image2
 end
                           
