# Platform Test Makefile
#
# This Makefile is used to test the platform.
# We avoided calling it `Makefile` in order to avoid conflicting with the
# Makefile that comes with the platform in `template-infra`

.PHONY = \
	clean \
	clean-infra \
	install-infra \
	install-flask \
	install-nextjs

# The git ref to use to upgrade from
UPGRADE_REF ?= $(shell git rev-parse --abbrev-ref HEAD)

clean: clean-app clean-infra

install-infra:
	# fetch latest version of template-infra
	git clone --single-branch --branch main --depth 1 git@github.com:navapbc/template-infra.git

	# copy over template files
	cp -r \
		template-infra/.github \
		template-infra/bin \
		template-infra/docs \
		template-infra/infra \
		template-infra/Makefile \
		.

	rm .github/workflows/template-only-*

	# clean up template-infra folder
	rm -fr template-infra

install-application-nextjs:
	# fetch latest version of template-application-nextjs
	git clone --single-branch --branch main --depth 1 git@github.com:navapbc/template-application-nextjs.git

	# copy app decision records
	mkdir -p docs/
	cp -r template-application-nextjs/docs/decisions/ docs/decisions/

	# copy app code
	cp -r template-application-nextjs/app/ app/

	# clean up template-application-nextjs folder
	rm -fr template-application-nextjs

install-application-flask:
	# fetch latest version of template-application-flask
	git clone --single-branch --branch main --depth 1 git@github.com:navapbc/template-application-flask.git

	# copy app decision records
	mkdir -p docs/
	cp -r template-application-flask/docs/decisions/ docs/decisions/

	# copy app code
	cp -r template-application-flask/app/ app/

	# clean up template-application-flask folder
	rm -fr template-application-flask

upgrade-infra-modules:
	git clone --single-branch --branch $(UPGRADE_REF) --depth 1 git@github.com:navapbc/template-infra.git
	cp -r template-infra/infra/modules infra/
	cp -r template-infra/infra/app/env-template/ infra/app/env-template/
	rm -fr template-infra

clean-app:
	rm -fr app/

clean-infra:
	rm -fr infra/
	rm -fr bin/
	rm -fr docs/
	rm -fr .github/
	rm Makefile
