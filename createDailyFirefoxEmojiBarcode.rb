#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'amazing_print'
require 'time'
require 'date'
require 'logger'
require 'io/console'
require 'fileutils'
require 'pry'
require 'pry-byebug'
require 'tzinfo'
require 'down/http'
require 'json'
require 'rmagick'
require 'csv'
require 'open-uri'
require 'nokogiri'

include Magick

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

VERTICAL = true
HORIZONTAL = false
def append_image(image_to_be_appended, image, vertical_or_horizontal)
  image_list = Magick::ImageList.new(image_to_be_appended, image)
  appended_images = image_list.append(vertical_or_horizontal)
  appended_images.write(image)
end

EMOJI_FILEPATH = 'EMOJI_PNG/'
MACOS_EMOJI = "#{EMOJI_FILEPATH}macos.png"
WINDOWS_EMOJI = "#{EMOJI_FILEPATH}windows11.png"
LINUX_EMOJI = "#{EMOJI_FILEPATH}linux.png"
UNKNOWN_EMOJI = "#{EMOJI_FILEPATH}x2753-BLACK-QUESTION-MARK-ORNAMENT-a50026.png"
KASPERSKY_EMOJI = "#{EMOJI_FILEPATH}kaspersky-20x20.png"
YAHOO_EMOJI = "#{EMOJI_FILEPATH}yahoo.png"
CHROME_EMOJI = "#{EMOJI_FILEPATH}chrome.png"

def get_os_emoji_filename(tags)
  case tags
  when /mac-os|os-x|osx|macos/i
    MACOS_EMOJI
  when /linux|ubuntu|redhat|debian/i
    LINUX_EMOJI
  when /windows-7|windows-8|windows-10|windows-11|windows/i
    WINDOWS_EMOJI
  else
    UNKNOWN_EMOJI
  end
end

SYNC_EMOJI = "#{EMOJI_FILEPATH}x1f504-ANTICLOCKWISE-DOWNWARDS-AND-UPWARDS-OPEN-CIRCLE-ARROWS-d73027.png"
BOOKMARK_EMOJI = "#{EMOJI_FILEPATH}x1f516-BOOKMARK-d73027.png"
DOWNLOAD_INSTALL_MIGRATION_EMOJI = "#{EMOJI_FILEPATH}x1f53d-DOWN-POINTING-SMALL-RED-TRIANGLE-d73027.png"
PRIVACY_SECURITY_EMOJI = "#{EMOJI_FILEPATH}x1f6e1-SHIELD-d73027.png"
CUSTOMIZE_CONTROLS_OPTIONS_ADDONS_EMOJI = "#{EMOJI_FILEPATH}x1f50c-ELECTRIC-PLUG-d73027.png"
SLOWNESS_CRASHING_ERROR_MESSAGES_OTHER_PROBLEMS_EMJOI = "#{EMOJI_FILEPATH}x1f4a5-COLLISION-SYMBOL-d73027.png"
TIPS_TRICKS_EMOJI = "#{EMOJI_FILEPATH}x2139xfe0f-INFORMATION-SOURCE-d73027.png"
COOKIES_EMOJI = "#{EMOJI_FILEPATH}x1f36a-COOKIE-d73027.png"
TABS_EMOJI = "#{EMOJI_FILEPATH}x1f4d1-BOOKMARK-TABS-d73027.png"
WEBSITE_BREAKAGES_EMOJI = "#{EMOJI_FILEPATH}x1f494-BROKEN-HEART-d73027.png"
OTHER_EMOJI = "#{EMOJI_FILEPATH}xd8-LATIN-CAPITAL-LETTER-O-WITH-STROKE-d73027.png"

def get_topic_emoji_filename(topic)
  case topic
  when /sync/i
    SYNC_EMOJI
  when /bookmark/i
    BOOKMARK_EMOJI
  when /tab/i
    TABS_EMOJI
  when /problems/i
    SLOWNESS_CRASHING_ERROR_MESSAGES_OTHER_PROBLEMS_EMJOI
  when /customize/i
    CUSTOMIZE_CONTROLS_OPTIONS_ADDONS_EMOJI
  when /tricks/i
    TIPS_TRICKS_EMOJI
  when /tab/i
    TABS_EMOJI
  when /breakage/i
    WEBSITE_BREAKAGES_EMOJI
  when /privacy/i
    PRIVACY_SECURITY_EMOJI
  when /install/i
    DOWNLOAD_INSTALL_MIGRATION_EMOJI
  else
    OTHER_EMOJI
  end
end

VERSION_PLUS_BETA_FILENAME = '/tmp/version_plus_beta.png'

def get_firefox_version_beta_tag(tags)
  tags_array = tags.split(';')
  return UNKNOWN_EMOJI if tags_array.nil?

  firefox_version_tag = tags_array.select { |x| x.include?('firefox') }.max_by(&:length)
  return UNKNOWN_EMOJI if firefox_version_tag.nil?

  firefox_version_tag = firefox_version_tag.delete_prefix('firefox-')
  firefox_version_tag = "#{firefox_version_tag}ß" if tags_array.include?('beta')
  version_plus_beta_image = Magick::Image.read("pango:#{firefox_version_tag}").first
  version_plus_beta_image.write(VERSION_PLUS_BETA_FILENAME)
  VERSION_PLUS_BETA_FILENAME
end

ID_DIGIT_FILENAME = '/tmp/digit.png'
ID_FILENAME = '/tmp/id.png'

def create_digit_image(id)
  id.chars.reverse.each_with_index do |d, i|
    digit_image = Magick::Image.read("pango:#{d}").first
    if i.zero?
      digit_image.write(ID_FILENAME)
    else
      digit_image.write(ID_DIGIT_FILENAME)
      append_image(ID_DIGIT_FILENAME, ID_FILENAME, VERTICAL)
    end
  end
end

PARAMS_TO_KEEP = %w[id created title content tags topic]
arg_count = ARGV.length
if arg_count != 0 && arg_count != 3
  puts "usage: #{$0} # to get current date's barcode OR"
  puts "usage: #{$0} <yyyy> <mm> <dd> # to get a specific date"
  exit
end

if arg_count.zero?
  utctime = Time.now.utc
  utcyyyy = utctime.strftime('%Y').to_i
  utcyyyy_str = utctime.strftime('%Y')
  utcmm = utctime.strftime('%m').to_i
  utcdd = utctime.strftime('%d').to_i
else
  utcyyyy = ARGV[0].to_i
  utcyyyy_str = ARGV[0]
  utcmm = ARGV[1].to_i
  utcdd = ARGV[2].to_i
end

YYYYMMDD = format('%<yyyy>4.4d/%<mm>2.2d/%<dd>2.2d', yyyy: utcyyyy, mm: utcmm, dd: utcdd)
logger.debug "YYYYMMDD: #{YYYYMMDD}"
YYYY_MM_DD = YYYYMMDD.gsub('/', '-')
YYYY_MM_DD_YYYY_MM_DD = "#{YYYY_MM_DD}-#{YYYY_MM_DD}"
startdate = Time.gm(utcyyyy, utcmm, utcdd, 0, 0).to_i

# Create firefox-sumo-emoji-barcode/yyyy/mm/dd directory if it doesn't exist
BARCODE_NAME = 'firefox-sumo-emoji-barcode'
DIRECTORY = "#{BARCODE_NAME}/#{YYYYMMDD}"
ID_FILEPATH = "#{DIRECTORY}/processed-ids.txt"
BARCODE_FILEPATH = "#{BARCODE_NAME}/#{BARCODE_NAME}.png"
DAILY_BARCODE_FILEPATH = "#{DIRECTORY}/#{YYYY_MM_DD}-#{BARCODE_NAME}.png"

FileUtils.mkdir_p DIRECTORY
processed_ids = []
processed_ids = IO.readlines(ID_FILEPATH).map(&:to_i) if File.exist?(ID_FILEPATH)

logger.debug "processed_ids: #{processed_ids}"

# If the CSV_URL doesn't exist then exit because there's no way to recover
CSV_URL = format("https://raw.githubusercontent.com/rtanglao/rt-kits-api3/main/\
#{utcyyyy_str}/#{YYYY_MM_DD_YYYY_MM_DD}-firefox-creator-answers-desktop-all-locales.csv")
questions = []
begin
  CSV.new(URI.parse(CSV_URL).open, headers: :first_row).each do |q|
    q = q.to_hash
    q['created'] = Time.parse(q['created']).to_i
    questions.push(q.slice(*PARAMS_TO_KEEP))
  end
rescue StandardError => e
  logger.debug "Can't read CSV:#{CSV_URL} exception:#{e}"
  exit
end
exit if questions.length.zero?
questions.reject! { |p| p['created'] < startdate }
questions.sort! { |a, b| a['created'] <=> b['created'] }
daily_file_exists = false
question_file = '/tmp/question.png'
logger.debug "date: #{YYYY_MM_DD} #of questions: #{questions.length}"
questions.each do |q|
  id = q['id']
  tags = q['tags']
  topic = q['topic']
  id_int = id.to_i
  logger.debug "id: #{id_int}"
  if processed_ids.include?(id_int)
    logger.debug "NOT processing id: #{id_int}"
    next
  end

  # Append the os emoji to a nil image
  os_emoji = Image.read(get_os_emoji_filename(tags)).first
  FileUtils.cp(os_emoji.filename, question_file)

  # Append the Firefox version emoji + beta if they exist
  version_emoji = get_firefox_version_beta_tag(tags)
  append_image(version_emoji, question_file, VERTICAL)

  # Append the topic emoji
  topic_emoji = Image.read(get_topic_emoji_filename(topic)).first
  append_image(topic_emoji.filename, question_file, VERTICAL) unless topic_emoji.nil?

  # Append the bugilla bug image if bug tags exist
  # Append the rest of the emojis if they exist
  content = "#{q['title']} #{Nokogiri::HTML(q['content']).text}".downcase
  append_image(KASPERSKY_EMOJI, question_file, VERTICAL) if content.include?('kaspersky')
  append_image(YAHOO_EMOJI, question_file, VERTICAL) if content.include?('yahoo')
  append_image(CHROME_EMOJI, question_file, VERTICAL) if content.include?('chrome')

  # Add id image
  create_digit_image(id)
  logger.debug "created image for id:#{id}"

  # Append the id image to the question image
  append_image(ID_FILENAME, question_file, VERTICAL)
  logger.debug "appended id image to question: #{id}"

  # Append the question image to the daily barcode image
  if daily_file_exists || File.exist?(DAILY_BARCODE_FILEPATH)
    logger.debug "daily file EXISTS for: #{DAILY_BARCODE_FILEPATH}"
    logger.debug("#{DAILY_BARCODE_FILEPATH} DOES exist, so appending: #{question_file} to it")
    append_image(question_file, DAILY_BARCODE_FILEPATH, HORIZONTAL)
    logger.debug "wrote image with id:#{id} to #{DAILY_BARCODE_FILEPATH}"
    daily_file_exists = true
  else
    daily_file_exists = true
    logger.debug("#{DAILY_BARCODE_FILEPATH} does not exist, so copying: #{question_file} to it")
    FileUtils.cp(question_file, DAILY_BARCODE_FILEPATH)
  end
  # After the question is processed and barcode updated, add the id to the file and to the array
  # so we don't download it again!
  File.open(ID_FILEPATH, 'a') { |f| f.write("#{id}\n") }
  processed_ids.push(id_int)
  # don't copy to daily barcode if we are not doing the current day
  FileUtils.cp(DAILY_BARCODE_FILEPATH, BARCODE_FILEPATH) if arg_count.zero?
end
