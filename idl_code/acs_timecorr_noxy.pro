function acs_timecorr_noXY,date,wave
;+
; compute the sensitivity degradation correction for ACS CCD photom before SM4
;	from quartic fit vs. WL found in tchang.pro. 
; Do *NOT* corr for WFC -77 to -81C change, which is done in stdphot via synacs.
; INPUT: - EITHER CAN BE VECTOR BUT *NOT* BOTH ***************
;	date - decimal year obs date. Array OK as of 2011May6
;	wave - pivot WL of filter or filter name. If string, then must be 1-D.
; OUTPUT RETURNED
;	the 1-D correction factor to be divided into the countrate
; 2007Feb13 - rcb
; 11sep13 - update 2002.2 to match Synphot QE files at 2002.16=MJD52334
; 15nov - new change coef.
; 15dec4 - new change coef.
; 15dec15 - add post SM4 corr w/ avg slope
; 15dec31 - truncate post SM4 corr to value below 4000 and >9033A=max(pivwl)
; 16may16 - update for elim 1st HRC obs @ 6.2" off-center.& HRC-UV @ half wgt
; 16may26 - better post-SM4 fit from use of fit pre-SM4 slopes in tchang
; 16may26 - Fix totcor result to be 9033A value at all longer WLs
;-
filt=['F220W','F250W','F330W','F344N','F435W','F475W','F502N','F555W',  $
       'F550M','F606W','F625W','F658N','F660N','F775W','F814W','F892N','F850LP']
; Ref Sirianni 2005, PASP (HRC values). Space 658,660 by +/- 60A:
;pivwl =   [2255.,2716,3363,3433,4311,4776,5021,5580,			$
;	5356,5888,6295,6520,6650,7665,8115,9145,8914] ; 658,660 fudged spacing
; above source independent pivwl do NOT agree w/ the synphot* files or w/
;	current headers. A recent header agrees to 1 A for F814W, so use avg of 
;	old-2003 synphot.hrc-gd71 & synphot.wfc-bd+17d4708 - 2011jan8 
;pivwl =   [2257.,2714,3362,3433,4316,4761,5022,5581,			$
;	5358,5897,6298,6583,6590,7687,8091,9131,8914]
; 2015dec - use old-2003 synphot.hrc-gd71 for 4 hrc only filters & Table 9.1
;	from IHB for WFC filters. 2015dec25-update to pivwl order
pivwl =   [2257.,2714,3362,3433,4319,4747,5023,5361,		$
	5581,5921,6311,6584,6599,7692,8057,8915,9033]
if datatype(wave(0)) eq 'STR' then begin
	indx=where(filt eq wave)
	wav=pivwl(indx)  &  wav=wav(0)
;	print,'ACS_timecorr conv filter to pivwl:',wave,wav
     end else wav=double(wave)

; omit Narrow band filters for fit
; 07apr12 - WFC fitted corrections:
; ###change
;  WFC+HRC pre-SM4 fitted corrections from tchang.pro w CTE corr:
;coef=[-0.03180,2.035e-05,-5.184e-09,5.652e-13,-2.189e-17]	; 2012feb3
;coef=[-0.051830d,3.5780e-05,-9.0922e-09,9.7476e-13,-3.7240e-17] ; 2016feb22 9:44
;coef=[-0.051871d,3.5807e-05,-9.0984e-09,9.7538e-13,-3.7263e-17] ;2016feb22 10:22
;coef=[-0.034118d,2.1933e-05,-5.4512e-09,5.8219e-13,-2.2369e-17] ;2016mar28
;coef=[-0.034094d,2.1919e-05,-5.4489e-09,5.8202e-13,-2.2364e-17] ;2016mar31
;coef=[-0.044523d,3.0351e-05,-7.7263e-09,8.3685e-13,-3.2538e-17] ;2016mayresid=.989
;coef=[-0.044566d,3.0381e-05,-7.7338e-09,8.3766e-13,-3.2569e-17] ;2016mayresid=.988
coef=[-0.044561d,3.0376e-05,-7.7328e-09,8.3760e-13,-3.2569e-17] ;2016may26

; coef for rel. sensitiv. at 2009.4 from tchang:
;coef09=[1.210,-9.644e-05,1.372e-08,-6.077e-13]			; 2012feb3
;coef09=[1.2226d,-1.0220e-04,1.4740e-08,-6.6649e-13]	; 2016feb16-val @ 2009.4
;coef09=[1.2062d,-9.4125e-05,1.3510e-08,-6.0762e-13]	; 2016mar28-val @ 2009.4
coef09=[1.1536d,-7.2839e-05,1.0806e-08,-5.0274e-13]	; 2016may27
;postslope=-0.00057					; avg post-SM4 loss rate
postslope=-0.000615					;2016may26 +/- 0.00020

; frac/year:
corr=coef(0)+coef(1)*wav+coef(2)*wav^2+coef(3)*wav^3+coef(4)*wav^4
badfit=where(wav gt max(pivwl),nbad)
; for qefit.pro: new QE curves
; 2016May26 if nbad gt 0 then corr(badfit)=0.
if nbad gt 0 then corr(badfit)=coef(0)+coef(1)*9033.+coef(2)*9033.^2+	$
		coef(3)*9033.^3+coef(4)*9033.^4		; 9033 is F850LP pivWL
date=double(date)
dely=date-2002.16
totcorr=1.+dely*corr		;has dimens of date or wav, whichever is not 1-D.
; MJD=54976=2009.3973, MJD=54977=2009.4000
indsm4=where(date ge 2009.399,nind)		; WFC revival in SM4
if nind gt 0 then begin
  dely=date-2009.4				; 2015dec15
; rel sens at 2009.4:
; ff assumes wav=wave is 1-D (like in flxcal):
  if n_elements(wav) eq 1 then begin		; for use in flxcal.pro:
	corr=coef09(0)+coef09(1)*wav+coef09(2)*wav^2+coef09(3)*wav^3
	totcorr(indsm4)=corr+dely(indsm4)*postslope
     end else begin		; 1 date>2009 for use in maktabl1.pro:
	  corr=coef09(0)+coef09(1)*wav+coef09(2)*wav^2+coef09(3)*wav^3
	  totcorr=corr+dely*postslope
; 2015dec31-trim to constrained WFC region for qefix.pro.
	  bad=where(wav le 4000,nbad)
	  if nbad gt 0 then totcorr(bad)=totcorr(bad(-1))
	  bad=where(wav ge max(pivwl),nbad)
	  if nbad gt 0 then totcorr(bad)=totcorr(bad(0))
	  endelse
     endif
;print,'Date,wave,corr=',date,wav,totcorr,n_elements(wav)
return,totcorr
end
