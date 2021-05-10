PRO nicmrg1,fil,wout,fout,sens=sens,notemp=notemp
;+
;
; convert to flux, corr for non-lin, and merge THREE (3) gratings
; for use in modcf, on-the-fly single obs merge.
;
; INPUT:
;	fil - file name to merge for g096, assume corresponding G096-141 exist
;	sens - optional keyword specifying which sensitiv file. default=sens.*
; OUTPUT
;	wout, fout - wavelength and flux
;
; 07Dec7
; 08sep16 - add the notemp keyword for testing.
;-

nicflx,fil,wout,fout,/corr,sens=sens,notemp=notemp
fil2=replace_char(fil,'096','141')
fil3=replace_char(fil,'096','206')

nicflx,fil2,w2,f2,/corr,sens=sens,notemp=notemp
wmerge=1.17
good1=where(wout lt wmerge,n1)
wmerge=wout(n1-1)						; adjust wmerge
longclip=1.95
good2=where(w2 gt wmerge and w2 lt longclip)			; case of 2 spec
wout=[wout(good1),w2(good2)]  &  fout=[fout(good1),f2(good2)]

fil3=findfile(fil3)  &  fil3=fil3(0)
if fil3 ne '' then begin
	nicflx,fil3,w2,f2,/corr,sens=sens,notemp=notemp
	wmerge=1.89				; See nicmrg.pro
	good1=where(wout lt wmerge,n1)
	wmerge=wout(n1-1)						; adjust wmerge
	longclip=2.5
	good2=where(w2 gt wmerge and w2 lt longclip)
	wout=[wout(good1),w2(good2)]  &  fout=[fout(good1),f2(good2)]
	endif
return
end
