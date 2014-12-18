#!ruby
# -*- coding: utf-8 -*-

require "./lib/scraiping"
require "./extractcontent/lib/extractcontent"
require "nkf"
require "./retrieveFunc"

# >>>>>>>>>> 検索語を設定 <<<<<<<<<<
query = ARGV

# >>>>>>>>>> 検索エンジンインスタンス初期化 <<<<<<<<<<
web_client = Scraiping::WebClient.new       # Webアクセスを担当するインスタンスを生成
yahoo_search = Scraiping::YahooSearch.new   # Yahoo検索エンジンのインスタンスを生成
yahoo_search.web_client = web_client        # 検索結果ページへのアクセスにweb_clientインスタンスを使用

# >>>>>>>>>> パラメータ設定 <<<<<<<<<<
page_start = 1                              # 1ページ目から検索する
retrieve_times = 3                         # 10ページ分(1~100件)検索する
out_dir = "./result/"                       # 検索文書を保存するディレクトリ

# >>>>>>>>>> 検索エンジンを使用して検索 <<<<<<<<<<
save_retrieved_documents(yahoo_search, web_client, query, page_start, retrieve_times, out_dir)
