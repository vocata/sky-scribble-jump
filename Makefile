GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
PROJECT_DIR := $(CURDIR)

.PHONY: run edit check import

run:
	$(GODOT) --path "$(PROJECT_DIR)"

edit:
	$(GODOT) --editor --path "$(PROJECT_DIR)"

check:
	godot --headless --path "$(PROJECT_DIR)" --quit-after 2

import:
	godot --headless --path "$(PROJECT_DIR)" --import
