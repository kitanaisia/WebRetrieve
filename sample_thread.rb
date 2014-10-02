#!ruby
# -*- coding: utf-8 -*-

require "./lib/scraiping"
require "./extractcontent/lib/extractcontent"
require "nkf"
require "./retrieveFunc"

# >>>>>>>>>> 検索語を設定 <<<<<<<<<<
query = ["自然言語処理", "キーワード抽出"]

# >>>>>>>>>> 検索エンジンインスタンス初期化 <<<<<<<<<<
web_client = Scraiping::WebClient.new       # Webアクセスを担当するインスタンスを生成
yahoo_search = Scraiping::YahooSearch.new   # Yahoo検索エンジンのインスタンスを生成
yahoo_search.web_client = web_client        # 検索結果ページへのアクセスにweb_clientインスタンスを使用

# >>>>>>>>>> パラメータ設定 <<<<<<<<<<
page_start = 1                              # 1ページ目から検索する
retrieve_times = 3                          # 10ページ分(1~100件)検索する
out_dir = "./result/"                       # 検索文書を保存するディレクトリ
thread_max = 2

# >>>>>>>>>> 検索エンジンを使用して検索 <<<<<<<<<<
thread_arr = []

# スレッドの担当する検索ページ数を計算
thread_retrieve_times = Array.new(thread_max, (retrieve_times / thread_max).floor)
for i in 0..(retrieve_times % thread_max)-1 do
    thread_retrieve_times[i] += 1
end

# スレッドの最初の検索ページ数
thread_page_start = page_start
for i in 0..thread_max-1 do
    thread_arr << Thread.new(thread_page_start, thread_retrieve_times[i]) do |page_start, retrieve_times| 
        save_retrieved_documents(yahoo_search, web_client, query, page_start, retrieve_times, out_dir)
    end
    thread_page_start += thread_retrieve_times[i]
    sleep 3
end

thread_arr.each { |thread| 
    thread.join
}

