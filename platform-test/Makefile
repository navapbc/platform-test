.PHONY = \
	clean \
	clean-infra \
	install-infra \
	install-flask \
	install-nextjs

clean: clean-infra

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

	# clean up template-infra folder
	rm -fr template-infra

clean-infra:
	rm docker-compose.yml
	rm -fr infra/
	rm -fr docs/