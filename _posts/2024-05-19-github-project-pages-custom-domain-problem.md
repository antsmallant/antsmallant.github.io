---
layout: post
title: "解决 github project site 在配置了自定义域名的情况下无法访问的问题"
date: 2024-05-19
last_modified_at: 2024-05-19
categories: [工具]
tags: [tools]
---

* 目录  
{:toc}
<br/>

今天遇到一个 github page 的问题，记录一下。  

---

# 1. 关于 github page

github 有两种 page，一种是 user site，另一种是 project site。user site 只能有一个，project site 可以有 n 个。  

user site 要求仓库名是 `<username>.github.io`，可以通过这样的 url ： `https://<username>.github.io` 访问。  

project site 无仓库名要求，只要在 settings 那里也启用 pages 就行了，可以通过这样的 url ：`https://<username>.github.io\<reponame>` 访问。  

操作很简单，follow github 的这个说明就行了： https://pages.github.com/ 。  

---

# 2. 我的问题 

我有个 user site : https://github.com/antsmallant/antsmallant.github.io ，我在它的 settings 里配置了 custom domain 为 `blog.antsmallant.top`，所以我的 user site 是可以通过 https://blog.antsmallant.top 访问的。  

然而，当我 fork 了一个 repo https://github.com/antsmallant/front-end-playground ，并在 settings 里设置了 pages 后，却无法用 https://blog.antsmallant.top/front-end-playground 去访问，https://antsmallant.github.io/front-end-playground 也是不行的。  

---

# 3. 解决办法

我一下子就怀疑到 custom domain 上了，然后按照这样的步骤就解决了： 

1. 先去 user site 那个 repo，把 custom domain remove 了，刷新了一下，发现可以通过 https://antsmallant.github.io/front-end-playground 访问了。  

2. 然后，再回到 user site 那个 repo，重新设置 custom domain 回去，发现也可以通过 https://blog.antsmallant.top/front-end-playground 访问了。  

---

# 4. 总结

如果配置了 custom domain，那么每次新增 project site，都需要先把 custom domain remove，然后再加回去，才能使 project site 生效。  
