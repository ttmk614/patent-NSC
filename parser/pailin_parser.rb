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

def crawl_patent(pid)
# begin
  # html 為每個專利文件的 html source code
  html = Nokogiri::parse(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{pid}.PN.&OS=PN/#{pid}&RS=PN/#{pid}"))
  #puts html
  result = get_reissued_patent_id_and_inventer_line(html)
  @f.write("#{pid}\t#{result[0]}\t#{result[1]}\n")
  #puts "#{pid}\t#{result[0]}\t#{result[1]}"
# rescue => e
#   @err_log.write("#{pid}\t#{e.to_s}\n")
#   next
# end
end

def get_reissued_patent_id_and_inventer_line(html)
  result = Array.new(2) {nil}
  #result = nil
  tempTime = 250012
  html.css('table').each do |table|
    #tmp = table.content
    #puts tmp
    if /Reissue of:/ =~ table.content then
      table.css('tr').each do |each|
        # puts each
        if each.at_css('td[4]')
          thisTime = (Date._parse(each.css('td[2]').text.strip)[:year].to_s+Date._parse(each.css('td[2]').text.strip)[:mon].to_s.rjust(2, '0')).to_i  #判斷filing date才知哪一個是最初的patent ex.RE41046 in 2008
          if each.css('td[4]').text != "" && ( thisTime < tempTime)
            # puts "++++"+each.css('td[4]').text.strip
              tempTime = thisTime
              result[0] = each.xpath("td[4]").text.upcase.gsub(/[^A-Z0-9]/, "")
              result[0] = result[0].gsub(/^0/,"")
          end
        end
      end
    else
      table.css('tr').each do |tuple|
        if /Inventors:/ =~ tuple.content then
          inventors_line = ''
          tuple.css('td b').each do |info|
          #puts info.content + info.next.content
          if /^[A-Z][A-Z]$/ =~ info then
            inventors_line += '%'
          end
          #puts inventors_line
          inventors_line = inventors_line + info.content.gsub(',', '#') + info.next.content
          end
          #puts inventors_line
          result[1] = inventors_line.to_s.gsub(/'/, "''") 
        end
      end
    end
  end
  if result[0] == nil 
    result[0] = "nil"
  end
  return result
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

def issued_year( )
  #2008
  text = File.read( "../issueyear.txt" )
  lines = text.split("\n")
  table = Hash.new
  lines.each do |line|
    line = line.split(/\s+/)
    table[line[0]] = line[1..line.size-1]
  end
  return table
end

puts "process start\n"
start_time = Time.now
issued_year_table = issued_year()
@year = ARGV[0]

if ARGV.count == 1
  begin_patent = issued_year_table[@year].first
elsif ARGV.count == 2
  begin_patent = ARGV[1]
end
begin_header = begin_patent.scan(/\D+/).first

go_on = false

this_yr_category_num = issued_year_table[@year].length
this_yr = issued_year_table[@year]
next_yr = issued_year_table[(@year.to_i+1).to_s]
(0..this_yr_category_num-1).each do |n|
  str_header = this_yr[n].scan(/\D+/).first
  #p str_header
  if begin_header == str_header or go_on == true
    if go_on == false
      begin_number = begin_patent.gsub("#{begin_header}", "").to_i
      go_on = true
    else
      begin_number = this_yr[n].gsub("#{str_header}", "").to_i
    end

    (begin_number..(next_yr[n].gsub("#{str_header}", "").to_i)).each do |patent_num|
      #puts patent_num
      patent_id = "#{str_header}#{patent_num}"
      puts patent_id
      crawl_patent(patent_id)
    end
  end
end

@f.close
@err_log.close
puts "Process Duration: #{Time.now - start_time} seconds\n"
puts "Process end"
