PRO CDEL,IPLANE
;+
; NAME:
;	CDEL
; PURPOSE:
;	To delete a window and update the common blocks.
;
; CALLING SEQUENCE:
;	CDEL, IPLANE
;
; INPUTS:
;	IPLANE - Image window index.
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	The variable CHAN in the common block TV is set to 0 if it is
;	equal to IPLANE.
;
; PROCEDURE:
;	The given window is deleted.
;
; REVISION HISTORY:
;	Written by Michael R. Greason, May 1990.
;	OPND variable in common block TV replaced with WINDOW_STATE statement,
;			K.Rhode, STX, 7/90.
;	WINDOW_STATE procedure and the IMAGES common block added.  
;						    MRG, STX, August 1990.
;-
On_error,2
;
COMMON TV, chan, zoom, xroam, yroam
COMMON IMAGES, x00, y00, xsize, ysize
;
;			Check for index validity.
;
IF (n_params(0) LT 1) THEN BEGIN
	print, "Syntax:  CDEL, Iplane"
	return
ENDIF
if !D.NAME EQ 'PS' then begin
	message,/INF,'Output device set to X windows'
	set_plot,'x'
endif

if ((!D.FLAGS and 256) NE 256) THEN $
        message,"Current device "+!D.NAME + " does not support windows"

if N_elements(iplane) NE 1 then $
        message,'ERROR - Image plane number (first parameter) must be a scalar"
;
;			Get the window status.
;
device,window_state=opnd
nmax = N_elements(opnd)
;
IF (iplane LT 0) OR (iplane GE nmax) THEN $
	message, "Window index must be between 0 and " + strtrim(nmax,2)
;
;
;			Close the window, if open.
;
IF (iplane EQ chan) THEN chan = 0 ;Update common block channel var.
IF (opnd(iplane) NE 0) THEN BEGIN ;Set the active window.
	wdelete, iplane
	x00(iplane) = 0
	y00(iplane) = 0
	xsize(iplane) = 0
	ysize(iplane) = 0
ENDIF
;
RETURN
END
