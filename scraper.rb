#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//a[contains(@href,"clt/run.asp?id=")][.//img]').each do |a|
    source = a.attr('href')
    data = { 
      id: source[/id=(\d+)/, 1],
      name: a.xpath('following::text()').find { |n| !n.text.tidy.empty? }.text.tidy,
      party: "Independent",
      image: a.css('img/@src').text,
      term: 14,
      source: source,
    }
    data.merge! scrape_person(data)
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

def scrape_person(p)
  noko = noko_for(p[:source])
  constituency = 'الدائرة الانتخابية'
  return { 
    name__ar: noko.css('img[src="%s"]' % p[:image]).xpath('following::text()').find { |n| !n.text.tidy.empty? }.text.tidy,

    area: noko.xpath('//p[contains(.,"%s")]' % constituency).text.tidy,
  }
end

scrape_list('http://www.kna.kw/clt/erun.asp?id=1979')
