pro stisfix
; 98jun - djl + rcb mod to copy 5th readout to sep file
;Routine to copy first 4 readouts of five readout observation into a new file

fits_open,'/data/rcbsun3/7674/o49x01010_raw.orig',fcb_in
fits_open,'/data/rcbsun3/7674/o49x01010_raw.fits',fcb_out,/write

for i=1,4 do begin              ;process only first four readouts
        fits_read,fcb_in,data,h ;science data
	sxaddpar,h,'nextend',12		; 02mar17 - corr first header
	sxaddpar,h,'crsplit',4		;.................
        fits_write,fcb_out,data,h
        fits_read,fcb_in,err,h  ;errors
        fits_write,fcb_out,0,h,/no_data
        fits_read,fcb_in,eps,h  ;data quality
        fits_write,fcb_out,0,h,/no_data
	endfor
fits_close,fcb_out
return					; 02mar17 - r5 screws up stisdir
; 98jun4 - also write the 5th readout:
fits_open,'/data/rcbsun3/7674/o49x01010r5_raw.fits',fcb_out,/write

fits_read,fcb_in,data,h ;science data
fits_write,fcb_out,data,h
fits_read,fcb_in,err,h  ;errors
fits_write,fcb_out,0,h,/no_data
fits_read,fcb_in,eps,h  ;data quality
fits_write,fcb_out,0,h,/no_data

fits_close,fcb_out
fits_close,fcb_in
end
; probably, i would want to change the protection to the orig raw, to avoid del.
; the # readouts = Ncombine are ok, as is the exptime in extr spectrum !!!
