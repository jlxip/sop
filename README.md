# sop overview
## Introduction
`sop` is short for _Sector OPerations_.
It's an overengineered x86 real mode BIOS bootsector (<=510 bytes) that implements a fully-working command line.
`sop` is very extensible and easily hackable: you can add your own commands, make them run at boot, and alter the existing ones as well as internal behavior. All labels (aka _function symbols_) are public and can be monkeypatched and trampolined.

## Features
This terminal-like interface supports:
- Text-mode screen assertion
- ASCII-only BIOS keyboard with backspace support
- One-way scrolling
- Clearing

The command-line enters a prompt loop in which commands can be ran. Out of the box, there are two supported commands which allow bootstrapping an enhanced shell:
- `l` is for _load_. Loads a sector into a given address.
  - Usage: `l <.4 hex address> <.4 hex LBA>`
  - Example: `l 8000 0001`
- `c` is for _call_. Performs a `call` to a given address.
  - Usage: `c <.4 hex address>`
  - Example: `c 8000`

## How to use
Clone the repository and run `make`. This will generate `sop.bin` and `symbols.txt`.
- `sop.bin` contains sop; that is, the bootsector
- `symbols.txt` is a generated NASM source that addresses the labels (functions)

Have a look at what you can do first. If you have `qemu` installed, run `make run`.

## Examples
Example extensions are available under `examples/`. The following ship with sop:
- `helloworld`, run with `make runhelloworld`, and execute `l 8000 0001` and `c 8000`. Prints `Hello world!`.
- `color`, run with `make runcolor`, no need to execute anything. Adds a `color` command which behaves like DOS' one.
  - Usage: `color 00<.2 hex color>`
  - Example: `color 00F1`

# sop development
If you want to develop an extension, copy `examples/helloworld.asm` and build on top of that.

## Available functions
`symbols.txt` includes addresses for SOP labels. These are the most useful:
- `printz` prints a null-terminated string to screen
- `print_char` prints only one character
- `clear` clears the screen
- `get_line` gets a line from keyboard input (blocks)
- `get_char` gets only one character
- `readsect` loads a sector from disk into memory
- `dapack_lba` contains the LBA to load when you run `readsect`
- `dapack_offset` contains the addres into which to copy the sector

For usage reference and side-effects, check the comment on top of each function in sop's source.

## Autoload
Extensions can be loaded automatically by sop if their first byte is `0x69`.
- This can only happen with the first extension, the one located at disk's LBA #1.
- Unlike a regular sop extension, `ret` is not available, and one must jmp to `SOP_cmd`.
