pro rdhaus,file,wave,flux,bb
;+
; PUPOSE:
;	Read a Hauschildt=NextGen model atmosphere w/ WL,Flux, Black body all
;		in single vectors in that order.
;		1st line: Teff, logg, [M/H] ,respective
;		2nd line: states the number of wavelength points
; CALLING SEQUENCE:
;	rdhaus,file,wave,flux,bb
; INPUT:
;	file - name of file to read
; OUTPUT:
;	wave - wavelength vector in Angstroms in Vacuum
;	flux - in erg s-1 cm-2 cm-1 (need 1e-8 scaling for A-1 at surface)
;	bb - black body spectrum of same Teff
; HISTORY: 08MAR18 - rcb
;-

close,1  &  openr,1,file
teff = 0.0 & logg= 0.0 & logz = 0.0
readf,1,teff,logg,logz

nwave=0L
readf,1,nwave

wave = fltarr(nwave)
flux = fltarr(nwave)
bb = fltarr(nwave)

readf,1,wave
readf,1,flux
readf,1,bb
close,1

return

end
