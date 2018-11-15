# SWAT MAKEFILE FOR INTEL COMPILER on LINUX
#
F95=ifort

FFLAGS= -O3 -cm -132 -zero -save -common-args -i-static -traceback

LDFLAGS= $(FFLAGS) -static -static-intel

EXEAPP=EPICapp.exe
EXESU=EPICsu.exe

SRCAPP=EPIC0509app.for
SRCSU=EPIC0509su.for

OBJAPP=$(SRCAPP:.f=.o)
OBJSU=$(SRCSU:.f=.o)

all: $(EXEAPP) $(EXESU)

clean:
	rm -f *.o $(EXEAPP) $(EXESU)

$(EXEAPP): $(OBJAPP)
	$(F95) $(LDFLAGS) $(OBJAPP) -o $@

$(EXESU): $(OBJSU)
	$(F95) $(LDFLAGS) $(OBJSU) -o $@

