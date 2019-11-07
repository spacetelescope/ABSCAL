pro lorentz,x,fwhm,y

; PURPOSE: compute Lorentzian profile: ~1/(x^2+(fwhm/2)^2), w/ peak at x=0
; INPUT: 
;	x - vector (of wavelengths) centered at x=0
;	fwhm - full width of half max in units of x
; OUTPUT:
;	y - vector w/ the values of the lorentzian 
;-
hwhm=fwhm/2
y=hwhm/((x^2+(hwhm)^2))
return
end
