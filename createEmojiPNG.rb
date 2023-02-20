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

include Magick

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

xml_entity = ARGV[0].codepoints.map { |cp| format('&#x%x;', cp) }.join
filename_xml_entity = xml_entity.gsub(/[&#;]/, '')   
filename_emoji_readable = Unicode::Name.readable(ARGV[0]).gsub(' ', '-')
filename = "#{filename_xml_entity}-#{filename_emoji_readable}.png"
logger.debug "filename: #{filename}"
image = Magick::Image.read("pango:#{xml_entity}").first
image.write(filename)
