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
@patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent')
puts "database connected"

def get_html( html )
    begin # Get HTML of patent_id
        #s = "SELECT `Html` FROM `content_#{year}` WHERE `Patent_id`='#{patent_id}'"
        #puts s
        #res = @new_patent.query( s )
        if html
        	blocks = html.gsub(/'/, "''").gsub(/<th/, "<td").gsub(/th>/, "td>").split("<hr>")
        	r = []
        	r << Nokogiri::parse(html)
        	blocks.each do |block|
        		r << Nokogiri::parse("<html>" + block + "</html>")
        	end
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
def reconnect_patent()
	@patent.close
	puts "Reconnecting to database `patent`... "
	@patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent')
	puts "Reconnected! \n"
end
def reconnect_new_patent()
	@new_patent.close
	puts "Reconnecting to database `new_patent`... "
	@new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')
	puts "Reconnected! \n"
end
def total_count(year)
  count = @new_patent.query("SELECT COUNT(*) FROM  `content_#{year}`").to_a[0]['COUNT(*)']
  return count.to_i
end
# def reconnect_patent()
# 	@patent.close
# 	puts "Reconnecting to database `patent`... "
# 	@patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent')
# 	puts "Reconnected! \n"
# end
#main######################################################
if ARGV.count > 0

	#issued_year_table = issued_year()
	#issued_year = year_lookup(issued_year_table, patent_id)
	#puts issued_year
	issued_year = ARGV.shift
	patent_index = ARGV.shift.to_i
	count = total_count(issued_year)
	s = "SELECT `Index`, `Patent_id`, `Html` FROM `content_#{issued_year}` ORDER BY `Index` ASC LIMIT #{patent_index-1}, #{count}"
	puts s.to_s
	@new_patent.query(s).to_a.each do |row|
		#if row['Index'].to_i < patent_index
		#	next
		#end
		puts "#{row['Index'].to_s}\t#{row['Patent_id'].to_s}"
		patent_id = row['Patent_id']
		html = get_html(row['Html'])
		# tables = html[0].xpath('//table')
		# fonts = html[0].xpath('//font')
		paragraphs = html[0].xpath('//p')
		#table of Patent##########################
		patent_attrs = []
		i = 2
		########################### A Patent_id := patent_id  
		########################### A issue_date	
		patent_attrs << issue_date( html[i] )
		i += 1
		########################### Claims for Design patent
		# if (html[i].xpath("//text()")[0].to_s.strip <=> "Claims")==0
		# 	patent_attrs << getRelatedPatent(html[i+1].xpath("//tr")[2..-2].to_s)
		# 	i += 2
		# end
		########################### A title		
		patent_attrs << title( html[i] )
		########################### A abstract		
		patent_attrs << abstract( html[i] )
		i += 1

		########################### Skip Design Patent's Claims
		if (html[i].xpath("//text()")[0].to_s.strip <=> "Claims")==0
			i += 2	
		end
		########################### C inventors_line 
		patent_attrs << getInventor(html[i])
		########################### A assignee_line  
		patent_attrs << assignee_line( html[i] )
		########################### A	appl_id
		patent_attrs << appl_id( html[i] )
		########################### A	filing_date
		patent_attrs << filing_date( html[i] )
		i += 1 # i = 5
		########################### A	relt_appl_id, A	relt_filing_date, A	relt_patent_id, A relt_issue_date
		# only one or more relt????????????????
		if (html[i].xpath("//text()")[0].to_s.strip <=> "Related U.S. Patent Documents")==0
			patent_attrs << getRelatedPatent( html[i+1].xpath("//tr")[2..-2].to_s )
			# a = RelatedPatent.new(html[i+1].xpath("//tr")[2..-2].to_s)
			# # puts a.relatedTable
			# a.relatedTable[0].each do |content|
			# 	patent_attrs << content[1]
			# end
			# # patent_attrs << a.relatedTable[0][1][1]#-----------["relt_appl_id", "09490342"]---------
			# # patent_attrs << a.relatedTable[0][2][1]
			# # patent_attrs << a.relatedTable[0][3][1]
			# # patent_attrs << a.relatedTable[0][4][1]
			i += 2
		else
			# (1..4).each do |j|
			# 	patent_attrs << nil
			# end
			patent_attrs << nil
		end
		
		########################### B	USPC_line
		pctable = html[i].xpath("//table").last
		uspc = USPC.new(pctable.xpath("tr[1]/td[2]")[0].to_s)
		# uspc = USPC.new(html[i].xpath("//tr[1]/td[2]")[0].to_s)
		patent_attrs << uspc.uspcLine
		########################### B	IPC_line
		ipc = IPC.new(pctable.xpath("tr[2]/td[2]")[0].to_s)
		patent_attrs << ipc.ipcLine	
		########################### B	CPC_line 
		if (html[i].xpath("//text()")[0].to_s.strip <=> "Current CPC Class")==0
			cpc = CPC.new(pctable.xpath("tr[2]/td[2]")[0].to_s)
			patent_attrs << cpc.cpc_line
		else
			patent_attrs << nil
		end
		########################### A	Field_of_Search_line
		patent_attrs << field_of_search_line( html[i] )
		i += 2

		########################### C	Reference_USPTO, Reference_Foreign, Reference_Other
		reference = getReferences(issued_year, patent_id, html[i].to_s)
		patent_attrs << reference['references_uspto']
		patent_attrs << reference['references_foreign']
		patent_attrs << reference['other_references']

		########################### A	primary_examiner
		patent_attrs << primary_examiner( html[i] )
		i += 1


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
			i += 2
		else
			(1..4).each do |j|
				patent_attrs << nil
			end
		end
		########################### description_full
		patent_attrs << description( html[-2] )
		# patent_attrs.each do |x|
		# 	puts x
		# end
		# MEMO: patent_id is not added into array patent_attrs
		# INSERTION
		begin
			Timeout::timeout(600){
				s = "INSERT INTO `patent`.`patent_#{issued_year}` 
					(`patent_id`, `issue_date`, `title`, `abstract`, 
					 `inventors_line`, `assigne_line`, `appl_id`, `filing_date`, 
					 `relt_patent_id`,
					 `USPC_line`, `IPC_line`, `CPC_line`, `field_of_search_line`, 
					 `reference_USPTO`, `reference_foreign`, `reference_other`, 
					 `primary_examiner`, `claim_full`, `claim_num`, `dept_claim_num`, `indept_claim_num`, `description_full`) 
					VALUES ("
				s = s + "'#{patent_id}'"
				patent_attrs.each do |att|
					s = s + ", '#{att}'"
				end
				s = s + ')'
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
					# 	s = s + ", '#{att}'"
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
				ipc.ipcTable.each do |row|
					s = "INSERT INTO `patent`.`cpc_#{issued_year}` 
						(`patent_id`, `CPC_class`, `main_class`, `level_1`, `level_2`, `version`) 
						VALUES ("
					s = s + "'#{patent_id}', '#{row['CPC_class']}', '#{row['main_class']}', '#{row['level_1']}', '#{row['level_2']}', '#{row['version']}'"

					s = s + ')'
					# File.open("query_cpc.txt", "w") { |file| file.write(s) }
					@patent.query( s )
				end
				puts "cpc done!"
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
else
	puts "Missing parameter: patent_id"	
end


