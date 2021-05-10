pro null_plot,x,y,over,psym=psym,linest=linest,thick=thick,color=color,	$
		xr=xr,yr=yr
;-
;
; procedure to plot data with nulls removed and shown as blank areas
; over=1 for oplot
;
; HISTORY
;	2013Apr23 - add keywords
;
;-
	if n_params(0) eq 2 then over=0
	save = [!xmin,!xmax,!ymin,!ymax]
;
; set plot range if over=0 and range not set
;
	null = 1.6e38
	if over eq 0 then begin
		if (!xmin eq !xmax) then begin
			!xmin = min(x)
			!xmax = max(x)
		endif
		if (!ymin eq !ymax) then begin
			good = where(y ne null)
			if keyword_set(xr) then good=where(y ne null	$
				and x ge xr(0) and x le xr(1))
			!ymin = min(y(good))
			!ymax = max(y(good))
		endif
		!cymin = !ymin
		!cymax = !ymax
		!cxmin = !xmin
		!cxmax = !xmax
	endif

	n=n_elements(x)
	ngood=0
	ipos=0
	overplot=over
;
; find next set of good points
;
next_piece:
	if y(ipos ) ne null then begin
		first=ipos
		for i=ipos,n-1 do if y(i) eq null then goto,found_null
found_null:
		last=i-1
		xx=x(first:last)
		yy=y(first:last)
; 00feb1-rcb	if (max(yy) gt !Cymin) and (min(yy) lt !Cymax) and $
		maxx=max(xx)  &  if !x.type eq 1 then maxx=alog10(maxx)
		minx=min(xx)  &  if !x.type eq 1 then minx=alog10(minx)
;print,minx,maxx,!cxmin,!cxmax
		if (maxx gt !Cxmin) and (minx lt !Cxmax) then begin
		  !c=0
		  if first eq last then begin & xx=[xx,xx] & yy=[yy,yy] & end
;stop
		  if overplot then oplot,xx,yy,psym=psym,linest=linest,	$
		  	thick=thick,color=color else plot,xx,yy,	$
			psym=psym,linest=linest,thick=thick,color=color,$
				xr=xr,yr=yr
		  overplot=1
		end
		ipos=last+1
	endif
	if ipos ge n then goto,done
;
; skip over nulls
;
	for i=ipos,n-1 do if y(i) ne null then goto,found_nonnull

	goto,done
found_nonnull:
	ipos=i
	goto,next_piece
done:
	!xmin = save(0)
	!xmax = save(1)
	!ymin = save(2)
	!ymax = save(3)
end
