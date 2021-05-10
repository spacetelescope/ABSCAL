pro respwr,res,wl,flx,wfrst,wres,fres,wbeg,wend
;+
; PURPOSE: degrade a spectrum to specified resolving power
; CALLING SEQUENCE: respwr,res,wl,flx,wfrst,wres,fres,wbeg,wend
; INPUT:
;	res-resolution required for output
;	wl -wavelength array
;	flx-flux array
;	wfrst-first WL of output wbeg array
; OUTPUT:
;	wres-center WLs of R=res degraded spectrum
;	fres-degraded flux array at wres points
;	wbeg-beginning wavelengths of output bins
;	wend-ending wavelengths of output bins
; HISTORY:
; 06dec28 - RCB for modcf and makastar.pro
; 08mar18 - add option to keep original WLs, if wfrst is <0 
;
; COMPARE: rsmooth.pro to make a 2x oversampled grid for specified R and
;	does tin twice for triangle profile. 
;-
if wfrst ge 0 then begin
	wend=wfrst+wfrst/res
	mx=max(wl)
	for i=1L,99999L do begin
		nxtend=wend(i-1)+wend(i-1)/res
		if nxtend gt mx then goto,done
		wend=[wend,nxtend]
		endfor
	done:
	npts=n_elements(wend)
	wbeg=[wfrst,wend(0:npts-2)]
	wres=(wbeg+wend)/2
    end else begin
; 08mar18 - option to keep orig WLs, eg hauschildt w/ fine sampling:
	wbeg=(wl-0.5*wl/res)>wl(0)
	wend=(wl+0.5*wl/res)<max(wl)
	wres=wl
	endelse
fres=tin(wl,flx,wbeg,wend)
	
return
end
