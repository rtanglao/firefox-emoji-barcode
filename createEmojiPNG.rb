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

xml_entity = ARGV[0].codepoints.map { |cp| format('&#x%x;', cp) }.join
filename_xml_entity = xml_entity.gsub(/[&#;]/, '')
filename_emoji_readable = Unicode::Name.readable(ARGV[0]).gsub(' ', '-')
filename = "#{filename_xml_entity}-#{filename_emoji_readable}.png"
logger.debug "filename: #{filename}"
#image = Magick::Image.read("pango:#{xml_entity}").first
# FIXME: add code to read the background colour from ARGV[1]
image = Magick::Image.read("pango:<span background='#a50026'>#{xml_entity}</span>").first
image.write(filename)
