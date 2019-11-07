PRO tvcir,x,y,id,sze=sze,rad=rad,offst=offst,circ=circ
;+
; NAME:
;	TVCIR
; PURPOSE:
;       Quickly draw circles around stars and display their IDs or index
;       numbers on the right or left.
; EXPLANATION:
;       Keywords allow selection of circle radius (RAD), size of ID print 
;       (SZE), printing on left of stars (OFFST=-1) and suppression of 
;       circles (CIRC=-1).  If an array of IDs is used and some elements 
;       are blank or -1, TVCIR will not print by the star.
; CALLING SEQUENCE:
;       TVCIR,X,Y [ID,RAD=r,OFFST=o,SZE=size]
; INPUTS:
;       X    - Array of X values
;       Y    - Array of Y values
; OPTIONAL INPUTS:
;       ID   - String or integer array of star IDs (default is index numbers 
;              of X array)
; KEYWORDS:
;       RAD      - Radius of circle (default is 6)
;       OFFST    - Offset for numbers (default is 4; -1 offsets to left)
;       SZE      - Size of numbers (default is 1.2)
;       CIRC     - Can suppress circles by using C = -1 or /C
; EXAMPLES:
;       TVCIR,X,Y,ID,R=7,S=1.5  Stars circled with radius of 7 and ID's 
;                                  printed using size 1.5
;       TVCIR,X,Y,O= -1         Prints index numbers offset to the left
;
;       TVCIR,X(14),Y(14),['star5']  Circles 14th star and prints id.
;
;       TVCIR,X,Y,/C            Circles suppressed; prints out hyphen and
;                                  index number next to each star.
; REVISION HISTORY:
;       Written by Joan Isensee, Hughes STX Corp., 12/16/91
;       Rad keyword for radius, J. Isensee, Hughes STX Corp., 1/31/92
;-
on_error,2	;Return to caller
;
if (n_params() lt 1) then begin
   print,'Calling Seq:  tvcir,x,y,id,[rad=r,offst=o,sze=s]'
   return
endif
pad = 4
cnt = n_elements(x)

if (keyword_set(rad) eq 0) then rad = 6
if (keyword_set(offst) eq 0) then offst = 4
if (keyword_set(sze) eq 0) then sze = 1.2

if (keyword_set(circ) eq 0) then tvcircle,rad,x,y	;Circles not suppressed

if (n_params() lt 3) then begin	   ;****** DISPLAY INDEX NUMBER ******

   if (offst lt 0) then begin	   ;Display on LEFT
      if (rad lt 10) then pad = 10
      pad = pad + 4*sze		   ;Offset for size
      for i=0,cnt-1 do begin
         if (i gt 99) then xyouts,x(i)-sze*rad-11*sze-pad,y(i),$
                      strtrim(i,2)+'-',/dev,size=sze
         if (i ge 10) AND (i lt 100) then xyouts,x(i)-sze*rad-9*sze-pad,y(i),$
                      strtrim(i,2)+'-',/dev,size=sze
         if (i lt 10) then xyouts,x(i)-sze*rad-4*sze-pad,y(i),$
                      strtrim(i,2)+'-',/dev,size=sze
      endfor
   endif else begin
      for i=0,cnt-1 do begin
         xyouts,x(i)+offst+1.005*rad,y(i),'-'+strtrim(i,2),$
           /dev,size=sze
      endfor
   endelse
endif else begin
;	
;		   ******** DISPLAY IDs from User *********
;
   if (n_elements(id) ne cnt) then begin
      print,''
      print,'ERROR:  Please check ID, array size should match x & y size'
      print,''
      return
   endif
   b = size(id)
   if (offst lt 0) then begin	;  Display on LEFT
      if (b(2) eq 7) then begin  ;  String array
         for i=0,cnt-1 do begin
           if (id(i) ne '') then begin    ; 
            pad = 0
            if (sze lt 2) then pad = 15
            lnth=strlen(strtrim(id(i),2))
            xyouts,x(i)-sze*rad-(lnth*9)-8*sze+pad,y(i),$
               strtrim(id(i),2)+'-',/dev,size=sze
                   ;offsets using length of string & radius of circle
           endif
         endfor
      endif
      if (b(2) eq 2) then begin  ;  Integer array
         for i=0,cnt-1 do begin	
           if (id(i) gt -1) then begin   ;  allows skipping over elements
            if (id(i) lt 10) then begin
              xyouts,x(i)+2*offst-9*sze,y(i),strtrim(id(i),2)+'-',/dev,size=sze
            endif 
            if (id(i) ge 10) AND (id(i) le 99) then begin
               xyouts,x(i)+2*offst-12*sze,y(i),strtrim(id(i),2)+'-',/dev,$
                   size=sze
            endif
            if (id(i) gt 99) then begin	 ; gt 99
               xyouts,x(i)+2*offst-14*sze,y(i),strtrim(id(i),2)+'-',/dev,$
                  size=sze
            endif
           endif 
        endfor
      endif
   endif else begin		  ;   Display IDs on Right

      if (b(2) eq 7) then begin  ;  String array
         for i=0,cnt-1 do begin
           if (id(i) ne '') then begin    ; 
               xyouts,x(i)+offst+1.005*rad,y(i),'-'+strtrim(id(i),2),/dev,$
                  size=sze
           endif
         endfor
      endif
      if (b(2) eq 2) then begin  ;  Integer array
         for i=0,cnt-1 do begin	
           if (id(i) gt -1) then begin   ;  allows skipping over elements
               xyouts,x(i)+offst+1.005*rad,y(i),'-'+strtrim(id(i),2),/dev,$
                  size=sze
           endif
         endfor
      endif
   endelse
endelse
return
end
