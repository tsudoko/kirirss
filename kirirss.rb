#!/usr/bin/env ruby
require 'net/http'
require 'time'

require 'chronic'
require 'nokogiri'
require 'toml'

module KiriRSS
  class ConfigError < StandardError
  end

  private_class_method def self.make_tag(root, options, name)
    tag = options["tag"][name]
    contents = nil

    if tag["use-root"]
      match = root
    elsif tag["selector"] != ""
      match = root.at_css(tag["selector"])
    else
      match = nil
    end

    if match
      if tag.key? "attribute" and tag["attribute"] != ""
        contents = match.attr(tag["attribute"])
      else
        contents = match.content.strip
      end
    else
      contents = tag["placeholder"]
    end

    if contents
      if tag.key? "date-format" and tag["date-format"] != ""
        if tag["date-format"] == "auto"
          time = Chronic.parse(contents, :context => :past)
        else
          time = Time.strptime(contents, tag["date-format"])
        end

        contents = time.rfc2822.to_s
      end

      if tag["is-url"]
        contents = URI.join(options["feed-link"], contents).to_s
      end
    end

    return contents
  end

  def self.make_feed(html, options)
    required_fields = ["feed-link", "root-selector"]

    required_fields.each do |f|
      raise ConfigError.new("required field '#{f}' not found") if !options[f]
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.rss(:version => "2.0") {
        xml.channel {
          xml.title       (options["feed-title"] or html.title)
          xml.description options["feed-description"]
          xml.pubDate     Time.now.rfc2822.to_s
          xml.link        options["feed-link"]
          xml.generator   "kirirss" # version?

          html.css(options["root-selector"]).each do |root|
            xml.item {
              (options["tag"] or {}).each do |tag|
                if tag[1]["out-attributes"]
                  xml.send(tag[0], make_tag(root, options, tag[0]), tag[1]["out-attributes"])
                else
                  xml.send(tag[0], make_tag(root, options, tag[0]))
                end
              end
            }
          end
        }
      }
    end

    return builder.doc
  end
end

if __FILE__ == $0
  if ARGV.empty?
    abort "usage: #{File.basename($0)} configfile"
  end

  begin
    options = TOML.load_file(ARGV[0])
  rescue => e
    abort "error: #{e}"
  end

  if !options["feed-link"]
    abort "feed-link is missing"
  end

  uri = URI(options["feed-link"])
  res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri, options["headers"])
      http.request(request)
  end

  begin
    feed = KiriRSS.make_feed(Nokogiri.HTML(res.body, options["feed-link"]), options)
    puts feed.to_xml

    if feed.css("channel > item").empty?
      STDERR.puts "warning: feed from #{options["feed-link"]} has no items"
    end
  rescue KiriRSS::ConfigError => e
    abort "config error: #{e}"
  end
end
