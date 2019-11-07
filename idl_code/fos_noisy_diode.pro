;+
;
; Procedure to flag a noisy diode in a raw FOS observation
; 95feb23-djl
;
; Modify rootname and diode in this main prog and then type .RUN FOS_NOISY_DIODE
;-

rootname=['y2h70906t','y2h70905t','y2h70206t','y2h70205t','y2h70208t']
diode = 138	;2/23/95-gd153 and hz43 obs

for loop=0,n_elements(rootname)-1 do begin
;
; open input .q0h file (raw data quality file)
;
	sxopen,1,rootname(loop)+'.q0h',h
	gcount = sxpar(h,'gcount')
	nxsteps = sxpar(h,'nxsteps')
	overscan = sxpar(h,'overscan')
	fchnl = sxpar(h,'fchnl')
;
; determine which data points to flag
;
	i1 = nxsteps*diode
	i2 = i1 + nxsteps*overscan - 1
;
; add history to the header
;	
	sxaddhist,'FOS_NOISY_DIODE '+!stime+' DIODE '+strtrim(diode,2)+ $
			' flagged with qual=500',h
;
; open new .q0h file for output
;
	sxopen,2,rootname(loop)+'.q0h',h,'','w'
;
; loop on groups
;
	for igroup=0,gcount-1 do begin

		qual = sxread(1,igroup,par)		;read quality
		qual(i1:i2,*) = 500			;flag diode
		sxwrite,2,qual,par			;write new quality array
	end

	close,1,2
;
; set prot of output data quality file so that it can not be easily deleted
;
	spawn,'set prot=(o:re) '+rootname(loop)+'.q0*'
	endfor
end
