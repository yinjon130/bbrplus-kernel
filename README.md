# bbrplus 内核 4.14.129（CentOS 7 x86_64 预编译二进制，第三方再分发）

> **语言：** [English](README.en.md) · 中文

一个可直接安装的 **BBRplus 拥塞控制算法 Linux 内核**预编译包，内核版本
`4.14.129-bbrplus`，面向 **CentOS 7 / RHEL 7 x86_64** 虚拟机。

本仓库**不是原创项目**，只是对社区已有二进制内核的再分发与安装便利化整理，
著作权归原作者所有，内核本身基于 Linux（GPL-2.0）。来源与署名见下方[来源与致谢](#来源与致谢)。

---

## ⚠️ 重要提示（先读）

- 这是一个 **2019 年编译的老旧内核（Linux 4.14.129）**，仅适用于**已停止维护的 CentOS 7**。
  现代发行版（Debian 11+/Ubuntu 22.04+/Rocky 9 等）的官方内核已内置 BBR/BBRv2，**不需要本包**。
- 安装第三方内核有**无法开机（变砖）**风险。请务必：
  1. 先在可重装/可控制台救援的测试机上验证；
  2. **保留旧内核**，不要删除，出问题可在 GRUB 启动菜单回滚；
  3. 云主机请确认厂商支持更换内核（部分云厂商锁定内核）。
- 本仓库提供的是**未修改的第三方预编译二进制**，使用者**自行承担一切风险**。
  建议在生产环境使用前自行从源码编译，源码补丁见上游项目。
- 编译指纹（二进制内嵌）：`4.14.129-bbrplus (root@vultr.guest) gcc 4.8.5 (CentOS 7) #1 SMP Tue Jun 25 12:23:41 UTC 2019`。

## 文件

| 文件 | 说明 |
|---|---|
| `kernel/kernel-bbrplus.tar.gz` | 内核完整包（53 MB，3068 个文件），含 `vmlinuz`、`System.map`、`config` 及 `/usr/lib/modules/4.14.129-bbrplus/` 全部模块（含 `tcp_bbrplus.ko`） |
| `kernel/SHA256SUMS.txt` | 压缩包 SHA-256 校验值 |
| `install.sh` | 安装脚本（备份 → 解包 → 重建 initramfs → 配置 GRUB → 写入 sysctl） |
| `uninstall.md` | 回滚到旧内核的方法 |

## 它解决什么问题

BBRplus 是社区在 Google BBR 基础上魔改的拥塞控制算法，主要调整了丢包判断与发包行为，
在**高丢包、长肥网链路（如部分国际线路）**下，相比默认的 cubic 往往能获得更好的吞吐与恢复能力。
配套队列调度算法必须使用 **`fq`**（不要用 `fq_codel`/`pfifo_fast`）。

> 它**不改变物理线路与峰值带宽上限**，只优化拥塞控制行为，效果因线路而异。

## 安装（CentOS 7 x86_64）

```bash
# 1. 下载并校验
KVER=4.14.129-bbrplus
# 将 kernel/kernel-bbrplus.tar.gz 上传到服务器后：
cd /path/to/download
sha256sum -c SHA256SUMS.txt    # 应输出 kernel-bbrplus.tar.gz: OK

# 2. 以 root 运行安装脚本（脚本会先做环境检查与备份）
sudo bash install.sh kernel-bbrplus.tar.gz

# 3. 重启
sudo reboot

# 4. 验证
uname -r                       # 应为 4.14.129-bbrplus
sysctl net.ipv4.tcp_congestion_control   # bbrplus
sysctl net.core.default_qdisc             # fq
lsmod | grep bbrplus          # 模块已加载
```

安装脚本做的事：解包到 `/`、`depmod`、用 `dracut` 重建包含 virtio 等半虚拟化驱动的
initramfs（解决云主机无 initramfs 无法识别磁盘的问题）、将 GRUB 默认启动项设为新内核、
在 `/etc/sysctl.d/99-bbrplus.conf` 写入 `bbrplus + fq`。

## 回滚

见 [uninstall.md](uninstall.md)。旧内核默认保留，控制台 GRUB 菜单选旧条目即可临时回退。

## 来源与致谢

- 本二进制源自社区流传的 bbrplus 4.14.129 自编译内核（2019）。
- BBRplus 算法补丁与构建方法参考：
  - 原始 bbrplus 项目：<https://github.com/cx9208/bbrplus>
  - 4.14 自编译与补丁整理（UJX6N）：<https://github.com/UJX6N/bbrplus>（含 `convert_official_linux-4.14.x_src_to_bbrplus.patch`）
- Linux 内核：<https://www.kernel.org>，版权归 Linus Torvalds 及各贡献者所有，许可证 GPL-2.0。

本仓库仅为在自有设备上留存与便利安装而再分发；如原作者对署名或分发有异议，请联系移除。

## 免责声明

本仓库与 BBRplus / Linux 原作者无隶属关系。所有内容“按现状”提供，不提供任何明示或暗示担保。
在任何生产系统使用前请自行评估与测试。请遵守你所在地区的法律法规。
