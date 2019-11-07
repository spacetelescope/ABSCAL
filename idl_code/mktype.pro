pro mktype,type,wave,cts
;+
; 08mar7 - read & co-add Cohen spectral classification Spectra,
;		also normalize to peak.
; INPUT:
;	type - Spectral type or star name
; OUTPUT:
;	wave - air Wavelengths in Ang
;	cts - Instrumental response units
;-

type=strupcase(type)
fils=findfile('~/pub/astars/'+type+'*')
fdecomp,fils,disk,dir,name,ext
typ=gettok(name,'-0')
good=where(typ eq type,ngood)
if ngood gt 0 then fils=fils(good)				    ; std star
if fils(0) eq '' then fils=findfile('~/pub/astars/*-'+type+'.fits') ; program *
ngood=n_elements(fils)
print,'Reading and co-adding files:',fils

fits_read,fils(0),spec,hd
if strpos(sxpar(hd,'ctype1'),'LINEAR') ne 0 then stop		; idiot ck.
if sxpar(hd,'crpix1') ne 1 then stop				; idiot ck.
cts=spec(*,0)
w0=sxpar(hd,'crval1')
disp=sxpar(hd,'cd1_1')
wave=w0+findgen(n_elements(cts))*disp
;print,w0,disp,'=offset,dispersion'
if ngood gt 1 then for i=1,ngood-1 do begin
	fits_read,fils(i),spec,hd
	ctnew=spec(*,0)
;	print,sxpar(hd,'crval1'),sxpar(hd,'cd1_1')
	if sxpar(hd,'crval1') ne w0 or sxpar(hd,'cd1_1') ne disp then begin
		wnew=sxpar(hd,'crval1')+sxpar(hd,'cd1_1')*		$
				findgen(n_elements(spec))
		linterp,wnew,ctnew,wave,ctnew	; ends of coadd NG
		endif
	cts=cts+ctnew
	endfor
cts=cts/max(median(cts,7))

return
end
