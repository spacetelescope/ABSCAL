pro hrd,file,header,wave,flux,eps,err,EXPO,gross,back,net
;+
;
; 97jun23 - djl to read fits output of GSFC HRS idl pipeline with 
;	bmd_corr=model, ie model bkg. see his plots.
;	as documented in his header by:
;	HISTORY  CALHRS_UBK version  1.00: User Supplied Background subtraction
; INPUTS:
;       file - List of file names
; Multiple readouts and/or files come as 2nd dim of arrays, eg wave(2000,4)
;
; OUTPUTS:
;       header - fits header from the .c1h file
;       wave - wavelength vectors in 2-D array (npoints x nspec) from c0h file
;       flux - flux vectors from c1h file
;       eps - data quality vectors from cqh file
;       err - propagated error vectors from c2h file
;       expo - exposure times
; HISTORY
;	97JUNE30-rcb MOD TO DO MULT INPUT FILES LIKE HRSGET & get exp times
;-
if n_params(0) lt 1 then begin
	print,'hrd,file,h,wave,flux,eps,err,gross,back,net'
	return
	end
nfil = n_elements(file)
disk='disk$user2:[lindler.ghrs]' 		; patch - rcb
if strpos(file(0),'[') lt 0 then file=disk+file else begin
	for i=0,nfil-1 do begin
		fdecomp,file(i),dsk,dir,name
		file(i) = disk+name
		endfor
	endelse
if strpos(strlowcase(file(0)),'.fits') lt 0 then file=file+'.fits'
print,'processing: ',file
fits_open,file(0),fcb
fits_read,fcb,dummy,header
siz=size(dummy)
grp=1 & if siz(0) eq 2 then grp=siz(2)
nspec = nfil*grp
npoints = sxpar(header,'naxis1')
flux = fltarr(npoints,nspec)
wave = dblarr(npoints,nspec)
eps = intarr(npoints,nspec)
err = fltarr(npoints,nspec)
gross=fltarr(npoints,nspec)
back=fltarr(npoints,nspec)
net=fltarr(npoints,nspec)
expo = fltarr(nspec)
for i=0,nfil-1 do begin

	fits_open,file(i),fcb
	fits_read,fcb,wv,h
	fits_read,fcb,fx,h
	fits_read,fcb,ep,h
	fits_read,fcb,er,h
	fits_read,fcb,gr,h
	fits_read,fcb,bk,h	
	fits_read,fcb,nt,header
	fits_close,fcb

	wave (0,grp*i)=wv			; put 2-d arr into 2-d array
	flux (0,grp*i)=fx
	eps  (0,grp*i)=ep
	err  (0,grp*i)=er
	gross(0,grp*i)=gr
	back (0,grp*i)=bk
	net  (0,grp*i)=nt

	expo(grp*i)=sxpar(header,'exposure')	; placeholder. exp missing?
	endfor
if min(expo) ne max(expo) then $
                print,'WARNING: all files'+ $
                        ' do not have the same exposure time',expo
return
end
