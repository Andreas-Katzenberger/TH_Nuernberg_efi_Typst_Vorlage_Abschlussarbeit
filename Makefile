MAIN = thesis.typ
OUTPUT = thesis.pdf

.PHONY: watch compile clean

# Standard-Befehl (ausgeführt bei einfachem 'make')
watch:
	typst watch $(MAIN) $(OUTPUT)

compile:
	typst compile $(MAIN) $(OUTPUT)

clean:
	rm $(OUTPUT)