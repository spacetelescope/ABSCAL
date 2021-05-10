function newflxcor,cam,wav,flx
; 2017Dec28 - to correct my oldsips fluxes to Calspec scale per oldvsnew.pro
;
; INPUT: cam - 1-lwp, 2-lwr, 3-swp
;	 wav - wavelength vector
;	 flx - old flux vector
; RESULT: corrected flux vector
;
; Must be used only in a top level dir, as long as I have a linux box.
;-

common iuecor,wlswp,corswp,wllwp,corlwp,wllwr,corlwr
if n_elements(wlswp) eq 0 then begin		; load common
	readcol,'../iuegalex/flxcor-use.newsipsswp',wlswp,corswp
	readcol,'../iuegalex/flxcor-use.newsipslwp',wllwp,corlwp
	readcol,'../iuegalex/flxcor-use.newsipslwr',wllwr,corlwr
	endif
	
if cam eq 3 then linterp,wlswp,corswp,wav,intcor   ; get interpolated correction
if cam eq 2 then linterp,wllwr,corlwr,wav,intcor   ; get interpolated correction
if cam eq 1 then linterp,wllwp,corlwp,wav,intcor   ; get interpolated correction

return,flx*intcor				; multiplicative corr.

end
