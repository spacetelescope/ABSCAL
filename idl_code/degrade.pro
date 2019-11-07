pro degrade,wave,flux,deltaw,wfirst,wd,fd
;+
;
; procedure to bin data into bins of specified width
;
; INPUTS:
;	wave - wavelegnth vector
;	flux - flux vector
;	deltaw - bin size
;	wfirst - wavelength for center of first bin
; OUTPUTS:
;	wd - degraded wavelength vector
;	fd - degraded flux vector
;
;---------------------------------------------------------
hdel=deltaw/2.0
nbins=(max(wave)-wfirst-hdel)/deltaw
wd=findgen(nbins)*deltaw+wfirst
fd=integral(wave,flux,wd-hdel,wd+hdel)/deltaw
return
end
