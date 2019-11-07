pro reltot1,file=file,niter,chmax
;
if n_elements(file) eq 0 then file='fort'
close,1
openr,1,file+'.9'
;
cmax=fltarr(1001,100)
mmax=fltarr(100)
data=fltarr(9)
;
a=''
for i=1,3 do readf,1,a   ;skip 3 lines
k=-1
while not eof(1) do begin
k=k+1
 readf,1,data
 iter=data(0)
 id=data(1)
 if k eq 0 then nd=id
 cmax(id,iter)=abs(data(6))
endwhile
close,1
;
niter=iter   ;actual number of iterations
lcmax=alog10(abs(cmax)> 1.e-8)
for k=1,niter do begin
  mmax(k)=max(lcmax(*,k))
end
chmax=mmax(niter)
print,niter,chmax
;
return
end


