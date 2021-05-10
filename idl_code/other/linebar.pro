pro linebar,frange,ftop,wmin,wmax,wave,zflag,titles,offsets,tiny
; 1991 JAN 28 CONVERTED TO VERSION 2 ; DC
;91apr26-if tiny<0. then make linebar ticks go up (case of gal absorb)
;	-if zflag is negative or zero hold the z-value printing
;	   (on the right side of the plots)
; 94sep2-comment out the zflag printing as it was coming only on ngc404 w/ z<0
	if tiny then csize = 0.50 else csize = 0.65
	stagger = 0	;last line not staggered

;	if z lt 0.0 then return
	z=abs(zflag)

	fbottom =  ftop-frange*0.025	;bottom of ticks
	fchar = fbottom-frange*0.030	;bottom of lables
	if tiny then begin
		fchar = fbottom-frange*0.023
		fstag = fchar - frange*0.023
	end
	w = wave*(1+z)
	wrange = wmax - wmin
; CHANGE LIMITS FROM 50 TO 20A OF ENDS OF PLOTS FOR THE GOOD LINES-RCB 90JAN27
	good = where((w gt (wmin+20)) and (w le (wmax-20))) & ngood = !err
;92jan22-which offsets to use mod criterion to get merged data to use 2nd pos.
	if wmax-wmin gt 1900.0 then ioffpos=1 else ioffpos=0

;	if zflag gt 0 then $
;         xyouts,wmax+(wrange)/100,ftop-frange*0.04,string(z,'(f6.4)')
	if ngood gt 0 then begin
	    w = w(good)
	    names = titles(good)
 	    if tiny ge 0 then plots,[min(w),max(w)],[ftop,ftop]
 	    if tiny lt 0 then plots,[min(w),max(w)],[fbottom,fbottom]
	    !c = 0
	    for i = 0,ngood-1 do begin
		plots,[w(i),w(i)],[ftop,fbottom]
		name = strtrim(names(i),2)
		len=strlen(name)
		case name of
			'La': name = '!6L!7a!6'
			'Lb': name = '!6L!7b!6'
			'Lg': name = '!6L!7c!6'
			'Ld': name = '!6L!7d!6'
			else:
		endcase
;
; stagger tiny characters
;
	        if (len gt 0) and tiny and (i gt 0) then begin
		    if stagger then begin	;last character staggered
			stagger=0
		      end else begin
			if (w(i)-w(i-1)) lt 70 then stagger=1  
		    end
	        end
		if stagger then begin
			ypos=fstag
			xpos = w(i)-wrange/300.0*len*csize/0.65+ $
				offsets(ioffpos,good(i))
		    end else begin
			ypos=fchar
			xpos = w(i)-wrange/300.0*len*csize/0.65+ $
				offsets(ioffpos,good(i))
		end
		!p.charthick = 0.5
		xyouts,xpos,ypos,name,size=csize,font=-1
		!p.charthick = 0
	    endfor
	end
return
end
