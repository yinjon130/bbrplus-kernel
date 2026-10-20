# bbrplus Kernel 4.14.129 — CentOS 7 x86_64 prebuilt binary (third-party redistribution)

A ready-to-install prebuilt **BBRplus congestion-control Linux kernel**,
version `4.14.129-bbrplus`, for **CentOS 7 / RHEL 7 x86_64** virtual machines.

This repository is **not the original work**. It redistributes an existing
community-compiled binary for convenient installation on the maintainer's own
devices. All rights belong to the original authors; the kernel is based on
Linux (GPL-2.0). See [Provenance & Credits](#provenance--credits).

> 中文说明见 [README.md](README.md).

## ⚠️ Read first

- This is an **old kernel (Linux 4.14.129) compiled in 2019**, for the
  end-of-life CentOS 7 only. Modern distros already ship BBR/BBRv2 and do
  **not** need this package.
- Installing a third-party kernel can leave a machine **unbootable**. Test on a
  disposable/console-recoverable VM first, **keep the old kernel** for GRUB
  rollback, and confirm your cloud provider allows kernel replacement.
- The binary is provided **unmodified and as-is**; use entirely at your own
  risk. For production, compile from source using the upstream patches.
- Embedded build string: `4.14.129-bbrplus (root@vultr.guest) gcc 4.8.5 (CentOS 7) #1 SMP Tue Jun 25 12:23:41 UTC 2019`.

## Files

- `kernel/kernel-bbrplus.tar.gz` — full kernel payload (53 MB, 3068 files)
- `kernel/SHA256SUMS.txt` — checksum
- `install.sh` — backup/extract/initramfs/GRUB/sysctl installer
- `uninstall.md` — rollback instructions

## Install

```bash
sha256sum -c SHA256SUMS.txt
sudo bash install.sh kernel-bbrplus.tar.gz
sudo reboot
uname -r        # 4.14.129-bbrplus
sysctl net.ipv4.tcp_congestion_control   # bbrplus
sysctl net.core.default_qdisc             # fq
```

## Provenance & Credits

- Original bbrplus: <https://github.com/cx9208/bbrplus>
- 4.14 self-compiled patches: <https://github.com/UJX6N/bbrplus>
- Linux kernel: <https://www.kernel.org> (GPL-2.0)

## Disclaimer

Provided "as-is" without warranty. Evaluate and test before any production use,
and obey applicable laws. Contact the maintainer for removal on copyright
grounds.
