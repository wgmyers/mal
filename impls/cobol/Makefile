STEPS = step0_repl
LIBS = readline
CLIBS = -lreadline
ENVFIX = export COB_LDFLAGS='-Wl,--no-as-needed';

all: $(STEPS)

dist: mal

mal: stepA_mal
	cp $< $@

step0_repl: $(LIBS).cob
	$(ENVFIX) cobc -debug -free $(CLIBS) -x $(STEPS).cob $(LIBS).cob -o $@

# %: %.cob
#	 cobc -free -x $(CLIBS) $*.cob -o $@

.PHONY: clean

clean:
	rm -f $(STEPS)
	rm -f mal
