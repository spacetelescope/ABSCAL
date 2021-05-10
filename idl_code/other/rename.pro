; 97feb1 to rename in a way not allowed by VMS

lst=findfile('new_*.c1*')
for i=0,n_elements(lst)-1 do begin
	part=str_sep(lst(i),'_')
	spawn,'$ren '+lst(i)+' '+part(1)
	endfor
end
