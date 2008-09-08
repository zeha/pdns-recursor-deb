# user editable stuff:
SBINDIR=/usr/sbin/
BINDIR=/usr/bin/
CONFIGDIR="/etc/powerdns/"
OPTFLAGS?=-O3
CXXFLAGS:= $(CXXFLAGS) -Wall -DBOOST_SP_DISABLE_THREADS $(OPTFLAGS) $(PROFILEFLAGS)
CFLAGS:=$(CFLAGS) -Wall $(OPTFLAGS) $(PROFILEFLAGS)
LINKCC=$(CXX)
CC?=gcc

# Lua 5.1 settings
LUA_CPPFLAGS_CONFIG ?= -I/usr/include/lua5.1
LUA_LIBS_CONFIG ?= -llua5.1

# Lua 5.0 settings
#LUA_CPPFLAGS_CONFIG=-I/usr/include/lua50 
#LUA_LIBS_CONFIG=-llua50 -llualib50

# static dependencies

PDNS_RECURSOR_OBJECTS=syncres.o  misc.o unix_utility.o qtype.o logger.o  \
arguments.o lwres.o pdns_recursor.o recursor_cache.o dnsparser.o \
dnswriter.o dnsrecords.o rcpgenerator.o base64.o zoneparser-tng.o \
rec_channel.o rec_channel_rec.o selectmplexer.o sillyrecords.o \
dns_random.o aescrypt.o aeskey.o aes_modes.o aestab.o lua-pdns-recursor.o

REC_CONTROL_OBJECTS=rec_channel.o rec_control.o arguments.o 

# what we need 
all: message pdns_recursor rec_control 

# OS specific instructions
-include sysdeps/$(shell uname).inc

ifeq ($(LUA), 1)
	LUALIBS=$(LUA_LIBS_CONFIG)
	CXXFLAGS+=$(LUA_CPPFLAGS_CONFIG) -DPDNS_ENABLE_LUA
endif


ifeq ($(STATIC),semi)
	STATICFLAGS=-Wl,-Bstatic -lstdc++ $(LUALIBS) -lgcc -Wl,-Bdynamic -static-libgcc -lm -lc
	LINKCC=$(CC)
	LDFLAGS += malloc.o -ldl -lm
else ifeq ($(STATIC),full)
	STATICFLAGS=-lstdc++ $(LUALIBS) -ldl -lm -static 
	LINKCC=$(CC)
else
	LDFLAGS += malloc.o $(LUALIBS)
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
	$(CXX) $(CXXFLAGS) -MM -MG *.cc *.c *.hh > $@

-include dep

optional:
	mkdir optional

pdns_recursor: optional $(OPTIONALS) $(PDNS_RECURSOR_OBJECTS) malloc.o
	$(LINKCC) $(PDNS_RECURSOR_OBJECTS) $(wildcard optional/*.o) $(LDFLAGS) -o $@

rec_control: $(REC_CONTROL_OBJECTS)
	$(LINKCC) $(REC_CONTROL_OBJECTS) $(LDFLAGS) -o $@

