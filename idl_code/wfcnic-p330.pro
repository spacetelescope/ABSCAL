; 2018Nov29 - compare wfc3-IR to Nicmos & model for P330E.
;-

 st=''						; null string
pset
!y.style=1
!p.font=-1
!p.charsize=2
!p.charthick=3*(!d.name eq 'PS')
!x.thick=4				; axis
!y.thick=4
!p.thick=7				; plot lines
!p.font=-1
loadct,0
red=[0,255,  0,  0,150,255] 		; see flxlim.pro for 6 saturated colors
gre=[0,  0,255,  0,  0,255]
blu=[0,  0,  0,255,255,255]
tvlct,red,gre,blu

wfcfil='spec/p330e.mrg'
rdf,wfcfil,1,wfc
wlwfc=wfc(*,0)  &  flxwfc=wfc(*,2)

nicfil='../nical/spec/p330e.mrg'
rdf,nicfil,1,nic
wlnic=nic(*,0)*1e4  &  flxnic=nic(*,2)

mzmod,5830,4.95,-0.21,wmz,fmz,bdum,cont	   ;per p330e_stiswfcnic_001.fits
chiar_red,wmz,fmz,-.030,fmz                      ; redden model
ssreadfits,'../calspec/p330e_stiswfcnic_001.fits',h,wst,fst
norm=tin(wst,fst,6800,7700)/tin(wmz,fmz,6800,7700)
fmz=fmz*norm


; PLOT (landscape)
;
!p.font=-1
!ytitle='!17FLUX * !7k!e2!n * 10!e15!n'
!xtitle='!17WAVELENGTH ('+!ang+')
!xtitle='!17WAVELENGTH (!7l!17m)'
!mtitle=''
wlwfc=wlwfc/1e4
wlnic=wlnic/1e4
wmz=wmz/1e4
plot,wlwfc,flxwfc*.9*wlwfc^2*1e15,xr=[.8,1.7],yr=[6e,11e]
oplot,wlnic,flxnic*1.1*wlnic^2*1e15
oplot,wmz,fmz*wmz^2*1e15,color=1

; For Colloquim
!p.font=1
xyouts,.95,7.9,'!17WFC3 R!19~!17200',chars=1.5
xyouts,.95,9.4,'Model',chars=1.5,color=1
xyouts,.95,10.5,'NICMOS R!20~!17100',chars=1.5

plotdate,'wfcnic-p330'

end
