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
YYYYMMDD = format('%<yyyy>4.4d/%<mm>2.2d/%<dd>2.2d', yyyy: utcyyyy, mm: utcmm, dd: utcdd)
YYYY_MM_DD = YYYYMMDD.gsub("/", "-")
YYYY_MM_DD_YYYY_MM_DD = "#{YYYY_MM_DD}-#{YYYY_MM_DD}"
# Create firefox-sumo-emoji-barcode/yyyy/mm/dd directory if it doesn't exist
BARCODE_NAME = 'firefox-sumo-emoji-barcode'
DIRECTORY = "#{BARCODE_NAME}/#{YYYYMMDD}"
ID_FILEPATH = "#{DIRECTORY}/processed-ids.txt"
BARCODE_FILEPATH = "#{BARCODE_NAME}/#{BARCODE_NAME}.png"
DAILY_BARCODE_FILEPATH = "#{DIRECTORY}/#{YYYY_MM_DD}-#{BARCODE_NAME}.png"
FileUtils.mkdir_p DIRECTORY
processed_ids = []
processed_ids = IO.readlines(ID_FILEPATH).map(&:to_i) if File.exist?(ID_FILEPATH)

# "https://raw.githubusercontent.com/rtanglao/rt-kits-api3/main/2023/2023-01-01-2023-01-01-firefox-creator-answers-desktop-all-locales.csv"
# FIXME: what if CSV_URL doesn't exist?
CSV_URL = format("https://raw.githubusercontent.com/rtanglao/rt-kits-api3/main/\
#{utcyyyy_str}/#{YYYY_MM_DD_YYYY_MM_DD}-firefox-creator-answers-desktop-all-locales.csv")
questions = []
CSV.new(URI.parse(CSV_URL).open, :headers => :first_row).each do |q|
  q = q.to_hash
  q["created"] = Time.parse(q["created"]).to_i
  questions.push(q.slice(*PARAMS_TO_KEEP))
end
exit if questions.length.zero?
questions.sort! { |a, b| a['created'] <=> b['created'] }
binding.pry

questions.reject! { |p| p['created'] < startdate }



# Get last photo and figure out the date for the Pacific timezone
# and skip prior dates (if there are any)
last = photos[-1]

startdate = tz.local_time(localyyyy, utcmm, localdd, 0, 0).to_i
photos.reject! { |p| p['dateupload'] < startdate }
exit if photos.length.zero?

photos.each do |photo|
  id = photo['id']
  next if processed_ids.include?(id)

  # Download the thumbnail to /tmp
  logger.debug "DOWNLOADING #{id}"
  # 640 height files shouldn't be more than 1 MB!!!
  retry_count = 0
  begin
    tempfile = Down::Http.download(photo['url_l'], max_size: 1 * 1024 * 1024)
  rescue Down::ClientError, Down::NotFound => e
    retry_count += 1
    retry if retry_count < 3
    next #raise(e) ie. skip the photo if we can't download it
  end
  thumb = Image.read(tempfile.path).first
  resized = thumb.resize(WIDTH, HEIGHT)
  resized.write(BARCODE_SLICE)
  if !File.exist?(DAILY_BARCODE_FILEPATH)
    FileUtils.cp(BARCODE_SLICE, DAILY_BARCODE_FILEPATH)
  else
    image_list = Magick::ImageList.new(DAILY_BARCODE_FILEPATH, BARCODE_SLICE)
    montaged_images = image_list.montage { |image| image.tile = '2x1', image.geometry = '+0+0' }
    montaged_images.write(DAILY_BARCODE_FILEPATH)
  end
  File.delete(tempfile.path)
  # After the thumbnail is downloaded,  add the id to the file and to the array
  # so we don't download it again!
  File.open(ID_FILEPATH, 'a') { |f| f.write("#{id}\n") }
  processed_ids.push(id)
  FileUtils.cp(DAILY_BARCODE_FILEPATH, BARCODE_FILEPATH)
end
