; 2013Apr11 - make WFC3 IR Grism wavelength vector from 0-order position

pro wfc_wavecal,hdr,zxposin,zyposin,x,wave,angle,wav1st
; INPUTS: 
;	hdr - header
;	zxpos,zypos-x,y posit of the zero order. Must be px w/ a 1014x1014 ref. 
; OUTPUTS:
;	x=indgen(1014)
;	wave - wavelength vector, customized for each order. For subarr, wave
;		is the X-size of subarr and w/ the actual (eg 512px) coverage.
;	angle - slope of spectrum
;	wav1st - 1st order WLs for flat fielding w/ FF data cube
; FORMULAE
;	wave=b+m*delx			;delx=dist from Z-order
;	b=b0+b1*zxpos+b2*zypos		coef from wlmake.pro
;	m=m0+m1*zxpos+m2*zxpos
; HISTORY 2013May20: Update for measures of +1st 10833 from 0-read ima
;	2018Apr26 - mod for subarrays to do WLs on sub-arr size.
;	2018jun23 - add wfcwlfix here per calwfc_spec_wave
;-
filter = strtrim(sxpar(hdr,'filter'))
x=indgen(1014)				; indices of image x size (was 1014)
zxpos=zxposin  &  zypos=zyposin
; if subarr, put input position onto 1014x1014 grid;
ns=sxpar(hdr,'naxis1')
if ns lt 1014 then begin
	ltv1=-sxpar(hdr,'ltv1')         	; positive subarr offset
	ltv2=-sxpar(hdr,'ltv2')         	; positive subarr offset
	zxpos=zxposin+ltv1			; onto 1014X1014 ref frame
	zypos=zyposin+ltv2
	print,'SUBarr in wfc_wavecal shifts Z-ord ref px by',ltv1,ltv2
	endif

case filter of
	 'G102': begin					
; +1st order:
; Y coef comes out first from sfit in wlmake.pro:
		b0= 148.538  &  b1= 0.145605  &  b2=-0.008558	; 2013May31
		m0=23.8796  &  m1=-0.000332  &  m2= 0.001489
		b=b0+b1*zxpos+b2*zypos
		m=m0+m1*zxpos+m2*zypos
		wave=b+m*(x-zxpos)
		sxaddpar,hdr,'b+1st',b,'Constant Term of the +1st order disp.'
		sxaddpar,hdr,'m+1st',m,'Linear Term of the +1st order disp.'
; -1st order:
		b0= 205.229  &  b1=-0.015426  &  b2=-0.019207	; 2013May31
		m0=24.7007  &  m1= 0.000047  &  m2= 0.001478
		b=b0+b1*zxpos+b2*zypos
		m=m0+m1*zxpos+m2*zypos
; Is -1 formula better than +1 order for finding pixel of 0-order?
		indx=where(wave lt -7000,npts)
		if npts gt 0 then begin
		   wave(indx)=(b+m*(indx-zxpos))
		   sxaddpar,hdr,'b-1st',b,'Constant Term of the -1st order disp.'
		   sxaddpar,hdr,'m-1st',m,'Linear Term of the -1st order disp.'
		   endif
		wav1st=wave			; 1st order WLs for FF
; 2nd order:
		b0= 213.571  &  b1= 0.561877  &  b2=-0.040419	; 2013May31
		m0=23.9983  &  m1=-0.000797  &  m2= 0.001532
		b=b0+b1*zxpos+b2*zypos
		m=m0+m1*zxpos+m2*zypos
		indx=where(wave gt 14000,npts)
		if npts gt 0 then begin
		   wave(indx)=b+m*(indx-zxpos)
		   sxaddpar,hdr,'b+2nd',b,'Constant Term of the +2nd order disp.'
		   sxaddpar,hdr,'m+2nd',m,'Linear Term of the +2nd order disp.'
		   wav1st(indx)=(b+m*(indx-zxpos))/2
; ck monotonicity:
		if wave(indx(0)) le wave(indx(0)-1) then stop; & enforce monotonicity
		endif
		  
	       angle = 0.61				; 2013apr26 - see ISR
	       end
	 'G141': begin					
; +1st order:
; Y coef comes out first from sfit in wlmake.pro, which does the swap:
		b0= 156.339  &  b1= 0.111342  &  b2=-0.010926	; 2013May31
		m0=45.3203  &  m1=-0.000408  &  m2= 0.002818
		b=b0+b1*zxpos+b2*zypos
		m=m0+m1*zxpos+m2*zypos
		wave=b+m*(x-zxpos)
		sxaddpar,hdr,'b+1st',b,'Constant Term of the +1st order disp.'
		sxaddpar,hdr,'m+1st',m,'Linear Term of the +1st order disp.'
; -1st order:
		b0= 165.764  &  b1= 0.055688  &  b2= 0.016568	; 2013May31
		m0=46.4521  &  m1= 0.000382  &  m2= 0.002960
		b=b0+b1*zxpos+b2*zypos
		m=m0+m1*zxpos+m2*zypos
; IS -1 formula better than +1 order for finding pixel of 0-order?
		indx=where(wave lt -8000,npts)
		if npts gt 0 then begin
		   wave(indx)=(b+m*(indx-zxpos))
		   sxaddpar,hdr,'b-1st',b,'Constant Term of the -1st order disp.'
		   sxaddpar,hdr,'m-1st',m,'Linear Term of the -1st order disp.'
		   endif
		wav1st=wave			; 1st order WLs for FF
; 2nd order:
		b0= 193.093  &  b1= 0.164508  &  b2=-0.017031	; 2013May31
		m0=45.6062  &  m1=-0.000499  &  m2= 0.002840
		b=b0+b1*zxpos+b2*zypos
		m=m0+m1*zxpos+m2*zypos
		indx=where(wave gt 18000,npts)			; 2013may9
		if npts gt 0 then begin
		   wave(indx)=b+m*(indx-zxpos)
		   sxaddpar,hdr,'b+2nd',b,'Constant Term of the +2nd order disp.'
		   sxaddpar,hdr,'m+2nd',m,'Linear Term of the +2nd order disp.'
		   wav1st(indx)=(b+m*(indx-zxpos))/2
; ck monotonicity:
		   if wave(indx(0)) le wave(indx(0)-1) then stop; & enforce monotonicity
		   endif



;-1 formula is better than +1 order for finding pixel of 0-order.
;;		indx=where(wave lt 300,npts)
;;		if npts gt 0 then begin
;;		 wave(indx)=-(a0+a1*(indx-xc))
; enforce monotonicity: btwn -1 & +1 orders:
;;		 ibreak=max(indx)
;;		 bad=where(wave(ibreak+1:1013) lt wave(ibreak),npts)
;;		  	if npts gt 0 then begin
;;			   delwl=((wave(ibreak+1+npts)-wave(ibreak))>1)/(npts+1)
;;			   wave(ibreak:ibreak+npts)=wave(ibreak)+	$
;;					delwl*indgen(npts+1)
;;			   endif

	       angle = 0.42			;old meas iab9*4* avg of 6 = .40
	       end
	endcase
; 2018jun23 - try moving wfcwlfix here instead of in calwfc_spec.pro
root=strtrim(sxpar(hdr,'rootname'),2)
offset=wfcwlfix(root)				; offset in Ang
wave=wave+offset
wav1st=wav1st+offset

;2018Apr - pick out wave subset for subarr
if ns lt 1014 then begin
	ibeg=ltv1
	iend=ltv1+ns-1
	wave=wave(ibeg:iend)
	wav1st=wav1st(ibeg:iend)
	endif

	if not keyword_set(noprnt) then 				$
	      print,string(minmax(wave),'(2f8.1)')+' minmax WLs. '+	$
	      		'Z-order at (1014 ref)px=',zxpos,zypos
end
