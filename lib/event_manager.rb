require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'pry'

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
  number.insert(0, '(')
  number.insert(4, ') ')
  number.insert(9, '-')
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

def log_reg_time(hours_log, reg_time)
  hours_log.has_key?(reg_time) ? hours_log[reg_time] += 1 : hours_log[reg_time] = 1
end

def most_registrations_hour(reg_hours)
  reg_hours.sort_by { |key, value| value }.reverse[0][0]
end

def log_reg_day(days_log, day)
  days_log.has_key?(day) ? days_log[day] += 1 : days_log[day] = 1
end

puts "EventManager Initialized!\n\n"

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)
reg_hours = {}
reg_days = {}
WEEK_DAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

contents.each do |row|
  id = row[0] # id header is blank, that's why we don't use the columns name

  reg_time = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")

  name = row[:first_name]

  phone_number = clean_phone_number(row[:homephone])

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  log_reg_time(reg_hours, reg_time.hour.to_s)

  log_reg_day(reg_days, WEEK_DAYS[reg_time.wday])

  puts "#{name} #{zipcode} #{phone_number}"
end

best_time_for_ads = most_registrations_hour(reg_hours)

puts "Best time for ads: #{best_time_for_ads}h"
puts "Best day for ads: #{reg_days.max[0]}"