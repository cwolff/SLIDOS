basic printer
asm c:sliboot.asm,c:sliboot.obj,lpt1:;
asm c:slidos.asm,c:slidos.obj,lpt1:;
asm c:slipict.asm,c:slipict.obj,lpt1:;
link c:slidos+c:slipict,sli.exe/map,prn/line
asm c:sliboss.asm,c:sliboss.obj,lpt1:;
asm c:slifmt.asm,c:slifmt.obj,lpt1:;
asm c:slifutl.asm,c:slifutl.obj,lpt1:;
asm c:slidutl.asm,c:slidutl.obj,lpt1:;
asm c:slidata.asm,c:slidata.obj,lpt1:;
sliclk

