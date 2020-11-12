require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry'

# def clean_zipcode(zipcode)
#   if zipcode.nil?
#     zipcode = "00000"
#   elsif zipcode.length < 5
#     zipcode = zipcode.rjust(5, "0")
#   elsif zipcode.length > 5
#     zipcode = zipcode[0..4]
#   else
#     zipcode
#   end
# end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  number = phone_number.scan(/\d+/).join

  number = '0000000000' if number.length < 10
  if number.length == 11 && number[0] == '1'
    number = number.slice(1, 10)
  elsif number.length > 11
    number = '0000000000'
  end

  number.insert(3, ' ')
  number.insert(7, '-')
  number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw' # not my key, mine throws inconsistent results 'AIzaSyACbATuyKkGcgGcKoKo9yEDQQyJoHuPnRs'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized!\n\n"

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0] # id header is blank, that's why we don't use the columns name
  name = row[:first_name]

  phone_number = clean_phone_number(row[:homephone])

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  puts "#{name} #{zipcode} #{phone_number}"
end
