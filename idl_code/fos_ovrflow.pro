;
; fix overflow in DISK$DATA4:[BIANCHI.5349.FOSPROCESSED]y2m80802t.d0h for HD6201
;
; to run:
;	.run fos_ovrflow
; From:	STFOSC::LINDLER       5-MAY-1995 14:36:15.61
;
	rootname = 'y2m80802t.d0h'

	sxopen,1,'DISK$DATA4:[BIANCHI.5349.FOSPROCESSED]'+rootname,h
	gcount = sxpar(h,'gcount')
	d=sxread(1,0,par)
;
; forward search
;
	for i=1,2063 do begin
		if (d(i-1)-d(i)) gt 32767 then d(i) = d(i)+65536
	end
;
; reverse search (needed if d(0) was overflowed)
;
	for i=2062,0,-1 do begin
		if (d(i+1)-d(i)) gt 32767 then d(i) = d(i)+65536
	end
sxaddhist,'Overflows fixed w/ FOS_OVRFLOW '+!STIME,H		;95JUL25-RCB
;
; write new file
;
	sxopen,1,rootname,h,'','W'
	sxwrite,1,d,par
	close,1
end
