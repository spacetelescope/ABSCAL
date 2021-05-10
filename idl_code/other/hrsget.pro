pro hrsget,file,header,wave,flux,eps,err,expo,bkgdiod,bkgmod
;+
;			hrsget
;
; Procedure to read reduced hrs data files
;
; CALLING SEQUENCE:
;	hrsget,file,header,wave,flux,eps,err,expo,bkgdiod,bkgmod
;
; INPUTS:
;	file - List of file names (extension is ignored)
;
; OUTPUTS:
;	header - fits header from the .c1h file
;	wave - wavelength vectors in 2-D array (npoints x nspec) from c0h file
;	flux - flux vectors from c1h file
;	eps - data quality vectors from cqh file
;	err - propagated error vectors from c2h file
;	expo - exposure times
;	bkgdiod - scaler avg bkg countrates from .c3h file=special bkg diode
;	bkgmod - scaler avg bkg countrates from .c5h file=model predict for bgk
;
; EXAMPLE:
;	hrsget,'[data.hrs]zabc0101t',h,wave,flux,eps,err,expo,bkgdiod,bkgmod
;
; HISTORY:
;	version 1  D. Lindler  Feb 1996 in DISK$USER2:[LINDLER.PRO]
; 96jul30 - mod to take nspec from size of FILE list to process data like 
;					[.6567]	 - rcb
; 96jul31 - Odd stuff this HRS data! [.6038] has 8 groups to add, while [.6567]
;	has 2 overlapping settings w/2 obs each to add.
; 97jun19 - add bkgdiod and bkgmod to output. rcb
;-
;----------------------------------------------------------------------------
	if n_params(0) lt 1 then begin
		print,'hrsget, file, header, wave, flux, eps, err,'+	$
			'expo,bkgdiod,bkgmod'
		retall
	endif
;
; take off extension to the file name
;
;	fdecomp,file,disk,dir,name
	fdecomp,file(0),disk,dir,name	;96jul30 - rcb
	filename = disk+dir+name
	sxopen,1,filename+'.c1h',header
	npoints = sxpar(header,'naxis1')
	grp = sxpar(header,'gcount')
	nfil = n_elements(file)
	nspec = nfil*grp
	flux = fltarr(npoints,nspec)
	wave = dblarr(npoints,nspec)
	eps = intarr(npoints,nspec)
	err = fltarr(npoints,nspec)
	bkgdiod=fltarr(nfil)
	bkgmod=fltarr(nfil)
	expo = fltarr(nspec)
	for i=0,nfil-1 do begin
		fdecomp,file(i),disk,dir,name	;96jul30 - rcb
		filename = disk+dir+name
		sxopen,1,filename+'.c1h',header
		if sxpar(header,'gcount') ne grp then begin
			print,filname+' groups ne ',grp,'. STOP in hrsget'
			stop
			endif
		indx=grp*i
	for jgrp=0,grp-1 do begin
;
; read flux vectors and exposure times
;
		flux(*,indx+jgrp) = sxread(1,jgrp,gpar)
		expo(indx+jgrp) = sxgpar(header,gpar,'exposure')
		endfor
;
; read wavelengths
	sxopen,1,filename+'.c0h'
	for jgrp=0,grp-1 do wave(*,indx+jgrp) = sxread(1,jgrp)
;
; read data quality
	sxopen,1,filename+'.cqh'
	for jgrp=0,grp-1 do eps(*,indx+jgrp) = sxread(1,jgrp)
;
; read errors
	sxopen,1,filename+'.c2h'
	for jgrp=0,grp-1 do err(*,indx+jgrp) = sxread(1,jgrp)
;
; read measured bkg from special diode
	sxopen,1,filename+'.c3h',header
	grp = sxpar(header,'gcount')			; 97jun23 fix:
; eg: 6*4=24 groups for Z3860507T: Nreads=4, 6=(4xsteps+2bkg steps of 512 array
;print,filename+'.c3h',i,grp,' Twelve special readout values:'
	for jgrp=0,grp-1 do begin
		twlvdiod=sxread(1,jgrp)
		bkgdiod(i)=bkgdiod(i)+avg([twlvdiod(0:1),twlvdiod(10:11)])
		endfor
	bkgdiod(i)=bkgdiod(i)/grp
;
; read bkg from model
	sxopen,1,filename+'.c5h',header
	grp = sxpar(header,'gcount')
	for jgrp=0,grp-1 do bkgmod(i)=bkgmod(i)+avg(sxread(1,jgrp))
	bkgmod(i)=bkgmod(i)/grp
	endfor
;
; print warning if all groups do not have same exposure time
;
if min(expo) ne max(expo) then $
		print,'WARNING: all files'+ $
			' do not have the same exposure time',expo
return
end
