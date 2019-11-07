pro fosprc,name
;+
;
; INSTRUCTION: DO A $DEL *.*;/EXCL=Y*/NOCON TO GET RID OF BAD CAL FILES FIRST
;
; 93dec13-to run calfos idl testbed to recalibrate fos data
;  switched in header are ignored. to run T/acq data, w/o errors, calfos should
;  be called directly. For FOS picture 96x64 files, just look at .d0h files.
;  Probably, same story for binary & peakup files too. The errors i get in 
;  running t/acq thru fos_process are from trying to make wavelengths and from
;  subtraction of the first line of image as a bkg!
; CALLING SEQUENCE:  fosprc,dirname
;
; input: name=directory containing obs to re-process, eg fosprc,'apk'
;                                              OR        fosprc,'complete dir'
; output: recalibrated files of fos data
;-

;fosdir,name			;96apr22-this line seems silly today?
;log=findfile('dir*.log')	;96apr22-method to find generic dir.log files
;log=log(0)
fosobs,'dir'+name+'.log',obs

siz=size(obs)

for i=0,siz(1)-1 do begin
	fos_process,obs(i)
	endfor
end
