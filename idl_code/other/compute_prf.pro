pro compute_prf,filelist,nsum=nsum,ps=ps,noplot=noplot
;
; routine to compute the pixel response function
;
; INPUTS:
;	filelist - list of *prf*.idl files from nic_coadd to process
;
;
; OPTIONAL KEYWORD INPUTS:
;	/ps - write results in a postscript file
;	nsum - number of data points per bin when plotting the results
;	/noplot - do not produce plots
;-
;----------------------------------------------------------------------------
;
	if keyword_set(ps) then begin
		dev = !d.name
	 	set_plot,'ps'
		device,file='compute_prf.ps'
	end
	  	
	filters = ['G096','G141','G206']
;
; loop on filters
;
	for ifilt = 0,2 do begin
	    pos = strpos(filelist,strlowcase(filters(ifilt)))
	    good = where(pos gt 0,ngood)
	    if ngood eq 0 then goto,next_ifilt
	    files = filelist(good)
   	    for i=0,n_elements(files)-1 do begin
print,files(i)
		a = mrdfits(files(i),1)
		flux = a.flux
		prf = a.prf
		y = a.y
		m_interp = a.m_interp
		
		s = size(prf) & ns = s(1) & nspec = s(2)
	
		threshold = median(flux)
		flux = rebin(flux,ns,nspec)
	
		frac = y-round(y)
		good = where((m_interp gt 0) and (flux gt threshold) and $
			     (prf gt 0.5) and (prf lt 1.5))
	
		if i eq 0 then begin
			P = prf(good)
			F = frac(good)
		   end else begin
			P = [P,prf(good)]
			F = [F,frac(good)]
		end	   
	    end
    
	    sub = sort(F)
	    F = F(sub)
	    P = P(sub)

	    
	    coef = poly_fit(double(F),double(P),4,fit)
	    xx = findgen(1000)/1000.0 - 0.5
	    yy = coef(0) + coef(1)*xx + coef(2)*xx^2 + coef(3)*xx^3 + $
	    	coef(4)*xx^4
	    if not keyword_set(noplot) then begin
	    	plot,F,P,title=filters(ifilt),ytitle='PRF correction', $
			xtitle='Y pixel position',psym=4,symsize=0.3, $
			yrange=[0.8,1.2],nsum=nsum
	    	oplot,xx,yy,thick=2
		if not keyword_set(ps) then wait,2
	    end
	    openw,unit,'prfcoef_'+strlowcase(filters(ifilt))+'.txt',/get_lun
	    printf,unit,';'+!stime
	    printf,unit,'RMS of Fit = '+strtrim(stdev(P-fit),2)
	    printf,unit,files
	    printf,unit,coef
	    free_lun,unit
next_ifilt:
	end
	if keyword_set(ps) then begin
		device,/close
		set_plot,dev
	end
end
