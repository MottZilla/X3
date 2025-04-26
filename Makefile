VERSION ?= eu

BUILD_DIR := build
TOOLS	  := tools
PYTHON	  := python3

TARGET = x3_ps.exe
SPLAT           ?= $(PYTHON) $(TOOLS)/splat/split.py
SPLAT_YAML      ?= $(TARGET).$(VERSION).yaml

extract:
	@$(RM) -r asm/$(VERSION)
	@echo "Unifying yamls..."
	@cp ./yamls/eu/splat.x3_ps.exe.eu.yaml ./x3_ps.exe.eu.yaml
	@echo "Extracting..."
	@$(SPLAT) $(SPLAT_YAML)