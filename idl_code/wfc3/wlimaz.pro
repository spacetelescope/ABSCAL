pro wlimaz,obs,y,wl,xcen,ycen,dir
;+
; 2013may13 - measure the saturated line (10830A) from the _ima zero-read file
;		in +1st order
; INPUT
;	obs - rootname of observation
;	y - vector of y(x) positions from prelim spectral extraction
;	wl - WL vector from prelim spectral extraction
; OUTPUT
;	xcen,ycen - px coordinates of 10830A line in 1st order
; 2013May27 - convert to subroutine called by wlmeas.pro
;-
if n_elements(dir) eq 0 then begin
	data_dir = '/user/deustua/wfc3/wavecal/'
endif else begin
	data_dir = dir + "/"
endelse

st=''
file=data_dir+obs+'_ima.fits'
fits_read,file,ima,hd,exten=0,/header_only
nexten=sxpar(hd,'nextend')
fits_read,file,ima,hd,exten=nexten-4		; zero read
ima=ima(5:1018,5:1018)				; trim to match _flt
fits_read,file,dq,hd,exten=nexten-2		; 8 is unstable in Zread
dq=dq(5:1018,5:1018)

; Use prelim spectral extractions for approx position:
xlin=ws(wl,10830.)
yapprox=fix(y(fix(xlin+.5))+.5)
xapprox=fix(xlin+.5)
print,'WLIMAZ: 10830 line at approx:',xapprox,yapprox

; fix the dq=8 px
ns=11						; 11x11 searh area
sbimg=ima(xapprox-ns/2:xapprox+ns/2,yapprox-ns/2:yapprox+ns/2)
sbdq=dq(xapprox-ns/2:xapprox+ns/2,yapprox-ns/2:yapprox+ns/2)
bad=where((sbdq and 8) gt 0,nbad)
; I see up to nbad=5 in later data, eg ic6906bzq, but ima NOT zeroed & looks OK
; no response from SED abt re-fetching new OTF processings
;	if nbad gt 2 then stop 				;& figure out what to do
;	if nbad le 2 and nbad ge 1 then begin		;fix bad px by interpol:
totbad=total(sbimg(bad))
if totbad eq 0 then begin
	print,nbad,' bad px repaired'
	for i=0,nbad-1 do begin
	    xbad=bad(i) mod ns
	    ybad=bad(i)/ns
;bad dq at edge should be OK
	    if xbad ne 0 and xbad ne ns-1 and ybad ne 0 and 	$
	    	ybad ne ns-1 then sbimg(bad(i))=		$
		(sbimg(xbad-1,ybad)+sbimg(xbad+1,ybad)+		$
		sbimg(xbad,ybad-1)+sbimg(xbad,ybad+1))/4
	    endfor
	endif
indmx=where(sbimg eq max(sbimg))
xpos = indmx mod ns
ypos = indmx/ns
cntrd,sbimg,xpos,ypos,xc,yc,2
if xc(0) lt 0 then begin		; peak too close to edge
	print,'Use approx position in sbimg='+string([xpos,ypos],'(2i3)')
	xc=xpos  &  yc=ypos  &  endif	; try approx pos
xcen=xc(0)+xapprox-ns/2			; vector-->float
ycen=yc(0)+yapprox-ns/2
if nbad gt 0 then begin
	print,'WLIMAZ: nbad,total of bad=',nbad,totbad
	endif

; ###change for test plot
;ylo=fix(ycen+.5)-3
;spec=rebin(ima(*,ylo:ylo+6),1014,1)
;plot,spec,xr=[xcen-10,xcen+10],psym=-4
;oplot,[xcen,xcen],[0,99999],line=2
;plotdate,'wlimaz'
return
end
