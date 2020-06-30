; 2018jul3 - measure change in sens. Adapted from stiscal/lowchang.pro
; 2020feb17 - remember to add the 0.87% gray flux incr. for Vega @ 3.47.. when
;	estimating the total change from the recal fig8 avg change,
;	which does result in a net increase of flux from ~.5% @ 8000A to ~.3% 
;	at 1.4-1.6mic. (i.e. LOWER sens.* ref files --> higher fluxes))
;-

comment=''
newdate=''
odate=''
; ###change - ff for convergence ck:
old=findfile('ref/sens.g*')		; convergence test
;old=findfile('ref/sens.g*-18jul20')
;old=findfile('ref/sens.g*-18oct23')
new=findfile('sens.g*')
grat=['g102','g141']

!y.style=1  &  !x.style=1
!p.noclip=1
!xtitle='!17WAVELENGTH ('+!ang+')'
!ytitle=''
!p.font=-1
!p.charsize=1.7
!p.multi=[0,1,n_elements(grat),0,0]
for imod=0,n_elements(grat)-1 do begin
	indx=where(strpos(new,grat(imod)) gt 0)
	indx=indx(0)
	openr,5,new(indx)
	readf,5,newdate
	close,5
	readcol,new(indx),wnew,snew
	print,'NEW=',new(indx)

	indx=where(strpos(old,grat(imod)) gt 0)
	indx=indx(0)
	openr,5,old(indx)
	readf,5,odate
	close,5
	readcol,old(indx),wold,sold
	print,'OLD=',old(indx)

	absratio,wnew,snew,wold,sold,0,0,0,0,wrat,rat

	!mtitle=grat(imod)
	ymn=min(rat)<.99  &  ymx=max(rat)>1.01
	plot,wrat,rat,xticklen=.12,yr=[.99,1.01],yticknam=['',' ','',' ','']
	oplot,wrat,rat*0+1,lines=2
	sig=stdev(rat,m)
	print,'mean,sig=',m,sig
	xyouts,!x.crange(0)*1.1,!y.crange(0)+.001,'Mean,sigma='+	$
		string([m,sig],'(2f8.3)'),chars=1
	endfor
xyouts,0.01,0.2,'Ratio: '+'Sens of '+newdate+	$
		' / '+odate,orient=90,/norm,charsiz=1.7	
xyouts,.2,.15,comment,/norm
plotdate,'senschang'
end
