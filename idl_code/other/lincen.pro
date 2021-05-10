pro lincen,wav,spec,cont,wxact,badflag
;+
; Compute the centroid of an em. line over the range xappr +/- fwhm/2 after
;	subtracting any continuum and half value at the remaining peak.
;	After clipping at zero, the wgt of the remaining spec wings have wgts
;	that approach zero, so any marginally missed or incl. pt matters little.
;
;  INPUTS:
;       wav - wavelenth vector
;	spec - spectral flux or counts
;       cont - continuum level to subtract to isolate line profile.
;  OUTPUTS:
;	wxact - the computed exact centroid wavelength
;	badflag-0=good data, 1-->result set to mid-point of input array
;  HISTORY
;	2013May23-RCB
;-
badflag=0
profil=spec-cont
; .4 for ic6906c0q: clip=(profil-max(profil)*.4) but NG for 16408A in ic6907cmq
clip=(profil-max(profil)*.5)
; if any negative points, accept only those >0 continuous from center.
npts=n_elements(clip)
midpt=(npts-1)/2
print,"lincen has ",npts," points, midpoint ",midpt," continuum ",cont
; check left side & set all pos values to 0 before first neg:
bad=where(clip(0:midpt) lt 0,nbad)
if nbad gt 0 then begin
	mx=max(bad)<(midpt-1)
	clip(0:mx)=0
	print,"lincen removing points 0:",mx
	endif
; check right side & set all pos values to 0 after first neg:
bad=where(clip(midpt:npts-1) lt 0,nbad)
if nbad gt 0 then begin
	mn=min(bad)+midpt>(midpt+1)
	clip(mn:npts-1)=0
	print,"lincen removing points ",mn,":end"
	endif
clip=clip>0
good=where(clip gt 0,ngood)
if ngood le 1 then begin
	wxact=wav(midpt)
	print,'WARNING: Bad profile, centroid set to mid-point of search array.'
	badflag=1
    end else wxact=total(wav*clip)/total(clip)

return
end
