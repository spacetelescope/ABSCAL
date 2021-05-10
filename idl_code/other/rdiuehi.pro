pro rdiuehi,file,wbeg,wave,flux,npts,px0,word,flxord
; 04jan14 - rdiuehi.pro to read NEWSIPS IUE binary tables for Hi-disp
; INPUT - file
;	wbeg - wavelength for desired order. ie first one starting after wbeg
;		Use 0 to get just all orders and skip doing the last 2 outputs
; OUTPUT:
;	wavelength (A)	768.nord array
;	flux
;	npts - number of defined fluxes per order
;	px0  - pixel number of first non-zero flux in ea order
;	word - trimmed wavelengths for specified order
;	flxord - ...... flux ........................
;-

z=mrdfits(file,1,hd)
!mtitle=sxpar(hd,'filename')

wl0=z.wavelength
px0=z.startpix
dlam=z.deltaw
npts=z.npoints
nord=n_elements(wl0)			; number of orders
wave=fltarr(768,nord)			; define output wavelength array
flux=z.abs_cal

for i=0,nord-1 do wave(px0(i):px0(i)+npts(i)-1,i)=wl0(i)+dlam(i)*indgen(npts(i))

; trim the specified order
if wbeg gt 0 then begin
	indx=where(wl0 ge wbeg)  &  indx=indx(0)
	good=where(wave(*,indx) gt 0)
	word=wave(good,indx)
	flxord=flux(good,indx)
	ql=z.quality & ql=ql(good,indx)
	good=where(ql ge 0)
	word=word(good)			; lazy fix for reso's etc.
	flxord=flxord(good)
	endif

end
