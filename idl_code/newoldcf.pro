pro newoldcf,filespec
;+
; to compare and plot new/old ratio, old being one version back.
; Run in Calspec dir... 
; example:  newoldcf,'*stisnic_002'
;	    newoldcf,'deliv/*mod_009' pure hyd rauch*008.fits have NaN prob. but
;				NaN fixed in newmakstd.pro for 009 versions.
;	    newoldcf,'*mod_010' If ver 10 is copied to calspec
;	    newoldcf,'deliv/*stis' All data files in deliv.
; 	    newoldcf,'bd_17d4708_stisnic_004'
;	    newoldcf,'g750lhgt11/*.g750l' & run in stiscal dir
;	(dat/*mrg gets new stars-NG! Fouls up weird names & odd old *.mrg files)
;	    newoldcf,'g750lhgt7/*mrg' run in stiscal,
;		before making hgt=11 default in dat/
; newoldcf,''  to do all files in doc/new.names-all (assumes input is in /deliv)
;	and do the skipmrg edit below to cf. w/ new .mrg files. 
;	OR edit below for input doc/new.names from Run in calspec
; newoldcf,'sirius_stis_003', run in calspec, & comment skipmrg
; newoldcf,'all' to cf all CALSPEC stars w/ new *.mrg & run in calspec dir
; 	& comment skipmrg below to cf w/ current calspec
;	(misses new stars, but see them AFTER making the deliv. files.)

; HISTORY
; 14feb - new WD data, new ttcorr. NOTE that small Teff diff, eg 60K at ~8000K
;	for 1757132, can cause flux diff of 1% from 7000 to 12000A,
;	Hair in ratios at short end of G230LB can be caused by scat lite change,
;		which changes when net changes per time change updates.
;-

fils=findfile(filespec+'*.fits')				; new for deliv
if fils(0) eq '' then fils=findfile(filespec)			;dat, g750lhgt11
if filespec eq '' and strpos(filespec,'g750l') lt 0 then begin
; ###change - new.names or new.names-all:
	readcol,'doc/new.names',fils,f='(a)'
	good=where(strpos(fils,'#') lt 0)
	fils='deliv/'+fils(good)+'.fits'
	endif
if filespec eq 'all' then begin					; 2017may11
	filall=findfile('*stis*.fits')				; in calspec dir
	filall=filall(where(strpos(filall,'sun') lt 0))
	filtmp=filall
	strnam=gettok(filtmp,'_stis')
	strnam=strnam(uniq(strnam))
	nfils=n_elements(strnam)
	fils=strarr(nfils)
	for i=0,nfils-1 do begin
		good=where(strpos(filall,strnam(i)) eq 0)
		if strnam(i) eq 'hz43' then				$
			good=where(strpos(filall,'hz43_') eq 0)
		fils(i)=filall(max(good))
		endfor
	endif
st=''
nfils=n_elements(fils)
print,fils
!x.style=1
!y.style=1
!p.noclip=1
!p.charsize=1.4					; over-ride =2 in ps.pro
!xtitle='Wavelength'
!ytitle='new/old flux ratio'
for ifil=0,nfils-1 do begin
	print,'NEW file=',fils(ifil)
	if strpos(fils(ifil),'fits') gt 0 then ssreadfits,fils(ifil),hn,wn,fn $
	    else begin				; for hgt7 or hgt11 runs
	    rdf,fils(ifil),1,d
	    wn=d(*,0)  &  fn=d(*,2)  &  endelse
; compute oldfil:						; 2020feb
	fdecomp,fils(ifil),disk,dir,name,ext
	tmp=name				; assume old is in calspec dir
	newfil=tmp
	dum=gettok(tmp,'_0')			; find version (good to 9 !)
	if strpos(fils(ifil),'sf1615') ge 0 or				$
		strpos(fils(ifil),'wd1327_083') ge 0 then dum=gettok(tmp,'_0')
	ver=fix(tmp)
	oldfil=replace_char(name,'_'+tmp,				$
			'_0'+string(ver-1,'(i2)'))
	oldfil=replace_char(oldfil,' ','0')
	oldfil=oldfil+'.'+ext
	help,tmp,oldfil,ver,name,fils(ifil)

	if strpos(fils(ifil),'stisnic_001') ge 0 then begin
		tmp=fils(ifil)
		star=gettok(tmp,'_stisnic')
		oldfil=star+'_nic_*'
		oldfil=findfile(oldfil)
		numfil=n_elements(oldfil)
		oldfil=oldfil(numfil-1)
		endif
; ###change:
	if oldfil eq '' then begin		; skipped ver #, eg gd153
		oldfil=replace_char(fils(ifil),'00'+string(ver,'(i1)')+'.',    $
		 '00'+string(ver-2,'(i1)')+'*.')
		oldfil=findfile(oldfil)  &  oldfil=oldfil(0)
		endif
; ff sort of works, but NG on details. See above. delete-see skipmrg below
;	if strpos(fils(ifil),'.mrg') gt 0 then begin		; 2019aug22
;		oldfil=findfile('~/calspec/'+name+'*stis*')
;		dumind=where(strpos(oldfil,'_01') gt 0,nproblem)
;		if nproblem gt 0 then stop		$	; and fix
;		else oldfil=oldfil(-1)
;		endif

; ###change: comment ff to cf current calspec w/ new NICMOS or STIS .mrg files:
	goto,skipmrg	; normally UN-comment to cf calspec versions
	oldfil=fils(ifil)		; old=latest calspec to cf to *.mrg
       
; ###change - temp total change for Sirius:
;;;	oldfil='sirius_stis_001.fits'
       
       star=strmid(name,0,5)+'*'	; & ff needed for odd & long names
       if strpos(star,'agk') ne 0 and strpos(star,'grw') ne 0		$
							then remchar,star,'_'
       if strpos(oldfil,'alpha_lyr') ge 0 then star='hd172167'
       if strpos(oldfil,'feige34') ge 0 then star='feige34'	; need long name
       if strpos(oldfil,'feige110') ge 0 then star='feige110'
       if strpos(oldfil,'g191') ge 0 then star='g191'
       if strpos(oldfil,'hz4_') ge 0 then star='hz4'
       if strpos(oldfil,'hz43_') ge 0 then star='hz43'
       if strpos(oldfil,'snap1') ge 0 then star='snap-1'
       if strpos(oldfil,'snap2') ge 0 then star='snap-2'
       if strpos(oldfil,'vb8') ge 0 then star='vb8'
       if strpos(oldfil,'wd0308') ge 0 then star='wd-0308-565'
;      newfil=findfile('~/nical/spec/'+star+'.mrg')  &  newfil=newfil(0)
       newfil=findfile('../stiscal/dat/'+star+'*.mrg')  &  newfil=newfil(0)
       help,ifil,'New file='+newfil,star
       print,star,' Actual new file=',newfil
       rdf,newfil,1,d
;       wn=d(*,0)*1e4  &  fn=d(*,2)		    	; nicmos
       wn=d(*,0)  &  fn=d(*,2)  	    		; end ###change
skipmrg:
	oldfil=findfile(oldfil)
	if oldfil eq '' then goto,onlyone		; NO old file, ie _001

	print,'Previous (old) file=',oldfil
	if strpos(oldfil,'.fits') gt 0 then ssreadfits,oldfil[0],ho,wo,fo
	good=where(wn ge wo(0))
	wn=wn(good)  &  fn=fn(good)
; 2019Aug23 - absratio seems to be screwy. Do the ratio right, anyhow.
;	absratio,wn,fn>1e-16,wo,fo>1e-16,0,0,0,0,wr,rat
;	rat=smooth(smooth(rat,5),5)		; approp for new R=500 BOSZ
; NG for models	numer=smooth(smooth(fn>5e-17,5),5)	;smooth before dividing!
	fo=double(fo)  &  fn=double(fn)			;2020feb
	linterp,wo,fo,wn,fo,missing=1		;?/NoINTERP
; 2020mar19 - elim 0/0
	good=where(fo ne 0 and fn ne 0)
	wn=wn(good)  &  fn=fn(good)  &  wo=wo(good)  &  fo=fo(good)
	wr=wn					; wn=master WL
	numer=smooth(smooth(fn,5),5)		; smooth before dividing!
	denom=smooth(smooth(fo,5),5)
	rat=numer/denom

	fdecomp,oldfil,disk,dir,name,ext
	fdecomp,newfil,disk,dir,newname,ext
	!mtitle=dir+newname+' / '+name
; TOP PLOT
	mxplt=10200
	if max(wr) gt 26000 then !p.multi=[0,1,2,0,0] else begin
		!p.multi=0  &  mxplt=max(wr)  &  endelse
	yrang=[.98,1.02]
	if strpos(filespec,'mod') gt 0 then yrang=[.99,1.01]
	if max(abs(1-minmax(rat(175:-100)))) gt .02 	$	; wr(170)~1250A
						then yrang=[.97,1.03]
	if max(abs(1-minmax(rat(175:-100)))) gt .05 	$
						then yrang=[.9,1.1]
	if oldfil ne newfil then plot,wr,rat,yr=yrang,xr=[min(wr),mxplt] $
	     else begin
		!p.multi=0
		!mtitle=newfil
		plot_oo,wn,fn>1e-20
		endelse
	oplot,[0,250000],[1,1],lin=2
; BOTTOM PLOT	(only for showing WL>26000A)
	if max(wr) gt 1e5 then begin
		avir=tin(wr,rat,5e4,1e5)
		if abs(avir-1) gt 0.02 then yrang=[.9,1.1]
		endif
	if !p.multi(1) ne 0 then begin
		good=where(wr gt 9000 and wr lt 3.18e5)
		plot,wr(good),rat(good),yr=yrang,xr=[9000,3.2e5]
		oplot,[9000,4e5],[1,1],lin=2
		endif
onlyone:
	if oldfil eq '' then plot_oo,wn,fn>5e-18
	plotdate,'newoldcf'
	if !d.name eq 'X' then read,st
	endfor
pset
end
