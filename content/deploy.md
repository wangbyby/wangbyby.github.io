+++
title = "使用zola设置github.io作为个人博客"
slug = "deploy"

+++

步骤如下：

1. 本地安装zola
2. 运行`zola init <your blog dir>`, like `zola init myblog`

目录如下：
```txt
myblog/
├── config.toml          # 配置文件
├── content/             # 内容文件（Markdown）
├── sass/                # Sass 样式文件（可选）
├── static/              # 静态资源（图片、CSS、JS 等）
├── templates/           # 模板文件（HTML）
└── themes/              # 主题文件（可选）
```
- 创建的博客就放在content下面。
- 图片放在static/images下面，在博客里用`![test](/images/a.png)`引用
- 博客格式：`+++`一定要有
```txt
+++
title = "我的第一篇文章"
+++

## hello zola
```

3. `cd <your blog dir> && git init`将这些目录加到版本控制进去。
4. 添加自定义模板`teplates/index.html`和`teplates/page.html`
5. 创建github actions: `.github/workflows/deploy.yml`
内容如下：
```yml
name: Deploy Zola site to GitHub Pages

on:
  push:
    branches:
      - master  # 触发部署的分支

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install Zola
        run: |
          wget https://github.com/getzola/zola/releases/download/v0.19.2/zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz
          tar -xzf zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz
          sudo mv zola /usr/local/bin

      - name: Build site
        run: zola build

      - name: Deploy to GitHub Pages
        uses: shalzz/zola-deploy-action@master
        env:
            PAGES_BRANCH: gh-pages
            TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
这里注意分支。
- master分支是我们源文件的分支
- gh-pages分支是制品分支

> 参考：[zola github-actions](https://www.getzola.org/documentation/deployment/github-pages/#github-actions)

6. 推送到 `git@github.com:<username>/<username>.github.io.git`
7. 设置github pages:
![alt text](/images/image-github-pages.png)

8. 如果上传图片，设置`config.toml`中`base_url = "https://<username>.github.io/"`
8. 等待github actions完成，就OK了

-----

之前用hexo，但图片上传太麻烦了:(
zola图片上传也没有那么方便