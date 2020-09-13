pro prewfc,directory,logfile,subdir,display=display,trace=trace
;+
; EXAMPLE:
; WFC3 Platescale is 0.13arcsec/px
; wfc3 _ima fails as there is not enuf signal in zero-read of IMA file
; ###change: /dirimg names the files in wfc_process to be *q.fits, while
;	my ZOE extract names output as *qpn.fits. star='PN' set in wfc_process &
;	filename switch is in calwfc_spec.pro
; STARE mode always applies FF. Option is for scanned:
; Name these *axe.fits if ever redoing the PN case:	,/dirimg
; DOCUMENTATION
;--------------
; wfc_process - extract spectra in 6 char visit-by-visit designations
; wfc_coadd   - Plot and Co-add wfc3 spectra visit-by-visit. These co-adds are 
;	just for quick look, as mrgall.pro does final global co-adds of each
;	target across all visits.
;-
st=''
!x.style=0
!y.style=1
!p.noclip=0
loadct,0
grism=['G102','G141']			; info

; YORK 2020-06-16: I get '% Not a legal system variable: !TEXTOUT.' when I
;	have this next line in the code (as opposed to commented out).
;	Same with '!dump=1'
; !textout=2				; to not pause on Don's msgs.
;!dump=1					; to see don's msgs & interpr. err msgs

; Input Data File
dirlog = 'dirirstare.log'
if n_params('logfile') ne 0 then dirlog = logfile

; Output Spectra File
specdir = 'spec'
if n_params('subdir') ne 0 then specdir = subdir

dir = ''
if n_params('directory') ne 0 then begin
	dir = directory
	dirlog = directory + '/' + dirlog
	specdir = directory + '/' + specdir
endif

; ###change
wfcobs,dirlog,obs,grat,aper,star,'','',''			; everything
;wfcobs,dirlog,obs,grat,aper,star,'','','WD1657_343'
;wfcobs,dirlog,obs,grat,aper,star,'','','WD1327_083'	;WD2341+322' Tremblay
;wfcobs,dirlog,obs,grat,aper,star,'','','C26202'
; ** Must run wfcmrg immediately ff one of the next 2 lines (or fix *.fits files
;	to incl star name ** otherwise cannot do 'everything' here at once!!!
;wfcobs,dirlog,obs,grat,aper,star,'','','GAIA593_1968'
;wfcobs,dirlog,obs,grat,aper,star,'','','GAIA593_9680'
;wfcobs,dirlog,obs,grat,aper,star,'','','GD71'		; 2020feb7
;wfcobs,dirlog,obs,grat,aper,star,'','','WD1657_343'	; 2020jun3

; cut to 1st 6 char to uniquely ID visits:
obs=strmid(obs,0,6)

good=where(strmid(obs,0,5) ne 'iab9a')	; 2 obs that should be part of iab90*
obs=obs(good)  &  star=star(good)  &  aper=aper(good)

; 2018apr13-NG as the order gets screwed up:
;indx=rem_dup(obs)			; all the data
; so make my own uniq, assuming all the same obs are together:
nobs=n_elements(obs)
indx=[0]
for i=1,nobs-1 do if obs(i) ne obs(i-1) then indx=[indx,i]
obs=obs(indx)  &  star=star(indx) &  aper=aper(indx)

; INDIVIDUAL, TEST, & SPECIAL REDUCTIONS:
; ###change special sub-sets or new bit of data:
;star='GD71'  &  obs='ibbt04'			; test run
;star='V-ALF-LYR'  &  obs='ibtw01q9q'		; test run
;star='VY2-2-COPY'  &  obs=['ic5v41b7q','ic5v41b8q']		; partial run
; One 9-char rootname in list is NG. Always have two or more for star, as well:
;star='PN-G045.4-02' &  obs=['ic6907ceq','ic6907cfq']		; test run
;star='G191B2B'  &  obs=['ibcf51ibq','ibcf51ifq']		; FF test run
;xstar=0  &  ystar=0
; STARE mode always applies FF. Option is for scanned:
;wfc_process,star,obs,/before,direct=dir,dirlog=dirlog,/displ,/trace,	$
;		xstar=xstar,ystar=ystar,				$
;;		flatfile='ref/sedFFcube-both.fits',			$
;;		subdir='spec/sedff'
;;		flatfile='ref/ryanFFcube-both.fits',			$
;;		flatfile='none',			 		$
;;		subdir='spec/ryanff'
;stop
;     END TEST section ##################################

;obs='ibbt03'  &  star='GD71'
;good=where(strmid(obs,0,6) eq 'ic6907')		; VY2 bad WL testing
;obs=obs(good)  &  star=star(good)

; ###change
; to find a particular obs set:
;print,where(obs eq 'icsf02')  &  stop	;ibwl81-0,ibwl82-3,ibwl88-8,ic6901-14
; ic6903-15,ibcf51-10,icqw0-40,icrw12-79,ibwi08-81,icsf02-7

print,obs,star
nobs=n_elements(obs)
; ###change - main part of prog to do whole dirlog
for i=0,nobs-1 do begin
;for i=5,5 do begin
; find each slope angle. /slope means use avg slope:
	xstar=0  &  ystar=0
        if obs(i) eq 'ibhj10' then begin			; C26202
	     xstar=182  &  ystar=143  &  endif
; 2018apr11-Default FF seems to be AXE, NOT none. But always use sedFFcube.
help,i,obs(i)
	wfc_process,star(i),obs(i),/before,direct=dir,dirlog=dirlog,	$
		xstar=xstar,ystar=ystar,display=display,trace=trace,		$
;dir img aXe disp ref, not ZO. Change code to name 'axe' if redoing.
;		/dirimg							$
;		grism='g141'
 		flatfile='ref/sedFFcube-both.fits',  		$;2018aprDEFAULT
;		flatfile='ref/ryanFFcube-both.fits', $
 		subdir=specdir						;default
	help,i,obs(i)
	print,'********** START Co=add *************'
;	read,st
; /ps puts .ps file in subdir for debugging/ checking
; 05mar14- double for coadds of mult obs:
	wfc_coadd,star(i),obs(i),/double,/ps,dirlog=dirlog,subdir=specdir
	print,obs(i),' ------------*** END ***---------------'
	endfor

end
