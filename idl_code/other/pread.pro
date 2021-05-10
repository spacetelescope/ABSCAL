PRO pread,file,wl,flux,tit
;+
;
; Peugeot Read for the odd format text files from Bergeron for model WDs
;
; INPUT: file name
;OUTPUT: wl-wavelength array
;	flux - 3 Model flux distributions
;	tit - 3 corresponding titles
; 2011Jun6-rccb
;-

st='   '
close,1 & openr,1,file
while strmid(st,0,3) ne '###' do readf,1,st	; flag for start of data

npts=0
readf,1,npts					; No. of pts in arrays
wl=dblarr(npts)
flux=dblarr(npts,3)
w=dblarr(10)					; No. of wl pts per row
f=dblarr(6)					; .......flux ...........
tit=strarr(3)					; titles
row=npts/10					; No. of rows of wavelengths
for i=0,row-1 do begin
	readf,1,w
	wl(10*i)=w
	endfor
w=0.d
f1=0.d
readf,1,w
wl(npts-1)=w					; last single wl point

for imod=0,2 do begin				; 3 models/file
	readf,1,st
	tit(imod)=st
	row=npts/6				; 6 flux pts/file
	for i=0,row-1 do begin
		readf,1,f,form='(6e12.5)'
		flux(6*i,imod)=f
		endfor
	readf,1,f1
	flux(npts-1,imod)=f1
	endfor

;help,npts,wl,flux,tit
;print,wl(0:3),wl(npts-4:npts-1)
;print,flux(0:3,0:2),flux(npts-4:npts-1,0:2)
;print,tit

close,1
return
end
