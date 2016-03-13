# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Makefile

ifndef KITURA_CI_BUILD_SCRIPTS_DIR
KITURA_CI_BUILD_SCRIPTS_DIR = .
endif

UNAME = ${shell uname}

CC_FLAGS = -Xcc -fblocks

ifeq ($(UNAME), Darwin)
SWIFTC_FLAGS =  -Xswiftc -I/usr/local/include
LINKER_FLAGS = -Xlinker -L/usr/local/lib
endif

all: build

build:
	@echo --- Running build on $(UNAME)
	@echo --- Build scripts directory: ${KITURA_CI_BUILD_SCRIPTS_DIR}
	@echo --- Checking swift version
	swift --version
ifeq ($(UNAME), Linux)
	@echo --- Checking Linux release
	-lsb_release -d
	@echo --- Fetching dependencies
	swift build --fetch
	@echo --- Invoking swift build
	swift build $(CC_FLAGS) $(SWIFTC_FLAGS) $(LINKER_FLAGS) `bash ${KITURA_CI_BUILD_SCRIPTS_DIR}/make_ccflags_for_module_maps`
else
	@echo --- Invoking swift build
	swift build $(CC_FLAGS) $(SWIFTC_FLAGS) $(LINKER_FLAGS)
endif

test: build
	@echo --- Invoking swift test
	swift test

run: build
	@echo --- Invoking KituraSample executable
	./.build/debug/KituraSample

refetch:
	@echo --- Removing Packages directory
	rm -rf Packages
	@echo --- Fetching dependencies
	swift build --fetch

clean:
	@echo --- Invoking swift build --clean
	swift build --clean

.PHONY: clean build refetch run test
