pro step2_combine,id1,id2,wave,flux,eps,err, $
	mult_noise=mult_noise,nsig = nsig, scat=scat, net=net, norm=norm, $
	slope=slope
;
; Combine two observations that were offset with a postarg in the y
; direction
;
; INPUTS:
;	id1, id2 - entry numbers for the two observations
; KEYWORD INPUTS:
;	mult_noise - multi_plicative noise factor (default = 0.01)
;	nsig - number of sigma differrence before rejection (default = 3.0)
;	scat - scattered light in counts/sec
;	/net - net flux
; OUTPUTS: wave,flux,eps,err
;
;--------------------------------------------------------------------

	if n_elements(mult_noise) eq 0 then mult_noise = 0.01
	if n_elements(nsig) eq 0 then nsig = 3.0
	if n_elements(net) eq 0 then net = 0
	a = mrdfits('spec_'+strtrim(id1,2)+'.fits',1,h,/silent)
	b = mrdfits('spec_'+strtrim(id2,2)+'.fits',1,h,/silent)
	wave = a.wavelength
;
; Convert to air wavelengths
;
	vactoair,wave

	if net then begin
		f1 = a.net
		f2 = b.net
  	    end else begin
		f1 = a.flux
		f2 = b.flux
	end
	
	eps1 = a.epsf
	eps2 = b.epsf
	err1 = a.errf
	err2 = a.errf
;
; scattered light correction
;
	if n_elements(scat) gt 0 then begin
		print,scat,slope
		sens = a.net/a.flux
		sc = scat*(1+findgen(1024)*slope)
		f1 = (a.net-sc)/sens
		sens = b.net/b.flux
		f2 = (b.net-sc)/sens
	end
;
; normalize dimmer spectrum to the level of the brighter one
;
	f1_smooth = median(f1,11)
	f2_smooth = median(f2,11)
	norm = total(f1_smooth(100:900))/total(f2_smooth(100:900))
	print,norm
	if norm gt 1 then begin
		f2 = f2*norm
		err2 = err2*norm
	   end else begin
	   	f1 = f1/norm
		err1 = err1/norm
	end
;
; compute maximum allowed difference
;
	var = err1^2+err2^2
	maxdiff = (sqrt(var)+(f2<f1)*mult_noise)*nsig
;
; coadd spectra 
;
	flux = (f1+f2)/2.0
	err = sqrt(var)/2.0
	eps = eps1>eps2
;
; find bad data points
;	
	bad = where(abs(f1-f2) gt maxdiff,nbad)
	print,'step2_combine',id1,id1,':',nbad,' bad data points'
	if nbad gt 0 then begin
;
; use value closest to a smoothed version of the flux
;
		sflux = median(flux,3)
		for i=0,nbad-1 do begin
			k = bad(i)
			if abs(f1(k)-sflux(k)) gt abs(f2(k)-sflux(k)) then begin
				flux(k) = f2(k)
				eps(k) = eps2(k)
				err(k) = err2(k)
			   end else begin
			   	flux(k) = f1(k)
				eps(k) = eps1(k)
				err(k) = err1(k)
			end
		end
	end
end
