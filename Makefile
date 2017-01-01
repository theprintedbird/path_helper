.PHONY: all
all: install postscript

PREFIX  := /usr/local/libexec/
MKDIR   := mkdir -p
CHMOD   := 0755

.PHONY: install
install:
	@printf "Installing…\n"
	$(MKDIR) $(PREFIX)
	install -m $(CHMOD) ./path_helper $(PREFIX)

.PHONY: postscript
postscript:
	@printf "\nYou may find it helpful to add this to your env files:\n\nif [ -x $(PREFIX)path_helper ]; then\n"
	@printf "  eval \`$(PREFIX)path_helper\`"
	@printf "\nfi\n"
