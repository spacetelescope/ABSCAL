PRO SSREADfits,NAME,hdr,WAVE,FLUX,error,syserr,eps,totex,fwhm
;+
;			SSREADfits
;
; ROUTINE TO READ CALSPEC STANDARD STAR .fits binary table std stars
;	use stisflx to read calstis STIS data
;
; Inputs:
;	Name - file name
; Outputs:
;	hdr  - header
;	wave - wavelengths
;	flux - flux
;	error - statistical error (or continuum for models)
;	syserr - systematic error (3% of iue flux)
;	eps - data qual (if IUE)
;	totex - total exp time (if IUE)
;	fwhm - full width @ half max (Ang)
;  IF a model w/ name containing _mod, then return, wave,flux,continuum	
;NOTICE: continuum in BOSZ models is too low below ~1350A for ~6250K star,z=-2.5
;
; HISTORY:
; 99jul19 - adapted from ssread.pro - rcb
; 04feb25 - change error from frac to usual flux units
; 2019jun4 - add continuum to output if _mod is in the name
;-
	z=mrdfits(name,0,hdr)		; read main header
	z=mrdfits(name,1,hd)		; read extension w/data
	wn=z.WAVELENGTH
	fn=z.FLUX
	namelow=strlowcase(name)
	if strpos(namelow,'_mod') ge 0 or strpos(namelow,'fake') ge 0	$
								then begin
		wave=wn  &  flux=fn
; 2019oct3 - Added contin. for 3 new prime WDs:
		ind=where(strpos(hd,'CONTINUUM') ge 0,ncont)
		if ncont gt 0 then error=z.continuum
		goto,done
		endif
	mode=sxpar(hdr,'OBSMODE')
	en=z.STATERROR
	syserr=z.SYSERROR
	fwhm=z.FWHM
	null=1.6e38
	eps=fwhm*0+null			; initialize to nulls
	totex=fwhm*0+null		; initialize to nulls
; 01jan26-need dataqual for sun_reference_stis_001 in make_stis_calspec
;old	if strtrim(sxpar(hdr,'obsmode'),2) eq 'IUE' then begin
	indx=where(strpos(hd,'DATAQUAL') gt 0,nind)
	if nind gt 0 then eps=z.DATAQUAL
	indx=where(strpos(hd,'TOTEXP') gt 0,nind)
	if nind gt 0 then totex=z.TOTEXP
; endif
	!mtitle=strtrim(sxpar(hdr,'targetid'),2)
	good=where((wn ne null) and (fn ne null))
	wave=wn(good)
	flux=fn(good)
	error = en(good)
	fwhm=fwhm(good)
	syserr=syserr(good)
	eps=eps(good)
	totex=totex(good)
	units=sxpar(hd,'TUNIT2')	; flux units
	case strtrim(units,2) of
		'FLAM' : begin
				flag = (flux gt 0.0) and (error ne null)
				good = where(flag,ngood)
				if ngood gt 0 then begin
; 04feb25			    error(good) = abs(error(good)/flux(good))
				    bad = where(flag eq 0,nbad)
; 04feb25 - why??: make this loop a no-op
; .....			    if nbad gt 0 then error(bad) = 99
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
; 04feb25				error(good) = abs(error(good)/flux(good))
; ......			bad = where(flag eq 0,nbad)
; ......			if nbad gt 0 then error(bad) = 99
			    end
		'STMAG' : begin
				x=(flux+21.1)/(-2.5)
				flux=10^x
			        ERROR=10.^((ERROR<5.)/2.5)-1.
			end
		else: begin
			help,units
			print,name,units
			print,'Input flux units '+string(units)+	$
				' not supported. No unit change done'
		      end
	endcase
done:
RETURN
END
