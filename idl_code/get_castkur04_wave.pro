pro get_castkur04_wave, w, wmin, wmax
;+
; NAME:
;    GET_KUR_WAVE--Wayne's .pro to do the same thing. see GET_KUR_WAVE.obsolete
; PURPOSE:
;      Return the wavelength grid used in the Castelli-Kurucz 2004 ATLAS9 models
;
; CALLING SEQUENCE:
;	GET_CASTKUR04_WAVE, W, [ WMIN, WMAX ]
;
; OPTIONAL INPUTS:
;	WMIN, WMAX -  Scalars specifying the minimum and maximum wavelength 
;		values (in Angstroms) to return.   If not supplied, then the 
;		entire 1221 element wavelength grid between 90.9 A and 
;		1600000 A is returned.       
; OUTPUTS:
;	W -  Floating point vector wavelength grid, in Angstroms
; EXAMPLE:
;	Return the 190 Kurucz wavelength values between 1200 and 3200 A
;
;	IDL> get_castkur04_wave, w, 1200, 3200
; PROCEDURES USED:
;	 LIST_WITH_PATH()
; REVISION HISTORY:
;	Written        R. Bohlin 07Jan24
; See documentation in the file stisidl/zaux/ castkur04.wavelengths-doc and 
;	in pub/astars/doc.models & ~/models/misc-doc.models
; 09dec8 - Put 657. in castkur04.wavelengths, because the CK04 grid uses that
;	value on  both the Kurucz and Castelli web sites. (Was 656.125)
;-
;? On_error,2

 if N_params() LT 1 then begin
     print,'Syntax - get_castkur04_wave, w, [wmin, wmax]'
     print,'w - output giving wavelength grid used in the Cast-Kurucz04 models'
     return
 endif

file=find_with_def('castkur04.wavelengths','ZAUX','fit',/nocur)
openr, lun, file, /GET_LUN
w = fltarr(1221)
readf,lun,w,'(8f)'
free_lun, lun

w=w*10					; convert from nm to Angstroms
;airtovac,w			; add 09feb5. rm 09feb6-kz seems to be vacuum
 n1 = N_elements(w) -1 
 If N_elements( wmin) EQ 0 then return
 if N_elements( wmax) EQ 0 then wmax = w(n1) +1.

 good = where ( ( w GE wmin) and (w LE wmax), Ngood )
 if Ngood EQ 0 then $
     message,'ERROR - Invalid Wavelength range specified' else $
     w = w[good]
 return
 end
