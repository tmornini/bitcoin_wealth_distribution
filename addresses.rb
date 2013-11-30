#!/usr/bin/env ruby

require 'bigdecimal'
require 'pp'

private

TOTAL_LINES = 2_161_563

def lines
  return @lines unless @lines.nil?

  @lines = [ ]

  ARGF.each_line do |line|
    entry = line.chomp

    address, text_amount = entry.split /\s+/

    amount = BigDecimal text_amount

    line = { :address => address,
              :amount  => amount }

    @lines << line
  end

  @lines
end

def total
  return @total unless @total.nil?

  @total = 0

  lines.each do |line|
    @total += line[:amount]
  end

  @total
end

def summarize segment_size
  line_number = 0

  segments = []

  lines.each do |line|
    line_number += 1

    segment = line_number / segment_size

    amount = line[:amount]

    if segment < 10
      if segments[segment].nil?
        segments[segment] = amount
      else
        segments[segment] += amount
      end
    end
  end

  return :segment_size => segment_size,
         :total        => total,
         :segments     => segments
end

FORMAT = '%17.8d'

def format i
  i.to_s 'f'
end

def render args
  segment_size = args[:segment_size]
  segments     = args[:segments]

  puts "segment_size: #{segment_size}"

  puts 'Balances'

  pp segments.collect { |segment| format segment }.reverse

  puts 'Percentages'

  pp segments.collect { |segment| format( segment / total ) }.reverse

  puts 'Averages'

  pp segments.collect { |segment| format( segment / segment_size ) }.reverse
end

public

puts 'All addresses'
render( summarize TOTAL_LINES / 10 + 1 )
puts

puts 'Top 10%'
render( summarize TOTAL_LINES / 10 / 10 + 1 )
puts

puts 'Top 1%'
render( summarize TOTAL_LINES / 10 / 10 / 10 + 1 )
puts
