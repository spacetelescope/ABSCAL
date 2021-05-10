pro halofrac,mode,aper,wavin,fhalo
;+
;
; halofrac,mode,aper,wave,fhalo
;
; 05sep29 - to compute spectral halo fraction from abscor files for CTE corr.
;
; INPUT:
;	mode - first order CCD spectral mode
;	aper - STIS entrance aperture
;	wavin - wavelength grid to compute the output fraction
; OUTPUT:
;	fhalo - fraction of signal from a single stellar spectrum above standard
;			7px extraction height
;-
z=mrdfits('~/stiscal/dat/abscor-'+strlowcase(mode)+'.fits',1,hdr)
naper=sxpar(hdr,'naxis2')/9				; # of apertures
apert=strtrim(z.APERTURE,2)
apert=reform(apert,9,naper)
wav=z.WAVELENGTH
avfnod=z.THROUGHPUT
apfix=strupcase(aper)
if apfix eq '0.3X0.09' then apfix='0.2X0.2'		; G750L tung for calstis
iapr=where(apert(0,*) eq apfix)  &  iapr=iapr(0)

; 7px hgt is 2nd for ea of 9hgts*7 apertures & wls the same for all 9hgts
avwnod=wav(*,iapr*9)
delnod=(avwnod(7)-avwnod(0))/7
dlam=(avwnod(7)-avwnod(0)+2*delnod)/500

wave=indgen(501)*dlam+avwnod(0)-delnod
abscor=CSPLINE(avwnod,avfnod(*,iapr*9+7),wave)			; 7th hgt=80

; Use hgt=80 for inf & frac outside hgt=7 is abscor(hgt=80)-1, as all norm to 7
fabove=(abscor-1)/2		; 7th hgt=80 & half above and half below.

linterp,wave,fabove,wavin,fhalo

return 
end
