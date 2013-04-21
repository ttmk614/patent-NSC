#!/usr/bin/env ruby
# encoding: UTF-8
require 'mysql2'

if ARGV.count > 0
	from = ARGV[0].to_i
	if ARGV.count == 2
		to = ARGV[1].to_i
	elsif ARGV.count == 1
		to = from
	end
	puts ARGV.count
	puts "from #{from}"
	puts "to #{to}"
	if from > to 
		puts "wrong input"
	else
		# year = ARGV[0]
		@new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent')

		for year in from..to
			s = " CREATE  TABLE  `patent`.`patent_#{year}` (  `patent_id` varchar( 20  )  NOT  NULL ,
				 `issue_date` date NOT  NULL ,
				 `title` text NOT  NULL ,
				 `abstract` text NOT  NULL ,
				 `inventors_line` text NOT  NULL ,
				 `assigne_line` text NOT  NULL ,
				 `appl_id` varchar( 100  )  NOT  NULL ,
				 `filing_date` date NOT  NULL ,
				 `relt_patent_id` varchar( 20  )  NOT  NULL ,
				 `USPC_line` text NOT  NULL ,
				 `IPC_line` text NOT  NULL ,
				 `CPC_line` text NOT  NULL ,
				 `field_of_search_line` text NOT  NULL ,
				 `reference_USPTO` text NOT  NULL ,
				 `reference_foreign` text NOT  NULL ,
				 `reference_other` text NOT  NULL ,
				 `primary_examiner` varchar( 100  )  NOT  NULL ,
				 `claim_full` text NOT  NULL ,
				 `claim_num` int( 11  )  NOT  NULL ,
				 `dept_claim_num` int( 11  )  NOT  NULL ,
				 `indept_claim_num` int( 11  )  NOT  NULL ,
				 `description_full` text NOT  NULL ,
				 `inventor_num` varchar( 10  )  NOT  NULL ,
				 `assignee_num` varchar( 10  )  NOT  NULL  ) ENGINE  =  MyISAM  DEFAULT CHARSET  = utf8;"
			@new_patent.query( s )

			s = " CREATE  TABLE  `patent`.`cpc_#{year}` (  `patent_id` varchar( 20  )  NOT  NULL ,
				 `CPC_class` text NOT  NULL ,
				 `main_class` varchar( 10  )  NOT  NULL ,
				 `level_1` varchar( 10  ) ,
				 `level_2` varchar( 10  ) ,
				 `version` varchar( 10  )  ) ENGINE  =  MyISAM  DEFAULT CHARSET  = utf8;"
			@new_patent.query( s )
			
			s = " CREATE  TABLE  `patent`.`inventor_#{year}` (  `patent_id` varchar( 20  )  NOT  NULL ,
				 `inventor_name` varchar( 100  )  NOT  NULL ,
				 `inventor_location` varchar( 100  )  NOT  NULL ,
				 `inventor_location_country` varchar( 20  )  NOT  NULL ,
				 `inventor_location_state` varchar( 20  )  NOT  NULL ,
				 `inventor_location_city` varchar( 20  )  NOT  NULL  ) ENGINE  =  MyISAM  DEFAULT CHARSET  = utf8;"
			@new_patent.query( s )

			s = " CREATE  TABLE  `patent`.`ipc_#{year}` (  `patent_id` varchar( 20  )  NOT  NULL ,
				 `IPC_class` text NOT  NULL ,
				 `main_class` varchar( 10  ) ,
				 `level_1` varchar( 10  ) ,
				 `level_2` varchar( 10  ) ,
				 `version` varchar( 10  )  ) ENGINE  =  MyISAM  DEFAULT CHARSET  = utf8;"
			@new_patent.query( s )

			s = " CREATE  TABLE  `patent`.`reference_#{year}` (  `patent_id` varchar( 20  )  NOT  NULL ,
				 `ref_type` varchar( 2  )  NOT  NULL ,
				 `ref_full` text NOT  NULL ,
				 `ref_uspto_patent_id` varchar( 20  )  ) ENGINE  =  MyISAM  DEFAULT CHARSET  = utf8;"
			@new_patent.query( s )

			s = " CREATE  TABLE  `patent`.`uspc_#{year}` (  `patent_id` varchar( 20  )  NOT  NULL ,
				 `USPC_class` varchar( 20  )  NOT  NULL ,
				 `level_1` varchar( 10  ) ,
				 `level_2` varchar( 10  )  ) ENGINE  =  MyISAM  DEFAULT CHARSET  = utf8;"
			@new_patent.query( s )
		end

		@new_patent.close
	end
end