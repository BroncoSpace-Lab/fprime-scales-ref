# Builds lucid_live_view against the LUCID Arena SDK + OpenCV.
# Normally driven from the repo root: `make camera-viewer-setup`, `make camera-view`.
#
# x86_64 (ground/host PC): Arena SDK for Linux x64 (LUCID download), default
#   ~/ArenaSDK-x64/ArenaSDK_Linux_x64, installed by `make camera-viewer-setup`.
# aarch64 (Jetson): the ARM64 SDK already in this repo (lib/ArenaSDK, `make arena-init`).
# Override with: make ARENA=/path/to/ArenaSDK_Linux_x64

UNAME_M := $(shell uname -m)
REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)

ifeq ($(UNAME_M),aarch64)
ARENA ?= $(REPO_ROOT)/lib/ArenaSDK
ARENA_LIB := $(ARENA)/lib
GENICAM_LIB := $(ARENA)/GenICam/library/lib/Linux64_ARM
else
ARENA ?= $(HOME)/ArenaSDK-x64/ArenaSDK_Linux_x64
ARENA_LIB := $(ARENA)/lib64
GENICAM_LIB := $(ARENA)/GenICam/library/lib/Linux64_x64
endif
FFMPEG_LIB := $(ARENA)/ffmpeg

# JetPack's libopencv-dev (4.8) ships an opencv4.pc that says prefix=/usr/local while
# the files are in /usr; re-point pkg-config when the advertised headers are missing.
OPENCV_INC := $(shell pkg-config --variable=includedir opencv4 2>/dev/null)
ifeq ($(wildcard $(OPENCV_INC)/opencv2/core.hpp),)
OPENCV_PC_FIX := --define-variable=prefix=/usr
endif
OPENCV_CFLAGS := $(shell pkg-config $(OPENCV_PC_FIX) --cflags opencv4 2>/dev/null)
OPENCV_LIBS := $(shell pkg-config $(OPENCV_PC_FIX) --libs opencv4 2>/dev/null)

CXXFLAGS = -std=c++14 -O2 -w \
	-I$(ARENA)/include/Arena -I$(ARENA)/include/Save -I$(ARENA)/include/GenTL \
	-I$(ARENA)/GenICam/library/CPP/include $(OPENCV_CFLAGS)
# RPATH (not RUNPATH, so it also covers the SDK libraries' own dependencies): runs
# without ldconfig registration, e.g. with the repo's ARM64 SDK on the Jetson
LDFLAGS = -L$(ARENA_LIB) -L$(GENICAM_LIB) -L$(FFMPEG_LIB) \
	-Wl,--disable-new-dtags -Wl,-rpath,$(ARENA_LIB):$(GENICAM_LIB):$(FFMPEG_LIB)
LDLIBS = -larena -lsave -lgentl -llucidlog \
	-lGCBase_gcc54_v3_3_LUCID -lGenApi_gcc54_v3_3_LUCID -lLog_gcc54_v3_3_LUCID \
	-llog4cpp_gcc54_v3_3_LUCID -lMathParser_gcc54_v3_3_LUCID -lNodeMapData_gcc54_v3_3_LUCID \
	-lXmlParser_gcc54_v3_3_LUCID \
	$(OPENCV_LIBS) -lpthread

.PHONY: all
all: lucid_live_view lucid_set_ip

.PHONY: check-sdk
check-sdk:
	@test -f $(ARENA)/include/Arena/ArenaApi.h || { echo "Arena SDK not found at $(ARENA) (run 'make camera-viewer-setup' from the repo root)"; exit 1; }

lucid_live_view: lucid_live_view.cpp Makefile | check-sdk
	@pkg-config --exists opencv4 || { echo "OpenCV dev files missing (run 'make camera-viewer-setup' from the repo root)"; exit 1; }
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(LDLIBS)

# Persistent-IP tool: Arena SDK only, no OpenCV
lucid_set_ip: lucid_set_ip.cpp Makefile | check-sdk
	$(CXX) $(filter-out $(OPENCV_CFLAGS),$(CXXFLAGS)) $< -o $@ $(LDFLAGS) $(filter-out $(OPENCV_LIBS),$(LDLIBS))

.PHONY: clean
clean:
	rm -f lucid_live_view lucid_set_ip
