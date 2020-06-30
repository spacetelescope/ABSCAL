; 2020feb5
;-

!x.style=1
!y.style=1
!p.font=-1
!p.noclip=0
!xtitle='!17WAVELENGTH ('+!ang+')'
!ytitle='Flux'
red=[0,255,  0,  0,255] 		; see flxlim.pro for 6 saturated colors
gre=[0,  0,255,  0,255]
blu=[0,  0,  0,255,255]
tvlct,red,gre,blu

rdf,'../stiscal/dat/gaia593_1968.mrg',1,st1968
rdf,'../stiscal/dat/gaia593_9680.mrg',1,st9680
rdf,'spec/gaia593_1968.mrg',1,ga1968
rdf,'spec/gaia593_9680.mrg',1,ga9680 

!mtitle='GAIA593_9680 brighter, GAIA593_1968 fainter'
plot_oo,st9680(*,0),st9680(*,2),xr=[4100,16500],yr=[2e-17,5e-13]
oplot,st1968(*,0),st1968(*,2)
oplot,ga9680(*,0),ga9680(*,2),color=1
good=where(ga1968(*,0) gt 7800)
ga1968=ga1968(good,*)
oplot,ga1968(*,0),ga1968(*,2),color=1

plotdate,'plotgaia'
end
