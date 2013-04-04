require 'rubygems'
require 'nokogiri'
require 'date' 

def issued_year( patent_id )
	2008
	#lines = File.read( "issueyear.txt" )
end
######################################################################################
######################################################################################
#html: the section of HTML object which contains requested information
def issue_date( html )
    return Date.parse(html.xpath('//table/tr[2]/td[2]/b/text()')[0].to_s.strip)
end
def title( html )
     return html.xpath('//font/text()')[0].to_s().strip
end
def abstract( html )
    return html.xpath('//p/text()')[0].to_s().strip
end
def assignee_line( html )
    assignee = html.xpath('//table/tr[2]/td[2]//text()')
    assignee_line = assignee[1].to_s.strip + assignee[2].to_s.strip.gsub(/\s/, "")
    return assignee_line
end
def appl_id( html )
    return html.xpath('//table/tr[3]/td[2]//text()').to_s.strip.gsub(/,/, "")
end
def filing_date( html )
    return Date.parse(html.xpath('//table/tr[4]/td//text()')[2].to_s.strip)
end
def field_of_search_line( html )
    return html.xpath('//tr[3]/td[2]//text()')[0].to_s.strip
end
def primary_examiner( html )
    return html.xpath('//text()')[-4].to_s.strip
end
def description( html )
    return html.xpath('//text()')
end
######################################################################################

def getRelatedPatent( xml )
    temp1 = Nokogiri::HTML(xml)
    result = nil
    temp1.xpath("//tr").each do |each|
        if each.xpath("td")[3].text != ""
            result = each.xpath("td")[3].text.upcase.gsub(/[^A-Z0-9]/, "")
            result = result.gsub(/^0/,"")
            break
        end
    end
    result
end

class RelatedPatent
    attr_accessor :relatedTable
    def initialize(xml)
        @relatedTable = Array.new
        temp1 = Nokogiri::HTML(xml)
        count = 0
        temp1.xpath("//tr").each do |each|
            # each = Nokogiri::HTML(each.to_s)    #important!
            @relatedTable[count] = Hash.new
            temp2 = each.xpath("td")    #don't use "//td"! "//" means to search full text?
            @relatedTable[count]['relt_appl_id'] = temp2[1].text
            if temp2[2].text != '' then
                dateTemp = Date._parse(temp2[2].text)
                @relatedTable[count]['relt_filing_date'] = dateTemp[:year].to_s + "-" + dateTemp[:mon].to_s 
            end
            @relatedTable[count]['relt_patent_id'] = temp2[3].text
            if temp2[4].text != '' then
                dateTemp = Date._parse(temp2[4].text)
                @relatedTable[count]['relt_issue_date'] = dateTemp[:year].to_s + "-" + dateTemp[:mon].to_s 
            end
            count += 1
        end

    end
end
# $test = '<tr>
# <td align="center"> </td>
# <td align="center">11931910</td>
# <td align="center">Aug., 2011</td>
# <td align="center">Re. 42620</td>
# <td align="center"></td>
# <td></td>
# </tr>
# <tr>
# <td align="center"> </td>
# <td align="center">11239628</td>
# <td align="center">Sep., 2005</td>
# <td align="center"></td>
# <td align="center"></td>
# <td></td>
# </tr>
# <tr>
# <td align="center"> Reissue of:</td>
# <td align="center">09439516</td>
# <td align="center">Nov., 1999</td>
# <td align="center">6628729</td>
# <td align="center">Sep., 2003</td>
# <td></td>
# </tr>'
# a = RelatedPatent.new($test)
# puts a.relatedTable

class Claim
    attr_accessor :claimNum, :deptClaimNum, :indeptClaimNum, :claimsFull
    def initialize(xml)
        @claimNum = xml.scan(/<br><br>/).length
        @deptClaimNum = xml.scan(/claim/).length
        @indeptClaimNum = @claimNum - @deptClaimNum
        temp = xml.gsub(/^<br><br>/, "#")   #for the first '#'
        @claimsFull = temp[2..temp.length-1]
    end
end
# $test = "<br><br> 1.  A graphic interface device usable in a digital TV, comprising: a receiving side for receiving user graphic environment data corresponding to various forms of user graphic
# environments .[.displayable on a screen.]., the user graphic environment data including icon data corresponding to various icons;  and a graphic interfacing side for .[.parsing and decoding.].  .Iadd.processing .Iaddend.the user graphic environment data
# received at the receiving side, and allowing an end user to design a user-preferred user graphic environment including at least one user-defined icon .[.using the user graphic environment data.]., wherein the graphic interfacing side displays an
# environment set menu, such that any one of the various forms of user graphic environments can be selected by the end user;  and wherein said user graphic environment data are assigned with specific packet identifications (PIDs), and said displaying of
# the menu comprises: if a menu icon, in the environment set menu which can be selected by the end user, has been selected by the end user, parsing a data stream associated with the PIDs corresponding to various forms of menu icons;  decoding the parsed
# stream to store the various forms of menu icons in a memory;  performing a graphical user interface (GUI) process for the various forms of menu icons and text type of indication menu names which are to be set as the menu icons to be displayed in a menu
# fashion;  if respective ones of the various forms of menu icons and the indication menu names have been selected by the end user, parsing a stream associated with the PID assigned to the selected icon;  decoding the parsed stream to store the
# corresponding icon in the memory;  and replacing the selected indication menu name with the corresponding icon and displaying the replaced icon.
# <br><br> 2.  The graphic interface device according to claim 1, wherein said user graphic environment data include program guide pattern data corresponding to various forms of program guide patterns.
# <br><br> 3.  The graphic interface device according to claim 1, wherein said user graphic environment data include data corresponding to various forms of identification figures.
# <br><br> 4.  The graphic interface device according to claim 1, wherein said user graphic environment data are coded, assigned with specific packet identifications (PIDs), and multiplexed with video information, audio information and additional
# information at a transmitting side.
# <br><br> 5.  The graphic interface device according to claim 4, wherein said PIDs, which are assigned to said user graphic environment data at the transmitting side, are distinguished from PIDs each assigned to the video information, the audio
# information and the additional information.
# <br><br> 6.  The graphic interface device according to claim 5, wherein different PIDs are assigned to different user graphic environments.
# <br><br> 7.  The graphic interface device according to claim 4, wherein the graphic interfacing side includes: a demultiplexor for receiving a transport stream through the receiving side and demultiplexing the transport stream to separate the transport
# stream into the video information, the audio information, the additional information and the user graphic environment data;  a controller for controlling the demultiplexing of said demultiplexor and inputting and decoding the user graphic environment
# data separated in said demultiplexor;  a memory for storing the user graphic environment data decoded in said controller;  a graphic processor for performing a graphic process for the user graphic environment data stored in said memory under a control of
# said controller;  and a display processor for processing the user graphic environment data processed in said graphic processor to be matched in an output format of a display unit to display the processed information on the display unit.
# <br><br> 8.  The graphic interface device according to claim 7, further comprising a code processor for inputting and decoding the user graphic environment data which has not been decoded in said controller and storing the decoded information in said
# memory.
# <br><br> 9.  The graphic interface device according to claim 7, wherein said controller controls said demultiplexor in order to parse only a data stream of a specific user graphic environment, if the specific user graphic environment from the various
# forms of user graphic environments displayed on a display unit has been selected by the user.
# <br><br> 10.  The graphic interface device according to claim 7, wherein said graphic processor performs a graphic user interface (GUI) process for the user graphic environment data stored in said memory and said display processor displays the
# GUI-processed information on the display unit in an on-screen display (OSD) fashion.
# <br><br> 11.  A graphic interface method usable in a digital TV, comprising the steps of: receiving user graphic environment data corresponding to various forms of user graphic environments .[.displayable on a screen.].  from a transmitting side, the
# user graphic environment data including icon data corresponding to various icons;  .[.parsing and decoding.].  .Iadd.processing .Iaddend.the user graphic environment data received at a receiving side, and allowing an end user to design a user-preferred
# user graphic environment including at least one user-defined icon .[.using the user graphic environment data.].;  displaying an environment set menu, such that any one of the various forms of user graphic environments can be selected by the end user,
# wherein said user graphic environment data are assigned with specific packet identifications (PIDs), and said displaying step comprises the steps of: if a menu icon, in the environment set menu which can be selected by the end user, has been selected by
# the end user, parsing a data stream associated with the PIDs corresponding to various forms of menu icons;  decoding the parsed stream to store the various forms of menu icons in a memory;  performing a graphical user interface (GUI) process for the
# various forms of menu icons and text type of indication menu names which are to be set as the menu icons to be displayed in a menu fashion;  if respective ones of the various forms of menu icons and the indication menu names have been selected by the end
# user, parsing a stream associated with the PID assigned to the selected icon;  decoding the parsed stream to store the corresponding icon in the memory;  and replacing the selected indication menu name with the corresponding icon and displaying the
# replaced icon.
# <br><br> 12.  The graphic interface method according to claim 11, wherein said user graphic environment data include program guide pattern data corresponding to various forms of program guide patterns.
# <br><br> 13.  The graphic interface method according to claim 11, wherein said user graphic environment data are assigned with specific packet identifications (PIDs), and said displaying step comprises the steps of: if a program guide, in the environment
# set menu which can be selected by the end user, has been selected by the end user, parsing a data stream associated with the PIDs corresponding to various forms of program guide patterns;  decoding the parsed stream to store the various forms of program
# guide patterns in a memory;  performing a graphical user interface (GUI) process for the various forms of program guide patterns to be displayed in an on-screen-display (OSD) fashion;  if any one of the various forms of program guide patterns has been
# selected by the end user, parsing a stream associated with the PID assigned to the selected program guide pattern;  decoding the parsed stream to store the corresponding program guide pattern in the memory;  and displaying the corresponding program guide
# pattern stored in the memory in the OSD fashion.
# <br><br> 14.  The graphic interface method according to claim 13, wherein said displaying step for displaying the corresponding program guide pattern displays additional information related to channel and program through link on the displayed program
# guide pattern.
# <br><br> 15.  The graphic interface method according to claim 11, wherein said step of selecting the respective ones of the various forms of menu icons and indication menu names and said steps of replacing the selected indication menu name with the
# selected icon and displaying the replaced icon are all performed in a repetitive manner by the selection of the user.
# <br><br> 16.  The graphic interface device according to claim 2, wherein the graphic interfacing side is configured to display a series of menus on the screen for allowing the end user to design the user-preferred user graphic environment.
# <br><br> 17.  The graphic interface device according to claim 16, wherein the graphic interfacing side replaces at least a portion of a text-based user graphic environment with icons whose representative functions have been defined by the end user using
# the series of menus to design the user-preferred user graphic environment.
# <br><br> 18.  The graphic interface device according to claim 17, wherein the text-based user graphic environment is in a particular program guide pattern selected by the end user from the various forms of program guide patterns using the series of menus
# to design the user-preferred user graphic environment.
# <br><br> 19.  The graphic interface device according to claim 1, wherein the user-preferred user graphic environment is a user-selected program guide having a portion of its text replaced with icons whose representative functions have been defined by the
# end user.
# <br><br> 20.  The graphic interface method according to claim 11, further comprising: displaying a series of menus on a screen for allowing the end user to design the user-preferred user graphic environment.
# <br><br> 21.  The graphic interface method according to claim 20, further comprising: replacing at least a portion of a text-based user graphic environment with icons whose representative functions have been defined by the end user using the series of
# menus, to design the user-preferred user graphic environment."
# a = Claim.new($test)
# puts a.claimsFull
# puts a.claimNum
# puts a.deptClaimNum
# puts a.indeptClaimNum



############################################################################################3

def getReferences(html)
translator = Hash.new
translator = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12'}

	doc = Nokogiri::HTML(html)
	ref = {}
	doc.css('center').each do |ref|
		if /Other References/ =~ ref.content then
			other_references = ''
			ref.next_element.css('br').each do |refcon|
				other_references = other_references + refcon.next.content.gsub(' cited by other', '') + "#"
				# insert into `reference` (`patent_id`, `ref_type`, `ref_full`) values (patent_id, '3', refcon)
			end
			ref['other_references'] = other_references.gsub('.#', '#')
			#puts other_references.gsub('.#', '#') ==> problems!
		elsif /U.S. Patent Documents/ =~ ref.content then
			references_uspto = ''
			ref.next_element.css('tr td a').each do |record|
				references_uspto = references_uspto + record + ";" 
				date = record.parent.next_element.content.gsub(/\n/, '')
				assignee = record.parent.next_element.next_element.content.gsub(/\n/, '')
				mm, yy = date.split(' ')
				ref_full = record.to_str + ';' + translator[mm[0..2]]  + '-' + yy + ';' + assignee
				# puts full_ref					# => 6701179;03;Martinelli et al.
				# insert into `reference` (`patent_id`, `ref_type`, `ref_full`, `ref_uspto_patent_id`) values (patent_id, '1', full_ref, record) 
			end
			ref['references_uspto'] = references_uspto
			#puts references_uspto
		elsif /Foreign Patent Documents/ =~ ref.content then
			references_foreign = ''
			ref.next_element.css('tr td').each do |record|
				if /^.\d/ =~ record.content then
					references_foreign = references_foreign + record + ";"
					date = record.next_element.next_element.content.gsub(/\n/, '')
					country = record.next_element.next_element.next_element.next_element.content.gsub(/\n/, '')
					mm, yy = date.split('., ')
					ref_full = record.to_str + ';' + translator[mm] + '-' + yy + ';' + country
					# puts ref_full # => 964149;03-1975;CA
					# insert into `reference` (`patent_id`, `ref_type`, `ref_full`, `ref_uspto_patent_id`) values (patent_id, '1', full_ref, record) 
				end
			end
			ref['references_foreign'] = references_foreign
			#puts references_foreign
		end
	end
	return ref
end

def getInventor(html)
	doc = html#Nokogiri::HTML(html)
	#puts doc
	doc.css('table').each do |field|
		field.css('tr').each do |tuple|
			if /Inventors:/ =~ tuple.content then
				inventors_line = ''
				tuple.css('td b').each do |info|
					#puts info.content + info.next.content
					if /^[A-Z][A-Z]$/ =~ info then
						inventors_line += '%'
					end
					inventors_line = inventors_line + info.content.gsub(',', '#') + info.next.content
				end
				#puts inventors_line
				return inventors_line
			end
		end
	end
end