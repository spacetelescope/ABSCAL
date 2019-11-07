pro veloc,w0,wl,vel
;+
;
; 91feb8-convert delta wl-w0 to velocity in km/sec
; calling seq: veloc,w0,wl,vel
; input: w0-scaler line center wl
;	 wl-wavelength vector
; output: vel-velocity vector
 vel=(wl-w0)*3.e5/w0
;-
end
