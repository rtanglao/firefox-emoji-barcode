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

PARAMS_TO_KEEP = %w[id created title content tags]
utctime = Time.now.utc
utcyyyy = utctime.strftime('%Y').to_i
utcyyyy_str = utctime.strftime('%Y')
utcmm = utctime.strftime('%m').to_i
utcdd = utctime.strftime('%d').to_i
utcdd = 27 # FIXME, i.e. delete
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
EMOJI_FILEPATH = 'EMOJI_PNG/'
MACOS_EMOJI = "#{EMOJI_FILEPATH}x1f34e-RED-APPLE-a50026.png"
WINDOWS_EMOJI = "#{EMOJI_FILEPATH}x1fa9f-WINDOW-a50026.png"
LINUX_EMOJI = "#{EMOJI_FILEPATH}x1f427-PENGUIN-a50026.png"
UNKNOWNOS_EMOJI = "#{EMOJI_FILEPATH}x2753-BLACK-QUESTION-MARK-ORNAMENT-a50026.png"
FileUtils.mkdir_p DIRECTORY
processed_ids = []
processed_ids = IO.readlines(ID_FILEPATH).map(&:to_i) if File.exist?(ID_FILEPATH)

# FIXME: what if CSV_URL doesn't exist?
CSV_URL = format("https://raw.githubusercontent.com/rtanglao/rt-kits-api3/main/\
#{utcyyyy_str}/#{YYYY_MM_DD_YYYY_MM_DD}-firefox-creator-answers-desktop-all-locales.csv")
questions = []
CSV.new(URI.parse(CSV_URL).open, headers: :first_row).each do |q|
  q = q.to_hash
  q['created'] = Time.parse(q['created']).to_i
  questions.push(q.slice(*PARAMS_TO_KEEP))
end
exit if questions.length.zero?
questions.reject! { |p| p['created'] < startdate }
questions.sort! { |a, b| a['created'] <=> b['created'] }
check_file_exists = true
ID_DIGIT_FILENAME = '/tmp/digit.png'
ID_FILENAME = '/tmp/id.png'

questions.each do |q|
  id = q['id']
  next if processed_ids.include?(id)

  os_emoji_filename =
    case q['tags']
    when /mac-os|os-x|osx|macos/i
      MACOS_EMOJI
    when /linux|ubuntu|redhat|debian/i
      LINUX_EMOJI
    when /windows-7|windows-8|windows-10|windows-11|windows/i
      WINDOWS_EMOJI
    else
      UNKNOWNOS_EMOJI
    end
  os_emoji = Image.read(os_emoji_filename).first
  binding.pry

  if check_file_exists
    unless File.exist?(DAILY_BARCODE_FILEPATH)
      FileUtils.cp(os_emoji_filename, DAILY_BARCODE_FILEPATH)
      check_file_exists = false
    end
  else
    image_list = Magick::ImageList.new(DAILY_BARCODE_FILEPATH, os_emoji_filename)
    montaged_images = image_list.montage { |image| image.tile = '2x1', image.geometry = '+0+0' }
    montaged_images.write(DAILY_BARCODE_FILEPATH)
  end

  # Add id image
  id.chars.reverse.each_with_index do |d, i|
    digit_image = Magick::Image.read("pango:#{d}").first
    if i == 0
      digit_image.write(ID_FILENAME)
    else
      digit_image.write(ID_DIGIT_FILENAME)
      image_list = Magick::ImageList.new(ID_DIGIT_FILENAME, ID_FILENAME)
      appended_images = image_list.append(true)
      appended_images.write(ID_FILENAME)
      binding.pry
    end
  end
  # Append the id image to the question image
  image_list = Magick::ImageList.new(ID_FILENAME, DAILY_BARCODE_FILEPATH)
  appended_images = image_list.append(true)
  appended_images.write(DAILY_BARCODE_FILEPATH)
  binding.pry
  # After the question is processed and barcode updated,  add the id to the file and to the array
  # so we don't download it again!
  File.open(ID_FILEPATH, 'a') { |f| f.write("#{id}\n") }
  processed_ids.push(id)
  FileUtils.cp(DAILY_BARCODE_FILEPATH, BARCODE_FILEPATH)
end
