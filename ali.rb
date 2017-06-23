#!/usr/bin/ruby

require 'rubygems'
require 'mechanize'
require 'json'
require 'yaml'
require 'optparse'
require 'find'

class Site_ALI
  def initialize
    @calendar_file = ENV['HOME'] + '/ali_calendar.yml'
    @agent = Mechanize.new
    @agent.cookie_jar.load ENV['HOME'] + '/.ali_cookies.yml' rescue puts 'No cookies.yml'
    @agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36'
    @agent.follow_meta_refresh = true
  end

  def save_cookies
    @agent.cookie_jar.save_as ENV['HOME'] + '/.ali_cookies.yml', session: true
  end

  def load_calendar
    begin
      Hash $calendar = YAML.load_file(@calendar_file)
    rescue Errno::ENOENT
      $calendar = Hash.new
    end
    $calendar['banned'] ||= {}
    $calendar['grayed'] ||= {}
  end

  def save_calendar
    File.open(@calendar_file, "w") do |file|
      file.write $calendar.sort.to_h.to_yaml
    end
  end

  def google_parse url
    page = @agent.get(url).search('div.rc h3.r a')
    return 'end' if page.count == 0
    page.each do |link|
      url = link.attributes['href'].to_s
      p url
      check url
    end
  end

  def google
    i=410
    loop do
      url = 'http://www.google.com/search?q="Limited quantity for a limited time only."+site%3Aaliexpress.com&start='+i.to_s
      #url = 'http://www.google.com/search?q="Сумасшедшие+купоны"+site%3Aaliexpress.com&start='+i.to_s
      puts url
      break if google_parse(url) == 'end'
      i += 10
    end 
    #url = 'http://www.google.com/search?q="Сумасшедшие+купоны"+site%3Aaliexpress.com&start=10'
    #url = 'http://www.google.com/search?q="Limited quantity for a limited time only."+site%3Aaliexpress.com&start=10'

  end

  def check url
  begin
    @agent.cookie_jar.clear!
    page = @agent.get url
    shop = page.at('span.shop-name a')
    shop_url = shop['href'].split('/').last
  rescue NoMethodError
    $calendar['error_urls'] ||= {}
    $calendar['error_urls'][url] ||= {}
    save_calendar
    return
  end
    shop_name = shop.text
    page.search("div.view-all-detail-content td:contains('201')").each do |item|  
      p item.text
      $calendar[item.text] ||= {}
      $calendar[item.text][shop_url] = shop_name
    end
    save_calendar
  end

  def find_round multiplier
    $calendar.each do |round|
      round_time = Time.parse(round.first + ' PST').localtime rescue next
      return round.first if round_time > Time.new+(multiplier||0)*60*60*6
    end
  end

  def print_calendar multiplier
     cur_round = find_round multiplier
     puts Time.parse(cur_round + ' PST').localtime
     $calendar[cur_round].each do |store|
       next if $calendar['banned'].include? store.first
       url = "http://ru.aliexpress.com/store/#{store.first}"
       if $calendar['grayed'].include? store.first
         #puts "\e[2m#{url}\t#{store.last}\e[0m"
       else
         puts "#{url}"#\t#{store.last}"
       end
     end
  end

  def ban store_id
    $calendar['banned'][store_id] = Time.new
    puts 'Banned store list:'
    puts $calendar['banned'].keys
    save_calendar
  end

  def unban store_id
    $calendar['banned'].delete(store_id)
    $calendar['grayed'].delete(store_id)
    puts "Banned store list: #{$calendar['banned'].keys}\nGrayed store list: #{$calendar['grayed'].keys}"
    save_calendar
  end

  def gray store_id
    $calendar['grayed'][store_id] = Time.new
    puts 'Grayed store list:'
    puts $calendar['grayed'].keys
    save_calendar
  end

end

site = Site_ALI.new
site.load_calendar

OptionParser.new do |opts|
  opts.banner = "Usage: jd [options]"
  opts.separator ""
  opts.separator "Specific options:"

  opts.on( '-b', '--ban [URL/ID]', 'ban' ) do |store_id|
    site.ban store_id.split('/').last.to_i
  end
  opts.on( '-g', '--gray [URL/ID]', 'gray' ) do |store_id|
    site.gray store_id.split('/').last.to_i
  end
  opts.on( '-u', '--unban [URL/ID]', 'ban' ) do |store_id|
    site.unban store_id.split('/').last.to_i
  end
  opts.on( '-p', '--print [MULTIPLIER]', Integer, 'print calendar' ) do |multiplier|
    site.print_calendar multiplier
  end
  opts.on( '-c', '--check [URL]', 'check' ) do |url|
    site.check url
  end
  opts.on( '-s', '--search', 'search in google' ) do
    site.google
  end
end.parse!
