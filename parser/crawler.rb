require 'nokogiri'
require 'open-uri'
require 'mysql2'

start_year = ARGV.shift.to_i
start_index = ARGV.shift.to_i
@patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')

def total_count(year)
  count = @patent.query("SELECT COUNT(*) FROM  `content_#{year}`").to_a[0]['COUNT(*)']
  return count.to_i
end
f = File.open("log_#{start_year}", 'a')
@patent.query("select `Index`, `Patent_id` from `content_#{start_year}` limit #{start_index-1}, #{total_count(start_year)-start_index+1}").to_a.each do |tuple|
	puts "#{tuple['Index']}\t#{tuple['Patent_id']}"
	begin
		page = Nokogiri::HTML(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{tuple['Patent_id']}.PN.&OS=PN/#{tuple['Patent_id']}&RS=PN/#{tuple['Patent_id']}")).to_s.gsub(/\'/, "''").gsub(/\"/, '\"')
		@patent.query("update `content_#{start_year}` set `Html` = \"#{page}\" where `Index` = #{tuple['Index']}")
	rescue => e
		f.write("#{tuple['Index']}\t#{tuple['Patent_id']}\tException: #{e.to_s}\n")
		next
	end
end
f.close
