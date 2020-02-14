PRO wfcADD,lst,HEAD,TITLE,Wav,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL,input=input
;+
; NAME:
;       wfcADD
; PURPOSE: COADDING on fixed WL grid covering 3 grating orders.
; CALLING SEQUENCE:
;	wfcADD,lst,HEAD,TITLE,Wav,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL
; INPUT:
;	lst-ASCII LIST OF ROOTNAMES TO BE COADDED. Normally ''
; OUTPUT:
;	HEAD-HEADER FOR LAST OBS SET
;	TITLE-CONSTRUCTED FROM HEAD, incl avg radial vel.
;	Wav-WAVELENGTH
;	CTRATE-AVERAGED COUNTRATE & corr for time change, ie sum(cts)/sum(exptm)
;	FLUX-AVERAGE FLUX weighted by exposure time
;	FLXERR-PROGAGATED FLUX STATISTICAL UNCERTAINTY
;	NPTS-ARRAY OF TOTAL POINTS COADDED for flux array
;	TIME-ARRAY OF TOTAL EXP TIME PER POINT in counts array
;	QUAL-(1=GOOD, 0=BAD), BASED ON ALL DATA QUALITY FLAG non-zero IS BAD.
;		see doc/dq.html
;       input - special subdir option. Normally not specified.
; HISTORY:
; 2018jun13-adapted from stisadd.pro - R. C. BOHLIN
; 2018jun28 - include 1st order flux in output.
; 2018jul17 - add time corr & /noflux to avoid extra interpol in wfcflx
;-

IF N_PARAMS(0) EQ 0 THEN BEGIN
PRINT,'wfcADD,lst,HEAD,TITLE,Wav,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL'
	RETALL
	ENDIF
st=''
SIZ=SIZE([lst])
NUM=SIZ(1)

;INITIALIZE COADDED QUANTITIES
; Use std WL arrays that cover -1 to +2 orders and oversample a bit:
w102=[findgen(326)*16-12200,findgen(1088)*16+7000]; -7000 to 24392
w141=[findgen(361)*25-18000,findgen(881)*25+9000] ;-9000 to 31000 (3rd @~32000)
mnepoch=''
mxepoch=''
; match dq flagging in wfc_coadd and see doc/dq.html
;512 & 32 OK per icqv02i3q RCB 2015may26, 16 hot px ok for brite *.
flags=(4+8+64+128+256)

;MAIN LOOP
	FOR I=0,NUM-1 DO BEGIN			; num of spectra to co-add
		idlist=lst(i)			; IDL oddity workaround

; flx computed from corrected net at end.
		wfcflx,'spec/'+input+'spec_'+idlist+'.fits',head,wl,dum,ct, $
			gross,bkg,blo,bup,ql,flxer,exptm,/tcor,/noflux

		GRAT=STRUPCASE(STRTRIM(SXPAR(HEAD,'filter'),2))
		expflg=strtrim(sxpar(head,'EXPFLAG'),2)		; 2017jan28:
		if expflg ne 'NORMAL' then begin
			print,expflg,' exposure. Skipping ',idlist
			targnam=strtrim(SXPAR(HEAD,'targname'),2)
			print,targnam,idlist & stop		; and think
			endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		if i eq 0 then begin		;initialize arrays to 0
			wav=w102		; master WLs, dlam=16 or 25A
			if grat eq 'G141' then wav=w141
			npx=n_elements(wav)
			NPTS=intarr(npx)
			QUAL=BYTE(npts)
			CTRATE=dblarr(npx)
			FLXERR=CTRATE
			TIME=CTRATE
			flux=ctrate
			endif
; calib good range of flux, works for 1st order only
		linterp,wl,ct,wav,ct,missing=0		;iterpol onto master WLs
		linterp,wl,exptm,wav,exptm,missing=0
		linterp,wl,flxer,wav,flxer,missing=0	; really net err units
; Fix flx,flxer for discont from 0's to flux units and consequent bad linterp:
;		good=where(flx ne 0)
; del		bad=where(wav gt wl((good(0)-1)>0) and wav lt wl(good(0)),nbad)
;		if nbad gt 0 then begin		; replace w/ 1st good linterp:
;			flx(bad)=flx(bad(-1)+1)  &  flxer(bad)=flxer(bad(-1)+1)
;			endif
;		bad=where(wav gt wl(good(-1)) and wav lt 		$
;			wl((good(-1)+1)<(n_elements(wl)-1)),nbad)
;		if nbad gt 0 then begin		; replace w/ 1st good linterp:
;			flx(bad)=flx(bad(0)-1)  &  flxer(bad)=flxer(bad(0)-1)
;			endif
;if grat eq 'G141' then stop
; proper qual fix for interpolated data:
		wavind=where(wav ge wl(0) and wav le wl(-1))
		tabinv,wl,wav(wavind),wlind	;frac indices in wl
		loind=fix(wlind)  &  hiind=fix(wlind+1)
		qli=fltarr(npx)		   ; initialize as all pipeline good=0
		ql=ql and flags		   ; most bad ql are OK. elim 16 etc.
		qlflg=ql*0+1		   ; conv from 0=good to 1=good
		bad=where(ql gt 0)
		qlflg(bad)=0
		qli(round(wavind))=qlflg(loind)>qlflg(hiind)	;2018jul9

		epoch=strtrim(sxpar(head,'pstrtime'),2)
		if mnepoch eq '' then mnepoch=epoch
		if epoch lt mnepoch then mnepoch=epoch
		if epoch gt mxepoch then mxepoch=epoch
		det=strtrim(sxpar(head,'detector'),2)

;The error for 0 counts is set to the sqrt(1) = 1.0.
;An error of 0.0 should only occur at undefined data points. ---Don 
; DQ=1 is good, 0 is bad
;pts of master WLs that are out of range of indiv spec are all zeroed by linterp
; ????????????:
; keep all bad data (+good, if any) 
; & avoid 0's in net and flux. leave the rest of 0's as flags
;Reset qual=0 pts, if new pt is good but was bad. -->FAILS as just one 
;	"good" can sneak in and make a noise pt.
		mask = qli			;mask=1 for good unflagged pix
		tINDEX=WHERE(mask eq 1)
; if npts = 1 good pt, then reset all sums and discard any previously bad flags:
		istgud=where(npts eq 0 and mask eq 1,n1st)
		if n1st gt 0 then begin
			CTRATE(istgud)=0.
			FLXERR(istgud)=0.
			TIME(istgud)=0.
			endif
		NPTS(tINDEX)=NPTS(tINDEX)+1
;MAKE QUAL=1, IF EVER HIT ANY "GOOD" DATA for output result and use by wfcreduce
		QUAL(tindex)=1
; keep bad when npts=0, i.e. when there is no good data:
		tINDEX=WHERE(mask eq 1 or npts eq 0)
				 
;wgt by exp time. see also wfc_coadd for proper treatment of time.  
		CTRATE(tINDEX)=CTRATE(tINDEX)+CT(tINDEX)*exptm(tINDEX)
		TIME(tINDEX)=TIME(tINDEX)+exptm(tINDEX)
; For contam spectra, exptm=0. eg GD71. Set in calwfc_spec	
; see Bevington p. 73 for proper formula. Avoid div by 0:
		tINDEX=WHERE((mask or npts eq 0) and flxer ne 0 and exptm gt 0)
		flxer(tindex)=1./FLXER(tINDEX)^2		 ;invert
		FLXERR(tINDEX)=flxer(tindex)+FLXERR(tINDEX)
;if grat eq 'G141' then stop
;help,i,tindex & stop
		ENDFOR			; END MAIN LOOP for spectral co-add
; set qual bad for points that are less than half populated:
;index=where(npts/float(max(npts)) lt 0.5,nbad)	; NG for WLs of sparse coverage
;if nbad gt 0 then qual(index)=0

;COMPUTE AVERAGES

; trim outputs to the size of good data, i.e where time>0 AND flxerr>0
;INDEX=WHERE((time GT 0) and (FLXERR GT 0))
INDEX=WHERE(time GT 0)			       ;97aug20-try to recover full net
CTRATE(index)=CTRATE(INDEX)/TIME(index)
INDEX=WHERE(FLXERR GT 0)
FLXERR(index)=1./SQRT(FLXERR(index))

; calib net and err array to flux units:
readcol,'~/wfc3/ref/sens.'+strlowcase(grat),wgrid,sens
good=where(wav ge min(wgrid) and wav le max(wgrid))	; should all be good
if n_elements(good) ne n_elements(wgrid) then stop	; idiot ck
flux(good)=ctrate(good)/sens					; cf wfcflx.pro
flxerr(good)=flxerr(good)/sens

;MAKE TITLE
targnam=strtrim(SXPAR(HEAD,'targname'),2)
sxaddhist,'EPOCH: '+mnepoch+'-'+mxepoch,head
TITLE=' '+GRAT+' sum '+STRING(NUM,'(I3)')+' OBS'
print,title
RETURN
END
