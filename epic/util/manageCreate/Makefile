F95  = ifort

#FLGS =  -byteswapio -Bstatic_pgi
FFLAGS = -O3 -cm -132 -zero -save -common-args -i-static 
LDFLAGS=  $(FFLAGS) -static -static-intel

LIBS = 

EXEAPP = ManGenFERT.exe
SRCAPP = ManGenFERT.FOR
EXESU = ManGenSU.exe
SRCSU = ManGenSU.FOR
EXETD = soilDrain.exe
SRCTD = soildrain.for

OBJAPP = $(SRCAPP:.f=.o)
OBJSU = $(SRCSU:.f=.o)
OBJTD = $(SRCTD:.f=.o)

all: $(EXEAPP) $(EXESU) $(EXETD)

clean:
	rm -f *.o $(EXEAPP) $(EXESU) $(EXETD)

$(EXEAPP): $(OBJAPP)
	$(F95) $(LDFLAGS) $(OBJAPP) $(LIBS) -o $@

$(EXESU): $(OBJSU)
	$(F95) $(LDFLAGS) $(OBJSU) $(LIBS) -o $@

$(EXETD): $(OBJTD)
	$(F95) $(LDFLAGS) $(OBJTD) $(LIBS) -o $@
