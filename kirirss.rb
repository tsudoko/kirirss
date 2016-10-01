#!/usr/bin/env ruby
require 'net/http'
require 'time'

require 'chronic'
require 'nokogiri'
require 'toml'

def make_tag(elem, options, name)
    tag = options[name]
    contents = nil

    if tag["selector"]
        if tag["attribute"]
            contents = elem.at_css(tag["selector"]).attr(tag["attribute"])
        else
            match = elem.at_css(tag["selector"])
            if match 
                contents = match.content.strip
            end
        end

        if tag["date-format"]
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
    else
        contents = tag["placeholder"]
    end

    return contents
end

def make_feed(html, options)
    builder = Nokogiri::XML::Builder.new do |xml|
        xml.rss(:version => "2.0") {
            xml.channel {
                xml.title       (options["feed-title"] or html.title)
                xml.description options["feed-description"]
                xml.pubDate     Time.now.rfc2822.to_s
                xml.link        options["feed-link"]
                xml.generator   "kirirss" # version?

                html.css(options["elem-selector"]).each do |elem|
                    xml.item {
                        xml.title       make_tag(elem, options, "title")
                        xml.description make_tag(elem, options, "description")
                        xml.link        make_tag(elem, options, "link")
                        xml.guid        make_tag(elem, options, "guid")
                        xml.pubDate     make_tag(elem, options, "pubDate")
                    }
                end
            }
        }
    end

    return builder.to_xml
end

options = TOML.load_file(ARGV[0])
content = Net::HTTP.get(URI(options["feed-link"]))

puts make_feed(Nokogiri.HTML(content, options["feed-link"]), options)
