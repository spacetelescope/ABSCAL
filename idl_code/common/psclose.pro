pro psclose
; 98feb13 - close .ps file w/o printing-rcb replaces deutch routine of same name
PSET		;RESET ALL PLOT DEFAULTS
device,/close
set_plot,'x'
end
