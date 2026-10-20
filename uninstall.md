# 回滚到旧内核

安装脚本不会删除旧内核。如果新内核无法启动或想恢复：

## 方法一：GRUB 启动菜单临时回退（推荐先试）

1. 在云主机控制台（VNC/串口）重启，进入 GRUB 启动菜单。
2. 选择旧内核条目（非 `4.14.129-bbrplus` 的那一项，通常是 `3.10.0-xxx.el7.x86_64`）。
3. 进系统后如果确认要永久切回，执行下面的方法二。

## 方法二：在系统内永久切回旧内核

```bash
# 查看已安装内核
grubby --info=ALL | grep -E 'kernel=|title='

# 查看当前默认
grubby --default-kernel

# 把默认设回某个旧内核（替换为实际路径）
sudo grubby --set-default /boot/vmlinuz-3.10.0-1160.el7.x86_64

# 重新生成 grub 配置
[ -d /sys/firmware/efi ] && sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg \
                        || sudo grub2-mkconfig -o /boot/grub2/grub.cfg

sudo reboot
uname -r   # 确认已切回
```

## 方法三：彻底卸载 bbrplus 内核

切回旧内核并重启确认正常后：

```bash
sudo rm -f /boot/vmlinuz-4.14.129-bbrplus \
           /boot/System.map-4.14.129-bbrplus \
           /boot/config-4.14.129-bbrplus \
           /boot/initramfs-4.14.129-bbrplus.img
sudo rm -rf /usr/lib/modules/4.14.129-bbrplus
sudo rm -f /etc/sysctl.d/99-bbrplus.conf
sudo sysctl --system
sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # EFI 用 /boot/efi/EFI/centos/grub.cfg
```

若要恢复拥塞算法为系统默认，可在 `/etc/sysctl.conf` 删除/改为：

```
net.ipv4.tcp_congestion_control = cubic
net.core.default_qdisc = fq_codel
```
