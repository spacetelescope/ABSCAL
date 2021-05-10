PRO RampProf, Wcen, Wped_cen, w1, w2, wvl, Tmod_L, over=over, noplot=noplot
;+
;
; compute ACS ramp profiles per zlatko prescription. used by ramplt & rampfits
; INPUT 
;	wcen - central wavelength from continuum of choices
;	Wped_cen - wavelength in name of one of 15 ramps (4-5 digits)
;	w1,w2 - wavelength range of plot
; OUTPUT
;	wvl - wavelength array
;	Tmod_L - filter profile, i.e. fractional transmission
; HISTORY
;	99May5 - rcb
;	01nov20 add noplot keyword & fix up for unix
;	SEE /data/rcbsun1/acsisr/ramp00-05 for driver routines
;-

wcen=float(wcen)  &  Wped_cen=float(Wped_cen)
 !ytitle='Transmission'
 !xtitle='Wavelength'
 !mtitle=string([Wped_cen,Wcen],'(f5.0," @",f6.0)')

if n_params(0) lt 4 then begin
	w1=3000.  &  w2=11000  &  endif		;default values
  wvl = w1 + findgen((w2-w1)/5+1)*5		; 5A spacing ---> <1% error
  alpha = 8
; read the b and c coef from ascii files
RampName='FR'+strtrim(string(wped_cen/10,'(i)'),2)+'N'
if Wped_cen eq 4590. or Wped_cen eq 6470. or Wped_cen eq 9140 then 	$
					RampName=replace_char(RampName,'N','M')
readcol,'/data/rcbsun1/acsisr/ramp00-05/ramps_t85_coeff.txt',rnames,	$
	d1,d2,d3,d4,d5,bzero,bone,btwo,format='(a,a,a,a,a,a,f,f,f)',/silent
readcol,'/data/rcbsun1/acsisr/ramp00-05/ramps_fwhm_coeff.txt',rnames,	$
	d1,d2,d3,d4,d5,czero,cone,ctwo,format='(a,a,a,a,a,a,f,f,f)',/silent
indx=where(RampName eq rnames)
indx=indx(0)
;print,rnames(indx)+' Ramp'
b0=bzero(indx)
b1=bone(indx)
b2=btwo(indx)
c0=czero(indx)
c1=cone(indx)
c2=ctwo(indx)
;print,b0,b1,b2,c0,c1,c2
  Tavg = b0 + b1*Wcen + b2*Wcen^2
  BW50 = c0 + c1*Wcen + c2*Wcen^2
  BW50 = BW50*Wcen

; approximate band shape with modified Loretzian profile  
  Flam_nrm = 1. / ((abs(wvl - Wcen)/(BW50/2.))^alpha + 1.)
  BP_L = Tavg*Flam_nrm

; use correct pedestal for N(arrow) or M(edium) ramps
  IF strpos(RampName,'N') gt 0 THEN BEGIN
; <50 in exp(-50) to avoid underflow:
   Ped  = 7.0e-4*exp(-(((wvl-Wped_cen)^4)/(2*(0.047*Wped_cen)^4)<50))
  ENDIF ELSE BEGIN
   Ped  = 7.0e-4*exp(-(((wvl-Wped_cen)^6)/(2*(0.197*Wped_cen)^6)<50))
  ENDELSE

; define the zero level of measurements
  zero = 1.e-6

; now form the total throughput = Bandpass + Pedestal + Zero level  
  Tmod_L = BP_L + Ped + zero

if keyword_set(noplot) then return
if not keyword_set(over) then					$
  plot,wvl,Tmod_L,xrange=[w1,w2],yrange=[1e-7,1],/ylog else	$
	oplot,wvl,Tmod_L
;stop			; for debugging
return						; skip data example below
if Wped_cen ne 6560. then return
; 00may24 ff file is missing
  RampBP = readfits('FR656N_BP.FITS',hdr)   ; first row is wl, rest are transm
  sz_RampBP = size(RampBP)
  nx = sz_RampBP(1)
  ny = sz_RampBP(2)
  a0 = 7.348        ;-435.887      12.7963
  a1 = -0.123       ;0.025         -0.124586
  a2 = 1.85e-5      ;1.20e-5       1.86443e-5    
  Xpos = a0 + a1*Wcen + a2*Wcen^2
  y = round(Xpos + ny/2.+0)			; for measured transm.
  Tmeas  = RampBP[*,y]				; measured transm.
  oplot,RampBP[*,0],RampBP[*,y],lines=2
END
