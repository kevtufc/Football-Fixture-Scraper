require 'rubygems'
require 'hpricot'
require 'open-uri'

# Simply set this to the page your team's fixtures are on, and run the script
page = "http://www.torquayunited.com/page/Fixtures/0,,10445,00.html"

doc = open(page) { |f| Hpricot(f) }

puts "BEGIN:VCALENDAR"
puts "VERSION:2.0"

month = nil 

(doc/"table.fixtureList")./("tr").each do |row|
  next if row.attributes['class'] == ""
  if row.attributes['class'] == "rowHeader"
    month = Date::MONTHNAMES.index(month = (row/"td").inner_html)
  else
    day  = (row/"td[1]").inner_html.match("[1234567890]+")[0].to_i
    time = (row/"td[2]").inner_html.gsub(/:/,"")
    puts "BEGIN:VEVENT"
    puts "DTSTART:201#{month > 6 ? "0" : "1"}#{"%02d" % month}#{"%02d" % day}T#{time}00Z"
    puts "DTEND:201#{month > 6 ? "0" : "1"}#{"%02d" % month}#{"%02d" % day}T#{time.to_i+200}00Z"
    puts "SUMMARY:#{(row/'td[4]/a').inner_html} #{(row/'td[3]').inner_html} (#{(row/'td[5]').inner_html.split.first})"
    puts "END:VEVENT" 
  end
end

puts "END:VCALENDAR"
