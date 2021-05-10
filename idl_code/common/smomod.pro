FUNCTION smomod,WAV,FLX,dlam
;+
;
; 98jun15 - Smooth a spectrum (eg model) w/ non-uniform sampling interval
;
;calling sequence:
;		FUNCTION smomod(WAV,FLX,dlam)
; input: wav-wl array
;	 flx-flux array
;	 dlam - smoothing range, scalar of delta lambda
; 08sep26 - add a second smoothing to make a triangle LSF
;-
wmin=wav-dlam/2.  &  wmax=wav+dlam/2.
good=where(wmin gt wav(0) and wmax lt wav(n_elements(wav)-1))
smoothd=flx
smoothd(good)=tin(wav,flx,wmin(good),wmax(good))
smoothd(good)=tin(wav,smoothd,wmin(good),wmax(good))		; 08sep26
RETURN,smoothd
END
