; 2018oct4 - generating .eps files seems to work only single, NOT mult frames.
;-
pro pse
device,/close
set_plot,'x'

!p.thick=1
!x.thick=1
!y.thick=1

; Do: "lpstat -a"  to find the names of printers installed.
; for Muller: spawn,'lp -dhpc80 idl.ps' 	; No extra pp
print,'idl.ps on PWPRINT-PA635CAN'
;spawn,'lpr -P hpc80_stsci_edu idl.eps'		; MAC --- 2019dec NG on mac
spawn,'lpr -P PWPRINT-PA635CAN idl.ps'		; Linux --- 2019dec NG on mac

; NG spawn,'lpq -PPWPRINT-PA635CAN'		; 2019dec NG on mac
return
end

pro ps,orient
; 2018Aug29 - I need to implement a new keyword, if I want to print landscape.
!p.charthick=3
!p.thick=2				; 2019apr25 - mod from 7 to 2
!x.thick=5				; Axis thickness
!y.thick=5
;? 2019apr25 !p.charsize=2
!p.font=-1

set_plot,'ps'				; original
;setup_ps_output,'idl',/eps		; new 2013nov8 - from Karl for Linux
; 2013nov - Linux box makes plots upsidedown. Must use portrait
;	xoff,yoff have NO effect w/ Linux!!!
IF N_PARAMS() EQ 0 THEN 						$
	device,/portrait,xs=8.1,ys=10.0,/inches,xoff=.3,yoff=0.5,/bold ELSE $
; 90deg off. Use for printing only:
;2018aug29-	device,/landscape,xs=10.1,ys=7.5,/inches,/bold
	device,/encapsulated,xs=10.1,ys=7.5,/inches,xoff=.3,yoff=0.5,/bold, $
		filename='idl.eps'
device,/helv,/color,bits=8
return
end
