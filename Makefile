# for pipefail
SHELL=/bin/bash
.SECONDARY:
.DELETE_ON_ERROR:

check:
	git diff --exit-code

XMLS = $(shell find -type f -name '*.xml')
check: check-xml
check-xml: $(patsubst %.xml,out/%.xml.ok,${XMLS})
	find -name '*.xml.ok' -delete
	find -name '*.xml.out' -delete
out/%.xml.ok: %.xml out/%.xml.out
	diff -u $^
	touch $@
out/%.xml.out: %.xml
	mkdir -p ${@D}
	set -e -o pipefail; \
	xmllint --format --schema tools/tmw.xsd $< 2>&1 > $@ | grep -v 'Skipping import of schema' 1>&2

check: xsd
xsd:
	xmllint --format --schema tools/dl/XMLSchema.xsd tools/tmw.xsd > tmw-formatted.xsd
	diff tools/tmw.xsd tmw-formatted.xsd
	rm tmw-formatted.xsd
