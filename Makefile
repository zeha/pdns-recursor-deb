# user editable stuff:
SBINDIR=/usr/sbin/
BINDIR=/usr/bin/
CONFIGDIR="/etc/powerdns/"
OPTFLAGS?=-O3
CXXFLAGS:= $(CXXFLAGS) -Wall $(OPTFLAGS) $(PROFILEFLAGS)
CFLAGS:=$(CFLAGS) -Wall $(OPTFLAGS) $(PROFILEFLAGS)
LINKCC=$(CXX)
CC?=gcc

# static dependencies

PDNS_RECURSOR_OBJECTS=syncres.o  misc.o unix_utility.o qtype.o logger.o  \
arguments.o lwres.o pdns_recursor.o recursor_cache.o dnsparser.o \
dnswriter.o dnsrecords.o rcpgenerator.o base64.o zoneparser-tng.o \
rec_channel.o rec_channel_rec.o malloc.o selectmplexer.o

REC_CONTROL_OBJECTS=rec_channel.o rec_control.o arguments.o 

# what we need 
all: message pdns_recursor rec_control 

# OS specific instructions
-include sysdeps/$(shell uname).inc

ifeq ($(STATIC),semi)
        STATICFLAGS=-Wl,-Bstatic -lstdc++ -lgcc -Wl,-Bdynamic -static-libgcc -lm -lc
        LINKCC=$(CC)
endif
ifeq ($(STATIC),full)
        STATICFLAGS=-lstdc++ -lm -static
        LINKCC=$(CC)
endif

LDFLAGS += $(PROFILEFLAGS) $(STATICFLAGS)

message: 
	@echo
	@echo PLEASE READ: If you get an error mentioning \#include '<boost/something.hpp>', please read README
	@echo PLEASE READ: for an easy fix!
	@echo 

basic_checks: 
	@-rm -f pdns_hw
	-$(CXX) $(CXXFLAGS)  pdns_hw.cc -o pdns_hw 
	@echo
	@if test -x ./pdns_hw ; \
		 then if ./pdns_hw; then echo Everything ok, now run $(MAKE) using same settings \(if any\) you passed ./configure; else echo Could compile binary, but not run it, read README please ; fi; \
	 else 	\
	 	echo; echo Could not compile simple binary, read README please; \
		rm -f dep ; \
	 fi

install: all
	-mkdir -p $(DESTDIR)/$(SBINDIR)
	mv pdns_recursor $(DESTDIR)/$(SBINDIR)
	strip $(DESTDIR)/$(SBINDIR)/pdns_recursor
	mkdir -p $(DESTDIR)/$(BINDIR)
	mv rec_control $(DESTDIR)/$(BINDIR)
	strip $(DESTDIR)/$(BINDIR)/rec_control
	-mkdir -p $(DESTDIR)/$(CONFIGDIR)
	$(DESTDIR)/$(SBINDIR)/pdns_recursor --config > $(DESTDIR)/$(CONFIGDIR)/recursor.conf-dist
	-mkdir -p $(DESTDIR)/usr/share/man/man1
	cp pdns_recursor.1 rec_control.1 $(DESTDIR)/usr/share/man/man1
	$(OS_SPECIFIC_INSTALL)	

clean:
	-rm -f dep *.o *~ pdns_recursor rec_control optional/*.o
	
dep:
	$(CXX) $(CXXFLAGS) -MM -MG *.cc *.hh > $@

-include dep

optional:
	mkdir optional

pdns_recursor: optional $(OPTIONALS) $(PDNS_RECURSOR_OBJECTS) 
	$(LINKCC) $(PDNS_RECURSOR_OBJECTS) $(wildcard optional/*.o) $(LDFLAGS) -o $@

rec_control: $(REC_CONTROL_OBJECTS)
	$(LINKCC) $(REC_CONTROL_OBJECTS) $(LDFLAGS) -o $@

