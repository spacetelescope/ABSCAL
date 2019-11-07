function synacs,time,filt,cam,wav,flux,effwav,wfltr,integr,qe,		$
		plt=plt,shft=shft,leshift=leshift,qefil=qefil,		$
		silent=silent,version=version
;+
;
; PURPOSE:
;	Compute synthetic photometry for ACS filters at 2002.16, -77K or
;		2006.5, -81k ONLY! ie only the output ct/s are constant from 
;		2002.16-2006.5 and then jump to a new constant level after 
;		2006.5 and correspond to the correct values only at 2002.16.
;
;	Returns computed countrate = synacs(filt,cam,wav,flux)
;
; INPUT
;	time - time as fractional year. Scaler only. NO acs_timecorr made. only
;		used to pick the WFC -77 or -81 TP.
;	filt - acs filter name
;	cam - hrc, wfc, or sbc (no filter curves yet for sbc)
;	wav - wavelength array of spectral flux distribution in ANG.
;	flux - spectral flux distribution
; OPTIONAL INPUT
;	qe - new QE vect defined on the current 3000(1700)-11000 WL scale 
;	plt - keyword to make plots
;	shft - keyword specifying shift of FILTER BP in Ang. Can be vector for
;		making Fig 9  of ISR 2007-06 
;	leshift-shift of the long WL edge, per Golimowski suggestions.
;	qefil-keyword to specify system thruput (TP) file flavor. ='qe2'
;		for my 2007 TP cal from Jen's zeropts table, ie dat/*.dat files.
;		 'qe3' for new *2011. qefil='q3e' isa no-op. Only ='qe2' changes
;		TP. Default is qe3. Shift keywords apply to any TP file.
;	silent-to avoid printing stuff
; OUTPUT
;	the result of the function in counts/sec for infinite radius aperture.
;	effwav - effective wavelength optional output (optional)
;	wfltr - the wavelength vector for the integrand (optional)
;	integr - the integrand for countrate (optional)
; HISTORY
;	05Feb23 - rcb  (cf. synphot.pro)
;	07feb15 - add effective wavelength optional output
;	07mar7  - allow vector shifts
;	07mar8  - add wfltr,integr to output options for use in filtshft.pro
;	11may19 - update for Jen's 2009 thruputs w/ my 2007 QE included.
;	11may19 - add time to input
;	11aug17 - add keywords to shift only the short or long WL edges
;	11aug30 - Shifting total ThruPut NOT equiv to shifting filter. See
;		doc.thruput. Mod to shift filter per f435wshft.pro and remove
;		the short & long edge shifting, which uses the TP & was not
;		of much use anyhow.
;	11sep1-shifted F435W: saved as dat/*f435w*.2011-shftonly per doc.thruput
;	11sep16-implement the new dat/*2011 TP ascii files for stdphot*qe3 files
;			See doc.thruput COOKBOOK and Logic for details.
;	11nov7-Put long WL edge shift back, as that is what ACS filters show.
;	12jul2-Read MAIN vectors wfltr,tfltr into common to speed findmin.pro
;	15jul9-Runs only in photom/calib or other dir 2 levels from top, because
;		of no ~ on rcblnx. For calib/photom/findmin.pro
;	15aug21-above jul15 is NG. Need to run in acssens, so fix to look for
;		files 1 level from top, if none found at 2 levels up.
;	15Dec21-update to 2015 TP files
;	15Dec21-change from orig to current filter (eg *.2011) to match syst TP
;		(eg *.2011) for purposes of computing TP for a filter shift.
;	16apr5-revise to interpol to fine WL grid of the system TP, instead of
;		the coarse (esp. wings) of filter WL grid. F435W  is 0.6% less
;		for  100A shift. But for F814 fix below, was a no-op, because
;		F814W is already on a finely sampled (0.5A) grid. See qefix.pro.
;	16apr6-add version=year of total TP files for pubshift & filtshft.pro
;
; MAIN VECTORS
;	wfltr,tfltr - total sys thruput (TP). 2011 update per ISR-IV is default.
;	wfltr,tfltr - total sys thruput (TP). 2015 pub update is new default.
;	worg,torg   - Filter thruput, if any shift is specified. Default was
;		updated transm for any shifts and norm from 2011-12 recal work;
;		BUT fix 2012Jan30 to use orig /grp...CDBS files w/ NO cam in the
;		file name so this should work even after new deliveries.
;		(if I ever want to do shifts in the future.)
;-

common acsbp,fsbc,wsbc,tsbc,fhrc,whrc,thrc,fwfc,wwfc77,twfc77,wwfc81,twfc81
if n_elements(fsbc) eq 0 then begin
	fsbc=['f115lp','f122m','f125lp','f140lp','f150lp','f165lp']
	wsbc=fltarr(10000,6)  &  tsbc=wsbc
	dir='../../acssens/dat/'
	fil=findfile(dir+'sbc*.dat',count=nfils)
	if fil(0) eq '' then begin
		dir='../acssens/dat/'
		fil=findfile(dir+'sbc*.dat',count=nfils)
		if fil(0) eq '' then stop		; & fix again
		endif
	for ifil=0,nfils-1 do begin
		readcol,fil(ifil),wfltr,tfltr,format='d,d',silent=silent
		wsbc(*,ifil)=wfltr
		tsbc(*,ifil)=tfltr
		endfor

	fhrc=['f220w','f250w','f330w','f344n','f435w','f475w','f502n','f550m', $
       'f555w','f606w','f625w','f658n','f660n','f775w','f814w','f850lp','f892n']
	whrc=fltarr(10000,17)  &  thrc=whrc
	vers='2015'						; default
	if keyword_set(version) then vers=version
	fil=findfile(dir+'hrc*.'+vers,count=nfils)		; 2016apr6
	for ifil=0,nfils-1 do begin
		readcol,fil(ifil),wfltr,tfltr,format='d,d',silent=silent
		whrc(*,ifil)=wfltr
		thrc(*,ifil)=tfltr
		endfor

	fwfc=['f435w','f475w','f502n','f550m','f555w','f606w','f625w',	$
			'f658n','f660n','f775w','f814w','f850lp','f892n']	
	wwfc77=fltarr(10000,13)  &  twfc77=wwfc77
	wwfc81=wwfc77  &  twfc81=wwfc77
 	fil=findfile(dir+'wfc*77.'+vers,count=nfils)		; 2016apr6
	for ifil=0,nfils-1 do begin
		readcol,fil(ifil),wfltr,tfltr,format='d,d',silent=silent
		wwfc77(*,ifil)=wfltr
		twfc77(*,ifil)=tfltr
		file=replace_char(fil(ifil),'_77','_81')
		readcol,file,wfltr,tfltr,format='d,d',silent=silent
		wwfc81(*,ifil)=wfltr
		twfc81(*,ifil)=tfltr
		endfor
	endif				; end population of common
camlow=strlowcase(cam)
if camlow eq 'sbc' then begin
	ifilt=where(strlowcase(filt) eq fsbc)
	wfltr=wsbc(*,ifilt)
	tfltr=tsbc(*,ifilt)
	endif
if camlow eq 'hrc' then begin
	ifilt=where(strlowcase(filt) eq fhrc)
	wfltr=whrc(*,ifilt)
	tfltr=thrc(*,ifilt)
	endif
if camlow eq 'wfc' then begin
	ifilt=where(strlowcase(filt) eq fwfc)
; 2011sep16 - My new qe3 TPs for 2002.16,-77k OR 2006.5,-81K:
	if time le 2006.5 then begin
		wfltr=wwfc77(*,ifilt)
		tfltr=twfc77(*,ifilt)
	     end else begin
		wfltr=wwfc81(*,ifilt)
		tfltr=twfc81(*,ifilt)
	     	endelse
	endif
st=''

if keyword_set(qefil) then if qefil eq 'qe2' then begin		; 2012jan30
; Jen's 2009 qe2 TPs, eg. to remake old stdphot*qe2 output:
	fil=dir+strlowcase(cam+'1_'+filt+'_77')+'.dat'	; WFC
	if time gt 2006.5 then 							$
		fil=dir+strlowcase(cam+'1_'+filt+'_81')+'.dat'
	if camlow eq 'hrc' then fil=dir+strlowcase(cam+'_'+filt)+'.dat'
	if not keyword_set(silent) then print,'***THRUPUT FILE ***  ',fil
	readcol,fil,wfltr,tfltr,format='d,d',silent=silent	; total TP
	endif

; check to see if a qe curve is specified
if n_elements(qe) gt 0 then begin
;2003 deMarchi	qecdbs='../../acssens/dat/acs_wfc_ccd1_017_syn.fits'
; ....	if camlow eq 'hrc' then qecdbs='../../acssens/dat/acs_hrc_ccd_011_syn.fits'
	qecdbs='/grp/hst/cdbs/comp/acs/acs_wfc_ccd1_019_syn.fits' ;2007 QE
stop ; and update to my new QE curves of 2011sep16
	if camlow eq 'hrc' then 					$
		qecdbs='/grp/hst/cdbs/comp/acs/acs_hrc_ccd_013_syn.fits' ;2007QE
	z=mrdfits(qecdbs,1,h)
	wlqe=z.wavelength
	qeorig=z.(2)				;  See ckcdbs.pro -77C 
	if time gt 2006.5 and camlow eq 'wfc' then qeorig=z.(3)	; -81C
	good=where(wlqe ge 3000-1300*(camlow eq 'hrc') and qeorig gt 0)
	wlqe=wlqe(good)  &  qeorig=qeorig(good)
	if n_elements(qe) ne n_elements(qeorig) then stop	; idiot ck.
	qechng=qe/qeorig
	linterp,wlqe,qechng,wfltr,qerat
	tfltr=tfltr*qerat
	endif
	
; use WL of TP for integral & if stellar wav does not cover wfltr, set missing=0
linterp,wav,flux,wfltr,fstar,missing=0

;	A(OTA)=45,239 cm2 from ACS Instr Handbook 6.2.1
;	hc=6.626e-27*3e18

; 07Feb19 as i do NOT have 1A grid, do special test on 1A grid:-->same answers!
;;w1=findgen(fix(max(wfltr)-wfltr[0]))+fix(wfltr(0))
;;linterp,wfltr,tfltr,w1,t1
;;linterp,wav,flux,w1,f1
;;countrate=45239.*integral(w1,w1*f1*t1,w1(0),max(w1))/(6.626e-27*2.998e18)
;;effwav=integral(w1,w1^2*f1*t1,w1(0),max(w1))/integral(w1,w1*f1*t1,w1(0),max(w1))
;;print,'special test countrate & effwl=',countrate,effwav

if not keyword_set(shft) then shft=0
if keyword_set(shft) or keyword_set(leshift) then begin
; case of FILTER shifts:
; ###change for old QE2 files and remake of Fig 3 for ISR IV.
;2015dec  ffilin=findfile('/grp/hst/cdbs/comp/acs/acs_'+			$
;				strlowcase(filt)+'_00*_syn.fits',count=nfil)
;current system TP below means I must start w/ curr filter TP, per QEfix
	ffilin=findfile('/grp/hst/cdbs/comp/acs/acs_'+			$
			strlowcase(filt)+'_'+camlow+'*syn.fits',count=nfil)
	ffilin=ffilin(nfil-1)
	z=mrdfits(ffilin,1,h)
	worg=z.wavelength				; orig filter
	torg=z.throughput				; transm
	print,'***FILTER FILE ***  ',ffilin
	endif
nshft=n_elements(shft)
countrate=fltarr(nshft)  &  effwav=countrate
torig=tfltr					; orig system TP
for ishft=0,nshft-1 do begin			; vector for Fig 9 ISR 2007-06
  tfltr=torig					; 2016apr6 fix
  if shft[ishft] ne 0 then begin
; corrected filter on orig WL scale
;old	linterp,worg+shft[ishft],torg,worg,tnew,missing=0
	linterp,worg,torg,wfltr,tprev,missing=0			; 2016apr5
	linterp,worg+shft[ishft],torg,wfltr,tnew,missing=0	; 2016apr5
	tnew(0)=0
	tnew(n_elements(tnew)-1)=0
	good=where(tprev gt 0)				;catch the zeros
	corr=tnew*0.
	corr(good)=tnew(good)/tprev(good)		; on fine TP WL scale
	tfltr=torig*corr				;  end 2016apr5 changes
;old	good=where(torg ne 0)				;catch the zeros
;	corr(good)=tnew(good)/torg(good)	; the filter corr w/ filt WLs
;	linterp,worg,corr,wfltr,corrlin,missing=0	; corr w/ TP WLs
; adjust system TP. Non-zero corr, where torg=0, are already 0 in torig.
;	  corr CURRENT system TP means I need to shift curr filt TP per qefix
;	tfltr=torig*corrlin				; new system TP
	endif
if keyword_set(leshift) then begin			; Long Edge shift
	linterp,worg,torg,wfltr,tprev,missing=0			; 2016apr5
	linterp,worg+leshift,torg,wfltr,tnew,missing=0
	ipkold=where(torig eq max(torig))  &  ipkold=ipkold(0)
	tnew(0:ipkold)=tprev(0:ipkold)			; keep orig at short WL
	tnew(n_elements(tnew)-1)=0
	good=where(tprev gt 0)
	corr=tnew*0.					; catch the zeros
	corr(good)=tnew(good)/tprev(good)		; the filter correction
	tfltr=torig*corr				; adjust system TP
	endif
; use fine WLs of TP for integral & if wav does not cover wfltr, set missing=0
  linterp,wav,flux,wfltr,fstar,missing=0
  integr=wfltr*fstar*tfltr

  countrate[ishft]=45239.*integral(wfltr,integr,wfltr(0),	$
  					max(wfltr))/(6.626e-27*2.998e18)
  effwav[ishft]=integral(wfltr,wfltr^2*fstar*tfltr,wfltr(0),max(wfltr))/$
		integral(wfltr,wfltr*fstar*tfltr,wfltr(0),max(wfltr))
  endfor
; convert simple cases to scaler:
if nshft eq 1 then begin  &  effwav=effwav[0]  &  countrate=countrate[0]  &  end 
if keyword_set(plt) then begin
	pset
	!xtitle='WL (Ang)'
	!ytitle='FLUX & '+cam+' '+filt+' Throughput'
	good=where(tfltr ge .001)
	plot,wfltr(good),fstar(good)>0
	indx=where(tfltr eq max(tfltr))  &  indx=indx(0)
	oplot,wfltr,tfltr*max(fstar[good])/tfltr(indx),lines=1
	plotdate,'synacs'
	if !d.name eq 'X' then read,st
	endif

; check to see if spectrum covers max of filter:
indx=where(tfltr eq max(tfltr))  &  indx=indx[0]
if wfltr[indx] le min(wav) or wfltr[indx] ge max(wav) then begin
	print,'*synacs-WARNING***',filt,' Out of range. ***SYNACS e-/s set to -'
	effwav=0
	return,-countrate		; 07mar23 - lower lim to count rate
	endif

; check that the spectrum covers enough of the filter:
frst=ws(wfltr,wav(0))
last=ws(wfltr,max(wav))
;if tfltr(frst) gt 0.02*max(tfltr) then begin
if tfltr(frst) gt 0.055*max(tfltr) then begin		; for shifted F850LP
	print,'***synacs-WARNING***First wavelength of spec. too big:',	$
							filt,wfltr(frst)
	effwav=0
	return,-countrate
	endif
if tfltr(last) gt 0.01*max(tfltr) then begin
	print,'***synacs-WARNING*** last wavelength of spec. too small:',$
							filt,max(wav)
	stop
	return,-countrate
	endif
	
return,countrate
end
