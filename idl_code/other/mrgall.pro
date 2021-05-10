; 2018jun12-merge all the spectra for ea star

; cf this line of processing w/ the Lindler line per prewfc.pro, which uses:
;	calwfc_imagepos.pro, wfc_coadd.pro, wfc_wavecal.pro, calwfc_spec.pro
;	wfc_flatscal.pro  wfc_process.pro
; This STIS style uses: wfcmrg.pro, wfcadd.pro, wfcreduce.pro, BUT must still be
;	preceeded by a prewfc run to extract all the spectra.
; Both lines use wfcflx.pro, wfcwlfix.pro, wfcobs.pro
; The main diff is that here, I coadd all 3 orders & write spectra by separate
;	order, while prewfc co-adds by APT visit using the WL scale of the 1st 
;	obs. Indiv spec_*.fits files are made by prewfc and are the input here.
; PROCEDURE
;	Precede w/ sens.pro (& prewfc & tchang, if new data)
;-
pset
; ###change
wfcobs,'dirirstare.log',fil,grat,aper,star,'','',''		;Everything

;wfcobs,'dirirstare.log',fil,grat,aper,star,'','','GAIA593_1968'
;wfcobs,'dirirstare.log',fil,grat,aper,star,'','','GAIA593_9680'
;wfcobs,'dirirstare.log',fil,grat,aper,star,'','','GD71'
star=star(uniq(star,sort(star)))	; unique occurances of a star
print,star

nstar=n_elements(star)
for istr=0,nstar-1 do begin
;for istr=4,4 do begin
	wfcobs,'dirirstare.log',fil,grat,aper,onestr,'','',star(istr)
	dograt=['G102','G141']
	good=where(grat eq 'G102',ngd)
	if ngd le 0 then dograt='G141'
	good=where(grat eq 'G141',ngd)
	if ngd le 0 then dograt='G102'
	wfcreduce,'dirirstare.log',dograt,'',star(istr),	$
; ###change
			out='spec/'+star(istr),/merge		; normal case
;			out='spec/noflat/'+star(istr),/merge

;Do no CRNL corr to derive the CRNL with fullin.pro. & ALSO make 2 special edits
;	of wfcflx for this case,
;	which could be redone whenever the tchang is updated.
;			out='spec/nolin/'+star(istr),/merge
	endfor
end
