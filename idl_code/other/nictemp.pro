function nictemp,mode,selstar,obset
;
; Compute avg temp for an obs.
;	avtemp=nictemp('G096','P330E','n8br01') for example
;
; INPUT:
;	mode - G096, G141, or G206
; 	selstar - star name
;	obset  - first 6 char of dataset
; HISTORY - RCB 08sep10
;-

; account for special cases of P041C before and after the lamp on data.
if obset eq 'n9jj02' or obset eq 'n9vo06' then begin
	stisobs,'dirnic.log',obs,grat,aper,star,'','','P041C'
	good=where(strpos(obs,obset) eq 0)
	obs=obs(good)  &  grat=grat(good)
	if obset eq 'n9jj02' and strpos(selstar,'bef') gt 0 then 	$
							indx=indgen(10)+1
	if obset eq 'n9jj02' and strpos(selstar,'aft') gt 0 then 	$
							indx=indgen(10)+107
	if obset eq 'n9vo06' and strpos(selstar,'bef') gt 0 then 	$
							indx=indgen(15)+1
	if obset eq 'n9vo06' and strpos(selstar,'aft') gt 0 then 	$
							indx=indgen(15)+83
	obs=obs(indx)  &  grat=grat(indx)
	good=where(grat eq strupcase(mode),ngood)
     end else begin		; Normal cases:
	stisobs,'dirnic.log',obs,grat,aper,star,mode,'',selstar
	good=where(strpos(obs,obset) ge 0,ngood)
	endelse
	
if ngood gt 0 then obs=obs(good) else begin
	print,'***NO TEMPERATURE from BIAS. SET TO AVG OF 76K for '+	$
				mode+' '+selstar
	return,76.
	endelse
nictemp=0.
npts=n_elements(obs)
for i=0,npts-1 do begin
	fil='../data/spec/nic/'+obs(i)+'_raw.fits'
	fits_read,fil,im,hd
	nictemp=nictemp+sxpar(hd,'tfbtemp')
	endfor

nictemp=nictemp/npts
print,'Avg temp=',nictemp,' for',npts,mode,obset,selstar,		$
						form='(a,f7.3,a,i3,2a7,1x,a)'
return,nictemp
end
