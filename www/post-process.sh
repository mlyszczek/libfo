#!/bin/sh

# add single new line before about in index.html
sed -i 's/<h1 id="synopsis">/<h1 id="synopsis" class="first">/' "out/index.html"

# man2html strips "" from include, let's get them back
sed -i 's/include\&nbsp;fo.h/include\&nbsp;\&quot;fo.h\&quot;/' out/manuals/*
