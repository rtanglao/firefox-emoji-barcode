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

include Magick

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

EMOJI_FILEPATH = 'EMOJI_PNG/'
MACOS_EMOJI = "#{EMOJI_FILEPATH}x1f34e-RED-APPLE-a50026.png"
WINDOWS_EMOJI = "#{EMOJI_FILEPATH}x1fa9f-WINDOW-a50026.png"
LINUX_EMOJI = "#{EMOJI_FILEPATH}x1f427-PENGUIN-a50026.png"
UNKNOWNOS_EMOJI = "#{EMOJI_FILEPATH}x2753-BLACK-QUESTION-MARK-ORNAMENT-a50026.png"

def get_os_emoji_filename(tags)
  case tags
  when /mac-os|os-x|osx|macos/i
    MACOS_EMOJI
  when /linux|ubuntu|redhat|debian/i
    LINUX_EMOJI
  when /windows-7|windows-8|windows-10|windows-11|windows/i
    WINDOWS_EMOJI
  else
    UNKNOWNOS_EMOJI
  end
end

SYNC_EMOJI ="#{EMOJI_FILEPATH}x1f504-ANTICLOCKWISE-DOWNWARDS-AND-UPWARDS-OPEN-CIRCLE-ARROWS-d73027.png"
BOOKMARK_EMOJI = "#{EMOJI_FILEPATH}x1f516-BOOKMARK-d73027.png"
DOWNLOAD_INSTALL_MIGRATION_EMOJI = "#{EMOJI_FILEPATH}x1f53d-DOWN-POINTING-SMALL-RED-TRIANGLE-d73027.png"
PRIVACY_SECURITY_EMOJI = "#{EMOJI_FILEPATH}x1f6e1-SHIELD-d73027.png"
CUSTOMIZE_CONTROLS_OPTIONS_ADDONS_EMOJI = "#{EMOJI_FILEPATH}x1f50c-ELECTRIC-PLUG-d73027.png"
SLOWNESS_CRASHING_ERROR_MESSAGES_OTHER_PROBLEMS_EMJOI = "#{EMOJI_FILEPATH}x1f4a5-COLLISION-SYMBOL-d73027.png"
TIPS_TRICKS_EMOJI = "#{EMOJI_FILEPATH}x2139xfe0f-INFORMATION-SOURCE-d73027.png"
COOKIES_EMOJI = "#{EMOJI_FILEPATH}x1f36a-COOKIE-d73027.png"
TABS_EMOJI = "#{EMOJI_FILEPATH}x1f4d1-BOOKMARK-TABS-d73027.png"
WEBSITE_BREAKAGES_EMOJI = "#{EMOJI_FILEPATH}x1f494-BROKEN-HEART-d73027.png"
OTHER_EMOJI ="#{EMOJI_FILEPATH}xd8-LATIN-CAPITAL-LETTER-O-WITH-STROKE-d73027.png"
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
    UNKNOWNSYNC_EMOJI
  end
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
      image_list = Magick::ImageList.new(ID_DIGIT_FILENAME, ID_FILENAME)
      # `true` means append vertically instead of horizontally
      appended_images = image_list.append(true)
      appended_images.write(ID_FILENAME)
    end
  end
  ID_FILENAME
end

PARAMS_TO_KEEP = %w[id created title content tags topic]
utctime = Time.now.utc
utcyyyy = utctime.strftime('%Y').to_i
utcyyyy_str = utctime.strftime('%Y')
utcmm = utctime.strftime('%m').to_i
utcdd = utctime.strftime('%d').to_i
YYYYMMDD = format('%<yyyy>4.4d/%<mm>2.2d/%<dd>2.2d', yyyy: utcyyyy, mm: utcmm, dd: utcdd)
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
begin
  CSV_URL = format("https://raw.githubusercontent.com/rtanglao/rt-kits-api3/main/\
#{utcyyyy_str}/#{YYYY_MM_DD_YYYY_MM_DD}-firefox-creator-answers-desktop-all-locales.csv")
rescue StandardError => e
  logger.debug "Can't read CSV:#{CSV_URL} exception:#{e}"
end
questions = []
CSV.new(URI.parse(CSV_URL).open, headers: :first_row).each do |q|
  q = q.to_hash
  q['created'] = Time.parse(q['created']).to_i
  questions.push(q.slice(*PARAMS_TO_KEEP))
end
exit if questions.length.zero?
questions.reject! { |p| p['created'] < startdate }
questions.sort! { |a, b| a['created'] <=> b['created'] }
check_daily_file_exists = true
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

  check_question_image_exists = true
  os_emoji = Image.read(get_os_emoji_filename(tags)).first
  if check_question_image_exists
    check_question_image_exists = false
    FileUtils.cp(os_emoji.filename, question_file)
  else
    image_list = Magick::ImageList.new(os_emoji.filename, question_file)
    appended_images = image_list.append(true)
    appendedimages.write(question_file)
  end

  # Append the topic emoji
  topic_emoji = Image.read(get_topic_emoji_filename(topic)).first
  unless topic_emoji.nil?
    image_list = Magick::ImageList.new(topic_emoji.filename, question_file)
    appended_images = image_list.append(true)
    appended_images.write(question_file)
  end

  # Add id image
  id_filename = create_digit_image(id)
  logger.debug "created image for id:#{id}"

  # Append the id image to the question image
  image_list = Magick::ImageList.new(ID_FILENAME, question_file)
  appended_images = image_list.append(true)
  appended_images.write(question_file)
  logger.debug "appended id image to question: #{id}"

  # Append the question image to the daily barcode image
  if check_daily_file_exists
    check_daily_file_exists = false
    unless File.exist?(DAILY_BARCODE_FILEPATH)
      logger.debug("#{DAILY_BARCODE_FILEPATH} does not exist, so copying: #{question_file} to it")
      FileUtils.cp(question_file, DAILY_BARCODE_FILEPATH)
    end
  else
    logger.debug("#{DAILY_BARCODE_FILEPATH} DOES exist, so appending: #{question_file} to it")
    image_list = Magick::ImageList.new(DAILY_BARCODE_FILEPATH, question_file)
    montaged_images = image_list.append(false) # append horizontally i.e. false
    montaged_images.write(DAILY_BARCODE_FILEPATH)
    logger.debug "wrote image with id:#{id} to #{DAILY_BARCODE_FILEPATH}"
  end
  # After the question is processed and barcode updated,  add the id to the file and to the array
  # so we don't download it again!
  File.open(ID_FILEPATH, 'a') { |f| f.write("#{id}\n") }
  processed_ids.push(id_int)
  FileUtils.cp(DAILY_BARCODE_FILEPATH, BARCODE_FILEPATH)
end
