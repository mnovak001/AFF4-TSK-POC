# Simple Make-based build (no CMake)

PREFIX ?= /usr/local
BUILD_DIR ?= build

CC ?= cc
CXX ?= c++
CFLAGS ?= -O2 -fPIC -Wall -Wextra -Wpedantic
CPPFLAGS ?= -I$(PREFIX)/include
LDFLAGS ?= -L$(PREFIX)/lib

# Core libraries
LIBS ?= -ltsk -laff4 -lpthread

SO_NAME ?= libaff4tsk.so
TEST_BIN ?= test_aff4tsk

SRC_LIB := aff4_tsk_img.c
OBJ_LIB := $(BUILD_DIR)/aff4_tsk_img.o
SRC_TEST := test.c
OBJ_TEST := $(BUILD_DIR)/test.o

.PHONY: all lib test clean dirs

all: lib test

lib: dirs $(BUILD_DIR)/$(SO_NAME)

test: dirs $(BUILD_DIR)/$(TEST_BIN)

dirs:
	@mkdir -p $(BUILD_DIR)

$(OBJ_LIB): $(SRC_LIB) aff4_tsk_img.h | dirs
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(SO_NAME): $(OBJ_LIB)
	$(CXX) -shared $(OBJ_LIB) $(LDFLAGS) $(LIBS) -o $@

$(OBJ_TEST): $(SRC_TEST) aff4_tsk_img.h | dirs
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TEST_BIN): $(OBJ_TEST) $(BUILD_DIR)/$(SO_NAME)
	$(CXX) $(OBJ_TEST) -L$(BUILD_DIR) -laff4tsk $(LDFLAGS) $(LIBS) -Wl,-rpath,'$$ORIGIN' -o $@

clean:
	rm -rf $(BUILD_DIR)
