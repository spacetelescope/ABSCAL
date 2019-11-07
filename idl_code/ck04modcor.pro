pro ck04modcor,nam,wstar,fstar,wmod,fmod,ebv,teff,logg,logz
;+
;
; PURPOSE:
;	create a corrected CK04 model, ie correct the lo-fi grid w/ hi-fi solar
;		model. model has param as pub in G star paper 
;		and norm to the wstar,fstar input flux @ 6-9000A
;
; INPUT
;	nam - star name
;	wstar - vac wavelength array of obs. spectral flux distribution in ANG.
;		if not an array, then do not normalize.
;	fstar - observed spectral flux distribution
; OUTPUT
;	wmod - wavelengths w/ min WL=2002A
;	fmod - flux
;	ebv - E(B-V)
;	teff - effective temperature
;	logg - surface gravity
;	logz - metallicity
; HISTORY
;	09Dec4 - rcb
;	11dec22 - omit ck04corr for Teff>7000K
;	13Feb28 - change model_int to ck04blanket to get new models.
;	14Oct13 - rm ck04corr entirely to match ck04blanket & findmin
;-

;;common dumnam,ck04corr
;;if n_elements(ck04corr) eq 0 then begin
; compute the corr to the CK04 models from the solar HI-Fi/lo-fi once:
;;	rdf,'../calib/sun/fsunallp.1000resam251',1,d		; KZ 2004 hi-fi
;;	!mtitle=''
;	model_int,5777.,4.44,0.,bwave,cksun,wrange=[2002,1.6e6]	; CK04 sun
;;	ck04blanket,5777.,4.44,0.,bwave,dumbl,dumco,cksun,wrange=[2002,1.6e6]
;;	ck04fix,bwave,cksun,bwave,cksun			;fill 10-30mic gaps
; Min fsunallp WL is 150nm=1500A & convert nm to A. Use 2 below to match CK04
;;	absratio,d(*,0)*10,d(*,1),bwave,cksun,2,0,0,0,wcorr,ck04corr
;;	ck04corr=ck04corr/tin(wcorr,ck04corr,6000,9000) ; unity in norm region
;;	bad=where(wcorr gt 42000 and wcorr lt 70000)	;bad CO band in Kz Hi-Fi
; replace the hi-fi corr from 4.2-7 w/ a ~const. match at endpoints:
;;	y1=ck04corr(bad(0))  &  y2=ck04corr(max(bad))
;;	x1=wcorr(0)  &  x2=wcorr(max(bad))
;;	m=(y2-y1)/(x2-x1)					; slope of line
;;	ck04corr(bad)=y1+m*(wcorr(bad)-x1) 			; straight line
;;	bad=where(wcorr lt 10000)
;;	ck04corr(bad)=1.
;;	print,'Below 2mic ck04corr set to unity'
;;	endif

vmg=vmag(nam,ebv,spty,bvri,teff,logg,logz,model='cast')
;model_int,teff,logg,logz,bwave,bflx,cas='castelli',wrange=[2002,1.6e6]
ck04blanket,teff,logg,logz,bwave,dumbl,dumco,bflx,wrange=[2002,1.6e6]
ck04fix,bwave,bflx,wmod,fmod			; 10-30mic gaps interpol
chiar_red,wmod,fmod,-(ebv),fmod
if n_elements(wstar) gt 1 then						$
	fmod=fmod*tin(wstar,fstar,6000,9000)/tin(wmod,fmod,6000,9000)

end
