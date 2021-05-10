pro set_xy, xmin, xmax, ymin, ymax
;+
; NAME:		SET_XY
; PURPOSE:	Emulate the Version I, VMS/IDL SET_XY procedure.
;		Sets the default axis ranges. 
; CATEGORY:	Plotting.
; CALLING SEQUENCE:
;	SET_XY, Xmin, Xmax
;	SET_XY, Xmin, Xmax, Ymin, Ymax
; INPUTS:
;	Xmin, Xmax, Ymin, Ymax = default values for data axis ranges.
; OPTIONAL INPUT PARAMETERS:
;	Ymin and Ymax are optional.
; KEYWORD PARAMETERS:
;	None.
; OUTPUTS:
;	No explicit outputs.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	Sets the RANGE, CRANGE, and S fields of !X and !Y.
; RESTRICTIONS:
;	Should only be used to emulate VMS Version I of IDL.
;	This procedure does a number of things which should not be
;	done.
; PROCEDURE:
;	Straightforward.
; MODIFICATION HISTORY:
;	DMS, June, 1989.
;-
on_error,2              ;Return to caller if an error occurs
n = n_params()
if n eq 0 then begin
	!x.range = [0,0]
	!y.range = [0,0]
end

if n ge 2 then begin	;set X ?
	!x.range = [ xmin, xmax]
	if xmin ne xmax then begin
		!x.crange = !x.range
		if !x.window(0) eq !x.window(1) then begin ;Window already set?
			tmp = !x.margin*!d.x_ch_size / !d.x_size
			!x.window = [ tmp(0), 1.0 - tmp(1)]
			endif ;window set
			;Compute slope and intercept
		!x.s(1) = (!x.window(1) - !x.window(0)) / (xmax - xmin)
		!x.s(0) = !x.window(0) - !x.s(1) * xmin
	end
endif		;X present
	
if n ge 4 then begin	;Do Y
	!y.range = [ ymin, ymax]
	if ymin ne ymax then begin
		!y.crange = !y.range
		if !y.window(0) eq !y.window(1) then begin ;Window already set?
			tmp = !y.margin*!d.y_ch_size / !d.y_size
			!y.window = [ tmp(0), 1.0 - tmp(1)]
			endif ;window set
			;Compute slope and intercept
		!y.s(1) = (!y.window(1) - !y.window(0)) / (ymax - ymin)
		!y.s(0) = !y.window(0) - !y.s(1) * ymin
	endif
endif			;Y present
end
