; 2012jun18 - Measure the correlation btwn xc, cam ref posit. & xzorder posit.
;-
st=''
!y.style=1
fil=findfile('spec/spec*',count=nfils)
xc=fltarr(999)  &  yc=xc  &  xz=xc  &  yz=xc
xpostarg=xc  &  ypostarg=xc
grism=strarr(999)
dogrism='G141'
!mtitle=dogrism

for i=0,nfils-1 do begin
	z=mrdfits(fil(i),1,hd)
;	xc(i)=sxpar(hd,'xc')		; missing 20jun
;	yc(i)=sxpar(hd,'yc')
	xc(i)=sxpar(hd,'xactual')	; see doc-restart-work.2020jun
	yc(i)=sxpar(hd,'yactual')
	xz(i)=sxpar(hd,'xzorder')
	yz(i)=sxpar(hd,'yzorder')
	xpostarg(i)=sxpar(hd,'postarg1')
	ypostarg(i)=sxpar(hd,'postarg2')
	grism(i)=strtrim(sxpar(hd,'filter'),2)
	endfor
print,minmax(xpostarg),minmax(ypostarg)

; Do xc-xz at top, middle, and bottom:
!xtitle='X-postarg'
!ytitle='XC-XZ (cam X -grism X of 0-order)
;!ytitle='XZ (grism X of 0-order)
mnypos=-99  &  mxypos=-35
for iy=-1,1 do begin
	if iy ne -1 then begin  &  mnypos=iy*35  &  mxypos=5+94*iy  &  endif
	good=where(ypostarg ge mnypos and ypostarg le mxypos		$
		and xc gt 0 and xz gt 0 and grism eq dogrism) 	; yz range
; xc-xz vs s-postrg
	plot,xpostarg(good),xc(good)-xz(good),psym=4,symsiz=2
	coef=linfit(xpostarg(good),xc(good)-xz(good))
	fit=coef(0)+coef(1)*minmax(xpostarg(good))
	avgy=avg(yz(good))
	xyouts,.4,.25,'Avg 0-ord Y='+string(avgy,'(f6.1)')+' Range='+	$
	string(minmax(yz(good)),'(2f6.1)'),/norm

; xz vs x-postarg for finding the 0-ord on trailed image at yz=559
;plot,xpostarg(good),xz(good),psym=4,symsiz=2
;coef=linfit(xpostarg(good),xz(good))
;fit=coef(0)+coef(1)*minmax(xpostarg)
	oplot,minmax(xpostarg(good)),fit,th=7
	plotdate,'scnoffset'
	print,coef

for j=0,n_elements(good)-1 do print,xc(good(j)),xz(good(j)),		$
	xc(good(j))-xz(good(j)),xpostarg(good(j)), 			$
	ypostarg(good(j)),' ',grism(good(j)),				$
	yc(good(j))-yz(good(j))
	if !d.name eq 'X' then read,st
	endfor
end
