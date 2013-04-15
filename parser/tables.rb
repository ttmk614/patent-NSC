# inventer_table.rb
# inventor_line = "Martinelli; Michael A. (Winchester, MA)#Haase; Wayne C. (Sterling, MA)#"
def patentToInventor(patent_id, inventor_line)
    inventors = Array.new
    count = 0
	inventor_line.split('# ').each do |inventor_info|
        inventors[count] = Hash.new
        inventor, tmp = inventor_info.split(' (')
        inventor_location = tmp.gsub(')', "")
        inventor_location_city, tmp = inventor_location.split(', ')
        if /^\%/ =~ tmp then
            inventor_location_country = tmp.gsub('%', '')
            inventor_location_state = 'NULL'
        else
            inventor_location_country = tmp
            inventor_location_state = 'USA'
        end
        inventors[count]['inventor_name'] = inventor
        inventors[count]['inventor_location'] = inventor_location
        inventors[count]['inventor_location_country'] = inventor_location_country
        inventors[count]['inventor_location_state'] = inventor_location_state
        inventors[count]['inventor_location_city'] = inventor_location_city
        inventors[count]['inventor_name'] = 
        count += 1
		# insert into inventor (`patent_id`, `inventor_name`, `inventor_location`, `inventor_location_country`, `inventor_location_state`, `inventor_location_city`) values (patent_id, inventor, inventor_location, inventor_location_country, inventor_location_state, inventor_location_city)
	end
    return inventors
end

class USPC
	attr_accessor :uspcLine, :uspcTable
	def initialize(xml)
		@uspcTable = Array.new

        if xml.count(";") > 0 then 
    		uspcLineTemp = xml.split("<b>")[1].split("</td>")[0].split("</b>  ; ")
        	@uspcLine = uspcLineTemp[0]

            @uspcTable[0] = Hash.new
            temp = uspcLineTemp[0].split("/")
            @uspcTable[0]['level_1'] = temp[0]
            @uspcTable[0]['level_2'] = temp[1]
            @uspcTable[0]['USPC_class'] = uspcLineTemp[0]

            count = 1
            uspcLineTemp[1].split("; ").each do |each|
            	@uspcTable[count] = Hash.new
            	temp = each.split("/")
            	@uspcTable[count]['level_1'] = temp[0]
            	@uspcTable[count]['level_2'] = temp[1]
            	@uspcTable[count]['USPC_class'] = each
            	@uspcLine = @uspcLine + "#" + each
                count += 1
            end
        else  #only 1 uspc class
            uspcLineTemp = xml.split("<b>")[1].split("</td>")[0].split("</b>")
            @uspcLine = uspcLineTemp[0]

            @uspcTable[0] = Hash.new
            temp = uspcLineTemp[0].split("/")
            @uspcTable[0]['level_1'] = temp[0]
            @uspcTable[0]['level_2'] = temp[1]
            @uspcTable[0]['USPC_class'] = uspcLineTemp[0]
        end  
  	end
end

# $test = '<td valign="TOP" align="RIGHT" width="80%">
# <b>607/101</b>  ; 606/41; 607/116</td>'
# a = USPC.new($test)
# puts a.uspcLine
# puts a.uspcTable

class IPC
	attr_accessor :ipcLine, :ipcTable
	def initialize(xml)
		ipcLineTemp = xml.split(">")[1].split("</td>")[0]
		@ipcTable = Array.new
		@ipcLine = ""
		count = 0
    	ipcLineTemp.split("; ").each do |each|
    		@ipcTable[count] = Hash.new
    		temp1 = each.split(" ")
    		@ipcTable[count]['main_class'] = temp1[0]
    		temp2 = temp1[1].split("/")
    		@ipcTable[count]['level_1'] = temp2[0]
    		temp3 = temp2[1].split("&amp;nbsp(")
    		@ipcTable[count]['level_2'] = temp3[0]
    		if temp3[1] != nil 
				@ipcTable[count]['version'] = temp3[1][0..3]+ "-" + temp3[1][4..5] + "-" + temp3[1][6..7]
				@ipcTable[count]['IPC_class'] = ipcTable[count]['main_class'] + " " + ipcTable[count]['level_1'] + "/" + ipcTable[count]['level_2'] + "(" + temp3[1][0..7] + ")"
				@ipcLine = @ipcLine + "#" + ipcTable[count]['IPC_class']
			else
				@ipcTable[count]['version'] = nil
				@ipcTable[count]['IPC_class'] = ipcTable[count]['main_class'] + " " + ipcTable[count]['level_1'] + "/" + ipcTable[count]['level_2'] 
				@ipcLine = @ipcLine + "#" + ipcTable[count]['IPC_class']
			end
            temp = @ipcLine
            @ipcLine = temp[1..temp.length-1]
			count += 1
    	end
  	end
end
# $test = '<td valign="TOP" align="RIGHT" width="80%">A61C 5/00&amp;nbsp(20060101); A61C 11/00&amp;nbsp(20060101); A61C 9/00&amp;nbsp(20060101)</td>'
# a = IPC.new($test)
# puts a.ipcLine
# puts a.ipcTable

class CPC
	attr_accessor :cpcLine, :cpcTable
	def initialize(xml)
		cpcLineTemp = xml.split(">")[1].split("</td>")[0]
		@cpcTable = Array.new
		@cpcLine = ""
		count = 0
    	cpcLineTemp.split("; ").each do |each|
    		@cpcTable[count] = Hash.new
    		temp1 = each.split(" ")
    		@cpcTable[count]['main_class'] = temp1[0]
    		temp2 = temp1[1].split("/")
    		@cpcTable[count]['level_1'] = temp2[0]
    		temp3 = temp2[1].split("&amp;nbsp(")
    		@cpcTable[count]['level_2'] = temp3[0]
    		if temp3[1] != nil 
				@cpcTable[count]['version'] = temp3[1][0..3]+ "-" + temp3[1][4..5] + "-" + temp3[1][6..7]
				@cpcTable[count]['CPC_class'] = cpcTable[count]['main_class'] + " " + cpcTable[count]['level_1'] + "/" + cpcTable[count]['level_2'] + "(" + temp3[1][0..7] + ")"
				@cpcLine = @cpcLine + "#" + cpcTable[count]['CPC_class']
			else
				@cpcTable[count]['version'] = nil
				@cpcTable[count]['CPC_class'] = cpcTable[count]['main_class'] + " " + cpcTable[count]['level_1'] + "/" + cpcTable[count]['level_2'] 
				@cpcLine = @cpcLine + "#" + cpcTable[count]['CPC_class']
			end
            temp = @cpcLine
            @cpcLine = temp[1..temp.length-1]
			count += 1
    	end
  	end
end
# $test = '<td VALIGN=TOP ALIGN="RIGHT" WIDTH="80%">B63C 11/04&amp;nbsp(20130101)</td>'
# a = CPC.new($test)
# puts a.cpcLine
# puts a.cpcTable