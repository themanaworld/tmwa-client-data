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

# Discord Rich Presence minimap generation
DISCORD_MINIMAPS_DIR = discord_minimaps
MAP_TMXS = $(wildcard maps/*.tmx)
DISCORD_MINIMAPS = $(patsubst maps/%.tmx,$(DISCORD_MINIMAPS_DIR)/%.png,$(MAP_TMXS))

.PHONY: discord discord-clean
discord: $(DISCORD_MINIMAPS)

discord-clean:
	@echo "[discord] Cleaning minimap directory"
	@rm -rf $(DISCORD_MINIMAPS_DIR)

$(DISCORD_MINIMAPS_DIR)/%.png: maps/%.tmx
	@mkdir -p $(DISCORD_MINIMAPS_DIR)
	@echo "[discord] Rendering $< -> $@"
	@tmxrasterizer --hide-layer Collision --hide-object-layers $< $@.full.png
	@magick $@.full.png -resize 512x512^ -gravity center -extent 512x512 -filter Lanczos $@.tmp.png
	@mv $@.tmp.png $@
	@rm -f $@.full.png
