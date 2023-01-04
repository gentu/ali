require 'nokogiri'

doc = Nokogiri::HTML(File.read('1.htm') + File.read('2.htm') + File.read('3.htm') + File.read('4.htm'))

hash={}

doc.css('ul.coupon-ul').css('li.clearfix').each do |coupon|
   details = coupon.css('div.use-coupons-details')
   store_name = details.css('a').first.text.strip
   time = details.css('ul.coupon-ul').css('li').first.text.strip
   coupon_price = coupon.css('span.use-coupons-info-lang-price').text.strip
   coupon_limit = coupon.css('.use-coupons-info-lang-limit').text.strip
   hash[store_name] ||= {}
   num = hash[store_name].keys.count
   hash[store_name][num] = { 'price' => (coupon_price + ' ' + coupon_limit), 'time' => time }
end

hash.each do |storename, coupon|
  puts storename
  coupon.each do |num, var|
    puts "#{num+1} #{var['price']} #{var['time']}"
  end
  puts
end
