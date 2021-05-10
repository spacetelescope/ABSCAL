pro rdlxl,file,wave,flux,eps,h,label
;+
;
; Read IUE NDADS Line by line file
;
; CALLING SEQUENCE:
;	rdlxl,file,wave,flux,eps,h,label
;
; INPUTS:
;	file - file name
;
; OUTPUTS:
;	wave - wavelength vector
;	flux - flux array
;	eps - epsilon array
;	h - record 0 vector
;	label - ascii label
;
; History;
;	Oct. 21, 1993 Modified to handle 2000 byte records (DJL)	
;-
;-----------------------------------------------------------------------------
	if n_params(0) eq 0 then begin
		print,'CALLING SEQUENCE: rdlxl,filename,WAVE,FLUX,EPS,H,LABEL'
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
	nl = (nrec-1)/3
	flux = fltarr(ns,nl)		;subtract 1 for record 0
	eps = fltarr(ns,nl)
	buffer = intarr(nb/2)		;input data buffer
;
; read record 0
;
	readu,unit,buffer & byteorder,buffer,/ntohs
	h = buffer(2:ns+1)
;
; loop on data lines
;
	for i=0,nl-1 do begin
	    for j=0,2 do begin		;read each data type
		readu,unit,buffer
		byteorder,buffer,/ntohs
		case j of
		    0: if i eq 0 then wave = buffer(2:ns+1)
		    1: eps(0,i) = buffer(2:ns+1)
		    2: flux(0,i) = buffer(2:ns+1)
		endcase
	    end
	end
;
; scale data and extract filled values
;
	ns = h(300)
	wave = wave(0:ns-1)*0.2
	flux = flux(0:ns-1,*) * (h(20)/2.0^h(21))
	eps  = eps(0:ns-1,*)
free_lun,unit
return
end
