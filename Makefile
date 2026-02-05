# Build AFF4 -> TSK bridge without CMake.
#
# The build is intended to work both inside and outside Nix shells.
# In a Nix shell, NIX_AFF4_CPP_LITE and NIX_SLEUTHKIT are exported by shell.nix.

CC ?= cc
CFLAGS ?= -O2 -g -Wall -Wextra -fPIC
CPPFLAGS ?=
LDFLAGS ?=

PREFIX ?= /usr/local
LIBDIR ?= $(PREFIX)/lib
INCLUDEDIR ?= $(PREFIX)/include

OUT_LIB := libaff4tsk.so
OUT_TEST := test_aff4tsk

AFF4_PREFIX ?= $(NIX_AFF4_CPP_LITE)
TSK_PREFIX ?= $(NIX_SLEUTHKIT)

PKG_CONFIG ?= pkg-config

# Prefer pkg-config when available; fall back to Nix prefix variables.
PKG_CFLAGS := $(shell $(PKG_CONFIG) --cflags tsk aff4 2>/dev/null)
PKG_LIBS := $(shell $(PKG_CONFIG) --libs tsk aff4 2>/dev/null)

FALLBACK_CFLAGS := $(if $(TSK_PREFIX),-I$(TSK_PREFIX)/include,) $(if $(AFF4_PREFIX),-I$(AFF4_PREFIX)/include,)
FALLBACK_LIBS := $(if $(TSK_PREFIX),-L$(TSK_PREFIX)/lib,) $(if $(AFF4_PREFIX),-L$(AFF4_PREFIX)/lib,) -ltsk -laff4

DEPS_CFLAGS := $(if $(PKG_CFLAGS),$(PKG_CFLAGS),$(FALLBACK_CFLAGS))
DEPS_LIBS := $(if $(PKG_LIBS),$(PKG_LIBS),$(FALLBACK_LIBS))

all: $(OUT_LIB) $(OUT_TEST)

$(OUT_LIB): aff4_tsk_img.c aff4_tsk_img.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEPS_CFLAGS) -shared -o $@ aff4_tsk_img.c $(LDFLAGS) $(DEPS_LIBS) -lpthread

$(OUT_TEST): test.c $(OUT_LIB)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEPS_CFLAGS) -o $@ test.c -L. -laff4tsk $(LDFLAGS) $(DEPS_LIBS) -lpthread

install: $(OUT_LIB)
	install -d $(DESTDIR)$(LIBDIR) $(DESTDIR)$(INCLUDEDIR)
	install -m 0755 $(OUT_LIB) $(DESTDIR)$(LIBDIR)/$(OUT_LIB)
	install -m 0644 aff4_tsk_img.h $(DESTDIR)$(INCLUDEDIR)/aff4_tsk_img.h

clean:
	rm -f $(OUT_LIB) $(OUT_TEST)

.PHONY: all clean install
