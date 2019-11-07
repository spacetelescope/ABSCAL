PRO nicadd,lst,titl,wav,ctrate,flux,poierr,scaterr,npts,wgt,gross,bkg,	$
	exptim,temps,corr=corr
;+
; PURPOSE:
;	NICMOS COADDING PROGRAM TO CORRESPOND TO stisadd
; CALLING SEQUENCE:
;	NICADD,lst,TITL,Wav,CTRATE,FLUX,poierr,scaterr,npts,wgt,gross,bkg,
;							exptim,corr=corr
; INPUT:
;	lst-ASCII LIST OF ROOTNAMES TO BE COADDED
;	corr-keyword =1 ---> correct for non-linearity
; OUTPUT:
;	TITL-a story
;	Wav-WAVELENGTH
;	CTRATE-AVERAGED COUNTRATE weighted by 1/sigpoi^2
;	FLUX-AVERAGE FLUX weighted by exposure 1/""""
;	poierr-PROGAGATED Poisson UNCERTAINTY in the mean net ctrate (flux unit)
;	scaterr-UNCERTAINTY in the mean net from scatter among dithers (......)
;	NPTS-ARRAY OF TOTAL POINTS COADDED for flux array
;	wgt - total wgt for ea point = sum of obs {sum(1/sigpoi^2) is NG}
;	gross & bkg from raw, ie NO FF
;	exptim - exposure time in sec
;	temps  - array of temperatures, corresponding to list.
; HISTORY:
; 05mar - modified from stisadd BY R. C. BOHLIN
; 05mar18-use propagated stat wgts for coadd.
; 06mar6 - try realistic sigmea, error in the means, NG for small # dither obs.
;	- usually exp times are ~ same. Just use 1 for weights.
; 06aug13 - add exptim
; 06aug15 - try using new exptimes for weighting point by point.
; 06dec18 - try weights by avg signal over all wls--> same as pt-by-pt.
; 06dec19 - unit wgt for p041c only
; 08oct7  - add temps to the output
;-
st=''
siz=size([lst])
num=siz(1)
temps=fltarr(num)

;INITIALIZE COADDED QUANTITIES
mnepoch=''
mxepoch=''

;MAIN LOOP
	for i=0,num-1 do begin
		idlist=lst(i)			; idl oddity workaround
		nicflx,idlist,wl,flx,ct,gros,bk,sigdum,sigpoi,sigmea,	$
					npt,extm,temper,corr=corr
		temps(i)=temper
		npx=n_elements(wl)
		if i eq 0 then begin
			wav=wl				; final WLs=first spec.
			dlam=(wav(npx-1)-wav(0))/(npx-1)	;a/px
			ctrate=dblarr(npx)
			poierr=ctrate
			scaterr=ctrate
			npts=ctrate
			wgt=0					; 06dec18
			flux=ctrate
			gross=ctrate
			bkg=ctrate
			exptim=ctrate
		     end else begin
; 06dec12 -snap-2 g206 spectra are diff by 2.8 dbl px before corr and 3.8 after!
;		see nicdoc/wl.scales (other cases are w/i 2 below)
			if abs(wl(0)-wav(0))/dlam gt 4 then begin
                      		print,'**WARNING** > 4px shift. BEG '+	$
							'WLs ARE ',wl(0),wav(0)
				print,'STOP IN NICADD for ',idlist
; Nor has G206 a tad too close to edge in na5105 P330E
				if strpos(idlist,'na5105') lt 0 then stop
				endif
			linterp,wl,ct,wav,ct
			linterp,wl,flx,wav,flx
			linterp,wl,sigpoi,wav,sigpoi
			linterp,wl,sigmea,wav,sigmea
			linterp,wl,npt,wav,npt
			linterp,wl,gros,wav,gros
			linterp,wl,bk,wav,bk
			linterp,wl,extm,wav,extm
			endelse				;for 2nd and ff spectra
; NG for 3 dithers		if min(sigmea) le 0 then stop
; .......		wt=1/sigmea^2
; 06aug15		wt=npt*0+1			;06mar6 - npt has zeros in HD209
;		wt=extm
; 06dec19	
		wt=avg(ct*extm)
		if strpos(idlist,'p041c') ge 0 then wt=1.
		if wt eq 1. then print,'Weight=1 for ',idlist
		pos=strpos(!mtitle,'   ')
		epoch=strmid(!mtitle,pos+3,10)
		if mnepoch eq '' then mnepoch=epoch
		if epoch lt mnepoch then mnepoch=epoch
		if epoch ge mxepoch then mxepoch=epoch
; 06aug15 ff lines could be streamlined. HD209458 has no zero exptimes.
;		tindex=where(wt gt 0)		; could del, if no zero wt vals
;		ctrate(tindex)=ct(tindex)*wt(tindex)+ctrate(tindex)
;		flux(tindex)=flx(tindex)*wt(tindex)+flux(tindex)
;		wgt(tindex)=wt(tindex)+wgt(tindex)
; see bevington p. 73 for proper formula
;		poierr(tindex)=1/sigpoi(tindex)^2+poierr(tindex)
;		scaterr(tindex)=1/sigmea(tindex)^2+scaterr(tindex)
;		npts(tindex)=npt(tindex)+npts(tindex)
;		gross(tindex)=gros(tindex)*wt(tindex)+gross(tindex)
;		bkg(tindex)=bk(tindex)*wt(tindex)+bkg(tindex)
;		exptim(tindex)=extm(tindex)+exptim(tindex)

		ctrate=ct*wt+ctrate
		flux=flx*wt+flux
		wgt=wt+wgt
; see bevington p. 73 for proper formula
		poierr=1/sigpoi^2+poierr
		scaterr=1/sigmea^2+scaterr
		npts=npt+npts
		gross=gros*wt+gross
		bkg=bk*wt+bkg
		exptim=extm+exptim

		endfor			; end main loop

;compute averages

; trim outputs to the size of good data
index=where(exptim*npts gt 0)
; 2016aug29 - all points look OK for HD189733:
if strpos(idlist,'189733') ge 0 then index=where(exptim*npts ge 0)
ctrate(index)=ctrate(index)/wgt
flux(index)=flux(index)/wgt
index=where(poierr gt 0)
poierr(index)=1./sqrt(poierr(index))
scaterr(index)=1./sqrt(scaterr(index))
gross(index)=gross(index)/wgt
bkg(index)=bkg(index)/wgt

; ??08nov6 delete exptim=exptim(index)  NAN in poierr is neither <0 or >=0
; convert from count rate to flux errors:
good=where(ctrate ne 0)
fnrat=flux*0
fnrat(good)=flux(good)/ctrate(good)		; flux/net 
poierr=poierr*fnrat
scaterr=scaterr*fnrat
;make title
fdecomp,lst(0),disk,dir,targnam,ext
grat=strupcase(strmid(ext,0,4))
titl=targnam+' '+grat+' Epoch: '+mnepoch+' to '+mxepoch
;redundant & too long for calspec 06aug3 +'  '+string(num,'(i2)')+' obs'
if corr eq 0 then titl=' NO linearity corr. '+titl else     		$
		  titl=' Corr. for non-linearity '+titl
print,titl
return
end
