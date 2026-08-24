VERSION ?= $(shell tr -d '\n' < VERSION)
NAME := ddev-tailnet-proxy
ARCHIVE := dist/$(NAME)-$(VERSION).tar.gz
ROOT := dist/$(NAME)-$(VERSION)

.PHONY: check release clean

check:
	bash tests/validate.sh

release: check
	rm -rf "$(ROOT)"
	mkdir -p "$(ROOT)/bin"
	cp bin/$(NAME) "$(ROOT)/bin/$(NAME)"
	cp README.md LICENSE "$(ROOT)/"
	chmod 755 "$(ROOT)/bin/$(NAME)"
	tar -C dist -czf "$(ARCHIVE)" "$(NAME)-$(VERSION)"
	cd dist && sha256sum "$(NAME)-$(VERSION).tar.gz" > "$(NAME)-$(VERSION).tar.gz.sha256"
	@printf 'Created %s and %s.sha256\n' "$(ARCHIVE)" "$(ARCHIVE)"

clean:
	rm -rf dist
