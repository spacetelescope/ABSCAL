pro tk,bw
!p.charthick=1
!p.thick=3
!x.thick=3
!y.thick=3
!p.font=0

set_plot,'ps'
device,/portrait,xs=8.1,ys=8.1,/inches,xoff=.2,yoff=1.2,/bold,filename='idl.ps'
;color added 96jun20--see also use of psout,/color... bits=8 96oct16
; the set_plot,'ps' alone causes the bits=4 to be set!!!!!!!!!!!!!!!!
if n_params(0) eq 0 then begin
	device,/helv,/color,bits=8
	print,'Color processing w/ bits=8'
     end else begin
	device,bits=4
	print,'B&W processing w/ bits=4'
	endelse
loadct,0		;97jan17 - x-window displ screws up color table !!!

print,!d.n_colors,' colors available in Postscript'
if !d.n_colors ne 256 then begin
	print,'tk.pro STOP. !d.ncolors ne 256, but is:',!d.ncolors
	stop
	endif
end
