#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'amazing_print'
require 'logger'
require 'io/console'
require 'fileutils'
require 'pry'
require 'pry-byebug'
require 'rmagick'
require 'unicode/name'

# https://colorbrewer2.org/?type=diverging&scheme=RdYlBu&n=11
# ['#a50026','#d73027','#f46d43','#fdae61','#fee090','#ffffbf','#e0f3f8','#abd9e9','#74add1','#4575b4','#313695']
include Magick

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

if ARGV.length < 2
  puts "usage: #{$0} <char> <colour-hex-code>"
  puts "e.g. #{$0} '❓' '313695'"
  exit
end

BACKGROUND_COLOUR = ARGV[1]
xml_entity = ARGV[0].codepoints.map { |cp| format('&#x%x;', cp) }.join
filename_xml_entity = xml_entity.gsub(/[&#;]/, '')
filename_emoji_readable = Unicode::Name.readable(ARGV[0]).gsub(' ', '-')
filename = "#{filename_xml_entity}-#{filename_emoji_readable}-#{BACKGROUND_COLOUR}.png"
logger.debug "filename: #{filename}"
image = Magick::Image.read("pango:<span background='##{BACKGROUND_COLOUR}'>#{xml_entity}</span>").first
image.write(filename)
