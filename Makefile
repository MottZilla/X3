# VERSION ?= eu
# 
# BUILD_DIR := build
# TOOLS	  := tools
# PYTHON	  := python3
# 
# TARGET = x3_ps.exe
# SPLAT           ?= $(PYTHON) $(TOOLS)/splat/split.py
# SPLAT_YAML      ?= $(TARGET).$(VERSION).yaml
# 
# extract:
# 	@$(RM) -r asm/$(VERSION)
# 	@echo "Unifying yamls..."
# 	@cp ./yamls/eu/splat.x3_ps.exe.eu.yaml ./x3_ps.exe.eu.yaml
# 	@echo "Extracting..."
# 	@$(SPLAT) $(SPLAT_YAML)

.SECONDEXPANSION:
.SECONDARY:

# Binaries
BOOT			:= boot
GAME			:= game
# OVL_AC			:= ac # The Ant Caves

# Compiler
CC1PSX          := ./bin/cc1-psx-26
CROSS           := mipsel-linux-gnu-
AS              := $(CROSS)as
CC              := $(CC1PSX)
LD              := $(CROSS)ld
CPP             := $(CROSS)cpp
OBJCOPY         := $(CROSS)objcopy

# Flags
AS_FLAGS        += -Iinclude -march=r3000 -mtune=r3000 -no-pad-sections -O1 -G0 -march=mips2
PSXCC_FLAGS		:= -quiet -mcpu=3000 -fgnu-linker -mgas -gcoff
CC_FLAGS        += -msplit-addresses -O2 -funsigned-char -w -fpeephole -ffunction-cse -fpcc-struct-return -fcommon -fverbose-asm -msoft-float -g
CPP_FLAGS       += -Iinclude -undef -Wall -fno-builtin
CPP_FLAGS       += -Dmips -D__GNUC__=2 -D__OPTIMIZE__ -D__mips__ -D__mips -Dpsx -D__psx__ -D__psx -D_PSYQ -D__EXTENSIONS__ -D_MIPSEL -D_LANGUAGE_C -DLANGUAGE_C -DHACKS -DUSE_INCLUDE_ASM
LD_FLAGS		:= -nostdlib --no-check-sections

# Directories
ASM_DIR         := asm
SRC_DIR         := src
ASSETS_DIR      := assets
INCLUDE_DIR     := include
BUILD_DIR       := build
CONFIG_DIR      := config
TOOLS_DIR       := tools

# Tooling
MAKE			:= make
PYTHON          := python3
SPLAT_DIR       := $(TOOLS_DIR)/splat
SPLAT_APP       := $(SPLAT_DIR)/split.py
SPLAT           := $(PYTHON) $(SPLAT_APP)
ASMDIFFER_DIR   := $(TOOLS_DIR)/asm-differ
ASMDIFFER_APP   := $(ASMDIFFER_DIR)/diff.py
M2C_DIR         := $(TOOLS_DIR)/m2c
M2C_APP         := $(M2C_DIR)/m2c.py
M2C             := $(PYTHON) $(M2C_APP)
M2C_ARGS        := -P 4
MASPSX_DIR      := $(TOOLS_DIR)/maspsx
MASPSX_APP      := $(MASPSX_DIR)/maspsx.py
MASPSX          := $(PYTHON) $(MASPSX_APP) --no-macro-inc --expand-div


# List source files
define list_src_files
	$(foreach dir,$(ASM_DIR)/$(1),$(wildcard $(dir)/**.s))
	$(foreach dir,$(ASM_DIR)/$(1)/data,$(wildcard $(dir)/**.s))
	$(foreach dir,$(SRC_DIR)/$(1),$(wildcard $(dir)/**.c))
endef

# List object files
define list_o_files
	$(foreach file,$(call list_src_files,$(1)),$(BUILD_DIR)/$(file).o)
endef

# Linking
define link
	$(LD) $(LD_FLAGS) -o $(2) \
		-Map $(BUILD_DIR)/$(1).map \
		-T $(CONFIG_DIR)/ld/$(1).ld \
		-T $(CONFIG_DIR)/symbols.txt \
		-T $(CONFIG_DIR)/symbols.game.txt \
		-T $(CONFIG_DIR)/undefined_syms.txt \
		-T $(CONFIG_DIR)/undefined_syms_auto.$(1).txt \
		-T $(CONFIG_DIR)/undefined_funcs_auto.$(1).txt
endef


# Build
all: build check
# build: boot game overlays
build: game

init:
	$(MAKE) clean
	$(MAKE) extract -j $(nproc)
	$(MAKE) all

### Game Executables ###

# SLES_005.03
# boot: main_dirs $(BUILD_DIR)/SCUS_942.27
# $(BUILD_DIR)/SLES_005.03: $(BUILD_DIR)/$(BOOT).elf
# 	$(OBJCOPY) -O binary $< $@
# $(BUILD_DIR)/$(BOOT).elf: $(call list_o_files,boot)
# 	$(call link,boot,$@)

# X3_PS.EXE
game: game_dirs $(BUILD_DIR)/X3_PS.EXE
$(BUILD_DIR)/X3_PS.EXE: $(BUILD_DIR)/$(GAME).elf
	$(OBJCOPY) -O binary $< $@
$(BUILD_DIR)/$(GAME).elf: $(call list_o_files,game)
	$(call link,game,$@)

%_dirs:
	$(foreach dir,$(ASM_DIR)/$* $(ASM_DIR)/$*/data $(SRC_DIR)/$* $(ASSETS_DIR)/$*,$(shell mkdir -p $(BUILD_DIR)/$(dir)))

### Overlays ###
# overlays: ac

# ac: ovlac_dirs $(BUILD_DIR)/AC.BIN
# $(BUILD_DIR)/AC.BIN: $(BUILD_DIR)/ovlac.elf
# 	$(OBJCOPY) -O binary $< $@
# 
# ovl%_dirs:
# 	$(foreach dir,$(ASM_DIR)/ovl/$* $(ASM_DIR)/ovl/$*/data $(SRC_DIR)/ovl/$* $(ASSETS_DIR)/ovl/$*,$(shell mkdir -p $(BUILD_DIR)/$(dir)))
# 
# $(BUILD_DIR)/ovl%.elf: $$(call list_o_files,ovl/$$*)
# 	$(call link,ovl$*,$@)


# Assembly
$(BUILD_DIR)/%.s.o: %.s
	$(AS) $(AS_FLAGS) -o $@ $<
$(BUILD_DIR)/%.c.o: %.c $(MASPSX_APP) $(CC1PSX)
	$(CPP) $(CPP_FLAGS) -lang-c $< | $(CC) $(CC_FLAGS) $(PSXCC_FLAGS)  | $(MASPSX) | $(AS) $(AS_FLAGS) -o $@


# Checksum
check:
	@sha1sum --check config/X3_PS.EXE.sha


# asm-differ expected object files
expected: check
	mkdir -p expected/build
	rm -rf expected/build/
	cp -r build/ expected/build/


# Assembly extraction
# extract: extract_boot extract_game extract_ovlac extract_ovlag extract_ovlcc extract_ovlch extract_ovlcr extract_ovlcredits extract_ovldc extract_ovlee extract_ovleh extract_ovlgg extract_ovlgs extract_ovlgy1 extract_ovlgy2 extract_ovlhh extract_ovlhr extract_ovlia extract_ovlla extract_ovllandmap extract_ovlpd extract_ovlpg extract_ovlps extract_ovlsf extract_ovlsv extract_ovltd extract_ovltl extract_ovlzl
extract: extract_game

## Main
extract_boot:
	cat $(CONFIG_DIR)/symbols.txt $(CONFIG_DIR)/symbols.boot.txt > $(CONFIG_DIR)/generated.symbols.boot.txt
	$(SPLAT) $(CONFIG_DIR)/splat.boot.yaml

## Game
extract_game:
	cat $(CONFIG_DIR)/symbols.txt $(CONFIG_DIR)/symbols.game.txt > $(CONFIG_DIR)/generated.symbols.game.txt
	$(SPLAT) $(CONFIG_DIR)/splat.game.yaml

## Overlays
extract_ovl%:
	cat $(CONFIG_DIR)/symbols.txt $(CONFIG_DIR)/symbols.ovl$*.txt > $(CONFIG_DIR)/generated.symbols.ovl$*.txt
	$(SPLAT) $(CONFIG_DIR)/splat.ovl$*.yaml


# Cleaning
clean:
	@git clean -fdx asm/
	@git clean -fdx config/
	@git clean -fdx build/


# Formatting
format:
	@./tools/format.py -j $(nproc)

checkformat:
	@./tools/check_format.sh -j $(nproc)


# Phony
.PHONY: init, all, clean, format, checkformat, check, expected
.PHONY: list_src_files, list_o_files, link
.PHONY: boot game ac ag cc ch cr credits dc ee eh gg gs gy1 gy2 hh hr ia la landmap pd pg ps sf sv td tl zl
.PHONY: %_dirs
.PHONY: extract, extract_%
