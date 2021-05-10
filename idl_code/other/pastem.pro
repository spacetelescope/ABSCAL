pro pastem,wcut,wold,fold,errold,sysold,exold,epold,fwold, $
                                wave,flux,sterr,syerr,exptime,dataqual,fwhm
;+
;
; 00jun1 - for use in MAKE_STIS_CALSPEC
; Input: everthing
; Output: concatenated wave,flux,sterr,syerr,exptime,dataqual,fwhm with
;	old stuff below wcut and wave,flux, etc longward of wcut
;-
goods=where(wold le wcut)
goodl=where(wave gt wcut)
wave=[wold(goods),wave(goodl)]
flux=[fold(goods),flux(goodl)]
sterr=[errold(goods),sterr(goodl)]
syerr=[sysold(goods),syerr(goodl)]
exptime=[exold(goods),exptime(goodl)]
dataqual=[epold(goods),dataqual(goodl)]
fwhm=[fwold(goods),fwhm(goodl)]
end
