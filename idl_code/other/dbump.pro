; 91aug3-measure reddening by reconstructing the dip
;
;spc=[39,10,16,9,11,12,63,37,5]	;1226,405,735,316,430,513,2130,1219,0121
;red=[.1,.1,.1,.15,.4,.1,.1,.12,.1]
;err=[.05,.1,.1,.1,.15,.1,.05,.08,.05]
;pmin=[-13.2,-13.9,-14.3,-14.5,-14.7,-13.6,-14.0,-14.3,-13.5]
spc=[1,68]			;0007,2251
red=[.15,.1]
err=[.1,.1]
pmin=[-14.3,-14.]

;red=[.4]			;2223 FROM LY PROGRAM
;err=[.2]
;pmin=[-15.]

!xtitle='WAVELENGTH (A)'
!ytitle='FLUX'
st=''

for i=0,n_elements(spc) do begin
;for i=0,0 do begin
	rd,'qso.mrg',spc(i),d
;	rd,'DISK$USER2:[BOHLIN.IBM]LYFIX.mrg',5,d	;2223???? 92jun12
	w=d(*,0)
	f=d(*,5)
	f=smooth(f,11)
	f=smooth(f,11)
	if err(i) eq 0 then !mtitle=!mtitle+' DERED BY '+strtrim(red(i),2)  $
		else							    $
		!mtitle=!mtitle+' DERED BY '+strtrim(red(i)-err(i),2)       $
		       +','+strtrim(red(i),2)+','+strtrim(red(i)+err(i),2)
	f=f>(10.^pmin(i))

	dered,w,f,red(i),df
	mn=alog10(min(df(where((w gt 2000) and (w lt 3150)))))
	set_xy,1250,3200,mn-.3,mn+.9
;	set_xy,1250,3200,mn-.8,mn+1.4		;FOR 2223-052
	flg=alog10(df)
	plot,w,flg
	if err(i) eq 0 then oplot,w,alog10(f)

	if err(i) ne 0 then begin
		dered,w,f,red(i)-err(i),df
		flg=alog10(df)
		oplot,w,flg

		dered,w,f,red(i)+err(i),df
		flg=alog10(df)
		oplot,w,flg

		endif		
	read,st
	plotdate,'nidl]dbump.pro'		;add 92jun12
	endfor
end
