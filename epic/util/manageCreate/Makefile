# MAKEFILE FOR INTEL COMPILER on LINUX
#

F95=ifort

FFLAGS= -O3 -warn nousage -132 -zero -save -common-args 

LDFLAGS= $(FFLAGS) -static-intel 


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
	$(F95) $(LDFLAGS) $(OBJAPP) -o $@

$(EXESU): $(OBJSU)
	$(F95) $(LDFLAGS) $(OBJSU) -o $@

$(EXETD): $(OBJTD)
	$(F95) $(LDFLAGS) $(OBJTD) -o $@
