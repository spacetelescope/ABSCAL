; 2013Jun26 - sum all the signal in a WL range to replace tin.pro for STIS
;			time-change
;-

for make-tchang.pro

Do integral of points & signal:
npts=fltarr(n_elements(wave))

integral(npts,net,pt1,pt2)/(pt2-pt1)
