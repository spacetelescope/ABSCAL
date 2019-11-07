pro nicreduce,star,infil=infil,nocorr=nocorr
;+
;
; PURPOSE:
; COADD & merge nicmos grism DATA AND WRITE ASCII OUTPUT FILES
;	co-adds of indiv gratings written here w/ "nicreduce' comment, then
;	nicmrg reads these indiv coadd files back, keeps co-add headers &
;	adds nicmrg comments.
; CALLING SEQUENCE:
;	nicREDUCE,STAR
; INPUT:
;	STAR-star name used in indir+star.* ascii file name to be merged
;	nocorr - keyword to avoid non-linearity correction
; OPTIONAL INPUT:
;	infil =special input and output directory name
; OUTPUT:
;	ASCII FILES OF THE COADDS & THE MERGING VIA nicMRG & corr for linearity
; EXAMPLE:
;	nicREDUCE,'GD153',infil='disptest'
; HISTORY
; 	04jul27 - R. BOHLIN
;	05feb10 - add nocorr keyword. Default is do linearity correction
;	05apr1  - add gross & net to  merged output
;	05dec15 - elim lamp on and bad WD1057
;	08apr28 - add special case HD209458 to elim old RG out-of-focus obs. now
;	      named hd209458.*-unfoc. Need an edit here to re-run those old obs.
;	08oct7 - add temperatures from bias to output file.
;	09apr28- add infil to process p330e in disptest/ (& elim outfil keyword)
;-

star=strlowcase(star)
st=''
!y.style=1  &  !x.style=1
!p.noclip=1
hdr=["WAVELENGTH COUNT-RATE    FLUX     STAT-ERROR  SCAT-ERROR   NPTS"+	$
 	"     GROSS       BKG     EXPTIME"," ###    1"]
grat=['g096','g141','g206']

if keyword_set(nocorr) then corr=0 else corr=1
if keyword_set(infil) then indir=infil+'/' else indir='spec/'
; loop for co-adding mult. obs in the same grating 
for igrat=0,2 do begin
	lst=findfile(indir+star+'.'+grat(igrat)+'-n*')
; Special CASES:
	if star eq 'p330e' then begin
; omit field mapping of na5105-PropID=11331 {rms is ~double}:
		good=where(strpos(lst,'na5105') lt 0)
		lst=lst(good)
		lst=[lst,findfile(indir+'p330-e.'+grat(igrat)+'-n*')]
		endif
	if star eq 'p041c' then lst=[lst,findfile(indir+'p041cbef.'+	$
		grat(igrat)+'-n*'),findfile(indir+'p041caft.'+grat(igrat)+'-n*')]
	good=where(strpos(lst,'n8i8b1') lt 0)		; unfocussed  HD209458
	lst=lst(good)
; omit bad 2 dither G096, but use G141 n9g501:
	good=where((strpos(lst,'n9g501') lt 0 or igrat eq 1 ) and	$
		strpos(lst,'dith') lt 0 and lst ne ''			$
; 09may13 - needed? fails for p330egwid23:  and strpos(lst,'gwid') lt 0$
		,ngood)
; END special CASES
	if ngood le 0 then goto,skipgrat
	lst=lst(good)
	nobs=n_elements(lst)
	print,'Co-adding:',lst
	nicadd,lst,title,w,c,f,e,scaterr,npts,wgt,gross,bkg,exptim,	$
		temps,corr=corr

; 09apr28  if keyword_set(filename) then outnam=strlowcase(filename) else  $
	outnam=indir+star+'.'+grat(igrat)
	ext1=''  &  if corr eq 0 then ext1='-un'
	close,11 & openw,11,strlowcase(outnam)+ext1
	printf,11,'file written by nicreduce.pro on ',!stime
	frst=strpos(strlowcase(lst),'-n')
	for i=0,nobs-1 do lst(i)=strmid(lst(i),frst(i)+1,6)
	printf,11,'coadd lst and Temp(K) for '+star+'.'+grat(igrat)+	$
			': ',lst,form='(a/(7(1x,a7)))'
	printf,11,temps,form='(7f8.2)'
	printf,11,title
	printf,11,hdr,form='(a/a)'
	printf,11,star
	!mtitle=star
	!ytitle='net counts/sec'
	!ytitle='flux(10 !e-15!n erg s!e-1!n cm!e-2!n a!e-1!n)'
	!xtitle='wavelength (mic)'
	plot,w,f
	plotdate,'nicreduce.pro'
	fmt='(f10.7,4e12.4,f7.1,2e12.4,f8.1)'
	numpts=n_elements(w)
	for i=0,numpts-1 do printf,11,format=fmt,w(i),c(i),f(i),e(i),	$
				scaterr(i),npts(i),gross(i),bkg(i),exptim(i)
	printf,11,' 0 0 0 0 0 0 0 0 0'
	close,11
skipgrat:
	endfor		;end main loop

;
; merge data and write in star.mrg file
;
title=strupcase(star+' '+grat(0)+'+'+grat(1))		;always have g096 & g141 obs
fil1=findfile(indir+star+'.'+grat(0)+ext1)
fil2=findfile(indir+star+'.'+grat(1)+ext1)
if fil1 eq '' or fil2 eq '' then return			;2016aug29-but NO plot
print,'merging: ',fil1,' ',fil2
ext='.mrg'  &  if corr eq 0 then ext='.unmrg'
; 07dec23 - mv star name=orig title to first in ff 2 strings:
if corr eq 0 then title=title+' NO linearity corr. ' else     $
		  title=title+' Corr. for non-linearity '
nicmrg,fil1,fil2,indir+star+ext,title=title

fil3=findfile(indir+star+'.'+grat(2))  
fil3=fil3(0)						;temp patch for mult obs
if fil3(0) ne '' then begin
	title=title+'+'+strupcase(grat(2))
	print,'merging 3rd file: ',fil3
	nicmrg,indir+star+ext,fil3+ext1,indir+star+ext,title=title
	endif

;read back the merged data with the ascii file reader

rdf,indir+star+ext,1,dat
w=dat(*,0)
f=dat(*,2)
stat=dat(*,3)
syst=dat(*,4)
;
;full plot:
!ytitle='flux(10 !e-15!n erg s!e-1!n cm!e-2!n a!e-1!n)'
flx=f*1.e15
mx=max(flx)*1.2
err=1.e15*stat
plot,w,flx,yr=[.01*mx,mx],/ylog
oplot,w,err,linestyle=2
plotdate,'nicreduce.pro'
!x.style=0
end
