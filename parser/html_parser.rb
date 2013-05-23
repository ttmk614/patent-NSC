#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'date' 
require 'mysql2'
require 'timeout'
require 'net/http'
require_relative  'branch'
require_relative  'tables'

@root_url = "http://patft.uspto.gov"
@file_name = "file_date_" + ARGV[0]
@f = File.open(@file_name, "a")
@err_log = File.open("err_log_" + ARGV[0], "a")

def get_html( html )
    begin # Get HTML of patent_id
        #s = "SELECT `Html` FROM `content_#{year}` WHERE `Patent_id`='#{patent_id}'"
        #puts s
        #res = @new_patent.query( s )
        if html
          # puts html
          blocks = html.gsub(/'/, "''").gsub(/(?i)(<th)/, "<td").gsub(/(?i)(th>)/, "td>").split(/(?i)(<hr>)/)
          r = []
          r << Nokogiri::parse(html)
          blocks.each do |block|
            r << Nokogiri::parse("<html>" + block + "</html>")
          end
          # puts "--------------------"
          # puts r[-3]
          return r
        else          
          return ["not found"]
        end
    rescue Exception => ex
      puts "Error: #{ex}"
      reconnect_new_patent()
      retry
    end
end 
def get_start_page(year)
  begin
    start_url = @root_url+"/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=0&p=1&f=S&l=50&Query=isd%2F1%2F1%2F#{year}-%3E12%2F31%2F#{year}&d=PTXT"
    start_page = Nokogiri::HTML(open(start_url))
  rescue => e
    puts "Start_page  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  return start_page
end

def get_jump_page(year, num)
  begin
    start_url = @root_url+"/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=0&f=S&l=50&d=PTXT&RS=ISD%2F#{year}0101-%3E#{year}1231&Query=isd%2F1%2F1%2F#{year}-%3E12%2F31%2F#{year}&TD=176082&Srch1=%40PD%3E%3D#{year}0101%3C%3D#{year}1231&StartAt=Jump+To&StartAt=Jump+To&StartNum=#{num}"
    start_page = Nokogiri::HTML(open(start_url))
  rescue => e
    puts "Start_page  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  return start_page
end

def get_next_page(url)
  begin
    next_page = Nokogiri::HTML(open(url))
  rescue => e
    puts "Next_page  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  return next_page
end

def crawl_patent(page)
  table = page.css('table')[1]
  tr = table.css('tr')
  (1..tr.to_a.count-1).each do |i|
    td = tr[i].css('td')
    patent_id = td[1].text.gsub(/,/,"") # 專利id
    puts patent_id
    # html 為每個專利文件的 html source code
    html = get_html(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{patent_id}.PN.&OS=PN/#{patent_id}&RS=PN/#{patent_id}").read())
    # paragraphs = html[0].xpath('//p')
    #table of Patent##########################
    # for i in 0..10
    #   puts html[i]
    #   puts "++++++++"
    # end
    patent_attrs = []
    i = 3
    ########################### A Patent_id := patent_id  
    ########################### A issue_date  
    patent_attrs << issue_date( html[i] )
    i += 2
    ########################### Claims for Design patent
    # if (html[i].xpath("//text()")[0].to_s.strip <=> "Claims")==0
    #   patent_attrs << getRelatedPatent(html[i+1].xpath("//tr")[2..-2].to_s)
    #   i += 2
    # end
    ########################### A title   
    patent_attrs << title( html[i] )
    ########################### A abstract    
    patent_attrs << abstract( html[i] )
    i += 2

    ########################### Skip Design Patent's Claims
    if (html[i].xpath("//text()")[0].to_s.strip <=> "Claims")==0
      i += 2  
    end
    ########################### C inventors_line  ////////////////////////////now!!!!!!
    patent_attrs << getInventor(html[i])
    ########################### A assignee_line  
    assigneeTemp = assignee_line( html[i] )
    patent_attrs << assigneeTemp
    assignee_num = assigneeTemp == "" ? "0" : "1"
    ########################### A appl_id
    patent_attrs << appl_id( html[i] )
    ########################### A filing_date
    patent_attrs << filing_date( html[i] )
    i += 2 # i = 5
    ########################### A relt_appl_id, A relt_filing_date, A relt_patent_id, A relt_issue_date
    # only one or more relt????????????????
    if (html[i].xpath("//text()")[0].to_s.strip <=> "Related U.S. Patent Documents")==0
      patent_attrs << getRelatedPatent( html[i+2].xpath("//tr")[2..-2].to_s )
      # a = RelatedPatent.new(html[i+1].xpath("//tr")[2..-2].to_s)
      # # puts a.relatedTable
      # a.relatedTable[0].each do |content|
      #   patent_attrs << content[1]
      # end
      # # patent_attrs << a.relatedTable[0][1][1]#-----------["relt_appl_id", "09490342"]---------
      # # patent_attrs << a.relatedTable[0][2][1]
      # # patent_attrs << a.relatedTable[0][3][1]
      # # patent_attrs << a.relatedTable[0][4][1]
      i += 4
    else
      # (1..4).each do |j|
      #   patent_attrs << nil
      # end
      patent_attrs << nil
    end
    
    ########################### B USPC_line
    pctable = html[i].xpath("//table").last
    uspc = USPC.new(pctable.xpath("tr[1]/td[2]")[0].to_s)
    # uspc = USPC.new(html[i].xpath("//tr[1]/td[2]")[0].to_s)
    patent_attrs << uspc.uspcLine
    ########################### B IPC_line
    ipc = IPC.new(pctable.xpath("tr[2]/td[2]")[0].to_s)
    patent_attrs << ipc.ipcLine 
    ########################### B CPC_line 
    cpc = nil
    if (html[i].xpath("//text()")[0].to_s.strip <=> "Current CPC Class")==0
      cpc = CPC.new(pctable.xpath("tr[2]/td[2]")[0].to_s)
      patent_attrs << cpc.cpc_line
    else
      patent_attrs << nil
    end
    ########################### A Field_of_Search_line
    patent_attrs << field_of_search_line( html[i] )
    i += 4 #/////////////////////now

    ########################### C Reference_USPTO, Reference_Foreign, Reference_Other
    reference = getReferences(issued_year, patent_id, html[i].to_s)
    patent_attrs << reference['references_uspto']
    patent_attrs << reference['references_foreign']
    patent_attrs << reference['other_references']

    ########################### A primary_examiner
    patent_attrs << primary_examiner( html[i] )
    i += 2


    while html[i] && (html[i].xpath("//text()")[0].to_s.strip <=> "Claims")!=0
      i+=2
    end

    ########################### Claims--claims_full, claim_num, dept_claim_num, indept_claim_num
    if (html[i] && html[i].xpath("//text()")[0].to_s.strip <=> "Claims")==0
      claim = Claim.new( html[i+1].xpath('//body')[0].to_s.gsub(/<\/*body>/, "").gsub(/^.*(?=<)/, "" ))
      # print claim.claimsFull
      patent_attrs << claim.claimsFull
      patent_attrs << claim.claimNum
      patent_attrs << claim.deptClaimNum
      patent_attrs << claim.indeptClaimNum
      i += 4
    else
      (1..4).each do |j|
        patent_attrs << nil
      end
    end
    ########################### description_full
    patent_attrs << description( html[-3] )
    # patent_attrs.each do |x|
    #   puts x
    # end
    # MEMO: patent_id is not added into array patent_attrs
    # INSERTION
    inventor_info = patentToInventor(patent_id, patent_attrs[3] )
    begin
      Timeout::timeout(600){
        s = "INSERT INTO `patent`.`patent_#{issued_year}` 
          (`patent_id`, `issue_date`, `title`, `abstract`, 
           `inventors_line`, `assigne_line`, `appl_id`, `filing_date`, 
           `relt_patent_id`,
           `USPC_line`, `IPC_line`, `CPC_line`, `field_of_search_line`, 
           `reference_USPTO`, `reference_foreign`, `reference_other`, 
           `primary_examiner`, `claim_full`, `claim_num`, `dept_claim_num`, `indept_claim_num`, `description_full`,
           `inventor_num`, `assignee_num`) 
          VALUES ("
        s = s + "'#{patent_id}'"
        patent_attrs.each do |att|
          s = s + ", '#{att}'"
        end

        s = s + ", '#{inventor_info.size}', '#{assignee_num}' )"
        # puts patent_attrs.size
        # File.open("query.txt", "w") { |file| file.write(s) }
        @patent.query( s )
        puts "patent done!"
      }
    rescue => ex
        puts "Error: #{ex}"
      reconnect_patent()
      retry
    end
    ####################################################################################
    #table of Inventor##################################################################
    ####################################################################################
    inventor_info = patentToInventor(patent_id, patent_attrs[3] )
    begin
      Timeout::timeout(600){
        inventor_info.each do |row|
          s = "INSERT INTO `patent`.`inventor_#{issued_year}` 
            (`patent_id`, `inventor_name`, `inventor_location`, 
             `inventor_location_country`, `inventor_location_state`, `inventor_location_city`) 
            VALUES ("
          s = s +  "'#{patent_id}', '#{row['inventor_name']}', '#{row['inventor_location']}', 
                '#{row['inventor_location_country']}', '#{row['inventor_location_state']}', '#{row['inventor_location_city']}'"
          # inventor_info.each do |att|
          #   s = s + ", '#{att}'"
          # end
          s = s + ')'

          # File.open("query_inventor.txt", "w") { |file| file.write(s) }
          @patent.query( s )
        end
        
        puts "inventor done!"
      }
    rescue => ex
        puts "Error: #{ex}"
      reconnect_patent()
      retry
    end
    ####################################################################################
    #table of USPC######################################################################
    ####################################################################################
    begin
      Timeout::timeout(600){
        uspc.uspcTable.each do |row|

          s = "INSERT INTO `patent`.`uspc_#{issued_year}` 
            (`patent_id`, `USPC_class`, `level_1`, `level_2`) 
            VALUES ("
          s = s + "'#{patent_id}', '#{row['USPC_class']}', '#{row['level_1']}', '#{row['level_2']}'"
          
          s = s + ')'
          # File.open("query_uspc.txt", "w") { |file| file.write(s) }
          @patent.query( s )
        end
        puts "uspc done!"
      }
    rescue => ex
        puts "Error: #{ex}"
      reconnect_patent()
      retry
    end
    ####################################################################################
    #table of IPC#######################################################################
    ####################################################################################
    begin
      Timeout::timeout(600){
        ipc.ipcTable.each do |row|

          s = "INSERT INTO `patent`.`ipc_#{issued_year}` 
            (`patent_id`, `IPC_class`, `main_class`, `level_1`, `level_2`, `version`) 
            VALUES ("
          s = s + "'#{patent_id}', '#{row['IPC_class']}', '#{row['main_class']}', '#{row['level_1']}', '#{row['level_2']}', '#{row['version']}'"

          s = s + ')'
          # File.open("query_ipc.txt", "w") { |file| file.write(s) }
          @patent.query( s )
        end
        puts "ipc done!"
      }
    rescue => ex
        puts "Error: #{ex}"
      reconnect_patent()
      retry
    end
    ####################################################################################
    #table of CPC#######################################################################
    ####################################################################################
    begin
      Timeout::timeout(600){
        if cpc != nil
          cpc.cpcTable.each do |row|
            s = "INSERT INTO `patent`.`cpc_#{issued_year}` 
              (`patent_id`, `CPC_class`, `main_class`, `level_1`, `level_2`, `version`) 
              VALUES ("
            s = s + "'#{patent_id}', '#{row['CPC_class']}', '#{row['main_class']}', '#{row['level_1']}', '#{row['level_2']}', '#{row['version']}'"

            s = s + ')'
            # File.open("query_cpc.txt", "w") { |file| file.write(s) }
            @patent.query( s )
          end
          puts "cpc done!"
        end
      }
    rescue => ex
        puts "Error: #{ex}"
      reconnect_patent()
      retry
    end
    ####################################################################################
    #table of Reference#################################################################
    ####################################################################################
    #do inside getReferences??
  end
end

def get_file_date(html)
  html.css('table').each do |table|
    if /Filed:/ =~ table.content then
      begin
        return Date.parse(table.xpath('tr[4]//text()')[2].to_s.strip)
      rescue  #若html檔資料格式不同則每個都試試看
        return Date.parse(table.xpath('tr[3]//text()')[2].to_s.strip)
      end
    end
  end
end

def get_next_url(page)
  next_page = page.css('table')[2].css('td a')
  if next_page.to_a.count == 4
    next_page_url = @root_url+next_page[0]['href'].gsub(/>/, "%3E")
    if next_page_url.match(/Page=Prev/)
      next_page_url = nil
    end
  elsif next_page.to_a.count == 5
    next_page_url = @root_url+next_page[1]['href'].gsub(/>/, "%3E")
  end
  return next_page_url
end

puts "process start\n"
start_time = Time.now
@new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')
@patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent')
puts "database connected"

if ARGV.count == 1
  @issued_year = ARGV[0]
  page = get_start_page(@issued_year)
  next_url = get_next_url(page)
elsif ARGV.count == 2
  @issued_year = ARGV[0]
  num = ARGV[1]
  page = get_jump_page(@issued_year, num)
  next_url = get_next_url(page)
end

while !next_url.nil?
  crawl_patent(page)
  next_url = get_next_url(page)
  puts ">>>> next_url >>>>"
  if !next_url.nil?
    page = get_next_page(next_url)
  else
    puts "END PAGE"
  end
end

@f.close
@err_log.close
puts "Process Duration: #{Time.now - start_time} seconds\n"
puts "Process end"
