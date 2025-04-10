# BuilderNet Playground

## ⚠️ Pre-Alpha Proof of Concept ⚠️

This project is currently in pre-alpha stage and is being actively developed as a proof of concept. The codebase is under heavy construction and may undergo significant changes.

## Overview

BuilderNet Playground is a toolset for customizing and deploying a local dev instance of BuilderNet, this includes:

- QEMU virtual machine configuration
- Disk encryption
- Ethereum client integration (Reth and Lighthouse)
- Debugging tools
- Integration with [builder-playground](https://github.com/flashbots/builder-playground)

## Status

- This is **experimental software**
- Not ready for production use
- Features and architecture may change without notice
- Documentation is minimal and in progress

## Development

Please refer to the Makefile for available commands to build, inject, and run the environment.

```
make extract   # Extract the initramfs
make inject    # Inject custom scripts
make disk      # Create QEMU disk image
make run       # Run the VM with modified initramfs
```
