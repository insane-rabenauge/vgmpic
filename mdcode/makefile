SRC68K=main.asm
PRG=$(SRC68K:.asm=.md)
LST=$(SRC68K:.asm=.lst)

.PHONY:	all
all:	$(SRC68K)
	date +" dc.b \"%Y%m%d\"" > mdrelease.inc
	vasmm68k_mot $(SRC68K) -m68000 -Fbin -o $(PRG) -L $(LST)
#	checkmd $(PRG)
	./rom2arr.py
#	./vgmpic.py test.vgm test.png test.md

.PHONY:	run
run:	
	mednafen -autosave 0 test.md

.PHONY:	send
send:	
	runmd test.md

.PHONY:	backup
backup:
	find . -maxdepth 1 -type f -print0 | tar cfz `date +old/v%Y%m%d%H%M.tar.gz` --null -T -
