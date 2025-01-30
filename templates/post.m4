define(`_NL', '
')dnl
define(`_FILENAME', translit(esyscmd(`date +%F'), _NL))dnl
define(`_FILE', _FILENAME`-'_SUFFIX`.md')dnl
changequote(`[',`]')dnl
define([_CONTENT],[
---
layout: post
title: "_TITLE"
description: "_TITLE"
date: _FILENAME[T07:00:00-07:00]
tags: _TAGS
---
])dnl
esyscmd([echo '] _CONTENT [' > ] _FILE)dnl
_CONTENT
File is written to _FILE
