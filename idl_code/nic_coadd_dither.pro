pro nic_coadd_dither,lst,filter
;+
;			nic_coadd_dither
;
; Routine to coadd observations at the same dither position
;
; CALLING SEQUENCE:
;	nic_coadd_dither,list,filter
;
; INPUTS/OUTPUTS:
;	list - list of input observations to process
;	filter - list of filter names
; HISTORY
;	2016aug22 - list --> lst
;
;-
;
; find positions for all observations
;
	nlist = n_elements(lst)
	crval1 = dblarr(nlist)
	crval2 = dblarr(nlist)
	for i=0,n_elements(lst)-1 do begin
		fits_read,lst(i),d,h,/header_only
		crval1(i) = long(sxpar(h,'crval1')*1e5)
		crval2(i) = long(sxpar(h,'crval2')*1e5)
	end
;
	list_out = strarr(nlist)
	filter_out = strarr(nlist)
	nout = 0L
	nobs = n_elements(lst)
;
; loop on observations
;
	iobs = 0
	while iobs lt nobs do begin
;
; just keep imaging mode observation
;
	    if strmid(filter[iobs],0,1) ne 'G' then begin
	    	filter_out[nout] = filter[iobs]
		list_out[nout] = lst[iobs]
		nout = nout + 1
		iobs = iobs + 1
		goto,nextobs
	    end
;
; find sequential observations for the same filter/dither position
;
	    crv1 = crval1[iobs]
	    crv2 = crval2[iobs]
	    filt = filter[iobs]
	    first = iobs		;first observation at the dither
	    last = iobs
	    for i = iobs+1,nobs-1 do begin
	    	if (filter[i] ne filt) or $
		   (abs(crval1[i]-crv1) gt 1) or $
		   (abs(crval2[i]-crv2) gt 1) then break
		last = i
	    end
	    print,'nic_coadd_dither Co-adding:',first,last
	    print,'   for filters ',filter[first:last]
	    print,crval1[first:last]
	    print,crval2[first:last]
	    print,' & obs=',lst[first:last]
;
; if single observation, just keep it
;
	    if first eq last then begin
	    	filter_out[nout] = filter[iobs]
		list_out[nout] = lst[iobs]
		nout = nout + 1
		iobs = iobs + 1
		goto,nextobs
	    end
;
; coadd the observations
;
	    fdecomp,lst[first],disk,dir,name
	    outfile = name+'_dither_tempfile'+'.fits'
	    list_out[nout] = outfile
	    filter_out[nout] = filter[first]
	    nout = nout+1
	    iobs = last+1
	    for i=first,last do begin
	    	fits_open,lst[i],fcb
		if i eq first then begin
			fits_read,fcb,d,h0,exten=0
			fits_read,fcb,image,h1,extname='SCI'
			fits_read,fcb,err,h2,extname='ERR'
			fits_read,fcb,dq,h3,extname='DQ'
			fits_read,fcb,samp,h4,extname='SAMP'
			fits_read,fcb,time,h5,extname='TIME'
			bunit = strtrim(sxpar(h1,'bunit'))
			exptime = sxpar(h1,'exptime')
			if bunit eq 'COUNTS/S' then begin
				image = image*exptime
				err = err*exptime
				end
		        var = err^2
		    end else begin
			fits_read,fcb,image1,h,extname='SCI'
			fits_read,fcb,err1,extname='ERR'
			fits_read,fcb,dq1,extname='DQ'
			fits_read,fcb,samp1,extname='SAMP'
			fits_read,fcb,time1,extname='TIME'
			exptime1 = sxpar(h,'exptime')
			bunit = strtrim(sxpar(h,'bunit'))
			if bunit eq 'COUNTS/S' then begin
				image1 = image1*exptime1
				err1 = err1*exptime1
				end
		        var = var + err1^2
			image = image + image1
			dq = dq > dq1
			samp = samp>samp1
; hmmm??? Neg values in time maybe compensate for zero read?
			time = time + time1
			exptime = exptime + exptime1
			expend = sxpar(h,'expend')
		end					; end: if i eq first
		fits_close,fcb
	    end						;endfor i=first,last 
	    n = last-first+1
	    if bunit eq 'COUNTS/S' then begin
	    	err = sqrt(var)/exptime
	    	image = image/exptime
	    end else err = sqrt(var)
	   
	    fits_open,outfile,fcb,/write
	    fits_write,fcb,0,h0
	    sxaddpar,h1,'exptime',exptime
	    sxaddpar,h1,'expend',expend
	    sxaddpar,h2,'exptime',exptime
	    sxaddpar,h2,'expend',expend
	    sxaddpar,h3,'exptime',exptime	; 2016aug22 - fix DJL 6 typos
	    sxaddpar,h3,'expend',expend
	    sxaddpar,h4,'exptime',exptime
	    sxaddpar,h4,'expend',expend
	    sxaddpar,h5,'exptime',exptime
	    sxaddpar,h5,'expend',expend		; all 6 lines above were h2
	    sxaddpar,h1,'NCOADD',n,'Number of observations averaged'
	    sxaddhist,['Observations coadded:',lst[first:last]],h1
	    fits_write,fcb,image,h1,extname='SCI'
	    fits_write,fcb,err,h2,extname='ERR'
	    fits_write,fcb,dq,h3,extname='DQ'
	    fits_write,fcb,samp,h4,extname='SAMP'
	    fits_write,fcb,time,h5,extname='TIME'
	    fits_close,fcb
nextobs:
	end					; end while
	lst = list_out[0:nout-1]
	filter = filter_out[0:nout-1]
end	    
	    
