asm c:sliboot.asm,c:slivboot.obj;
asm c:slidos.asm,c:slidos.obj;
asm c:slipict.asm,c:slipict.obj;
link c:slidos+c:slipict,slidos.exe;
exe2bin slidos.exe,slidos.com
asm c:sliboss.asm,c:sliboss.obj;
asm c:slifmt.asm,c:slifmt.obj;
asm c:slifutl.asm,c:slifutl.obj;
asm c:slidutl.asm,c:slidutl.obj;
asm c:slidata.asm,c:slidata.obj;
sliclknl



