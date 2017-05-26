# MAKEFILE FOR INTEL COMPILER on LINUX
#
F95=ifort

FFLAGS= -O3 -cm -132 -zero -save -common-args -i-static

LDFLAGS= $(FFLAGS) -static -static-intel

EXECR=SITE_FILE_CREATOR.exe
SRCCR=SITE_FILE_CREATOR.FOR
EXEHU=SITEBELD4HUC8.exe
SRCHU=SITEBELD4HUC8.FOR

OBJCR=$(SRCCR:.f=.o)
OBJHU=$(SRCHU:.f=.o)

all: $(EXECR) $(EXEHU)

clean:
	rm -f *.o $(EXECR) $(EXEHU)

$(EXECR): $(OBJCR)
	$(F95) $(LDFLAGS) $(OBJCR) -o $@

$(EXEHU): $(OBJHU)
	$(F95) $(LDFLAGS) $(OBJHU) -o $@
