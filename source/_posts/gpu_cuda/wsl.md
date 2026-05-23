
---
title: "wsl2 & cuda"
date: 2026-05-23
---


# wsl2 NCU 错误

1. Failed to initialize the profiler
```txt
==ERROR== An error was reported by the counter measurement library:
==ERROR== Failed to initialize the profiler: LibraryNotLoaded. Check that a compatible driver library is loaded.
==PROF== Trying to shutdown target application
==ERROR== The application returned an error code (9).
```
ncu和驱动的cuda版本不一致。
根据nvidia-smi安装对于cuda版本

# wsl2 nsys采样问题

- nsys不打印kernel时间

检查步骤：
1. 查看windwos测NVIDIA控制面板，开启开发者模式+GPU采样对所有用户开放
2. https://forums.developer.nvidia.com/t/nsys-doesnt-show-cuda-kernel-and-memory-data/315536 
3. 检查驱动和cuda-toolkit版本是否一致