PRO VT100,A
;+
; NAME:
;  VT100
; PURPOSE:
; Erases screen and puts retrographics or selanar terminal
; into the VT100 mode.
;-
ERASE 
ESC = STRING(27B)
;               CASE TERM OF
CASE !d.name of
'SUN' : CLEAR
'TEK' : PRINT,ESC,'O',ESC,"'",ESC,'2'
'SELA': PRINT,ESC,'O',ESC,"'",ESC,'2'
'HIRE': PRINT,ESC,'2'
'MICR': print,esc,'O',esc,'2'	;Microterm
'GO25': print,esc,'2'		;Graphon 250
'GRAP': print,esc,'2'		;Graphon
'SG22': print,esc,'2',esc,'[4i' ;Selanar SG-220
; Assume its a Retrographics
ELSE:	PRINT,STRING([24B,27B])+'[2J' ; TO VT100 MODE AND ERASE.
ENDCASE
RETURN
END
