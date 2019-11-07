PRO TWOCON,IMAGE,ISCL,H,SMO,confac,minlevel=minlevel,maxlevel=maxlevel,	$
								displ=displ
;+
;
; INPUT:	
;	IMAGE - image to be rescaled
;	h - ascii header w/ targname for optional display
; INPUT/OUTPUT:
;	maxlevel - maximum used for scaling (=mx). if not specified or =0,
;							then ignore.
; OPTIONAL INPUT:
;	smo - box smoothing length for image before scaling. Done twice.
;	confac - factor to scale from black to white. DEFAULT=2
;	minlevel - keyword to set a minimum to scale to 0 output
;	displ = keyword to turn on display option.. only use for header
;
; OUTPUT:
;	iscl - scaled image in range 0-255
; HISTORY:
;
; 92FEB14 - TO MAKE THE IMAGE IM INTO ISCL W/ CONTOURS EVERY FACTOR OF CONFAC
; 01oct15 - upgrade and promote to UNIX
; 01Nov20 - set zeros in input to zero output
; 01nov27 - scale up to almost next even pwr of confac, 
;						so that the max is at ~254DN
; 01nov30 - add maxlevel keyword
;
; CALLING SEQUENCE
; TWOCON,IMAGE,ISCL,H,SMO,confac,minlevel=minlevel,maxlevel=maxlevel,displ=displ
;-
;

IM = IMAGE

; optional smooth
;
	if ((n_params(0) gt 3) and (smo ge 3)) then begin
		im = smooth(im,smo)
		im = smooth(im,smo)
		endif
	good=where(im gt 0)  &  bad=where(im le 0)
; n_elements(undefined)=0
	if n_elements(minlevel) lt 1 then begin
		minlevel=min(im(good))>1e-35
; allow max dyn range of 1e10 in image to be scaled.
		if max(im) gt 1e10*minlevel then minlevel=max(im)*1e-10
		endif
	maxim=max(im)
	IM = IM/minlevel		; min=1 to avoid neg logs
;92may8-optional contour change from 2x default
;
	if n_params(0) lt 5 then confac=2.
; 01nov27 - scale up to almost next even pwr of confac, 
;						so that the max is at ~254DN
; 01nov30 - add maxlevel keyword
	mx=max(im)
	if keyword_set(maxlevel) then if maxlevel gt 0 then mx=maxlevel
	maxlevel=mx
	wrap=ALOG10(mx)/ALOG10(CONFAC)
	wrap=1.1^(fix(wrap)+1-wrap)
;print,mx,confac,im(where(im eq max(im)))
	im=im*.999*wrap
print,'TWOCON scaled image to 255(white) at max=',maxim,'  Minlevel=',minlevel,$
		'   Maxlevel=',maxlevel

; >=0 input will be 0 output:
	ISCL=((ALOG10(IM>1) MOD ALOG10(CONFAC))		$
			/alog10(confac))*((!d.n_colors<256)-1)
;print,!d.n_colors,iscl(where(im eq max(im))),im(where(im eq max(im)))
	below = where(im lt 1,n)
	if n gt 0 then iscl(below) = 0		; useful for minlevel keyword
	if ((!d.name NE 'X') or (not keyword_set(displ))) THEN RETURN
;--------------- NORMAL END -----------------------------------------
;
; set up window (leave 100 pixel area at bottom for text
;
	nreserve = 100		;number of lines to reserve for text
	S = SIZE(IM)
	ns = s(1) & nl = s(2)
	WINDOW,1,XS = ns,YS = nl+nreserve
;
	TV,ISCL,0,nreserve
;
; find a middle contour level that is an even power of 10
;
	mnmx = alog10([min(im>minlevel),max(im)])
	conlev = fix(total(mnmx)/2.+.5)
	conlev = 10.^conlev
	table_val=(ALOG10(conlev>minlevel) MOD ALOG10(CONFAC))/alog10(confac)* $
			(!d.n_colors-1)
;
; set contour color (black or white) and draw contour
;
	set_viewport,0,1,float(nreserve)/(nl+nreserve),1.0
	if table_val gt !d.n_colors/2 then 	$
			concolor = 0 else concolor = !d.n_colors-1
	contour,im,levels = conlev,/noerase,xticks=1,xstyle=5,ystyle=5, $
			color=concolor,thick=3
	if table_val le !d.n_colors/2 then 	$
			concolor = 0 else concolor = !d.n_colors-1
	contour,im,levels = conlev,/noerase,xticks=1,	$
			xstyle=5,ystyle=5,color=concolor,thick=1
;
; write text at bottom
;
	tv,replicate(!d.n_colors-1,ns,nreserve)
	if n_params(0) gt 2 then begin		;get target name
	    name = sxpar(h,'targname')
	    if !err lt 0 then name=sxpar(h,'targnam1')	;old st data
	    if !err ge 0 then xyouts,20,80,strtrim(name),color=0,/device
	endif
	xyouts,20,65,strtrim(sxpar(h,'filtnam1')),color=0,/device
	xyouts,20,50,'Contour Level = '+strtrim(long(conlev),2),color=0,/device
	xyouts,20,35,'Contour Factor = '+strtrim(long(confac),2),color=0,/device
        plotdate,'twocon'
	pset	;reset for default viewport, etc.
return
END
