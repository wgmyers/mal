STEPS = step0_repl

all: $(STEPS)

dist: mal

mal: stepA_mal
	cp $< $@

%: %.cob
	cobc -free -x $*.cob -o $@

.PHONY: clean

clean:
	rm -f $(STEPS)
	rm -f mal
