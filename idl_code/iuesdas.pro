pro iuesdas,filespec
;+
;			iuesdas
;
; procedure to convert iue ascii file to SDAS files
;
; CALLING SEQUENCE:
;	iuesdas,filespec   EG:	iuesdas,'merge*.mrg' 
;
; INPUTS:
;	filespec - filespec for ascii merge files
;
; OUTPUTS:
;	SDAS image files
;
; HISTORY:
;	Mar 28, 1996 Kluged from make_iue_calobs and iueread
;-
;-----------------------------------------------------------------------------
;
; find files to process
;
    filelist = findfile(filespec)
;
; loop on files
;
    for ifile=0,n_elements(filelist)-1 do begin
	file = filelist(ifile)

;
; read input file
;
	rd,file,0,x
;
; get header
;
        st = ''
        header = strarr(1000)
        nheader = 0
        close,1 & openr,1,file
        readf,1,st
;
; lines to delete from input ascii header
;
	badst = ['OBS DATE=','NET/TIME','RECORDS FOUND','EXP. TIME(sec)', $
		 'POSITION IUE TAPE','POINTS IN SPECTRUM']
	nbadst = n_elements(badst)

        while strmid(st,1,3) ne '###' do begin
;
; ignore BAD LINES
;
		st=strtrim(st,2)	;reduce blank lines to ''
		if st eq '' then goto,nextl
		for k=0,nbadst-1 do if strpos(st,badst(k)) ge 0 then goto,nextl
		header(nheader) = strmid(st,0,71)
		nheader = nheader+1
nextl:
                readf,1,st
        end
;
; read target name
;
        target='' & readf,1,target              ;target name
	target = strtrim(target,2)
        close,1
;
; extract information from header
;
	nspeclw = 0
	nspecsw = 0
	wmerge = 0
	for i=0,nheader-1 do begin
		if strmid(header(i),0,7) eq ' SUM OF' then begin
			pos = strpos(header(i),'CAMERA')
			if pos lt 0 then begin
				print,'ERROR - CAMERA Not Found *************'
				goto,nextfile
			end

			camera = fix(strtrim(strmid(header(i),pos+6,3)))
			nspec = fix(strmid(header(i),7,3)) + $
				fix(strmid(header(i),17,4))
			if camera le 2  then nspeclw = nspeclw+nspec $
					else nspecsw = nspecsw+nspec
		end
		if strmid(header(i),0,11) eq 'MERGE POINT' then $
				wmerge = float(strmid(header(i),13,7))
	end
;
HEAD=STRARR(25)
sxaddPAR,HEAD,'SIMPLE','F'
sxaddPAR,HEAD,'BITPIX',32
sxaddPAR,HEAD,'NAXIS',2,'TWO DIMENSIONAL DATA'
sxaddPAR,HEAD,'NAXIS1',0,'NUMBER OF POINTS IN SPECTRA'
sxaddPAR,HEAD,'NAXIS2',0,'NUMBER OF IUE RECORDS IN GROUP'
sxaddPAR,HEAD,'DATATYPE','REAL*4','FLOATING POINT DATA'
sxaddPAR,HEAD,'GROUPS','T','GROUP FORMAT'
sxaddPAR,HEAD,'GCOUNT',1,'ONE GROUP FOR LOW DISPERSION SPECTRA'

;
; add old history
;
	sxaddhist,header(0:nheader-1),head
;
; add some more keyword information
;
	sxaddpar,head,'wmin',min(X(*,0)),'MINUMUM WAVELENGTH'
	sxaddpar,head,'wmax',max(X(*,0)),'MAXIMUM WAVELENGTH'
	sxaddpar,head,'pcount',0
	sxaddpar,head,'psize',0
	if wmerge gt 0 then sxaddpar,head,'wmerge',wmerge,'MERGE POINT'
	sxaddhist,'Written by IUESDAS.PRO '+!stime,head
;
; create SDAS file
;
	nstart = 1762
	sxmake,1,'MRG'+strtrim(nstart+ifile,2),x,0,1,head
	sxwrite,1,x
	close,1
nextfile:
    end
return
end
