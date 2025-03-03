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
9. 等待github actions完成，就OK了

------

# 部署静态网址到服务器

需要
1. 一个云服务器，带ip地址/域名的

步骤如下
  1. 在云服务器安装zola（pre-build比较好）
  2. **在服务器安装nginx**
  3. 拉取博客代码到服务器：`git clone example_blog@git`
  4. 运行命令`cd example_blog && zola build -u ""`. 构建好的文件在`example_blog/public`下
  5. `cp public /var/www/static-site -r`
  6. 给nginx权限并确保自己有权限`sudo chown -R $USER:$USER /var/www/static-site && sudo chown -R www-data:www-data /var/www/static-site && sudo chmod -R 755 /var/www/static-site`
  7. 修改nginx的配置文件（ai生成的）
    - 新建配置文件`/etc/nginx/sites-available/static-site.conf`
    - 添加内容

    ```conf
    server {
      listen 80;
      server_name example.com;  # 替换为你的域名或服务器 IP（如 192.168.1.100）

      root /var/www/static-site;  # 静态文件根目录
      index index.html index.htm;  # 默认索引文件

      location / {
          try_files $uri $uri/ =404;  # 按顺序查找文件或目录，否则返回 404
      }

      # 可选：启用 Gzip 压缩
      gzip on;
      gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    }
    ```

    - 设置符号链接`sudo ln -s /etc/nginx/sites-available/static-site.conf /etc/nginx/sites-enabled/`

  8. 重启nginx  `sudo nginx -t && sudo systemctl reload nginx`

>坑
>1. 本来打算用nginx做为动态转发，服务器后台跑个zola serve，结果发现zola build出来的都有端口`ip:1111/xxx`. 此路不通
>2. 然后就用静态网页。最开始有403，权限问题。然后发现博客的url链接是`ip/ip/xxx`, 用`zola build -u ""`可以处理掉。然后就OK啦 

-----

之前用hexo，但图片上传太麻烦了:( zola图片上传也没有那么方便。
ai真好用，特别是这种琐碎的安装部署。