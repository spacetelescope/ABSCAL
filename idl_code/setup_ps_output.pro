; From Karl 2013Nov8
pro setup_ps_output,output_filename,ps=ps,eps=eps,bw=bw, $
                    square=square,aspect_ratio=aspect_ratio

if (keyword_set(ps) or keyword_set(eps)) then begin
    set_plot,'ps'
    if (keyword_set(bw)) then begin
        output_filename = output_filename + '_bw'
    endif
    if (keyword_set(ps)) then begin
        device,filename=output_filename+'.ps'
        device,/landscape
        device,encapsulated=0
    endif else begin
        device,filename=output_filename+'.eps'
	device,/portrait,/bold		;Landscape is upside down on Linux!!!rcb
        device,encapsulated=1
	print,'idl.eps is portrait & encapsulated'
    endelse
; in my ps.pro-rcb    device,/color
    if (keyword_set(square)) then begin
        device,xsize=10,ysize=10,/inches
    endif
    if (keyword_set(aspect_ratio)) then begin
        print,aspect_ratio
        device,xsize=10,ysize=10/aspect_ratio,/inches
    endif
    device,bits_per_pixel=8
endif

end
