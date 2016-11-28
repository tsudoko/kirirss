#!/usr/bin/env ruby
require 'net/http'
require 'time'

require 'chronic'
require 'nokogiri'
require 'toml'

module KiriRSS
  private_class_method def self.make_tag(root, options, name)
    tag = options["tag"][name]
    contents = nil

    if tag["use-root"]
      match = root
    elsif tag["selector"]
      match = root.at_css(tag["selector"])
    else
      match = nil
    end

    if match
      if tag["attribute"]
        contents = match.attr(tag["attribute"])
      else
        contents = match.content.strip
      end
    else
      contents = tag["placeholder"]
    end

    if contents
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
    end

    return contents
  end

  def self.make_feed(html, options)
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
              options["tag"].each do |tag|
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

    return builder.to_xml
  end
end

if __FILE__ == $0
  options = TOML.load_file(ARGV[0])
  content = Net::HTTP.get(URI(options["feed-link"]))

  puts KiriRSS.make_feed(Nokogiri.HTML(content, options["feed-link"]), options)
end
