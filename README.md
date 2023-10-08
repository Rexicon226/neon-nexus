# Nexus

Nexus is an SDK for writing DOS applications/games based on Jay Petacat's [dos.zig](https://github.com/jayschwa/dos.zig). 

We've expanded on the original library to include:

- Better FatPtr support/use
- More `<dos.h>` and `<conio.h>` compatibility
- A simple graphics API
  - Using DPMI VGA access
  - And a simple 320x200x256 mode (mode 13h) graphics API 
  - **MORE COMING SOON**


## Setup

Install:

- [Zig](https://ziglang.org) (version 0.11.0 or newer)
- [DOSBox](https://www.dosbox.com)

## Run A Test Program

Each file in the `programs` directory is a test program. To run one, use the following command:

```bash
zig build run-{MODULE_NAME}
```

For example, to run `programs/demo.zig`, use the following command:

```bash
zig build run-demo
```

## Docs

- [Development Sources](./docs/SOURCES.md)

## Legal

```
To comply with the CWSDPMI license, published programs must provide notice to users that they have the right to receive the source code and/or binary updates for CWSDPMI. Distributors should indicate a site for the source in their documentation.
```
You can find the CWSDPMI source code [here](https://github.com/jayschwa/cwsdpmi).