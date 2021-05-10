FUNCTION TIN,WAV,FLX,WMIN,WMAX
;+
;
;92JUN11 BOHLIN TRAPEZOIDAL "INTEGRAL" [REALLY AVERAGE!]
;
;calling sequence:
;		FUNCTION TIN(WAV,FLX,WMIN,WMAX)
; input: wav-wl array
;	 flx-flux array
;	 wmin,wmax- wl range to do integral. Can be vectors.
; 96jul17 - fix the problem of array of one element, if wmin,wmax are scalers.
;-
TRAPINT=INTEGRAL(WAV,FLX,WMIN,WMAX)/(WMAX-WMIN)
if n_elements(trapint) eq 1 then return,trapint(0) else RETURN,TRAPINT
END
