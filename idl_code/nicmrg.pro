PRO nicmrg,f1,f2,fout,number,title=title
;+
;
; MERGE TWO SPECTRA IN ASCII FILES INTO A SINGLE ASCII FILE.
;
; nicMRG,F1,F2,FOUT,number,TITLE=TITLE
;
; INPUT:
;	F1 - FILE NAME OF SHORT WAVELENGTH SPECTRUM (Ascii file)
;	F2 - FILE NAME OF LONG WAVELENGTH SPECTRUM  (Ascii file)
; 	FOUT - FILE NAME OF OUTPUT MERGED SPECTRUM  (Ascii file)
; Optional input/output
;	number - OPTIONAL output file number (DEFAULT=1)
;	TITLE  - OPTIONAL OUTPUT TITLE FOR LINE after ### IN ASCII OUTPUT FILE
;
;HISTORY:
; 04jul27-MODIFIED FROM stismrg.PRO BY R.C.BOHLIN
; 04aug13-throw away new gross and bkg for merged files
; 05mar14- convert to read output of nicadd, instead of djl *-n* files
; 05apr1 - include gross and bkg
; 06aug15- add exposure time
; 07dec7 - (remove unused corr keyword here & in nicreduce)
;-------------------------------------------------------------------------
;
if n_params(0) lt 4 then number=1
;
; get headers
;
st = ''
header = strarr(10000)
nheader = 0
close,1 & openr,1,f1
readf,1,st
while strmid(st,1,3) ne '###' do begin
	if strpos(st,'gross') ge 0 or strpos(st,'COUNT') ge 0 then goto,skipit
	header(nheader) = st
	nheader=nheader+1
skipit:	readf,1,st
end
target='' & readf,1,target		;target name
targ=gettok(target,' ')			;target assumed to be first item
if f2 eq '' then goto,onefil
close,1 & openr,1,f2
readf,1,st
while strmid(st,1,3) ne '###' do begin
	if strpos(st,'gross') ge 0 or strpos(st,'COUNT') ge 0 then goto,skipit2
	header(nheader) = st
	nheader=nheader+1
skipit2: readf,1,st
end
close,1
; get input data
;data order: wl,net,flux,data err,stat err,err-mean,npts,gross,bkg

onefil:
rdf,f1,0,x1
if f2 ne '' then rdf,f2,0,x2
s1=size(x1) & s2=size(x2)		;size arrays
np1 = s1(1) & np2 = s2(1)		;number of data pts
ncol=s2(2)				;second dimension of x1 and x2
if f2 eq '' then begin		;single spectrum
	xout=x1
	wmerge=0. & goto,skip
	endif
w1=x1(*,0)  &  w2=x2(*,0)

; set merge point
wmerge=1.17		; 05mar18 - BD17 P-gamma NO better w/ g141 to 1.085.
; 08jul31 - G191 & GD153 could be impr. w/ wmerge=1.83-1.85
; 08sep22 - Make the sw to G206 1.89 for brite *s to get all of Palph at hi-res!
;	1.89 works for P330,G191,Hd165459,1805292
;if strpos(f2,'g206') ge 0 then wmerge=1.865	;NG 06jul28 A-stars 1805292,etc
; Put same default into nicmrg1.pro
if strpos(f2,'g206') ge 0 then wmerge=1.89	; 08sep was 1.81. P-alph @ 1.875
; 08aug5-faint stars: eg C26202-1.915. Was 1.93. 06dec18 2.0-->2.1e-16 for gd71:
; 08aug27-round down to 1.91 from 1.915 (good for1743045 the only faint A-star)
;	and move limit up to 7e-16 to pick up 3 WDs (was 1.915 & 2.1e-16)
;	1.91mic is pretty bad for G191B2B.
; ff 1.85 is a minimum for faint stars.
;if strpos(f2,'g206') ge 0 then if tin(w1,x1(*,2),1.8,1.9) lt 7e-16	$
;							then wmerge=1.85
;if strpos(f2,'g206') ge 0 and targ eq '2M0559-14' then wmerge=1.89 ; 08aug8
print,targ,' wmerge = ',wmerge,title

; try - good1=where(w1 gt 0.8 and w1 lt wmerge,n1)	;also trim short wl g096
good1=where(w1 lt wmerge,n1)
wmerge=w1(n1-1)						; adjust wmerge
if strpos(f2,'g206') ge 0 then longclip=2.5 else longclip=1.95
good2=where(w2 ge wmerge and w2 lt longclip,n2)
first=good2(0)
;
; merge spectra
;
npout=n1+n2				;number of points in output spectrum
xout=fltarr(npout,ncol)			;output array
xout(0,0) = x1(good1,0:ncol-1)		;insert first spectrum
xout(n1,0) =x2(first:first+n2-1,0:ncol-1) ;insert good part of second
;
; write output spectrum
;
skip:
close,1 & openw,1,fout
printf,1,'file written by nicmrg.pro on ',!stime
for i=0,nheader-1 do printf,1,header(i)
printf,1,'MERGE POINT (microns) ='+string(wmerge,'(f7.3)')
printf,1,"WAVELENGTH COUNT-RATE    FLUX     STAT-ERROR  "+		$
			"SCAT-ERROR   NPTS    GROSS        BKG     EXPTIME"
printf,1,' ###'+string(number,'(i5)')
if keyword_set(title) then printf,1,title
form='(f10.7,4e12.4,f7.1,2e12.4,f8.1)'
printf,1,transpose(xout),format=form
printf,1,fltarr(ncol),format=form	;record of zeroes for eof delim.
close,1
return
end
