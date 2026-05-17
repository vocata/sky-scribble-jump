GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
PROJECT_DIR := $(CURDIR)
EXPORT_TMP := /tmp/sky_scribble_jump_export
MACOS_CODESIGN_IDENTITY ?= -

.PHONY: run edit check import export-macos

run:
	$(GODOT) --path "$(PROJECT_DIR)"

edit:
	$(GODOT) --editor --path "$(PROJECT_DIR)"

check:
	godot --headless --path "$(PROJECT_DIR)" --quit-after 2

import:
	godot --headless --path "$(PROJECT_DIR)" --import

export-macos:
	rm -rf build "$(EXPORT_TMP)"
	mkdir -p build "$(EXPORT_TMP)"
	$(GODOT) --headless --path "$(PROJECT_DIR)" --export-release "macOS" "$(EXPORT_TMP)/SkyScribbleJump-godot.zip"
	ditto -x -k "$(EXPORT_TMP)/SkyScribbleJump-godot.zip" "$(EXPORT_TMP)"
	if [ "$(MACOS_CODESIGN_IDENTITY)" = "-" ]; then \
		codesign --force --deep --sign - "$(EXPORT_TMP)/Sky Scribble Jump.app"; \
	else \
		codesign --force --deep --options runtime --timestamp --sign "$(MACOS_CODESIGN_IDENTITY)" "$(EXPORT_TMP)/Sky Scribble Jump.app"; \
	fi
	rm -f build/SkyScribbleJump.zip
	ditto -c -k --sequesterRsrc --keepParent "$(EXPORT_TMP)/Sky Scribble Jump.app" build/SkyScribbleJump.zip
