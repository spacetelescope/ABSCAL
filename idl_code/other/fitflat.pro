pro fitflat,hdr,img,mask,nodes,fit,flat,col=col,nomed=nomed
; +
;
; fitflat to make spline fits to ACS flats
; INPUT:
;	hdr - header of img
;	img - the flat field image to fit
;	nodes - the specification of the spline nodes
;	col - KEYWORD for fitting in col, instead of default row
;	nomed - KEYWORD to turn off median filtering (for MAMAs) & fits of fits
;		defaults: /col=0 - 11x11 median of image
;			  /col=1 - 13 pt 1-D median for stis w/ D2 lines
; INPUT/OUTPUT:
;	mask - the mask for points to ignore in fitting. same size as img. Mask
;		is updated to -1 for lines not fit
; OUTPUT:
;	fit - the spline fit to img
;	flat - the flat: img/fit
; HISTORY:
;	99JAN - rbohlin
;	99feb4 - go from 2-d to 1-d median to avoid smoothing edges of stis em
;		lines that are almost along the col. Leave 2-d for row fitting.
;	99jun24- set mask=-1 for lines that are not fit.
;-

s=size(img)  &  nx=s(1)  &  ny=s(2)
det=strtrim(sxpar(hdr,'detector'),2)

; set up positions of spline nodes
xpx=indgen(nx)
xnod=findgen(nodes)*(nx-1.)/(nodes-1)	;= spaced nodes incl ends
if keyword_set(col) then begin		; 00jun21 wfc 1 chip is only 2048px high
	xpx=indgen(ny)
	xnod=findgen(nodes)*(ny-1.)/(nodes-1)	;= spaced nodes incl ends
	endif
del=xnod(1)-xnod(0)

fit=img					; unfit lines will be unit flats
tmp=img					; initialize for 1-d median filter
bad=where(mask eq 0 and fit eq 0,nbad)	; just in case fit is not updated
if nbad gt 0 then fit(bad)=1		;to avoid 0/0 in img/fit for all bad row

; Special section for SBC Splat flats w/ data only in the center:
if float(nbad)/(nx*ny) gt .5 and det eq 'SBC' then begin
	print, 'Special splat fit is just a smoothing of img.'
; Fill the bad rows and the repeller wire columns:
	fill=(rebin(img(*,592:597),1024,1)+rebin(img(*,606:611),1024,1))/2
	for i=599,604 do tmp(*,i)=fill
	fill=(rebin(img(566:571,*),1,1024)+rebin(img(585:590,*),1,1024))/2
	for i=576,580 do tmp(i,*)=fill

	fit=median(img,11)
	fit=smooth(smooth(fit,21),21)
	goto,splat
	endif

; 05apr12 - to fix SBC col fits -- if not keyword_set(col) then begin
; add extra pt half way btwn first and last pts at ends 
	xnod=[xnod(0),del/2,xnod(1:nodes-2),xnod(nodes-1)-del/2,xnod(nodes-1)]
	if not keyword_set(nomed) then begin
		tmp=median(img,11)		; default for CCDs
		print,'Median done'
		endif
; 05apr12	endif

loop=ny-1
lenfit=nx
if keyword_set(col) then begin
	loop=nx-1
	lenfit=ny
; 06oct3 - more nodes & omit bad for sbc internal lamp vig. at top:
; 06nov14 - too flexible for single f165lp, internal image, eg: --> ~1% glitches
	numnod=n_elements(xnod)
	xnod=[xnod(0:numnod-2),980,990,1000,1010,1019]
	print,'Col nodes=',xnod
	if det eq 'HRC' then begin	; 06oct2-assume ff hrc is not used.
		print,'Special pre-fix HRC extra node added in col dir'
		xnod=[xnod(0:6),(indgen(3)+1)*(1023-xnod(6))/3+xnod(6)]
		print,'xnodes=',xnod
		endif
	endif
nskip=0
for i=0,loop do begin                   ; MAIN SBC LOOP
        if keyword_set(col) then begin          ; COLUMN FITTING
		good=where(mask(i,*) gt 0,ngd)
		if float(ngd)/lenfit lt 0.55 then begin	; .65 before 99jun24
			mask(i,*)=-1
			nskip=nskip+1  &  goto,skipfit  &  endif
		if not keyword_set(nomed) then 		$; filter ccd, NOT mama
				tmp(i,good)=median(transpose(img(i,good)),13)
		ynod=xnod*0+avg(tmp(i,good))
		fiti=splinefit(xpx(good),tmp(i,good),xpx(good)*0+1,xnod,ynod)
		fit(i,*)=cspline(xnod,ynod,xpx)
;if i eq 700 then begin
;plot,tmp(i,*),yr=[9000,13000],xr=[900,1023]
;oplot,fit(i,*),thic=2  &  stop  &  endif
	    end else begin                      ;ROW FITTING:
		good=where(mask(*,i) gt 0,ngd)
		if float(ngd)/lenfit lt 0.55 then begin	; .65 before 99jun24
			mask(*,i)=-1
			nskip=nskip+1  &  goto,skipfit  &  endif
; reallocate nodes, esp for STIS tung 52x2 w/ 1st 215 px ignored
		xnod=findgen(nodes)*(xpx(max(good))-xpx(good(0)))/      $
                                                               (nodes-1)+good(0)
; add SBC pts half way btwn 1st & 2nd,two btwn 2nd & 3rd, 		$
;						and 2 more btwn last 2 nodes
                del=xnod(1)-xnod(0)
                if det eq 'SBC' then    $               ; not for STIS
        	   xnod=[xnod(0),xnod(0)+del/2,xnod(1),xnod(1)+del/3,	$
		   	xnod(1)+.667*del,				$
		   	xnod(2:nodes-2),xnod(nodes-1)-.667*del,		$
			xnod(nodes-1)-del/3,xnod(nodes-1)]
		ynod=xnod*0+avg(double(tmp(good,i)))	; double is mystery fix
		fiti=splinefit(xpx(good),tmp(good,i),xpx(good)*0+1,xnod,ynod)
		fit(*,i)=cspline(xnod,ynod,xpx)
;if i eq 200 then stop	
;plot,tmp(*,i),yr=[9000,12000]  &  oplot,fit(*,i),thic=2  &  stop
		endelse
skipfit:
	endfor
print,'FITFLAT W/ ',n_elements(xnod),' NODES=',xnod
print,nskip,' Fits skipped'

splat:

bad=where(fit eq 0,nbad)
if nbad gt 0 then fit(bad)=1		;to avoid 0/0 in img/fit
flat=img/fit
end
