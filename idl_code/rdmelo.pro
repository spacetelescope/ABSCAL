pro rdmelo,file,wave,flux,eps,gross,back,net,h,label
;+
; Read IUE NDADS MELO file
;
; CALLING SEQUENCE:
;	rdmelo,file,wave,flux,eps,gross,back,net,h,label
;
; INPUTS:
;	file - file name
;
; OUTPUTS:
;	wave - wavelength vector
;	flux - flux array
;	eps - epsilon array
;	gross - gross spectrum
;	back - background spectrum
;	net - not so gross spectrum
;	h - record 0 vector
;	label - Ascii label
;-
; July 1, 1992 changed to handle 1000 VILSPA word record files
;-----------------------------------------------------------------------------
	if n_params(0) eq 0 then begin
		print,'CALLING SEQUENCE: rdmelo,filename,WAVE,FLUX,EPS'+ $
					',GROSS,BACK,NET,H,LABEL'
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
	totbytes = (nlab+1)*360 + nb * nrec
	if totbytes gt f.size then begin
		print,'Changing from 1024 to 1000 word records'
		nb = 2000
	endif
	buffer = intarr(nb/2)
	ns = (nb-4)/2			;number of samples
;
; read data
;
	readu,unit,buffer & byteorder,buffer,/ntohs	;record 0
	h = buffer(2:ns+1)
	readu,unit,buffer & byteorder,buffer,/ntohs	;scaled wavelengths
	wave = buffer(2:ns+1)		
	readu,unit,buffer & byteorder,buffer,/ntohs	;epsilons
	eps = buffer(2:ns+1)
	readu,unit,buffer & byteorder,buffer,/ntohs	;scaled gross
	gross = buffer(2:ns+1)
	readu,unit,buffer & byteorder,buffer,/ntohs	;scaled back
	back = buffer(2:ns+1)
	readu,unit,buffer & byteorder,buffer,/ntohs	;scaled net
	net = buffer(2:ns+1)
	readu,unit,buffer & byteorder,buffer,/ntohs	;scaled abnet
	flux = buffer(2:ns+1)
;
; scale data and remove fill
;
	ns = h(300)
	wave = wave(0:ns-1)*0.2
	gross = gross(0:ns-1,*) * (h(20)/2.0^h(21))
	back = back(0:ns-1,*) * (h(24)/2.0^h(25))
	net = net(0:ns-1,*) * (h(28)/2.0^h(29))
	flux = flux(0:ns-1,*) * (h(32)/2.0^h(33))
	eps  = eps(0:ns-1,*)
free_lun,unit
return
end
