function niclincor,wave,net
; 05nov22 - repackage the guts of the NICMOS linearity correction
;
; Purpose: To provide the non-linearity correction to the NET vector
;
; Calling Seq: niclincor(wave,net)
;
; Input:
;	wave - wavelengths
;	net - count/sec vector
; Output:
;	niclincor - returned vector of corrections at the wave wavelengths.
;-
; 04dec27 - using only 2 WD models for faint stars
; 05dec28 - update (from linwd.pro-obsolete now)
; 06apr28 - ............ lampbval.pro & flxlinbin
; 06aug21 - ............ lampbval.pro & flxlinbin - bkg all-in-one spectrum
; 13sep19 - ............ lampbval.pro & flxlinbin
;-

; linterp extends first (or last) value for WLs out of range.
linterp,								     $
;	[.825,.875,.925,.975,1.,1.05, 1.1,1.15, 1.2, 1.3, 1.4, 1.5,  $
;					1.6,1.65,1.7,  1.8,  1.9,2],	     $
;		       [0.067,.052,.047,.040,	$	; from flxlinbin.pro
;			.044,.054,.052,.054,.048,.032,.012,   0,   0,   0,   $
;			-.012,-.028,-.015,0],	$	; from linwd.pro
;	[.825,.875,.925,.975,  1.,1.05, 1.1,1.15, 1.2, 1.3, 1.4, 1.5, 1.6],  $
;	[.068,.056,.051,.048,.047,.053,.049,.056,.049,.042,.024,.011,   0],  $
;06jan15 - from LAMPBVAL:
;	[.825,.875,.925,.975, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9], $
;	[.068,.056,.051,.048,.048,.048,.038,.026,.021,.016,.0105,.005,   0], $
; 06APR19,28 - from LAMPBVAL plot w/ hand drawn fit (& flxlinbin):
;	[.068,.056,.052,.048,.046,.045,.038,.020,.016,.012,.008,.004,   0], $ 
; 06aug16,21:
;	[.069,.057,.052,.050,.049,.048,.041,.023,.013,.008,.004,    0,   0], $
; 07jun5
;	[.064,.055,.049,.052,.049,.0425,.036,.024,.014,.008,.002,   0,  0,  0],$
; 08nov7
;     [.062,.054,.047,.050,.049,.0435,.0365,.027,.017,.010,.0025,   0,  0,  0],$
; 08nov26
;     [.062,.054,.047,.050,.047,.0435,.0365,.027,.0155,.008,.0015,  0,  0],$
;09jun8
;     [.063,.0565,.047,.050,.047,.0413,.035,.0228,.0168,.0106,.0038,  0,  0], $
;09sep17
;     [.064,.058,.048,.052,.047,.0413,.035,.0228,.0168,.0106,.0038,  0,  0], $
;10JAN19
;     [.065,.058,.049,.052,.047,.0413,.035,.0228,.0168,.0106,.0038,  0,  0], $
;13sep19 - New Rauch models
;      [.825,.875,.925,.975, 1.1, 1.2,  1.3, 1.4,  1.5, 1.6,  1.7, 1.76,1.9], $
;      [.066,.058,.049,.053,.047,.0413,.035,.0228,.0168,.0106,.0038,  0,  0], $
;14Feb21 - New abs level from MSX Sirius paper for F(5556)=3.44e-9 Vega.
      [.825,.875,.925,.975, 1.1, 1.2,  1.3, 1.4,  1.5, 1.6,  1.7, 1.76,1.9], $
      [.066,.059,.050,.053,.047,.0413,.035,.0228,.0168,.0106,.0038,  0,  0], $
			wave, bonly
			
; lincor is really the desired change in the NET as a fn of net!
	niclincor= 1-2*bonly+bonly*alog10(net>1e-8)	; 05aug4 add >1e-8
print,'MinMax niclincor=',minmax(niclincor)
return,niclincor
end
