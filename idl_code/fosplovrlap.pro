; 93NOV23-COMPARE HI-DISP grating overlap regions
; 94nov10-update
;
!xtitle='!17WAVELENGTH ('+!ANG+')'
!ytitle='FLUX (10!e-12!n erg s!e-1!ncm!e-2!nA!e-1!n)'
wbeg=[1550,2200,3150,4550,6200]
wend=[1650,2400,3350,4850,6900]

STARS=['M33-OB10-3']
FILES=['M33-OB10-3']
GRATS=STRARR(2,2)
STARS=['LMC-SMP32HB']
FILES=['LMC-SMP32']
DD='DISK$DATA2:[BOHLIN.FOSDATA.gopn]'
GRATS=STRARR(4,2)
GRATS(*,0)=['H13','H19','H27','H40']
DETS=['BLUE']
st=''
wbeg=[1550,2200,3150]
wend=[1650,2400,3350]
st=''

FOR IG=0,0 DO BEGIN	;LOOP OVER 2 detector modes
	FOR IS=0,n_elements(stars)-1 DO BEGIN		;LOOP OVER STARS
		INDX=WHERE(GRATS(*,IG) NE '',ICOUNT)
		IF ICOUNT LT 1 THEN GOTO,SKIPIT
		GRAT=GRATS(INDX,IG) 
		rdf,DD+files(is)+'h'+strmid(dets(ig),0,1)+'.'+grat(0),1,d
		w1=d(*,0)
		f1=d(*,2)/1.e-12
		for i=1,n_elements(grat)-1 do begin
			!p.font=-1      ;override startup need vector fonts
			rdf,DD+files(is)+'h'+strmid(dets(ig),0,1)+       $
					'.'+grat(i),1,d
			w2=d(*,0)
			f2=d(*,2)/1.e-12
			star=stars(is)
			if star eq 'WD0501+527' then star='G191B2B'
			!mtitle='Overlap region for '+star+' '+grat(i-1)+ $
				' and '+grat(i)+' '+dets(ig)
;			mx=max(f1(where(w1 gt wbeg(i-1+ig))))
			mx=max(f1(where(w1 gt wbeg(i-1+ig)+20)))	;for PN
			plot,w1,f1,xr=[wbeg(i-1+ig),wend(i-1+ig)],	  $
;				yr=[.5*mx,mx],charsiz=1.5
				yr=[0*mx,.8*mx],charsiz=1.5
			oplot,w2,f2,linest=1
; 94apr29-compute overlap error
			w1st=min(w1(where(w1 gt w2(0))))
			last=n_elements(w1)-1
			wlst=max(w2(where(w2 lt w1(last))))
			rat=tin(w1,f1,w1st,wlst)/tin(w2,f2,w1st,wlst)
			xyouts,.4,.9,'Overlap Ratio='+string(rat,'(f5.3)'),/norm
; fix overlap region for continuity
			fosovrlap,w1,w2,f1,f2,fo1,fo2
;			oplot,w1,fo1-!CYMAX*.1,linest=2
;			oplot,w2,fo2-!CYMAX*.1,linest=2
			!p.font=0
;			xyouts,.95,.0,'Fig. 9',/norm	;for calfos.isr125
			plotdate,'fosplovrlap'
			w1=w2  &  f1=f2
			if !d.name eq 'X' then read,st
		ENDfor
SKIPIT:
	ENDFOR
ENDFOR
END
