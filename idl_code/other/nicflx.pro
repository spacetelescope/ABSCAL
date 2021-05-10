PRO nicflx,file,wave,flux,net,gross,bkg,sigdat,sigpoi,sigmea,npts,exptim,     $
		temper,sens=sens,corr=corr,notemp=notemp
;+
;
; PURPOSE:
;	read nicmos grism data & calibrate net countrate to flux. 
; INPUT
;	- file-extracted spectral ascii data file, eg g191b2b.g141-na5301
;		OR .grat or .mrg files, eg wd1057+719.g206
;	- sens - optional keyword specifying which sensitiv file. default=sens.*
;	- corr keyword - correct for brightness non-linearity
;	- notemp - do not correct for temperature from bias.
; OUTPUT
;	- wave=wavelengths
;	- FLUX=calibrated Nicmos FLUX
;	- NET DN/s
;	- GROSS counts/s
;	- bkg background ct/s
;	- sigdat: rms scatter among 15 obs positions
;	- sigpoi: propagated statistical error
;	- sigmea: error in the mean. col-7=Col-5/sqrt(#of good obs out of the 
;			15), combined w/ uncertainty in sens cal (sig)
;	- npts: the total number of good points out of the 15.
;	- exptim: the exposure time in  sec.
;	- temper: the temperature from bias value (K)
;
; AUTHOR-R.C.BOHLIN
; HISTORY:
; 04jul26 - adopted from stisflx
; 04AUG18 - add sens keyword
; 04aug19 - trim output below sens cutoff
; 04sep27 - Add special case of defocussed HD209458 w/ gwidth=23
; 04dec17 - Add keword corr to correct for non-linearity
; 05apr1 -  mod to read merged files, as well.
; 05aug4 - update linearity corr from linwd.pro & apply as fn of net, not gross
; 05nov22- implement niclincor function
; 06jan16 - try corr gross & bkg, then subtr to get corr net. NG--> bigger resid
; 06may 1 - patch for improper dithers in 1812095, G141, n9iu02
; 06jun26-jul18 - try omitting the linearity corr for G206, but photom is 
;	better w/ the correction!!?? (see rat141206 plots)
; 06aug15 - add exptime
; 08sep18 - add temp corr and /notemp to avoid temp corr for derivation in 
;		tfbcorel.pro. Use 0.618 +/- 0.071 %/K for the correction.
; 08Oct7 - add temperature to the output list.
; 08oct21 - change to 0.737+/-.068 %/K for temp corr.
; 08nov10 - change from a mean temp of 76.5 to 76.0
; 08nov13 - change to 0.697 +/-.075%/K for temp corr from just G096 & 141
; 09jun8 - 0.556 +/- 0.110 .................... after new disp constants
; 10jan19- linearity corr changed a tad, but no change in the 0.556.
; 13sep18 - No change, still 0.556 w/ Rauch model cal.
;-
st=''
rdf,file,1,d
if strpos(file,'-n') ge 0 then begin
	wave=d(*,0)
	gross=d(*,1)
	bkg=d(*,2)
	net=d(*,3)
	sigdat=d(*,4)
	sigpoi=d(*,5)
	sigmea=d(*,6)
	npts=d(*,7)
	exptim=d(*,8)
; patch for James bad dithers:
	if strpos(file,'1812095.g141-n9iu02') ge 0 then begin
		bad=where(wave gt 1.1765 and wave lt 1.1885)
		net(bad)=210.  &  npts(bad)=1
		exptim(bad)=exptim(bad)/2		; reduce weight
		endif
    end else begin					; merged files
	wave=d(*,0)
	gross=d(*,6)
	bkg=d(*,7)
	net=d(*,1)
	flux=d(*,2)
	sigdat=0					; rms not available
	sigpoi=d(*,3)
	sigmea=d(*,4)
	npts=d(*,5)
	exptim=d(*,8)
	return
	endelse
fdecomp,file,dir,subdir,targ,ext
optmode=strmid(ext,0,4)
sfile='sens.'+optmode
if keyword_set(sens) then sfile=findfile(sens+'.'+optmode)
print,'SENSITIVITY FILE=',sfile
restore,sfile(0)			; restores wgrid,avsns
; trim data below wgrid(0) in sens file. should be no trim now=04aug19:
good=where(wave gt wgrid(0))
wave=wave(good)  &  gross=gross(good)  &  bkg=bkg(good)  &  net=net(good)
		sigdat=sigdat(good)  &  sigpoi=sigpoi(good)
		sigmea=sigmea(good)  &  npts(good)=npts(good)
		exptim=exptim(good)

; correct net for measured non-linearity:
; 06jun26 - try g206 w/o linearity corr, as bkg>>net, eg g191 bk/net>~8
;if keyword_set(corr) and optmode ne 'g206' then net=net/niclincor(wave,net)

; Normal Correction:
if keyword_set(corr) then net=net/niclincor(wave,net)
if not keyword_set(notemp) then begin	; do even if corr=0
	mode=gettok(ext,'-')
	datset=strmid(ext,0,6)
; i want to use odd targ names in the file. So find primary star for temper.
	fils=findfile('spec/'+strmid(targ,0,3)+'*'+ext)
	fdecomp,fils(0),dir,subdir,targ,ext
	temper=nictemp(mode,targ,datset)
	tcorr=1+(temper-76.0)*.00556
	net=net/tcorr
	print,'NET & Flux corr for Temper='+string([temper,tcorr],  $
							'(f7.2,"by",f6.3)')
	endif

;if keyword_set(corr) then begin	---NG --> bigger residuals
;	gtemp=net+bkg				; temporary gross
;	gtemp=gtemp/niclincor(wave,gtemp)
;	bkgcor=bkg/niclincor(wave,bkg)
;	net=gtemp-bkgcor
;	endif
	
linterp,wgrid,avsns,wave,sensterp
flux=net/sensterp
; convert gwidth=23 to gwidth=4 default & do approx smoothing
; 	for orig out of focus hd209458.g*-n8i8b1 obs:
if strpos(file,'n8i8b1') ge 0 then begin
	flux=net/smooth(smooth(sensterp,5),3)		; account for defocus
	flux=flux*(0.94-0.05*wave)
	print,'SPECIAL HD209458 out-of-focus CAL applied'
	endif
if strpos(file,'189733') ge 0 then begin		;2016aug29
	flux=net/smooth(smooth(sensterp,5),5)		; account for defocus
	flux=flux*(0.895-0.00943*wave)			; bdist=35,gwidth=10
	print,'SPECIAL HD189733 out-of-focus CAL applied'
	endif
RETURN
END
