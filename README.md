kirirss
=======

Simple HTML→RSS converter. Can be easily integrated with cron, feed readers with
external script support or other Ruby applications. Input data is specified with
CSS selectors.

Dependencies
------------

`chronic`, `nokogiri`, and `toml-rb` gems need to be installed before using
kirirss.

Config file
-----------

Sample configuration files can be found in the `misc` directory.

Fields prefixed with 🔶 are required. "Skipped" means not present in the config
file or empty. Note that even though some fields are not required, skipping them
will produce invalid RSS feeds.

### `feed-title` (string)

Content of the `<title>` feed tag. Page title is used if the field is skipped.

### `feed-description` (string)

Content of the `<description>` feed tag. Empty if the field is skipped.

### 🔶 `feed-link` (string)

URL of the page to extract data from. Used in of the `<link>` feed as well.
Required.

### 🔶 `root-selector` (string)

Root selector of a single input item. "Input item" is a tag which contains all
data used in a single feed item. Required.

### `headers` (table)

Additional headers to use when fetching the input page. Can be used for
authentication or UA spoofing. Example:

    [headers]
    Cookie = "session_id=asdf42194"
    X-Requested-With = "XMLHttpRequest"

### `tag.(name)` (table)

Child tag of each `<item>` in the feed with the name `(name)`. If this field is
present, the `<(name)>` tag will exist in each item. Example tag:

    [tag.pubDate]
    selector = "time"
    attribute = "datetime"
    date-format = "auto"

#### `selector` (string)

Selector for the current tag contents. Not used if `use-root` is true.

#### `use-root` (boolean)

Use the tag matched by the root selector.

#### `attribute` (string)

Attribute of a matched input tag to be used for the current tag contents. When
this field is present, content will be extracted from the specified attribute
instead of the contents of the tag.

#### `out-attributes` (table)

Additional tag attributes. The most common use case:

    [tag.guid]
    # ...
    out-attributes = {isPermaLink = false}

#### `placeholder` (string)

Text used when the input tag is empty or not found.

#### `date-format` (string)

[strptime][1] format of the date in the contents. If a special "auto" value is
given, the format is parsed heuristically with [chronic][2]. Output tag will
contain a [RFC 2822][3]-formatted date. Contents will not be date-formatted if
this field is skipped.

[1]: http://ruby-doc.org/stdlib/libdoc/date/rdoc/DateTime.html#method-c-strptime
[2]: https://github.com/mojombo/chronic
[3]: https://tools.ietf.org/html/rfc2822.html#section-3.3

#### `is-url` (boolean)

Make the URL absolute if it's relative.
