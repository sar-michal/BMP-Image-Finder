EXEFILE = findimg
OBJECTS = findimg.o myfindimg.o
CCFMT = -m32
NASMFMT = -f elf32
CCOPT = 
NASMOPT = -w+all

.c.o:
	cc $(CCFMT) $(CCOPT) -c $<

.s.o:
	nasm $(NASMFMT) $(NASMOPT) -l $*.lst $<

$(EXEFILE): $(OBJECTS)
	cc $(CCFMT) -o $@ $^
	
clean:
	rm *.o *.lst $(EXEFILE)
