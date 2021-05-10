PRO CHAN,IPLANE, PLOT=plot,FREE = free
;+
; NAME:
;	CHAN
; PURPOSE:
;	To display a different image window and update the common blocks.
;
; CALLING SEQUENCE:
;	CHAN, IPLANE, [ /PLOT, /FREE ]
;
; INPUTS:
;	IPLANE - Image window index.
;
; OUTPUTS:
;	None.
;
; OPTIONAL INPUT KEYWORDS:
;	PLOT - If this keyword is set, then a window of the default size is
;		is opened.   However, images displayed with CTV will not be 
;		displayed to this plane.
;	FREE - If present and non-zero, a free window is created.
;
; COMMON BLOCKS:
;	The variable CHAN in the common block TV is updated to the new image 
;	plane 
;
; PROCEDURE:
;	The given window is made active and shown.  If it has yet to be opened,
;	it is opened with the WINDOW command
;
; REVISION HISTORY:
;	Written, Wayne Landsman, July, 1986  Adapted for IVAS July 1989
;	Adapted for workstations.  Michael R. Greason, May 1990.
;	Removed hard-coding of number of windows   W. Landsman  January, 1991
;	Added /FREE keyword		J. D. Offenberg Nov, 1991
;	Removed the RETAIN = 2 default
;	Switch to X windows if not already there W. Landsman  Mar 1994
;-
;
 On_Error,2
 COMMON TV, chan, zoom, xroam, yroam

 if N_params() EQ 0 then begin 
	print, "Syntax:  CHAN, Iplane, [/FREE , /PLOT]"
	return
 endif
;			Check for index validity.

 if (!D.FLAGS AND 256) NE 256 then begin 
	set_plot,'X'
	message,/INF, 'Output device set to X windows'
 endif

; OPND is a 128-element array which is 1 wherever window is open

 device,window_state = opnd                    ;Get state of each window

 if keyword_set(FREE) then iplane = min( Where(opnd eq 0) )


; OPND is a 128-element array which is 1 wherever window is open

 N_window = n_elements(opnd)
 IF NOT(Keyword_set(FREE)) then $
    IF (iplane LT 0) OR (iplane GE N_window) THEN $
	message, "Index must be between 0 and " + strtrim(N_window-1,2)

 IF keyword_set(plot) then begin
             window, iplane, xsize=512,ysize=410, $ 
                 title = 'IDL '+strtrim(iplane,2) + ' Plot Window'
         return
 endif

 chan = iplane                         ;Update common block channel var.

 IF (opnd(iplane) NE 0) THEN BEGIN       ;Set the active window.
	wset, iplane
	wshow, iplane, 1
 ENDIF ELSE $                        ;Open the window.
         window, iplane, xsize=512, ysize=410, $ 
                 title = 'IDL '+strtrim(iplane,2) + ' Plot Window'

 RETURN
 END
