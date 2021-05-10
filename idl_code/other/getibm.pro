;+
;
; GETIBM - main program
; 95apr17 - copy IUE data files created on IBM by ibm2ndads.ibm
; read output files w/ rdmelo and rdlxl, just like ndads files
;-

list= findfile('GIBBS::[Y6RCB]lwr*.*')
tlist=findfile('GIBBS::[Y6RCB]lwp*.*')
if tlist(0) ne '' then list=[list,tlist]
;swp fails as there are sometimes too many files, eg ralph3-4
tlist=findfile('GIBBS::[Y6RCB]swp0*.*')		
if tlist(0) ne '' then list=[list,tlist]
tlist=findfile('GIBBS::[Y6RCB]swp1*.*')		
if tlist(0) ne '' then list=[list,tlist]
tlist=findfile('GIBBS::[Y6RCB]swp2*.*')		
if tlist(0) ne '' then list=[list,tlist]
tlist=findfile('GIBBS::[Y6RCB]swp3*.*')		
if tlist(0) ne '' then list=[list,tlist]
tlist=findfile('GIBBS::[Y6RCB]swp4*.*')		
if tlist(0) ne '' then list=[list,tlist]
tlist=findfile('GIBBS::[Y6RCB]swp5*.*')		
if tlist(0) ne '' then list=[list,tlist]
help,list
for i=0,n_elements(list)-1 do begin
	fdecomp,list(i),disk,dir,name,ext
	spawn,'cop gibbs::"[y6rcb]'+name+'.'+ext+'/image" '+name+'.'+ext
	if strmid(ext,0,3) eq 'LAB' then BEGIN
		ibm2ndads,name+'.'+ext
		spawn,'delete '+name+'.'+ext+';/nocon'
		strput,ext,'DAT',0
		spawn,'delete '+name+'.'+ext+';/nocon'
		print,'finished file',i
		ENDIF
	endfor
end
