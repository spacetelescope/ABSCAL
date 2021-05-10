pro tke
; 93may24-postscipt default close and print to techtonix phaser iisd-rcb
;	use pse to print to laser printer
device,/close
set_plot,'x'
print,'$lpr -Phpc24_on_printserv.stsci.edu idl.ps'
print,'$lpq -Phpc24_on_printserv.stsci.edu'
PSET            ;RESET ALL PLOT DEFAULTS - except (since 98oct5) plot titles
end
