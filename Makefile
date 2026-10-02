# for pipefail
SHELL=/bin/bash
.SECONDARY:
.DELETE_ON_ERROR:

check:
	git diff --color=always

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

# Optimized PNG copies used when building the update zips. Each file
# under opt/ is regenerated only when its source image is newer, so
# repeated builds only spend time on changed images. zopflipng picks the
# smallest lossless encoding, switching to a palette PNG when that wins.

PNG_SRCS := $(shell find graphics -type f -name '*.png')
PNG_OPT := $(patsubst %.png,opt/%.png,$(PNG_SRCS))

.PHONY: optimize-pngs
optimize-pngs: $(PNG_OPT)

opt/%.png: %.png
	@mkdir -p $(@D)
	@zopflipng -y $< $@.tmp >/dev/null 2>&1 || true
	@if [ ! -s $@.tmp ] || [ ! $$(wc -c < $@.tmp) -lt $$(wc -c < $<) ]; \
	then cp $< $@.tmp; fi
	@mv $@.tmp $@
	@printf "%s: %d -> %d bytes\n" "$<" $$(wc -c < $<) $$(wc -c < $@)
