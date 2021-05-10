pro echlREDUCE,aper,STAR
;+
;
; PURPOSE:
; 97jul21-COADD stis DATA AND WRITE ASCII OUTPUT FILES
; CALLING SEQUENCE:
;	echlREDUCE,aper,STAR
; OPTIONAL INPUT:
;	aper - restrict aperture selection. Use '' to get all apertures.
;	STAR-RESTRICT PROCESSING TO A CERTAIN STAR NAME *************
;	     OTHERWISE, ALL STARS GET ADDED TOGETHER!!!!!!!!!!!!!!!!!
;		Also, specifying star, makes a nice title, for normal use.
; OUTPUT:
;	ASCII FILE OF THE COADDS
; EXAMPLE:
;	echlREDUCE,'','G191B2B' --- but all the shifted data are incl !
; HISTORY
; 	2012July9 - R. BOHLIN
;	2012nov15 - see also Ayres co-add from starcat in wd/rauch
;-

st=''
if n_params(0) gt 2 then STAR=STRUPCASE(STAR)
!y.style=1  &  !x.style=1
!P.NOCLIP=1
hdr1=["SYS-ERROR is the broadband ~2% INTERNAL repeatability of echelles.", $
 "IN ADDITION, THERE IS A SYSTEMATIC UNCERTAINTY IN THE ABS CALIB OF ~2-4%", $
 "    Bohlin (2000,AJ,120,437). BOTH THE STAT-ERR AND SYS-ERR ARE 1-SIGMA."]
hdr2=" WAVELENGTH   COUNT-RATE     FLUX     STAT-ERROR   SYS-ERROR  NPTS   TIME"

stisobs,'direchl-x1d.log',root,grat,aper,stars,'','',star
dum=gettok(root,'_')
root=gettok(root,'.fits')
good=where(strmid(grat,4,1) eq 'H')
root=root(good)
spec='~/data/spec/echl/'+root+'_x1d.fits'
help,root
print,'STISREDUCE for Star/obs: ',star,root

echladd,spec,HEAD,TITLE,Wav,count,FLUX,FLXERR,NPTS,TIME

; ###change
outnam='dat/'+star+'.h-echl-temp'	; output file. Setup only for Hi-disp now.

syserr=0.02*abs(flux)
CLOSE,11 & OPENW,11,strlowcase(outnam)
PRINTF,11,'FILE WRITTEN BY ECHLREDUCE.PRO ON ',!STIME
printf,11,'coadd list for E*H'+': ',root,form='(a/(7(1x,a9)))'
printf,11,hdr1
printf,11,hdr2
printf,11,'NO correction for stellar RADIAL VELOCITY'
printf,11,' ###    1'
printf,11,title
FMT='(F12.6,4E12.4,I4,F10.1)'
NUMPTS=N_ELEMENTS(wav)
FOR I=0,NUMPTS-1 DO PRINTF,11,FORMAT=FMT,wav(I),count(I),flux(I),	$
	flxerr(I),syserr(I),NPTS(I),TIME(I)
PRINTF,11,' 0 0 0 0 0 0 0'
close,11

;;READ BACK THE MERGED DATA WITH THE ASCII FILE READER
RDF,outnam,1,DAT
W=DAT(*,0)
F=DAT(*,2)
STAT=DAT(*,3)
SYST=DAT(*,4)
;
;full PLOT:
!ytitle='FLUX & ERROR ARRAY (10 !e-14!n erg s!e-1!n cm!e-2!n A!e-1!n)'
flx=f*1.e14
MX=MAX(flx(WHERE((W GT 1200))))*1.2
err=1.e15*Stat
plot,w,flx,YR=[.0001*mx,MX],/ylog
oplot,w,err,linestyle=2
plotdate,'stisreduce.pro'
END
