pro rdmehi,file,wave,flux,eps,gross,back,net,ns,h,label
;+
; Read IUE NDADS MELO file
;
; CALLING SEQUENCE:
;	rdmehi,file,wave,flux,eps,gross,back,net,ns,h,label
;
; INPUTS:
;	file - file name
;
; OUTPUTS: (wave thru net are 2-diminsional: (# of pts, # of echelle orders)
;	wave - wavelength vector
;	flux - ripple corrected net
;	eps - epsilon array
;	gross - gross spectrum
;	back - background
;	net - net spectrum
;	ns - number of data points in each order
;	label - Ascii label
;
; HISTORY
;	Oct. 21, 1993  Modified to handle 2000 byte records
;-
;-----------------------------------------------------------------------------
	if n_params(0) eq 0 then begin
		print,'CALLING SEQUENCE: rdmehi,filename,WAVE,FLUX,EPS,'+ $
					'GROSS,BACK,NET,NS,H,LABEL'
		retall
	endif
;
; open file
;
	openr,unit,file,/get_lun
;
;
; Read label
;
	label = strarr(300)
	nlines = 0
	nlab = 0
	lab = bytarr(72,5)
nextlab:
	readu,unit,lab
;
; get data size from first label
;
	if nlab eq 0 then begin		; first label?
		st = strebcasc(string(lab(*,0))) ;first line
		nb = fix(strmid(st,36,4))	;number of bytes in data	
		nrec = fix(strmid(st,32,4))	;number of records in data
	endif
;
; check to see if it is the last label
;
	for i=0,4 do begin
		label(nlines) = strebcasc(string(lab(*,i)))
		nlines = nlines+1
		if strebcasc(string(lab(71,i))) eq 'L' then goto,get_data
	end
	nlab = nlab+1
	goto,nextlab
;
; set up output data arrays
;
get_data:
	label = label(0:nlines-1)
;
; Check for 1000 word records not properly specified in the label record 0
;
        f = fstat(unit)
        totbytes = (nlab+1)*360L + long(nb) * nrec
        if totbytes gt f.size then begin
                print,'Changing from 1024 to 1000 word records'
                nb = 2000
        endif
	ns = (nb-4)/2			;number of samples
	buffer = intarr(nb/2)
;
; read record 0
;
	readu,unit,buffer & byteorder,buffer,/ntohs	;record 0
	h = buffer(2:ns+1)
	wmin = h(100:199)
	m = h(200:299)
	ns = h(300:399)
	wscale = 500.0d0
; 93MAY28-DJL HARDCODE PATCH FOR AN LCB PROBLEM CASE. WAS: wscale = double(h(56))
	norders = total(m gt 0)
	ns = ns(0:norders-1)
;
; set up output arrays
;
	maxns = max(ns)
	wave = dblarr(maxns,norders)
	eps = intarr(maxns,norders)
	flux = fltarr(maxns,norders)
	gross = flux
	back = flux
	net = flux
; 
; read each order
; 
	for i=0,norders-1 do begin
	    readu,unit,buffer & byteorder,buffer,/ntohs	;scaled wavelengths
	    wave(0,i) = buffer(2:ns(i)+1)/wscale+wmin(i)
	    readu,unit,buffer & byteorder,buffer,/ntohs	;epsilons
	    eps(0,i) = buffer(2:ns(i)+1)
	    readu,unit,buffer & byteorder,buffer,/ntohs	;scaled gross
	    gross(0,i) = buffer(2:ns(i)+1)
	    readu,unit,buffer & byteorder,buffer,/ntohs	;scaled back
	    back(0,i) = buffer(2:ns(i)+1)
	    readu,unit,buffer & byteorder,buffer,/ntohs	;scaled net
	    net(0,i) = buffer(2:ns(i)+1)
	    readu,unit,buffer & byteorder,buffer,/ntohs	;scaled flux
	    flux(0,i) = buffer(2:ns(i)+1)
	end
;
; scale data
;
	gross = gross * (h(20)/2.0^h(21))
	back = back * (h(24)/2.0^h(25))
	net = net * (h(28)/2.0^h(29))
	flux = flux * (h(32)/2.0^h(33))
free_lun,unit
return
end
