#!/usr/bin/env ruby

require 'bigdecimal'

private

def page addresses, segment_size
  length = addresses.length

  segment = 0

  while length >= segment * segment_size
    first = segment * segment_size
    last  = ( ( segment + 1 ) * segment_size ) - 1

    yield addresses[ first..last ]

    segment += 1
  end
end

def read_addresses
  @all_addresses                      = [ ]
  @more_than_single_satoshi_addresses = [ ]

  ARGF.each_line do |line|
    entry = line.chomp

    address, text_amount = entry.split /\s+/

    amount = BigDecimal text_amount

    address = { :address => address,
                :amount  => amount }

    @all_addresses << address

    print '.'
  end

  puts
  puts 'Reversing...'
  puts

  @all_addresses.reverse!
end

def all_addresses
  @all_addresses
end

SATOSHI = BigDecimal '0.00000001'

def more_than_single_satoshi_addresses
  all_addresses.reject { |a| a[:amount] == SATOSHI }
end

def sum_amounts addresses
  addresses.collect { |a| a[:amount] }.reduce :+
end

def format amount, precision=8
  total = 9 + precision

  "%#{total}.#{precision}f" % amount
end

def segment_size addresses
  addresses.length / 10 + 1
end

def segmentize addresses
  page_size = segment_size addresses

  page( addresses, page_size ) do |page_of_addresses|
    sum = sum_amounts page_of_addresses
    min = page_of_addresses.first[:amount]
    max = page_of_addresses.last[:amount]

    yield sum, min, max
  end
end

def render addresses, divided_addresses
  overall_sum = sum_amounts addresses

  puts ' ---------------------------------------------------------------------------------------------------'
  puts '|             Total |        Percentage |           Average |               Min |               Max |'
  puts ' ---------------------------------------------------------------------------------------------------'

  segmentize( divided_addresses ) do | sum, min, max |
    amount     = format sum
    percentage = format ( sum / overall_sum ) * 100
    average    = format sum / segment_size( divided_addresses )
    minimum    = format min
    maximum    = format max

    puts "| #{amount} | #{percentage} | #{average} | #{minimum} | #{maximum} |"
  end

  puts ' ---------------------------------------------------------------------------------------------------'
  puts
end

def render_top addresses, percentage
  top_index = addresses.length * percentage

  render addresses, addresses[ -top_index..-1 ]
end

def run_top_hundred addresses
  puts 'Top 100%'
  render_top addresses, 1
end

def run_top_ten addresses
  puts 'Top 10%'
  render_top addresses, 0.1
end

def run_top_one addresses
  puts 'Top 1%'
  render_top addresses, 0.01
end

def run_with_single_satoshi
  puts 'With single satoshi addresses'
  puts '-----------------------------'
  puts

  run_top_hundred all_addresses
  run_top_ten     all_addresses
  run_top_one     all_addresses
end

def run_without_single_satoshi
  puts 'Without single satoshi addresses'
  puts '--------------------------------'
  puts

  run_top_hundred more_than_single_satoshi_addresses
  run_top_ten     more_than_single_satoshi_addresses
  run_top_one     more_than_single_satoshi_addresses
end

def run_reports
  run_with_single_satoshi
  run_without_single_satoshi
end

public

read_addresses
run_reports
