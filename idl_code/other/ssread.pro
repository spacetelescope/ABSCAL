PRO SSREAD,NAME,WAVE,FLUX,ERROR,hdr,fwhm,syserr,eps,totex,		$
			okefx=okefx,epsfx=epsfx,magfx=magfx
;+
;			SSREAD
;
; ROUTINE TO READ STANDARD STAR old sdas .tab DATA TABLE
;  ********** SSREADFITS to read new (99jul19) .fits binary table std stars ****
;
; Inputs:
;	Name - file name
;	Keywords - okefx to call okefix subroutine
;		 - epsfx to convert eps flags to unity & error from frac to flux
;		 - magfx to change flux levels by magfx value
; Outputs:
;	wave - wavelengths
;	flux - flux
;	error - statistical error (Fractional error converted to flux err) 
;	hdr  - header
;	fwhm - full width @ half max (Ang)
;	syserr - systematic error (3% of iue flux)
;	eps - data qual (if IUE)
;	totex - total exp time (if IUE)
;	
;
; HISTORY:
; D. Lindler April 21, 1988
; added mtitle and statistical errors  Nov. 20, 1990  (DJL/RCB)
; 99jul13 - add header to output - rcb
; 99jul19 - add fwhm,syserr,eps,totex to output
; 00nov14 - add keywords for stis std stars (see make_stis_calspec)-nicola help.
;-
	tab_read,name,tcb,tab,hdr
; table_help,tcb,hdr      ; to see all the content of .tab files.
	mode=sxpar(hdr,'OBSMODE')
	wn=tab_val(tcb,tab,'WAVELENGTH')
	fn=tab_val(tcb,tab,'FLUX')
	en=tab_val(tcb,tab,'STATERROR')
	syserr=tab_val(tcb,tab,'SYSERROR')
	fwhm=tab_val(tcb,tab,'FWHM')
	null=1.6e38
	eps=fwhm*0+null			; initialize to nulls
	totex=fwhm*0+null		; initialize to nulls

	if strtrim(sxpar(hdr,'obsmode'),2) eq 'IUE' then begin
		eps=tab_val(tcb,tab,'DATAQUAL')
		totex=tab_val(tcb,tab,'TOTEXP')
		endif
	!mtitle=strtrim(sxpar(hdr,'targetid'),2)
	tab_col,tcb,'FLUX',offset,width,dtype,cname,units,format
	good=where((wn ne null) and (fn ne null))
	wave=wn(good)
	flux=fn(good)
	error = en(good)
	fwhm=fwhm(good)
	syserr=syserr(good)
	eps=eps(good)
	totex=totex(good)
	case strtrim(units,2) of
		'FLAM' : begin
				flag = (flux gt 0.0) and (error ne null)
				good = where(flag,ngood)
				if ngood gt 0 then begin
				    error(good) = abs(error(good)/flux(good))
				    bad = where(flag eq 0,nbad)
; 01jan25 reason for 99 is not clear AND is in conflict w/ last line of code?!  
;				  if nbad gt 0 then error(bad) = 99
				  if nbad gt 0 then error(bad) = null ; 01jan25
				end
			 end
		'ABMAG' : begin
				fnu=(flux+48.6)/(-2.5)
				fnu=10^fnu
				flux=fnu*3.0e18/(wave*wave)
			        ERROR=10.^((Error<5.)/2.5)-1.
			end
		'PHOTLAM' : begin
				flux=flux*6.625e-27*3.0e18/wave
				error=error*6.625e-27*3.0e18/wave
				flag = (flux gt 0.0) and (error ne null)
				good = where(flag)
				error(good) = abs(error(good)/flux(good))
				bad = where(flag eq 0,nbad)
; 01jan25 reason for 99 is not clear?  if nbad gt 0 then error(bad) = 99
				  if nbad gt 0 then error(bad) = null ; 01jan25
			    end
		'STMAG' : begin
				x=(flux+21.1)/(-2.5)
				flux=10^x
			        ERROR=10.^((ERROR<5.)/2.5)-1.
			end
		else: begin
			print,name,units
			print,'Input flux units '+units+' not supported'+ $
				' No unit change done'
		      end
	endcase
; 00nov14 - optional fixes:
if keyword_set(epsfx) then eps=eps*0+1
if keyword_set(okefx) then okefix,hdr,WAVE,ERROR,eps
if keyword_set(magfx) then begin
	print,'1996 Fluxes increased by ',magfx,' mag'
	flux=flux*10^(magfx/2.5)	; positive magfx makes flux increase
	endif
indx=where(error ne null,nind)
; convert to flux units for uncert.
if nind gt 0 then error(indx)=error(indx)*flux(indx)
RETURN
END
