# fluent-plugin-fields-parser [![Build Status](https://travis-ci.org/tomas-zemres/fluent-plugin-fields-parser.png)](https://travis-ci.org/tomas-zemres/fluent-plugin-fields-parser)

Fluent output filter plugin for parsing key/value fields in records
based on &lt;key>=&lt;value> pattern.

## Installation

Use RubyGems:

    gem install fluent-plugin-fields-parser

## Configuration

    <match pattern>
        type                fields_parser

        remove_tag_prefix   raw
        add_tag_prefix      parsed

        strict_key_value     false
    </match>

If following record is passed:

```
{"message": "Audit log user=Johny action='add-user' result=success" }
```

then you will get a new record:

```
{
    "message": "Audit log username=Johny action='add-user' result=success",
    "user": "Johny",
    "action": "add-user",
    "result": "success"
}
```

### Parameter parse_key

For configuration

    <match pattern>
        type        fields_parser

        parse_key   log_message
    </match>

it parses key "log_message" instead of default key `message`.

### Parameter fields_key

Configuration

    <match pattern>
        type        fields_parser

        parse_key   log_message
        fields_key  fields
    </match>

For input like:

```
{
    "log_message": "Audit log username=Johny action='add-user' result=success",
}
```

it adds parsed fields into defined key.

```
{
    "log_message": "Audit log username=Johny action='add-user' result=success",
    "fields": {"user": "Johny", "action": "add-user", "result": "success"}
}
```

(It adds new keys into top-level record by default.)

### Parameter pattern

You can define custom pattern (regexp) for seaching keys/values.

Configuration

    <match pattern>
        type        fields_parser

        pattern     (\w+):(\d+)
    </match>

For input like:
```
{ "message": "data black:54 white:55 red:10"}
```

it returns:

```
{ "message": "data black:54 white=55 red=10",
  "black": "54", "white": "55", "red": "10"
}
```

### Tag prefix

You cat add and/or remove tag prefix using Configuration parameters

    <match pattern>
        type                fields_parser

        remove_tag_prefix   raw
        add_tag_prefix      parsed
    </match>

If it matched tag "raw.some.record", then it emits tag "parsed.some.record".

### Parameter strict_key_value

```
    <match pattern>
        type                fields_parser
        strict_key_value   true
    </match>
```

If `strict_key_value` is set to `true`, the parser will use the [ruby logfmt
parser](https://github.com/cyberdelia/logfmt-ruby) which will parse the log
message based on the popular [logfmt](https://brandur.org/logfmt) key/value
format.  Do note that this parser will create Fixnum and Float type values
when it parses integer and float values.

All information provided in the log message must be in a strict key=value
format.  For example, if following record is passed:

```
{"message": "msg=\"Audit log\" user=Johnny action=\"add-user\" result=success iVal=23 fVal=1.02 bVal=true" }
```

then you will get a new record:

```
{
    "message": "msg=\"Audit log\" user=Johnny action=\"add-user\" result=success iVal=23 fVal=1.02 bVal=true",
    "msg": "Audit log",
    "user": "Johnny",
    "action": "add-user",
    "result": "success",
    "iVal": 23,
    "fVal": 1.02,
    "bVal": "true"
}
```
