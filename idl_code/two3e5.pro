pro two3e5,modt,modg,modz,wave,flxlo,flxhi,cntlo,cnthi
; PURPOSE
;	fetch pairs of flux & continuum of Mz models for del Z = 0.25
;		and R=300,000, 1 samp/resel
; INPUT
;	modt-model temperature
;	modg-log g
;	modz-lower of the pair of bracketing log z's
; OUTPUT
;	wave-wavelength in Angstroms, 
;	flxlo,flxhi models at modz and next higher Z in erg cm-2 s-1 A-1
;	cntlo,cnthi- continuumm, as above for flux, in same units
;HISTORY
; 2016dec28

;tmin=3500.  &  gmin=0.  &  zmin=-2.5
;modt=[indgen(35)*250.+tmin,indgen(16)*500.+12500.,indgen(15)*1000.+21000.]
;modg=indgen(ngrav)*0.5+gmin
;modz=indgen(nz)*.25+zmin 		eg =2.5, -2.25.-2...

for iz=0,1 do begin
	z=modz+0.25*iz
	pm='p'  &  if z lt 0 then pm='m'
	zabs=abs(z)
	zasc=string(round(10*zabs+.1),'(i2)')		; eg 1.25-->12.6 --> 13
	if zabs lt 1 then zasc=string(round(10*zabs+.1),'("0",i1)')
	name='am'+pm+zasc+'cp00op00t'+string(modt,'(i4)')
	if modt gt 9800 then name='am'+pm+zasc+'cp00op00t'+string(modt,'(i5)')
	name=name+'g'+string(modg*10,'(i2)')+'v20modrt0b300000rs.asc'
	name=replace_char(name,' ','0')				; 2020feb23
	print,modt,modg,modz,z,' ',name
	fil='../models/BOSZ3e5/'+name
	ckit=findfile(fil)
	if ckit eq '' then begin
		dir='m'+pm+zasc+'cp00op00/'
		bzfil=findfile('/astro/absfluxcal1/'+dir+name+'.bz2')
		if bzfil eq '' then stop else begin
; the ff 2 spawn commands work fine, but give spurious .setenv: errors
			spawn,'cp '+bzfil+' ../models/BOSZ3e5'
			spawn,'bzip2 -df ../models/BOSZ3e5/'+name+'.bz2'
			endelse
		print,'two3e5.pro is converting '+bzfil
		endif
	if iz eq 0 then rdfloat,fil,wave,flxlo,cntlo,/silent  $
				else rdfloat,fil,wave,flxhi,cnthi,/silent
	endfor
return

end
