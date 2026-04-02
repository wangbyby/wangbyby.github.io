---
title: "[WIP] SVF介绍"

---

static value flow，一种模块级别的aa分析（跨函数）。

其基本思路比较简单
- 记录每个指针指向的address
- 在call graph上迭代到不动点


耗时+耗费空间。

