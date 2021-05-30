STEPS = step0_repl
LIBS = readline
CLIBS = -lreadline

all: $(STEPS)

dist: mal

mal: stepA_mal
	cp $< $@

step0_repl:
	cobc -free -x $(CLIBS) $(STEPS).cob $(LIBS).cob -o $@

# %: %.cob
#	 cobc -free -x $(CLIBS) $*.cob -o $@

.PHONY: clean

clean:
	rm -f $(STEPS)
	rm -f mal
