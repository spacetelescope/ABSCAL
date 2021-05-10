PRO stisADD,lst,HEAD,TITLE,EXP,Wav,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL,    $
 			sctval=sctval,scterr=scterr,dith=dith
;+
; NAME:
;       stisADD
; PURPOSE:
;	stis READING AND COADDING PROGRAM TO CORRESPOND TO fosadd
; CALLING SEQUENCE:
;	stisADD,lst,HEAD,TITLE,EXP,Wav,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL, $
;			sctval=sctval,scterr=scterr
; INPUT:
;	lst-ASCII LIST OF ROOTNAMES TO BE COADDED
;	dith-optional but assume dither pattern is 'STIS-ALONG-SLIT'
; OUTPUT:
;	HEAD-HEADER FOR LAST OBS SET
;	TITLE-CONSTRUCTED FROM HEAD, incl avg radial vel.
;	EXP-TOTAL EXPOSURE TIME OF COADDED DATA
;	Wav-WAVELENGTH
;	CTRATE-AVERAGED COUNTRATE weighted by exposure time
;	FLUX-AVERAGE FLUX weighted by exposure time
;	FLXERR-PROGAGATED FLUX STATISTICAL UNCERTAINTY
;	NPTS-ARRAY OF TOTAL POINTS COADDED for flux array
;	TIME-ARRAY OF TOTAL EXP TIME PER POINT in counts array
;	QUAL-(1=GOOD, 0=BAD), BASED ON ALL DATA QUALITY FLAG GE 175 IS BAD.
;	sctval-value of any scattered light subtraction (counts/sec)-scalar
;	scterr-uncertainty in sctval-a scalar
; HISTORY:
; 97jul25-WRITTEN BY R. C. BOHLIN
; 97aug1  - use linterp to account for different stretches of wl scales and 
;		WL shifts between obs 
; 97aug20 - drop flxer condition for good data to get all of the NET, @flx=0
; 97aug21 - no-abs-cal quality is 251. keep data, but set qual=0 here.
; 97dec9  - add avg radial veloc to title
; 98mar2  - omit 1st and last 2 points of each spectrum
; 98jun9  - for extr hgt >99, accept data ql of 252=unrepairable hot px.
; 98jul17 - add time & temp correction to stisflx call
; 99may7  - use wl scale of first spectrum in list. warn if any spectrum is 
;	       >10 pts off. Stop if >17 pts off. (might want to rearrange list.)
; 99jun18 - keep new blemish flag=175 in coadd, just set ql=0
; 99jun22 - Drop extra 1% for FF in calc of statistical flxerr (ccd is <0.1%),
;	even tho don does NOT propagate FF stats to spectral stat err. I could/
;	should put a frac of % in for MAMAs.
; 99sep15 - compute net,flx for hot px (180), & ql=1. OK for GRW-fuv-mama. CCD?
; 00apr6 - verified stat flxerr is just the resamp. value, which is wrong
;	locally; but ok globally for averages of points.
; 02apr4 - put in skip for G140 obs @ +3" after 1999.2
; 02jun7 - try keeping flux for all qual=252, unrepairable hot px.
; 02sep3 - remove nop3m3 keyword, now that L-flat is used for G140L
; 04mar9 - add epoch range to the output Header (head) 
; 15jun15-add dither capability for 2 or more spectra. See also step2_combine.
;	try assuming photometric dithers, so skip the normalization step.
;	Also cannot have diff WL shifts among dithers. No CR-reject here.
; 17jan26 - Major upgrade to rm 0 fluxes in hd189733 ht-11 --> no change in Vega
;	But Basically back to old version....!!!
; 19aug23 - Recover negative fluxes, that were zeroed per flxerr=0.
;-
IF N_PARAMS(0) EQ 0 THEN BEGIN
PRINT,'stisADD,lst,HEAD,TITLE,EXP,Wav,CTRATE,FLUX,FLXERR,NPTS,TIME,QUAL',  $
		',sctval=sctval,scterr=scterr'
	RETALL
	ENDIF
st=''
SIZ=SIZE([lst])
NUM=SIZ(1)

;INITIALIZE COADDED QUANTITIES
sctval=0
scterr=0
EXP=0
mnepoch=''
mxepoch=''
if keyword_set(dith) then begin			;initialize for dithered data
	dflux=fltarr(1024,num)  &  derr=dflux
	for i=0,NUM-1 DO BEGIN
		stisflx,lst(i),head,wl,flx,ct,gross,blo,bup,ql,flxer
		dflux(*,i)=flx
		derr(*,i)=flxer
		endfor
	minflx=min(dflux,dim=2)>1e-18
	minerr=min(derr,dim=2)
	bad=where(minerr le 0,nbad)
	if nbad gt 0 then minerr(bad)=max(minerr)
	maxdif=1.414*minerr*4	; expected diff btwn 2 spectra @ 4 sigma
	endif

;MAIN LOOP
	FOR I=0,NUM-1 DO BEGIN
;98jul17-time,temp corr to flx & net. flx recomputed from corrected net.
		idlist=lst(i)			; IDL oddity workaround
		dum=mrdfits(idlist,1,hdr,/silent)
		indx=where(strpos(hdr,"= 'A2CENTER") ge 0,nstsci)
		if nstsci eq 0 then					$
		   stisflx,idlist,head,wl,flx,ct,gross,blo,bup,ql,flxer,/ttcor $
; ff case of MAST X1 file, do not correct, at least for Xcal project-2019jun11
		  else  stisflx,idlist,head,wl,flx,ct,gross,blo,bup,ql,flxer
		lst(i)=idlist		; B put in by stisflx!
		if strmid(lst(i),0,1) eq 'B' then begin
			print,lst(i),' at +3" after 1999.2. Skipping.'
;			if strpos(idlist,'o5jj99030') lt 0 then read,st
			goto,skipit
			endif
		expflg=strtrim(sxpar(head,'EXPFLAG'),2)		; 2017jan28:
		if expflg ne 'NORMAL' then begin
			print,expflg,' exposure. Skipping ',idlist
			targnam=strtrim(SXPAR(HEAD,'targname'),2)
			if strpos(targnam,'189733') lt 0 then stop else	$
								goto,skipit
			endif
; temp listing for findfringe cases:
		ifrng=where(strpos(head,'FINDFRINGE') gt 0)
	if ifrng(0) gt 0 then print,'#####$$$$$*****&&&&@',lst(i),head(ifrng)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		npx=n_elements(wl)
; Flag 1st & last 4 pts; BUT do not change size of array, as Tung flat is 1024px
; 2017jan26 - 254 --> 251
		ql(0:3)=251      &  ql(npx-4:npx-1)=251	; keep data but qual=0
		flx(0:3)=0.  &  flx(npx-4:npx-1)=0.	; to be safe
		flxer(0:3)=0.  &  flxer(npx-4:npx-1)=0.	; to be safe
		if i eq 0 then begin		;initialize arrays to 0
			wav=wl			; master WLs
			dlam=(wav(npx-1)-wav(0))/(npx-1)	;A/px
			CTRATE=dblarr(npx)
			FLXERR=CTRATE
			NPTS=FIX(CTRATE)
			TIME=CTRATE
;2019aug			flxtim=ctrate	; 98jul3 - exptime for calib pts
			QUAL=BYTE(CTRATE)
			flux=ctrate
			radvel=0
		     end else begin
			if abs(wl(0)-wav(0))/dlam gt 10 then 		$
                      print,'**WARNING** > 10px shift. BEG WLs ARE',wl(0),wav(0)
;02dec22-o3zx08hlm & O4VT10ZYQ ..........17.2px =26.2A G230L GD153
;023may6-o3zx08hlm & O4VT10ZYQ ..........17.7px =27.4A G230L GD153
			if abs(wl(0)-wav(0))/dlam gt 17.8 then begin
				print,'STOP IN STISADD'
				stop
				endif
			linterp,wl,ct,wav,ct,missing=0
			linterp,wl,flx,wav,flx,missing=0
;hope qual has flags for missing data (flxer=0)... just interp stat error - ok!
			linterp,wl,flxer,wav,flxer,missing=0
; proper qual fix for interpolated data:
			indxwav=where(wav ge wl(0) and wav le wl(npx-1))
			tabinv,wl,wav(indxwav),wlind	;frac indices in wl
			loind=fix(wlind)  &  hiind=fix(wlind+1)
			qltmp=fltarr(npx)+255      	;NG=255 initially
			qltmp(round(indxwav))=ql(loind)>ql(hiind)
			ql=qltmp
			endelse				;for 2nd and ff spectra
		EX=sxpar(head,'exptime')
		EXP=EXP+EX
		epoch=sxpar(head,'pstrtime')
		if mnepoch eq '' then mnepoch=epoch
		if epoch lt mnepoch then mnepoch=epoch
		if epoch gt mxepoch then mxepoch=epoch
		det=strtrim(sxpar(head,'detector'),2)
		if det ne 'CCD' then begin
			Q180=WHERE(ql eq 180,n180)	;mama hot px ok
			if n180 gt 0 then QL(q180)=0	;mama hot px ok
			endif

; I have 'nosat' flagging set in my preproc CALstis call but dblck here:
		dblck=where(ql eq 190,nqual)
		if nqual gt 0 then stop

;The error for 0 counts is set to the sqrt(1) = 1.0.
;An error of 0.0 should only occur at undefined data points. ---Don 
; 02jun7 - 252, unrepair hot px is ok for ngc6681-7.g430L & wide exhgt
		qndx=where(ql eq 252,nqual)
		if nqual gt 0 then ql(qndx)=0

;2017jan26- MAJOR OVERHAUL to keep all bad data (+good, if any)
; & avoid 0's in net and flux. lv the rest of 0's as flags, eg HD189733
;	as the problem for hd189733-oc3301.g430l, try the ff:
;keep zero sens (251) for net, where flxer must be 0.
;Reset qual=0 pts, if new pt is good (<175) but was bad. FAILS as just one 
;	"good" can sneak in and make a noise pt.
; Also failing is to exclude the bad eg 175,if some are good->makes ~1% glitches
		tINDEX=WHERE(ql le 180) ; keep all bad
		if keyword_set(dith) then tINDEX=			$
			WHERE(ql le 180 and abs(flx-minflx) lt maxdif)
		CTRATE(tINDEX)=CT(tINDEX)*EX+CTRATE(tINDEX)	;wgt by exp time
		TIME(tINDEX)=TIME(tINDEX)+EX
		FLUX(tINDEX)=FLX(tINDEX)*ex+FLUX(tINDEX)	; keep flux<0
; see Bevington p. 73 for proper formula. Avoid div by 0:
		tINDEX=WHERE((ql le 180 and flxer gt 0))	;avoid div by 0
		if keyword_set(dith) then tINDEX=WHERE(ql le 180 and	$
			flxer gt 0 and abs(flx-minflx) lt maxdif) 
;2019aug		flxTIM(tINDEX)=flxTIM(tINDEX)+EX
		flxer(tindex)=1./FLXER(tINDEX)^2		 ;invert
		FLXERR(tINDEX)=flxer(tindex)+FLXERR(tINDEX)
;2019aug		FLUX(tINDEX)=FLX(tINDEX)*ex+FLUX(tINDEX)
		radvel=radvel+ex*(-sxpar(head,'earthvel')) ; star vel NOT incl
;  2017jan29-Use npts to flag motes (175) as bad, but keep hot px(180) as OK:
		tINDEX=WHERE((ql LT 175 or ql eq 180) and flxer gt 0)
		if keyword_set(dith) then tINDEX=			$
		   WHERE((ql lt 175 or ql eq 180) and flxer gt 0	$
		   and abs(flx-minflx) lt maxdif)
		NPTS(tINDEX)=NPTS(tINDEX)+1

;MAKE QUAL=1, IF EVER HIT ANY "GOOD" DATA: (zero sens (251) will be bad.)
; 99sep15 - use motes (ql=175) & hot px (180), keep flag both flags=0 as bad:
		QUAL(WHERE(QL LT 175))=1
skipit:
		ENDFOR			; END MAIN LOOP
; 99jun18 - set qual bad for points that are less than half populated:
index=where(npts/float(max(npts)) lt 0.5,nbad)
if nbad gt 0 then qual(index)=0		; except G230L+LB combined elsewhere

;COMPUTE AVERAGES

; trim outputs to the size of good data, i.e where time>0 AND flxerr>0
;INDEX=WHERE((time GT 0) and (FLXERR GT 0))
INDEX=WHERE(time GT 0)			       ;97aug20-try to recover full net
if n_elements(wav) ne 1024 then stop		; 99may7 - idiot ck
CTRATE(index)=CTRATE(INDEX)/TIME(index)
FLUX(index)=FLUX(INDEX)/time(index)
;2019aug INDEX=WHERE(flxtim GT 0)
; 2019aug FLUX(index)=FLUX(INDEX)/flxtim(index)
INDEX=WHERE(FLXERR GT 0)
FLXERR(index)=1./SQRT(FLXERR(index))
radvel=radvel/exp

;MAKE TITLE
targnam=strtrim(SXPAR(HEAD,'targname'),2)
cenwav=strtrim(SXPAR(HEAD,'cenwave'),2)
GRAT=STRUPCASE(STRTRIM(SXPAR(HEAD,'opt_elem'),2))
sxaddhist,'EPOCH: '+mnepoch+'-'+mxepoch,head
dum=where(strmid(lst,0,1) ne 'B',num)			; 02apr4
;02jun4-TITLE=TARGNAM+' '+GRAT+'-'+cenwav				$
TITLE=' '+GRAT+'-'+cenwav						$
 +' TOT exp for '+STRING(NUM,'(I3)')+' OBS='+STRING(EXP,'(f8.1)')+'sec'+  $
 ' Avg * heliocen. vel='+string(radvel,'(f7.2)')
helio=strtrim(sxpar(head,'helio'),2)
if helio eq '1' then title=title+' Corrected' else title=title+' NOT Corr.'
print,title
RETURN
END
