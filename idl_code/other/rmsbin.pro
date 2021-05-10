pro rmsbin,npx,wl,yval,wlbin,valbin,rms
;
; INPUT
;	npx - the width of bin in px
;	wl  - wavelength vector to bin
;	yval- y vector to bin & compute rms
; OUTPUT
;	wlbin - avg wl in bin
;	valbin- avg y value in bin
;	rms  - one sigma scatter in bin
; 06jan11 - bin a wl,yval data set & compute rms scat w/i each bin
;-

nbin=fix(n_elements(wl)/npx)				; number of bins
wlbin=fltarr(nbin)  &  valbin=wlbin  &  rms=wlbin

for i=0,nbin-1 do begin
	ist=i*npx					; first and 
	lst=(i+1)*npx-1					; last indices of bin
	wlbin(i)=avg(wl(ist:lst))
	rms(i)=stdev(yval(ist:lst),av)
	valbin(i)=av
	endfor
end
