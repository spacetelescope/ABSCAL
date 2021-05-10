PRO rsmooth,res,wav,flx,newl,smoflx
;+
; Compute a Wavelength array at Resolution=res*2 and smooth flx to
;	R=res w/ a triangle function of delta-wave = wav/res
; INPUT:
;	res - resolution R = WL/dlam for output
;	wav - wavelength vector of high resolution spectrum
;	flx - flux vector of high resolution spectrum
; OUTPUT:
;	newl - wavelength vector w/ spacing of half of dlam=WL/R, ie 2 pts per
;		the new resolution elements
;	smoflx - flx smoothed twice w/ tin to give a triangle profile of 
;		FWHM=wav/res
; HISTORY - 08Apr1 to smooth Lanz models
;
; COMPARE: respwr.pro does NOT do a 2x oversampled grid,
;	does tin only once for rectangular LSF.
;-

; Let wmin=1 & note e^(n/R) ~ (1+n/R)^n, ie wl(i)= (1+i/R)^i = e^(i/R)
indx=findgen(2*res*alog(max(wav)))+1		; indices of the new WL vector
newl=exp(indx/(2*res))				; R=res*2 wl array for 2x sample
newl=newl(where(newl ge min(wav)))

npts=n_elements(newl)
dlam=newl(1:npts-1)-newl(0:npts-2)		; del-wav @ R=2*res
dlam=[dlam(0),dlam]				; make same length as wav

wmin=(newl-dlam)>newl(0)			; smooth by 2pts @ R=2*res =
wmax=(newl+dlam)<max(newl)			;	1pt width at R=res

smoflx=tin(wav,flx,wmin,wmax)
smoflx=tin(newl,smoflx,wmin,wmax)

end
