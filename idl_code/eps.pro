pro pse
device,/close
set_plot,'x'

!p.thick=1
!x.thick=1
!y.thick=1

; Do: "lpstat -a"  to find the names of printers installed.
;spawn,'lpr -Phpc82 idl.ps'			; Banner + blank page
; for Muller: spawn,'lp -dhpc80 idl.ps' 	; No extra pp
print,'idl.eps on hpc80'
;spawn,'lpr -P hpc80_stsci_edu idl.eps'		; MAC
spawn,'lpr -P hpc80 idl.eps'		; Linux

spawn,'lpq -Phpc80'
;spawn,'lpq -P hpc80_stsci_edu'
return
end

pro eps,orient
; for linux pub plots
!p.charthick=3
!p.thick=3
!x.thick=5
!y.thick=5

; original:  set_plot,'ps'
setup_ps_output,'idl',/eps		; new 2013nov8 - from Karl for Linux
; 2013nov - Linux box makes plots upsidedown. Must use portrait
;	xoff,yoff have NO effect w/ Linux!!!
; 4mac: IF N_PARAMS() EQ 0 THEN device,/landscape ELSE 				$
;orig device,/portrait,xs=7.5,ys=9.0,/inches,xoff=.5,yoff=1.00,/bold
; testing		device,/portrait,xs=8.6,ys=10.,/inches,xoff=0,yoff=.5
;if N_PARAMS() ne 0 then print,'ps, PORTRAIT '
device,/helv,/color,bits=8
loadct,0
return
end
