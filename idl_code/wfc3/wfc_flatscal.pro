function wfc_flatscal,hdr,image,xpos,ypos,grism,gwidth,flat
;+
;
; INPUT:
;	image - grism image
;	grism - G102, G141
;	gwidth - height of extraction to make bkg estimate
; INPUT/OUTPUT: hdr - to get the mean bkg.
;	xpos,ypos - x,y position of the spectrum. Ypos NOT used.
; OUTPUT
;	return scaled Flat Field per background of data image for use in
;		calwfc_spec. Scaled flat is mean of image after stars are rm.  
; 	flat - flat field used.
;
; 2012Feb20 - RCB mod from nic_flatscal
; 2018Apr26 - mod for subarrays to output flat = size & position of subarr.
; 2021aug18 - This routine returns garbage for super sat iebo5*, so
;	set this bkg tweak to zero for iebo5* & stop to consider if avrat gt 3
;-

; read FF image
if grism eq 'G102' then file='WFC3.IR.G102.sky.V1.0.fits'
if grism eq 'G141' then file='WFC3.IR.G141.sky.V1.0.fits'
lst = find_with_def(file,'WFCREF')
if lst(0) eq '' then begin
	print,'ERROR: '+file+' not found in WFCREF'
	stop						; rcb-07jan2
	endif
fits_read,lst(0),flat,h

; 2018Apr26 - mod to work for Sub-images.
siz=size(image)
nl=siz(1)  &  ns=siz(2)
ltv1=-sxpar(hdr,'ltv1')         ; positive subarr offset
ltv2=-sxpar(hdr,'ltv2')         ; positive subarr offset
flat=flat(ltv1:ltv1+ns-1,ltv2:ltv2+nl-1)
xpos=indgen(ns)			; 2018Apr26
sclfac=nl/1014.			; =1 for usual 1014x1014 images 

xmin=min(xpos)  &  xmax=max(xpos)
imav=reform(rebin(image(xmin:xmax,*),1,nl),nl)	; collapse along x
bkav=reform(rebin(flat(xmin:xmax,*),1,nl),nl)
smimav=median(imav,61)					; remove spikes
smbkav=median(bkav,21)
rat=smimav/smbkav					; const for perfect flat
sigma=stdev(rat(100*sclfac:900*sclfac),avrat)	;scale to mean of rows 100:900
; subtr avrat*flat & Div by flat in calwfc_spec
avgbkg=avg(smimav(100*sclfac:900*sclfac))*gwidth
sxaddpar,hdr,'avgbkgr',avgbkg,'Average Background from wfc_flatscal'
print,'wfc_flatscal: Avg bkg =',avgbkg,'+/-',sigma,' for gwidth=',gwidth

; 2021aug18:
fil=sxpar(hdr,'filename')
; 2021sep23:
; Crowded img ieboz9mjq_flt.fits has avgrat=6.24276. Was 3 below
; avrat is the avg ratio of rat=smoothed image / (smoothed flat=~1)
if strpos(fil,'iebo5') ge 0 then avrat=0 
if avrat gt 9 then stop			; & consider 2022sep-7-->9 for ie3f02an

;window,1
;st=''
;plot,imav-smbkav*avrat,yr=[-1,5]
;oplot,[0,1013],[0,0],lines=2
;read,st
;plot,rat,yr=[.9*avrat,1.1*avrat]
;oplot,[0,1014],[avrat,avrat],lines=2
;read,st
;net=image-avrat*flat
;bn=rebin(net,1,1014)
;plot,bn,yr=[-1,1]
;window,xs=1014,ys=1014
;tvscl,net>(-.5)<.5
;read,st
return,avrat*flat				; scaled sky flat to subtract
end
