function dbomit,lst,searchpar,count
;
; example:
;	lst = dbfind('filter2=[c,f]')
;	lst = dbomit(lst,'filter=fr')
;
	if lst(0) le 0 then begin
		count=0
		return,0 ;  already no entries
	end

	list1 = lst	
	list2 = dbfind(searchpar,lst,/silent)
	match,list1,list2,sub1,sub2,count=count
	print,strtrim(count,2)+' Entries removed, '+ $
		strtrim(n_elements(lst)-count,2)+' left'
	if count gt 0 then begin
		list1(sub1) = -1
		good = where(list1 gt 0,count)
		if count gt 0 then list1 = list1(good) else list1 = -1
	end else count = n_elements(list1)
	return,list1
end
