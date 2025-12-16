# sop overview
## Introduction
`sop` (_Sector OPerations_) is an x86 BIOS bootsector (<=510 bytes) that implements a fully-working command line.
`sop` is very extensible and easily hackable: you can add your own commands, make them run at boot, and alter the existing ones as well as internal behavior. All labels (aka _function symbols_) are public and can be monkeypatched and trampolined.

## Features
This terminal-like interface supports:
- Text-mode screen assertion
- ASCII BIOS keyboard with backspace support
- One-way scrolling
- Clearing

The command-line enters a prompt loop in which commands can be ran. Out of the box, there are two supported commands which allow bootstrapping an enhanced shell:
- `l` is for _load_. Loads a sector into a given address.
  - Usage: `l <.4 hex address> <.4 hex cylinder> <.4 hex head> <.4 hex sector>`
  - Example: `l 8000 0001 0001 0002`
- `c` is for _call_. Performs a `call` to a given address.
  - Usage: `c <.4 hex address>`
  - Example: `c 8000`

## How to use
Download the latest release, or clone the repository and run `make`. This will generate `sop.bin` and `symbols.txt`.
- `sop.bin` contains sop; that is, the bootsector
- `symbols.txt` is a generated NASM source that addresses the labels (functions)

## Examples
Example extensions are available under `examples/`. The following ship with sop:
- `make helloworld`: execute `l 8000 0000 0000 0002` and `c 8000`. Prints `Hello world!`.
- `make color`: no need to execute anything. Adds a `color` command which behaves like the DOS one.
  - Usage: `color 00<.2 hex color>`
  - Example: `color 00F1`

## Available functions
`symbols.txt` includes addresses for SOP labels. These are the most useful:
- `printz` prints a null-terminated string to screen
- `print_char` prints only one character
- `clear` clears the screen
- `get_line` gets a line from keyboard input (blocks)
- `get_char` gets only one character
- `readsect` loads a sector from disk into memory

For usage reference and side-effects, check the comment on top of each function in sop's source.

## Autoload
Extensions can be loaded automatically by sop if their first byte is `0x69`.
- This can only happen with the first extension, the one located at sector 2.
- Unlike a regular sop extension, `ret` is not available, and one must jmp to `SOP_cmd`.
