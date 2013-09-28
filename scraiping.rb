#!/usr/bin/ruby
$KCODE="utf-8"

require "extractcontent"
#================================================================================
#   
#================================================================================

html = File.open("./sampleHTML/ruby2.html").read
opt = {:waste_expressions => /お問い合わせ|会社概要/}
ExtractContent::set_default(opt)

body, title = ExtractContent::analyse(html) # 本文抽出
puts body
