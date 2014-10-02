#!ruby
# -*- coding: utf-8 -*-
 
# save_retrieved_documents
#   Yahoo$B$K$*$$$F%/%(%j$G8!:w$7$F!$$=$N7k2L$rJ]B8$9$k!%(B
#
#   yahoo_search:   Yahoo$B8!:w%(%s%8%s%/%i%9(B
#   web_client:     URL$B$X$N%"%/%;%9C4Ev%/%i%9(B
#   query:          $B%/%(%j$rMWAG$H$9$kG[Ns(B
#   page_start:     $B2?%Z!<%8L\$+$i8!:w$9$k$+!%(B(1$B0J>e(B)
#   retrieve_times: $B2?%Z!<%88!:w$9$k$+!%(B 
#   out_dir:        $B7k2L$NJ]B8%G%#%l%/%H%j(B
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
                       
                        # $B%U%!%$%kL>$O(Bquery+$B%Z!<%8HV9f(B.txt
                        output_file_name = out_dir + query.join("+") + "_" + sprintf("%03d",10*(i-1) + j) + ".txt"
                        output_file = open(output_file_name, "w") 
                        output_file.puts body
                    rescue
                        # $B2?$+$i$N860x$G%(%i!<$,$G$?$i!$<!$N%Z!<%8$rFI$`(B
                        next
                    end
                end
            end
        rescue
            # $B2?$+$i$N860x$G%(%i!<$,$G$?$i!$<!$N%Z!<%8$rFI$`(B
            next
        end
    end
end

