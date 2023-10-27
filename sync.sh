#!/bin/bash

git pull github master

git add ./
git commit -m "sync"
git push github
git push gitee master