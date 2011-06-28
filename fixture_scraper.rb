require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rack'
require 'date'

class FixtureServlet

  URL = "http://www.torquayunited.com/page/Fixtures/0,,10445,00.html"
  
  def call(env)
    f=FixtureList.new(URL)
    f.parse
    return [400, {"Content-Type" => "text/plain"}, f.to_vcalendar]
  end
end

class Fixture
  attr_accessor :start,:home, :away, :hscore, :ascore, :comp
  def to_vcalendar
    out  = "BEGIN:VEVENT\n"
    out += "DTSTART:#{start.strftime('%Y%m%dT%H%M00Z')}\n"
    out += "DTEND:#{(start + 7200).strftime('%Y%m%dT%H%M00Z')}\n"
    out += "SUMMARY:#{home}"
    out += " " + hscore.to_s if hscore
    out += " v "
    out += ascore.to_s + " " if ascore
    out += "#{away} (#{comp})\n"
    out += "END:VEVENT\n" 
  end
end

class FixtureList
  attr_accessor :fixtures

  def initialize(url)
    @url = url
    @fixtures = []
  end
 
  def parse
    doc = open(@url) { |f| Hpricot(f) }
    month = nil 
    team = (doc/"head/title").inner_html.split("|").first.strip
    (doc/"table.fixtureList")./("tr").each do |row|
      next if row.attributes['class'] == ""
      if row.attributes['class'] == "rowHeader"
        month = Date::MONTHNAMES.index(month = (row/"td").inner_html)
      else
        game = Fixture.new
        day             = (row/"td[1]").inner_html.match("[1234567890]+")[0].to_i
        (hour,
	 min)           = (row/"td[2]").inner_html.split(/:/)
        game.start      = Time.utc(month > 6 ? 2011 : 2012,month,day,hour,min)
        opponents       = (row/'td[4]/a').inner_html.strip
        game.comp       = (row/'td[5]').inner_html.split.first
        home            = (row/'td[3]').inner_html=="H"
	if home
          (game.hscore,
	   game.ascore) = (row/'td[7]').inner_html.gsub(/[^\-0-9]/,"").split("-").map{|s| s.to_i}
	   game.home    = team
	   game.away    = opponents
	else
          (game.ascore,
	   game.hscore) = (row/'td[7]').inner_html.gsub(/[^\-0-9]/,"").split("-").map{|s| s.to_i}
	   game.away    = team
	   game.home    = opponents
	end
	@fixtures << game
      end
    end
  end

  def to_vcalendar
    out = "BEGIN:VCALENDAR\n"
    out += "VERSION:2.0\n"
    out += "X-WR-CALNAME:Torquay United Fixtures\n"
    out += @fixtures.map{|f| f.to_vcalendar}.join
    out += "END:VCALENDAR\n"
  end

  def count
    @fixtures.size
  end

end

