;
; DRIVER routine for ralphs special pop plot
; July 25, 1989  D. Lindler
; 89DEC8 MOD TO DO IUE ASCII FILE FORMAT FOR ONE CAMERA
; 89DEC17 MOD TO DO IUE ASCII FILE FORMAT FOR two CAMERAs
; 92AUG20-START THE CONVERSION FOR V2
;
;
	hist=strarr(72,2)
; determine files to process
;
	FILE=''
	read,'enter name of data file',FILE
	first=1
start:
	i1=0 & i2=0
	read,'Enter file ranges to process first,last  (0,0) when done',i1,i2
	if i1 eq 0 then goto,doit
	if first then list=indgen(i2-i1+1)+i1 $
		 else list=[list,indgen(i2-i1+1)+i1]
	first=0
	goto,start
;
; loop on targets
;
doit:
	nlist=n_elements(list)
	pos=0
	while pos lt nlist do begin	
;
; read first data set for target
;
		RD,FILE,LIST(POS),D1
		s=size(d1) & n1=s(1)
;
; get history line and target name
;
		target_name = !mtitle
;
; get header for next file
;
		if (pos+1) lt nlist then begin
			RD,FILE,LIST(POS+1),D2
			n=0
;
; is it the same target
;
			target_name2 = !mtitle
			if target_name2 eq target_name then begin
				s=size(d2) & n2=s(1)
				d=fltarr(n1+n2,9)
				nmerge=n1
				d(0,0)=d1
				d(nmerge,0)=d2
				short=intarr(n1+n2)
				short(0:n1-1)=1
			   end else begin
				nmerge=0
			end
		   end else begin
			nmerge=0
		end
		if nmerge eq 0 then begin
			d=d1
			short=intarr(n1)
			if d(0,0) lt 1500 then short=short+1
			pos=pos+1
		   end else begin
			pos=pos+2
		end

;
; plot the data
;
	dblplot,hist,d(*,0),d(*,5),d(*,7)*100,d(*,2),d(*,2)-D(*,4)*D(*,6), $
					d(*,1),nmerge,short
	plotdate
	endwhile

	!type=16
	!PSYM=0
	!linetype=0
	!noeras=0
	!mtitle=''
        set_xy
	set_viewport,0.10,0.95,0.10,0.95
end
