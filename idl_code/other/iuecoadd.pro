pro iuecoadd,lst,aper,wav,net,bkg,flux,flxerr,npts,time,		$
		flxout,errout,lstout,correct=correct,silent=silent

; 2012Dec6 - coadd a bunch of IUE MXLO fits files (for revpap)
; do not write output, as I have limited use plans. Use in revpap/stisrat.pro
; 2017dec11 - Add aper & do better dq for Galex newsips project
; 2017dec18 - NEWsips net must be total signal & NOT per unit time.
; 2017dec19-expand ql flags by +/-1px. Reso too narrow & Sat. is insuffic flagd
; 2017dec27 - Reseau flags insufficient. Flag 2 by wavelength.
;
; INPUT:
;	lst-ASCII LIST OF File NAMES TO BE COADDED all for the SAME CAMERA.
;		if there are both L&S apers, then the obs # appears twice.
;	aper - S for small aper, etc. Updated here to rm bad S-ap.
;	correct - to correct fluxes to the CALSPEC scale.
;	silent - to omit plotting of S/L aper comparisons
; Bad files deleted: swp48543, swp55661, lwp19682
; OUTPUT:
;	Wav-WAVELENGTH - for trimmed good pts
;	net-summed COUNTRATE divided by summed exposure time.
;	bkg-background
;	FLUX-AVERAGE FLUX weighted by exposure time
;	FLXERR-PROGAGATED FLUX STATISTICAL UNCERTAINTY
;	NPTS-ARRAY OF TOTAL POINTS COADDED for flux array
;	TIME-ARRAY OF TOTAL EXP TIME PER POINT in counts array
;	flxout,errout - good individual specta used in the result.
;	lstout - List or L-AP images + good S-ap that are coadded
; COMMENT: I should have computed rms among the co-added spectra.
;-
st=''
icam=3
wlbeg=1600.  &  wlend=1725.	; Norm. range per fortran mrgpt.ibm
if strpos(lst(0),'lwp') gt 0 then icam=1
if strpos(lst(0),'lwr') gt 0 then icam=2
if icam lt 3 then begin
;	wlbeg=2235.  &  wlend=2360.  &  endif
	wlbeg=2100.  &  wlend=2500.  &  endif	; 2017dec27 - try for more S/N
lstout=lst  &  aperout=aper
num=n_elements(lst)
FOR i=0,num-1 DO BEGIN
	z=mrdfits(lst(i),0,head,/silent)
	EX=sxpar(head,'Lexptime')  &  flxex=ex
	sexp=sxpar(head,'SEXPTIME')		; S-ap exptime
	slindx=0				; S (1) or L(0) index
	if strtrim(sxpar(head,'aperture'),2) eq 'BOTH' and 		$
		aper(i) eq 'S' then slindx=1
	z=mrdfits(lst(i),1,h,/silent)
	wlzero=z(slindx).wavelength  &  del=z(slindx).deltaw
	npt=z(slindx).npoints
	wl=wlzero+del*indgen(npt)
	ct=z.net  &  ct=ct(*,(slindx))
	bk=z.background  &  bk=bk(*,(slindx))
	flxer=z.sigma  &  flxer=flxer(*,(slindx))
	ql=z.quality  &  ql=ql(*,(slindx))
	flx=z.flux  &  flx=flx(*,(slindx))
	if keyword_set(correct) then begin
		flx=newflxcor(icam,wl,flx)
		flxer=newflxcor(icam,wl,flxer)			;2018jan29
		endif
; 2017dec19-expand ql flags by +/-1px. Reso too narrow & Sat. is insuffic flagd
	shft=shift(ql,1)
	ind=where(ql eq 0 and shft ne 0)
	ql(ind)=shft(ind)
	shft=shift(ql,-1)
	ind=where(ql eq 0 and shft ne 0)
	ql(ind)=shft(ind)
	if i eq 0 then begin
		wav=wl				; master WLs
		net=wl*0
		bkg=net  &  flux=net  &  flxerr=net  &  npts=net  &  time=net
		flxtim=net
; initialize indiviual output arrays:
		flxout=fltarr(npt,num)  &  errout=flxout
;if lst(i) eq 'iuespec/swp22988.mxlo' then stop
		gdout=-1			; # of good indiv. spectra
	   end else begin
		linterp,wl,ct,wav,ct,missing=0
		linterp,wl,flx,wav,flx,missing=0
		linterp,wl,flxer,wav,flxer,missing=0
		indxwav=where(wav ge wl(0) and wav le wl(-1))
		tabinv,wl,wav(indxwav),wlind		;frac indices in wl
		loind=fix(wlind)  &  hiind=fix(wlind+1)
; bad quality expanded. 2017dec13 - ql is neg, so sw from > to < below!
		ql(indxwav)=ql(loind)<ql(hiind)
		endelse
;print,i, ' ',lst(i)  &  read,st

	if aper(i) ne 'S' then begin		; 2017dec11 - rcb norm S to L:
; Force bigger reseau flags for 2 egregious L-ap reso's:
		bad=where((icam eq 3 and wav ge 1787 and wav le 1795)	$
			or (icam eq 1 and wav ge 3044 and wav le 3069),nbad)
		if nbad gt 0 then ql(bad)=-4096		; force reso flag
	     end else begin			; S-ap:
	     	if strpos(lst(i),'swp01528') ge 0 then 			$; HZ43
				ql(where(wav gt 1800))=-9999	; High region
		INDEX=WHERE(time GT 0 and wav ge wlbeg and wav le wlend,ngd)
		if ngd gt 0 then begin
			lnorm=avg(net(INDEX)/TIME(index))	; net-wgtd sum
			snorm=avg(ct(INDEX))/sexp		; fix 2017dec18
			corr=snorm/lnorm			; S=ap transm
			ex=sexp*corr
;so ct in sum below is always just ct but the eff exp time is < recorded, as
;	long as ct rate (net) is just signal. But flux has been boosted, so 
;	exptime in the sum should NOT be boosted, as true ex-wgt is per, 
;	presumably unboosted, ct rate.
;  BUT flx norm works better, maybe because NEWsips net is screwy. USE flx norm.
			print,'Normalization range:',wlbeg,wlend
			print,'NET: Orig,eff Exp times=',sexp,ex,' for ',corr
			flxrat=avg(flx(INDEX))/avg(flux(INDEX)/TIME(index))
; However, norm is best wghted by signal
			flxer=flxer/flxrat
			flx=flx/flxrat
			flxex=sexp*flxrat			; flux exptime
			print,'Flux: Orig,eff Exp times=',sexp,		$
					flxex,' ratio',flxrat
			print,lst(i),' S-ap DN=',sxpar(head,'SDATACNT')
			!mtitle=lst(i)+' '+sxpar(head,'STARGET')
			plt=WHERE(time GT 0)
			flxplt=flux(plt)/TIME(plt)
	    		mx=max(flxplt(45:-40))
			if not keyword_set(silent) then 		$
				plot,wav(plt),flxplt,yr=[0,mx],th=2
			if not keyword_set(silent) then begin
				gdql=where(ql eq 0)
				oplot,wav(gdql),flx(gdql),lin=1
				endif
			timrat=flxex/max(time)
; use S-ap only if > 4.8% of L-ap exp time, unless lots (~10) of spec-2018mar11:
			if (corr lt .22 or sxpar(head,'SDATACNT') lt 50)$
; hd232121 to include LWR1519 at .0488
				    or (timrat lt 0.048 and max(npts)	$
				    lt 10) then begin
				print,'Omitting S-ap. Frac contrib=',timrat
; rm bad S-ap from lst
				good=where(lstout ne lst(i) or aperout ne 'S')
				lstout=lstout(good)  &  aperout=aperout(good)
				if not keyword_set(silent) then read,st
				goto,skipit
				endif
			if not keyword_set(silent) then read,st
		      end else begin
			print,'No points in iuecoadd norm region'  &  stop
			endelse
		endelse						; end S-ap
	tINDEX=WHERE(ql eq 0 and flxer gt 0)	; elim bad data
	net(tINDEX)=CT(tINDEX)+net(tINDEX)	; net is ct, NOt ct/s!
	bkg(tINDEX)=bk(tINDEX)+bkg(tINDEX)
	TIME(tINDEX)=TIME(tINDEX)+flxEX
	if min(flxer(tINDEX)) le 0 then stop		; & consider
	flxer(tindex)=1./FLXER(tINDEX)^2		;invert
	FLXERR(tINDEX)=flxer(tindex)+FLXERR(tINDEX)
	FLUX(tINDEX)=FLX(tINDEX)*flxex+FLUX(tINDEX)
	NPTS(tINDEX)=NPTS(tINDEX)+1
; 2017dec12 - output indiv files
	gdout=gdout+1
	flxout(tindex,gdout)=FLX(tINDEX)
	errout(tindex,gdout)=FLXer(tINDEX)
skipit:
	endfor					; i loop of iue obs

;COMPUTE AVERAGES

; trim outputs to the size of good data, i.e where time>0
INDEX=WHERE(time GT 0)
wav=wav(index)
;if strpos(lst(-1),'lwp03339') ge 0 then stop	; reseaux debugging
net=net(INDEX)/TIME(index)			; conv from FN to FN/t
bkg=bkg(INDEX)/TIME(index)			; conv from FN to FN/t
FLUX=FLUX(INDEX)/time(index)
FLXERR=1./SQRT(FLXERR(index))
npts=npts(index)
time=time(index)

flxout=flxout(index,0:gdout)       ; still leaves some 0's at reseaux, etc.
errout=errout(index,0:gdout)
aper=aperout
dum=gettok(lstout,'/')
end
