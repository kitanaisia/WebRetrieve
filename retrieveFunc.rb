#!ruby
# -*- coding: utf-8 -*-
 
# save_retrieved_documents
#   Yahooにおいてクエリで検索して，その結果を保存する．
#
#   yahoo_search:   Yahoo検索エンジンクラス
#   web_client:     URLへのアクセス担当クラス
#   query:          クエリを要素とする配列
#   page_start:     何ページ目から検索するか．(1以上)
#   retrieve_times: 何ページ検索するか． 
#   out_dir:        結果の保存ディレクトリ
#
def save_retrieved_documents(yahoo_search, web_client, query, page_start ,retrieve_times, out_dir)
    for i in page_start..(page_start + retrieve_times - 1)
        begin
            urlList = yahoo_search.retrieve(i, query)
            for j in 0..urlList.length-1
                url = urlList[j]
                http_obj = web_client.open(url)
                if http_obj != nil
                    begin
                        encoded_contents = NKF.nkf("-wLu", http_obj.read)
                        body = ExtractContent::analyse(encoded_contents)
                       
                        # ファイル名はquery+ページ番号.txt
                        output_file_name = out_dir + query.join("+") + "_" + sprintf("%03d",10*(i-1) + j) + ".txt"
                        output_file = open(output_file_name, "w") 
                        output_file.puts body
                    rescue
                        # 何からの原因でエラーがでたら，次のページを読む
                        next
                    end
                end
            end
        rescue
            # 何からの原因でエラーがでたら，次のページを読む
            next
        end
    end
end

