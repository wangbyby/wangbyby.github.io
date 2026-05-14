---
title: "agent"
date: 2026-05-09

---

最近在看一个开源的agent项目。
有一个问题当输入"find files with ABCD name"时候，agent开始进行web search。
由此，我不太确定agent是如何理解输入意图的。

其实是把输入提示词发给llm，让llm决定使用不使用工具调用。
然后agent执行工具调用，然后拼接结果再给llm发过去。



> 终端打印颜色注意背景残留，先恢复默认背景再换行解决`printf("%-*s", width, text); /*用空格填充整行*/     printf("\x1b[0m\n");`
> inkv5不支持box的backgroundColor，需要更高版本

