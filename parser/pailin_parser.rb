#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'date' 

@root_url = "http://patft.uspto.gov"
@file_name = "file_date_" + ARGV[0]
@f = File.open(@file_name, "a")
@err_log = File.open("err_log_" + ARGV[0], "a")

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
    pid = td[1].text.gsub(/,/,"") # 專利id
    # begin
      # html 為每個專利文件的 html source code
      html = Nokogiri::parse(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{pid}.PN.&OS=PN/#{pid}&RS=PN/#{pid}"))

      reissued_patent_id = get_reissued_patent_id(html)
      # @f.write("#{pid}\t#{reissued_patent_id}\n")
      puts "#{pid}\t#{reissued_patent_id}"
    # rescue => e
    #   @err_log.write("#{pid}\t#{e.to_s}\n")
    #   next
    # end
  end
end

def get_reissued_patent_id(html)
  result = nil
  tempTime = 250012
  html.css('table').each do |table|
    if /Reissue of:/ =~ table.content then
      table.css('tr').each do |each|
        # puts each
        if each.at_css('td[4]')
          thisTime = (Date._parse(each.css('td[2]').text.strip)[:year].to_s+Date._parse(each.css('td[2]').text.strip)[:mon].to_s.rjust(2, '0')).to_i  #判斷filing date才知哪一個是最初的patent ex.RE41046 in 2008
          if each.css('td[4]').text != "" && ( thisTime < tempTime)
            # puts "++++"+each.css('td[4]').text.strip
              tempTime = thisTime
              result = each.xpath("td[4]").text.upcase.gsub(/[^A-Z0-9]/, "")
              result = result.gsub(/^0/,"")
          end
        end
      end
    end
  end
  return result == nil ? "nil" : result
end


# def get_reissued_patent_id(html)
#   result = nil
#   html.css('table').each do |table|
#     if /Reissue of:/ =~ table.content then
#       table.css('tr').each do |each|
#         # puts each
#         if each.at_css('td[3]')
#           if each.css('td[3]').text != ""
#               result = each.xpath("td")[3].text.upcase.gsub(/[^A-Z0-9]/, "")
#               result = result.gsub(/^0/,"")
#           end
#         end
#       end
#     end
#   end
#   return result == nil ? "nil" : result
# end

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

if ARGV.count == 1
  @year = ARGV[0]
  page = get_start_page(@year)
  next_url = get_next_url(page)
elsif ARGV.count == 2
  @year = ARGV[0]
  num = ARGV[1]
  page = get_jump_page(@year, num)
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
