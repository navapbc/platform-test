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

clean: clean-app clean-infra

install-infra:
	# fetch latest version of template-infra
	git clone --single-branch --branch main --depth 1 git@github.com:navapbc/template-infra.git

	# copy docker-compose.yml
	cp template-infra/docker-compose.yml .

	# copy infra decision records
	mkdir -p docs/
	cp -r template-infra/docs/decisions/ docs/decisions/

	# copy infra code
	cp -r template-infra/infra/ infra/

	# copy github actions
	cp -r template-infra/.git/workflows/ .git/workflows

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

clean-app:
	rm -fr app/

clean-infra:
	rm -f docker-compose.yml
	rm -fr infra/
	rm -fr .git/workflows
	rm -fr docs/
