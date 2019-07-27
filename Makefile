.PHONY: all
all: install postscript

PREFIX  := /usr/local/libexec
MKDIR   := mkdir -p
CHMOD   := 0755

.PHONY: install
install:
	@printf "Installing…\n"
	$(MKDIR) $(PREFIX)
	install -m $(CHMOD) ./path_helper.rb $(PREFIX)

.PHONY: postscript
postscript:
	@printf "\nYou may find it helpful to add this to your env files if using the shell version:\n\nif [ -x $(PREFIX)/path_helper ]; then\n"
	@printf "  eval \`$(PREFIX)/path_helper\`"
	@printf "\nfi\n"
	@printf "\nIf using the ruby version (my preferred one):\n"
	@printf "\nif [ -x "
	@printf $(PREFIX)
	@printf "/path_helper.rb ]; then\n"
	@printf '  PATH=$$('
	@printf "$(PREFIX)/path_helper.rb -p \"\""
	@printf ")\nfi\n"
