pro tinpts,WAV,FLX,WMIN,WMAX,binflx,npts,wmnout,wmxout

; PURPOSE - Count the points in each bin
;INPUT
; wav - WL of vector to integrated
; flx - Flux .....................
; wmin-vector of begining bin WLs
; wmax-vector of ending bin WLs
;OUTPUT
; binflx-avg flux in each bin w/ 0 values for out-of-range bins
; npts - Number of points in each bin
; wmnout-revised vector of begining bin WLs
; wmxout- -revised vector of ending bin WLs
; HISTORY - 2018Feb27 rcb
;-

begind=0
binflx=wmin*0.					; initialize output to zeros
wmnout=wmin  &  wmxout=wmax
; adjust range, as needed
if wmin(0) lt wav(0) then begin
	good=where(wmin ge wav(0),nck)
	if nck le 0 then stop
	wmnout=wmnout(good)  &  wmxout=wmxout(good)
	begind=good(0)				; index of first good binflx
	endif
if wmxout(-1) gt wav(-1) then begin
	good=where(wmxout le wav(-1),nck)
	if nck le 0 then stop
	wmnout=wmnout(good)  &  wmxout=wmxout(good)
	endif

bingud=tin(WAV,FLX,wmnout,wmxout)		; main binned result
binflx(begind)=bingud				;binned results into full output

; count the points in each bin
;
npts=intarr(n_elements(binflx))			; initialize to zero count
for i=0,n_elements(wmnout)-1 do begin
	dum=where(wav ge wmnout(i) and wav lt wmxout(i),npt)
	npts(begind+i)=npt
	endfor
end
	
