pro f435cor,xc,yc,c435,c814,cor435
;+
;  PURPOSE: Correct F435W for flat-field errors 
; INPUTS:
;	xc,yc - the vector coordinates (0-4095) of the star on each chip.
;	c435 - vector F535W inf. aper photom (ct/s) to be corrected.
;	c814 - vector F814W inf. aper photom (ct/s).
; OUTPUT:
;	cor435 - the corrected F45W photometry
; RESTRICTION: run in a top level dir.
; HISTORY
;	2017nov6 - rcb
;-

fits_read,'../acssens/deliv/F435WdeltaFF-GD153.fits',gdcor,hg
fits_read,'../acssens/deliv/F435WdeltaFF-KF06T2.fits',kfcor,hk

rat=c435/c814

aval=(rat-0.137)/(2.223-0.137)
delflt=(1-aval)*kfcor(xc,yc)+aval*gdcor(xc,yc)		; the delta-flat

cor435=c435/delflt

end
