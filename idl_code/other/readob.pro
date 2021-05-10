; 2014June - Read in the Cloudy format merged Lanz & Hubeny file for NLTE OB
;		star models. See models/doc.lanzOB.
;-
st=''
close,5  &  openr,5,'/internal/1/models/lanzOB/umd-cloudy.mrg'
for i=0,11 do readf,5,st				; skip 12 intro lines
modlst=fltarr(3246)					;1082 models * 3 param
readf,5,modlst
freq=dblarr(19998)
readf,5,freq
mods=dblarr(19998,1082)
readf,5,mods
wav=3e18/reverse(freq)
flam=3e18*reverse(mods,1)/wav^2			; reverse 1st dimension of arr

teff=47500.
logg-3.75
logz=0.3

indt=where(???

end
