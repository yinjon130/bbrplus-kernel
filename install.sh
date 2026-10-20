#!/usr/bin/env bash
#
# install.sh — 安装 4.14.129-bbrplus 预编译内核（CentOS/RHEL 7 x86_64）
#
# 用法：sudo bash install.sh kernel-bbrplus.tar.gz
#
# 作用：解包内核 -> depmod -> 重建含 virtio 驱动的 initramfs ->
#       设置 GRUB 默认启动项 -> 写入 bbrplus + fq sysctl 配置。
#
# 注意：脚本不会删除旧内核；执行完需手动 reboot。
set -euo pipefail

KVER="4.14.129-bbrplus"
TARBALL="${1:-}"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "请用 root 运行：sudo bash install.sh <tar.gz>"
[ -n "$TARBALL" ] || die "未指定内核包。用法：sudo bash install.sh kernel-bbrplus.tar.gz"
[ -f "$TARBALL" ] || die "文件不存在：$TARBALL"

ARCH="$(uname -m)"
[ "$ARCH" = "x86_64" ] || die "本包仅支持 x86_64，当前架构：$ARCH"

if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}" in
    centos|rhel|rocky|almalinux) ;;
    *) warn "当前系统 ID=${ID:-unknown}，不是 CentOS/RHEL 系，继续但不保证可用。" ;;
  esac
fi

if [ -e "/boot/vmlinuz-${KVER}" ] || [ -d "/usr/lib/modules/${KVER}" ]; then
  warn "检测到 ${KVER} 已存在，将覆盖/更新文件。"
fi

log "当前内核：$(uname -r)"
log "解包内核文件到 / ..."
tar xzf "$TARBALL" -C /

[ -f "/boot/vmlinuz-${KVER}" ] || die "解包后未找到 /boot/vmlinuz-${KVER}"
[ -d "/usr/lib/modules/${KVER}" ] || die "解包后未找到 /usr/lib/modules/${KVER}"

log "执行 depmod ${KVER} ..."
depmod "$KVER"

INITRAMFS="/boot/initramfs-${KVER}.img"
log "重建 initramfs：$INITRAMFS"
# 云主机常见 virtio 磁盘/网卡驱动务必打进 initramfs，否则可能无法启动。
if command -v dracut >/dev/null 2>&1; then
  dracut --force \
    --add-drivers "virtio_blk virtio_scsi virtio_pci virtio_console virtio_net xfs ext4" \
    "$INITRAMFS" "$KVER"
elif command -v mkinitrd >/dev/null 2>&1; then
  mkinitrd -f --with=virtio_blk --with=virtio_scsi --with=virtio_pci --with=virtio_net \
    "$INITRAMFS" "$KVER"
else
  die "未找到 dracut 或 mkinitrd，无法生成 initramfs。"
fi

log "设置 GRUB 默认启动项为 ${KVER} ..."
if command -v grubby >/dev/null 2>&1; then
  grubby --set-default="/boot/vmlinuz-${KVER}"
else
  # 兜底：CentOS 7 grub2
  MENU_ENTRY=$(awk -F\' '/menuentry / {print $2}' /boot/grub2/grub.cfg \
    | grep -F "$KVER" | head -n1 || true)
  [ -n "$MENU_ENTRY" ] || die "未能在 GRUB 菜单找到 $KVER"
  grub2-set-default "$MENU_ENTRY"
fi
if [ -d /sys/firmware/efi ]; then
  grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg >/dev/null
else
  grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null
fi

log "写入 /etc/sysctl.d/99-bbrplus.conf ..."
cat > /etc/sysctl.d/99-bbrplus.conf <<EOF
# BBRplus congestion control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbrplus
EOF
sysctl --system >/dev/null

log "安装完成。当前 GRUB 默认内核："
grubby --default-kernel 2>/dev/null || true
cat <<EOF

下一步：
  1. 检查上方默认内核是否包含 ${KVER}
  2. 重启：reboot
  3. 重启后验证：
       uname -r
       sysctl net.ipv4.tcp_congestion_control
       sysctl net.core.default_qdisc
       lsmod | grep bbrplus

如无法启动，在控制台 GRUB 菜单选择旧内核进入，然后按 uninstall.md 回滚。
EOF
