pro finger_mask,hd,mask
;+
;
; finger_mask,mask	- to set mask to zero under ACS HRC occulting finger.
;
; INPUT/OUTPUT
;	mask - the mask set to zero under finger position.
; 01oct18 - add the coronographic masks for obstype=CORON
; 01dec18 - shift for PR200L
; 02aug20 - drop coronagraph masking
; 02sep6  - change mask value from 0 to 2
; 03jan28 - reduce size to ~50% contour. 
;-

xbad=[290,349,364,386,402,408,352]		; intermediate det in lab
ybad=[0,205,220,223,213,193,0]
jd=sxpar(hd,'EXPSTART')         ; Julian day
if jd lt 51083 then begin       ; guess ~98sep30 non-flight
	xbad=[330,384,406,420,437,433,392]
	ybad=[0,175,190,188,168,138,0]
	print,'Flight spare HRC. Finger mask shifted.'
	endif
if jd ge 51960 then begin	; 01feb20 back to flight build 1 HRC
; 	xbad=[318,394,413,431,446,456,380]	03jan28
;        ybad=[0,250,263,265,253,239,0]		03jan28
	xbad=[337,416,424,428,432,434,364]
	ybad=[  0,240,244,243,239,231,  0]
	print,'Build 1 finger mask'
	endif
if strtrim(sxpar(hd,'filter2'),2) eq 'PR200L' then begin
	print,'Shift finger mask for PR200L'
	xbad=xbad+50
	endif
if strtrim(sxpar(hd,'obstype'),2) eq 'INTERNAL' then begin
	xbad=xbad-7  &  ybad=ybad*1.03  &  endif
bad=polyfillv(xbad,ybad,1024,1024)
mask(bad)=2
; 02aug20 - depth of spots is always >.01 (for earth f250w). So why mask at all?
;if strpos(sxpar(hd,'obstype'),'CORON') ge 0 then begin
;	;tvellipse,51,40,500,474,110			; GO coord
;	;tvellipse,78,62,405,805,110
;	dist_ellipse,emask,1024,500,1023-474,51./40,-20	; LAB coord
;	bad=where(emask le 51.)
;	mask(bad)=0
;	dist_ellipse,emask,1024,405,1023-805,78./62,-20
;	bad=where(emask le 78.)
;	mask(bad)=0
;	endif
end
