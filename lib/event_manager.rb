require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'

def clean_zipcode(zip)
  zip.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_num)
  phone_num = phone_num.tr('^0-9', "")
  if phone_num.length == 10
    phone_num
  elsif phone_num.length == 11 && phone_num.char == '1'
    phone_num.sub('1', "")
  else
    "Invalid phone number."
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"],
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter }
end

puts "Event Manager Initialized."

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol,
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
  zip = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zip)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
