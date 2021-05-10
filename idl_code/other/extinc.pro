pro extinc,w,f,v,bv,ws,fs,vs,bvs,wex,ex,bin=bin
;+
;
; compute selective extinction per bohlin & savage (1981,apj,249,109)
;
; CALLING SEQUENCE: extinc,w,f,v,bv,ws,fs,vs,bvs,wex,ex,galred
; INPUT:
;	w - wavelength of reddened star
;	f - flux of reddened star
;	v - V mag of reddened star
;	bv - B-V mag of reddened star
;	ws,fs,vs,bvs - as above for unreddened standard comparison star
; OUTPUT:
;	wex - wavelength array for ex w/ 10A spacing.
;	ex - selective extinction E(lambda-V), normalized to E(B-V)
;	galred - optional Seaton galactic avg selective extinction @ wex wl's
; KEYWORDS:
;	bin - optional default bin size in Ang. default=10
; HISTORY
;	95MAR22-rcb
;	13Jul10-mod for constant starting WL
;-
nstart=fix(ws(0)/bin)+1
wbeg=nstart*bin
if wbeg-bin/2 lt ws(0) then wbeg=wbeg+bin
print,'min(WLs), wbeg=',ws(0),w(0),wbeg
if not keyword_set(bin) then bin=10
absratio,ws,fs,w,f>1e-30,4,0,wbeg,bin,wex,rat	; f>0 to make absratio work
print,minmax(wex)
ex=(2.5*alog10(rat)-(v-vs))/(bv-bvs)

end
