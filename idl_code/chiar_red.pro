pro chiar_red, wave, flux, ebv, funred,gc=gc
;+
; NAME:
;    chiar_red
;*CLASS:
;     Spectral Data Reduction
;
; PURPOSE:
;     Correct a flux vector for interstellar extinction from Chiar and Tielens
;	(2006,ApJ,637,774) longward of 1.24mic and below 1.24 mic:
;       from unred.pro # 10 CCM (1989) w/ R = 3.1
; Scale Chiar&Tielens by 3.1 for E(B-V), *0.09 for A(K)=0.09*A(V), & *1.15 to
;	match CCM @ 1.2mic. Extrapolate local ISM from 27 to 35 mic to match
;	galactic center result.
;
; CALLING SEQUENCE:
;       chiar_red, wave, flux, ebv, funred     
;
; INPUT:
;       WAVE - wavelength vector (Angstroms)
;       FLUX - flux vector, same number of elements as WAVE
;       EBV  - color excess E(B-V), scalar.  If a negative EBV is supplied,
;               then fluxes will be reddened rather than dereddened.
; KEYWORD
;	gc - galactic center reddening selected. Default is local ISM curve.
;
; OUTPUT:
;       FUNRED - unreddened flux vector, same units and number of elements
;               as FLUX
;
; DATA FILE:
;       The environment variable ASTRO_DATA should 
;       point to the directory containing the data files. This line may need 
;       to be changed for your local system environment. (See the
;       procedure ASTROLIB).
;
; FILE USED: extfitzchiar.ascii
;
; RESTRICTION:
;       funred is set to zero outside the valid 910-350000A range
;
; EXAMPLE:
;        Correct for e(b-v) of 0.2
;               chiar_red,wave,flux,0.2,newflux
; REVISION HISTORY:
; 	Written by calib/makirred.pro 
;       adapted from unred.pro 07Jan15-R.C. Bohlin
; 08mar11 - switch from fitzpatrick to CCM reddening and rescale chiar a tad
; 13sep9  - Extend CCM from 1000 down to 910A. CCM is defined to 909A.
;-
 if N_params() LT 4 then begin
     print,'Syntax: chiar_red, wave, flux, ebv, funred'
     return
 endif

flx = float(flux)                  ;Make sure input wave, flux are 
wav = float(wave)                  ;floating point format 

 TABFILE = find_with_def('extccmchiar.ascii','ZAUX','fit',/nocur)
 readcol,tabfile,xtab,agc,aloc,form='(f,f,f)',/silent

; message,'CCM (1989) + CT (2006)'+' E(B-V) ='+ string( ebv, f='(f6.3)'), /INF
;
; Interpolate to output wavelengths
;
 if keyword_set(gc) then begin
 	message,'Extinction curve for Galactic center CT (2006)',/INF
	linterp,xtab,agc,wav,alam 
     end else linterp,xtab,aloc,wav,alam
	
 funred = flx*10^(0.4*ebv*alam)		;Derive unreddened flux

return     
end
