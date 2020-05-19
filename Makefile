.PHONY: all
all: install postscript

PREFIX  := /usr/local/libexec
MKDIR   := mkdir -p
CHMOD   := 0755

.PHONY: install
install:
	@printf "Installing…\n"
	$(MKDIR) $(PREFIX)
	$(MKDIR) $(PHLIB)
	install -m $(CHMOD) exe/path_helper $(PREFIX)

.PHONY: postscript
postscript:
	@printf "\nYou may find it helpful to add this to your ~/.zshenv or ~/.bashenv etc:\n"
	@printf "\nif [ -x "
	@printf $(PREFIX)
	@printf "/path_helper ]; then\n"
	@printf '  PATH=$$('
	@printf "$(PREFIX)/path_helper -p \"\""
	@printf ")\n"
	@printf '  DYLD_FALLBACK_FRAMEWORK_PATH=$$('
	@printf "$(PREFIX)/path_helper --dyld-fram \"\""
	@printf ")\n"
	@printf '  DYLD_FALLBACK_LIBRARY_PATH=$$('
	@printf "$(PREFIX)/path_helper --dyld-lib \"\""
	@printf ")\n"
	@printf '  C_INCLUDE_PATH=$$('
	@printf "$(PREFIX)/path_helper -c \"\""
	@printf ")\n"
	@printf '  MANPATH=$$('
	@printf "$(PREFIX)/path_helper -m \"\""
	@printf ")\n"
	@printf "fi\n"
	@printf "\n\n"
	@printf "export PATH\n"
	@printf "export DYLD_FALLBACK_FRAMEWORK_PATH\n"
	@printf "export DYLD_FALLBACK_LIBRARY_PATH\n"
	@printf "export C_INCLUDE_PATH\n"
	@printf "export MANPATH\n"
