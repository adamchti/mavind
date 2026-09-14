# tests/

| Script | What it does | Needs |
|---|---|---|
| `run-qemu.sh` | interactive UEFI (or `--bios`) boot in QEMU | `qemu-system-x86`, `ovmf` |
| `smoke-boot.sh` | headless serial boot, waits for the ready marker, exit code | `qemu-system-x86` |
| `run-virtualbox.sh` | create + start a VirtualBox VM for the ISO | `VirtualBox` |
| `vmware.md` | manual VMware setup notes | — |
| `measure-size.sh` | real installed size vs the ~1 GB core target | `unsquashfs` / `xorriso` |
| `measure-ram.sh` | boots headless, reads `free -m` over serial vs the RAM budget | `qemu-system-x86` |
| `test-measure-ram.sh` | regression tests for RAM runner boot arguments and serial reporting (mock QEMU) | Bash, coreutils, grep, sed, awk |
| `windows-apps/run-matrix.sh` | Windows-app compat procedure (stub) | — |

## CI

`.github/workflows/build.yml` runs `build-iso.sh` then `smoke-boot.sh` on every
push to main/master and on pull requests. The components job also runs
`bash tests/test-measure-ram.sh` without building or booting an ISO. This checks
command construction and report handling, not actual desktop RAM usage.
The ISO job attaches a size report; RAM measurement is currently manual.

## Quick loop

```bash
./scripts/build.sh --profile core --keep-work
./tests/smoke-boot.sh build/out/Mavind.iso
./tests/measure-size.sh build/out/Mavind.iso
./tests/run-qemu.sh build/out/Mavind.iso      # eyeball the desktop
```
