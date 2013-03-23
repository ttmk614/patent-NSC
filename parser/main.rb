#!/usr/bin/env ruby
# encoding: UTF-8
require 'mysql2'
require 'timeout'
require 'net/http'
require 'nokogiri'
require 'open-uri'
require_relative  'branch'
require_relative  'tables'

@new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')
puts "database connected"

def get_html( patent_id, year )
    begin # Get HTML of patent_id
        s = "SELECT `Html` FROM `content_#{year}` WHERE `Patent_id`='#{patent_id}'"
        puts s
        res = @new_patent.query( s )
        if res
        	blocks = res.to_a[0]['Html'].split("<hr>")
        	r = []
        	r << Nokogiri::parse(res.to_a[0]['Html'])
        	blocks.each do |block|
        		r << Nokogiri::parse("<html>" + block + "</html>")
        	end
        	return r
        else        	
        	return ["not found"]
        end
    rescue Exception => ex
    	puts "Error: #{ex}"
    	@new_patent.close
    	puts "Reconnect to database..."
    	@new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')
    	retry
    end
end 

#main######################################################
if ARGV.count > 0
	patent_id = ARGV[0]
	puts "issued_year = #{issued_year(patent_id)}"
	html = get_html( patent_id , issued_year( patent_id ))
	tables = html[0].xpath('//table')
	fonts = html[0].xpath('//font')
	paragraphs = html[0].xpath('//p')
	#table of Patent##########################
		patent_attrs = []
		# A Patent_id := patent_id  
		# A issue_date	
		patent_attrs << issue_date( html[2] )
		# A title		
		patent_attrs << title( html[3] )
		# A abstract		
		patent_attrs << abstract( html[3] )
		# C inventors_line 
		patent_attrs << getInventor(html[4])
		# A assignee_line  
		patent_attrs << assignee_line( html[4] )
		# A	appl_id
		patent_attrs << appl_id( html[4] )
		# A	filing_date
		patent_attrs << filing_date( html[4] )

		i = 5
		# A	relt_appl_id, A	relt_filing_date, A	relt_patent_id, A relt_issue_date
		#relt_appl_id = ""
		#relt_filing_date = ""
		#relt_patent_id = ""
		#relt_issue_date = ""
		print html[i].xpath("//text()")[0].to_s.strip 
		if (html[i].xpath("//text()")[0].to_s.strip <=> "Related U.S. Patent Documents")==0
			a = RelatedPatent.new(html[i+1].xpath("//tr")[2..-2].to_s)
			patent_attrs << a.relatedTable[0]['relt_appl_id']
			patent_attrs << a.relatedTable[0]['relt_filing_date']
			patent_attrs << a.relatedTable[0]['relt_patent_id']
			patent_attrs << a.relatedTable[0]['relt_issue_date']
			i += 2
		end
		
		# B	USPC_line ######
		uspc = USPC.new(html[i].xpath("//tr[1]/td[2]")[0].to_s)
		patent_attrs << uspc.uspcLine
		# B	IPC_line
		ipc = IPC.new(html[i].xpath("//tr[2]/td[2]")[0].to_s)
		patent_attrs << ipc.ipcLine		
		# B	CPC_line ########
		if (html[i].xpath("//text()")[0].to_s.strip <=> "Current CPC Class")==0
			cpc = CPC.new(html[i].xpath("//tr[2]/td[2]")[0].to_s)
		end
		# A	Field_of_Search_line
		patent_attrs << field_of_search_line( html[i] )
		
		i += 2
		# C	Reference_USPTO
		# C	Reference_Foreign
		# C	Reference_Other
		reference = getReferences(html[i].to_s)

		# A	primary_examiner
		patent_attrs << primary_examiner( html[i] )

		# Claims
		# Class Claim
		# => arg: paragraph
		# =>  	
			#claim = Claim.new( text['claim'] )
			# B	claims_full
			# B	claim_num
			# B	dept_claim_num
			# B	indept_claim_num

		# A	description_full
#		patent_attrs << description( html[-2] )
		
		patent_attrs.each do |x|
			puts x
		end
		# puts issue_date
		# puts title
		# puts abstract
		# puts inventors_line
		# puts assignee_line
		# puts appl_id
		# puts filing_date
		# puts field_of_search_line
		# puts reference
		# puts primary_examiner
		# puts relt_appl_id+ relt_filing_date+ relt_patent_id+ relt_issue_date
		# puts USPC_line, IPC_line
		# puts description

	# MEMO: patent_id is not added into array patent_attrs
	# INSERTION
		# begin
		# 	Timeout::timeout(600){
		# 		s = ""
		# 		@new_patent.query( s )
		# 	}
		# rescue => ex
		# 	begin #reconnect to new_patent
		# 		@new_patent.close
		# 		puts "Reconnecting to database... "
		# 		#@mysql = Connect_mysql.new('chuya', '0514')
		# 		@new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')
		# 		puts "Reconnected! \n"
		# 	rescue
		# 		retry
		# 	end
		# end

	#table of Inventor########################
	patentToInventor(patent_id, patent_attrs[3] )
	#table of USPC############################
	uspc.uspcTable.each do |row|
		puts row
	end
	#table of IPC#############################
	ipc.ipcTable.each do |row|
		puts row
	end
	#table of CPC#############################

	#table of Reference#######################


else
	puts "Missing parameter: patent_id"	
end


