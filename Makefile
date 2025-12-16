RESULT := sop.bin
SYMBOLS_TMP := symbols.tmp
SYMBOLS := symbols.txt
SRCS := $(shell find src -type f -name '*.asm')

.PHONY: all run
all: $(RESULT) $(SYMBOLS)

$(SYMBOLS): $(SYMBOLS_TMP)
	python3 convert_symbols.py $(SYMBOLS_TMP) $@

$(RESULT): tmp.bin
	head -c 512 $< > $@
$(SYMBOLS_TMP): tmp.bin
	tail -c +513 $< > $@
tmp.bin: $(SRCS)
	nasm -f bin -O0 -I src src/sop.asm -o $@

clean:
	rm -f *.bin *.img $(SYMBOLS) $(SYMBOLS_TMP)

# --- Examples ---

.PHONY: helloworld
helloworld: helloworld.img
helloworld.img: sop.bin helloworld.bin
	cat $^ > $@
helloworld.bin: examples/helloworld.asm all
	nasm -f bin -I src $< -o $@

.PHONY: color
color: color.img
color.img: sop.bin color.bin
	cat $^ > $@
color.bin: examples/color.asm all
	nasm -f bin -I src $< -o $@
