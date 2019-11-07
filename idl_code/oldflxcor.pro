function oldflxcor,wav,flx
; 2017Dec28 - to correct my oldsips fluxes to Calspec scale per oldvsnew.pro
;
; INPUT: wav - wavelength vector
;	 flx - old flux vector
; RESULT: corrected flux vector
;
; Must be used only in a top level dir, as long as I have a linux box.
;-

if wav(0) lt 1300 then readcol,'../iuegalex/flxcor-use.oldsipsswp',wcor,corr  $
	else readcol,'../iuegalex/flxcor-use.oldsipslw',wcor,corr 

linterp,wcor,corr,wav,intcor			; get interpolated correction

return,flx*intcor				; multiplicative corr.

end
