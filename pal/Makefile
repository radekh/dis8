# File: pdp8progs/Makefile
# Makefile for building small testing pdp8 programs.
# Copyright (c) 2010 Radek Hnilica.

sources = $(shell ls *.pal)
rims	= $(subst .pal,.rim,$(sources))
bins    = $(subst .pal,.bin,$(sources))
lists   = $(subst .pal,.lst,$(sources))
revs    = $(subst .pal,.rev,$(sources))

dis8	= ../dis8.rb

.PHONY: all clean superclean
all: $(lists) $(revs)
clean:
	-rm *~

superclean: clean
	-rm *.lst *.bin *.rim *.rev

# Generic rules
%.lst: %.pal
	pal $<
%.rim: %.pal
	pal -r $<
%.bin: %.pal
	pal $<
%.rev: %.bin %.dis $(dis8)
	$(dis8) $* >$@

# Specific rule
