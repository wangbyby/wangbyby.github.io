+++
title = "clang配置"

+++


clangd+vscode在win11上经常崩溃，记录下可能的解决方案。

1. 配置文件冲突

用户和工作区的clangd配置冲突了。用一个就行

2. inlay hints

可以尝试关掉( 不一定有用)

3. clangd配置

```txt
--log=verbose
--background-index=0
-j=1
--clang-tidy
--header-insertion=never
```


4. 设置`--query-driver`
详见https://github.com/clangd/clangd/issues/2187