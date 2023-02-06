pro pset
;+
;
; PSET FOR RESETTING ALL KNOWN PLOT PARAMS BACK TO DEFAULTS-LINDLER AND BOHLIN
; 
; HISTORY
; 93MAY29-ADD !P.MULT=0
; 93JUL17-MAKE COMPATIBLE W/ STARTUP.PRO
; 98oct5 - comment out the title lines, so that titles remain after a pse
; 2022dec = mod plot char & border thickness from 0 to 2
;-
	!P.MULTI=0
	!type = 4
	!x.thick = 4			; axis thickness fails???
	!y.thick = 4
	!p.thick = 1
	!p.charthick = 4
	!psym = 0
	!linetype = 0
	!noeras = 0
;	!mtitle = ''
;	!xtitle = ''
;	!ytitle = ''
	!X.STYLE=1	; TO USE X AND Y RANGES SPECIFIED EXACTLY
	!y.style=1
	!p.noclip=0	; to keep plot in box..use =1 to go out of box
; 93may20-comment out ff line
	!P.FONT=0	;91JAN3-USE DEVICE FONT RATHER THAN IDL VECTOR FONT(-1)
;	!p.font=-1	;93JUL17-BACK TO HARDWARE FONTS--MUCH NICER
	set_viewport
	set_xy
; 06mar29 - ff makes color plots fail!!
;???	if !d.name eq 'PS' then device,/landscape,color=0,bits=8
return
end
