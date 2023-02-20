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
require 'json'
require 'rmagick'
require 'unicode/name'

include Magick

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

xml_entity = ARGV[0].codepoints.map { |cp| format('&#x%x;', cp) }.join
filename_xml_entity = xml_entity.gsub(/[&#;]/, '')   
filename_emoji_readable = Unicode::Name.readable(ARGV[0]).gsub(' ', '-')
filename = "#{filename_xml_entity}-#{filename_emoji_readable}.png"
print "#{filename}\n"
image = Magick::Image.read("pango:#{xml_entity}").first
image.write(filename)
#'❓'.codepoints.map { |cp| format('&#x%x;', cp) }.join
# => "&#x2753;"
# https://www.compart.com/en/unicode/search?q=question#characters
# `emoj question`
# Unicode::Name.of "🤳" 
# => "SELFIE"
# Unicode::Name.readable("🤳")
# => "SELFIE"

