function nic_flatscal,hdr,image,xpos,ypos,grism,gwidth,flat
;+
;
; INPUT:
;	image - 256x256 NICMOS grism image
;	xpos,ypos - x,y postion of the spectrum
;	grism - G096, G141, or G206
;	gwidth - height of extraction to make bkg estimate
; INPUT/OUTPUT: hdr - Added 06feb28 to get the mean bkg, medquad, returned.
; OUTPUT
;	return scaled Flat Field per background of data image for use in
;		calnic_spec
; 	flat - flat field used.
;
; 2006Jan9 - RCB
; 2006Feb28 - force G206 to subtract a continuum flat
; 2006mar4  - make G206 subtraction more sophisticated because of stars in G191 im
;		But the problem is residuals from the stars. Use the snap1+2 FF
; 2006Jul11 - DJL - modified to use NICREF environment variable
; 2006jul18 - change to g206 cont flat from blank obs.
; 2006Aug18 - DJL - modified to also return flat field
;-

medquad=median(image(0:127,0:127))
if medquad lt 100 and grism ne 'G206' then begin ; elim all but the lamp-on case
	print,'skipping contin bkg subtraction: 1st quad count rate=',medquad
	return,0
	endif

; read FF image
flat = 0
file = 'FF_'+strlowcase(grism)+'.fits'
;if grism eq 'G206' then file='skyflat-g206-snap.fits'
;if grism eq 'G206' then file='skyflat-g206-blank.fits'	; rcb-06jul18
if grism eq 'G206' then file='skyflat-g206-all.fits'
list = find_with_def(file,'NICREF')
if list(0) eq '' then begin
	print,'ERROR: '+file+' not found in NICREF'
	stop						; rcb-07jan2
	retall
	endif
fits_read,list(0),flat,h
if grism ne 'G206' then flat=1/(flat>.001)	; fix nicmos inverse flats

xmin=min(xpos)  &  xmax=max(xpos)
imav=reform(rebin(image(xmin:xmax,*),1,256),256)	; collapse along x
bkav=reform(rebin(flat(xmin:xmax,*),1,256),256)
smimav=median(imav,21)					; remove spikes
smbkav=median(bkav,21)
rat=smimav/smbkav					; const for perfect flat
sigma=stdev(rat(30:170),avrat)			; scale to mean of rows 30:170
; Div by flat in calnic_spec; but G206 will be a diff flat-->worse approx of bkg
avgbkg=avg(smimav(30:170))*avg(smbkav(30:170))*gwidth
sxaddpar,hdr,'avgbkgr',avgbkg,'Average Background*FF from _cal'
print,'Avg bkg * FF=',avgbkg,'+/-',sigma
;window,1
;plot,imav-bkav*avrat,yr=[-10,20]
;oplot,[0,255],[0,0],lines=2
;plot,rat,yr=[.9*avrat,1.1*avrat]
;oplot,[0,256],[avrat,avrat],lines=2
;net=image-avrat*flat
;bn=rebin(net(70:125,*),1,256)
;plot,bn,yr=[-1,1]
;oplot,[89,89],[-2,2]
;oplot,[105,105],[-2,2]
;tvscl,net>(-.5)<.5
;st=''
;read,st
return,avrat*flat				; scaled flat to subtract
end
