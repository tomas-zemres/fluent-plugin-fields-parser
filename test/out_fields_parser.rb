require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_fields_parser'

class FieldsParserOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf='')
    Fluent::Test::Driver::Output.new(Fluent::Plugin::OutputFieldsParser).configure(conf)
  end

  def test_config_defaults
    d = create_driver()

    orig_message = %{parse this num=-56.7 tok=abc%25 null=}
    d.run(default_tag: 'orig.test.tag') do
      d.feed({
        'message' => orig_message,
        'other_key' => %{ test2 a=b },
      })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'other_key' => %{ test2 a=b },
        'num' => '-56.7',
        'tok' => 'abc%25',
        'null' => '',
      },
      events[0][2]
    )
  end

  def test_quoted_values
    d = create_driver()

    orig_message = %{blax dq="asd ' asd +3" sq='as " s " 4' s=yu 6}
    d.run(default_tag: 'orig.test.tag') do
      d.feed({
        'message' => orig_message,
      })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'dq' => "asd ' asd +3",
        'sq' => 'as " s " 4',
        's' => 'yu'
      },
      events[0][2]
    )
  end

  def test_parsed_key_is_missing
    d = create_driver()

    d.run(default_tag: 'orig.test.tag') do
      d.feed({})
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {},
      events[0][2]
    )
  end

  def test_existing_keys_are_not_overriden
    d = create_driver()

    orig_message = %{mock a=77 message=blax a=999 e=5}
    d.run(default_tag: 'orig.test.tag') do
      d.feed({'message' => orig_message, 'e' => nil })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'a' => '77',
        'e' => nil,
      },
      events[0][2]
    )
  end

  def test_tag_prefixes
    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    })

    d.run(default_tag: 'orig.test.tag') do
      d.feed({ 'message' => 'abc' })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "new.test.tag", events[0][0]

    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    })

    d.run(default_tag: '') do
      d.feed({ 'message' => 'abc' })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "new", events[0][0]

    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    })

    d.run(default_tag: 'original') do
      d.feed({ 'message' => 'abc' })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "new.original", events[0][0]

    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    })

    d.run(default_tag: 'orig') do
      d.feed({ 'message' => 'abc' })
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "new", events[0][0]
  end

  def test_parse_key
    d = create_driver('parse_key  custom_key')

    d.run(default_tag: 'orig.test.tag') do
      d.feed({
        'message' => %{ test2 c=d },
        'custom_key' => %{ test2 a=b },
      })
      d.feed({})
    end

    events = d.events
    assert_equal 2, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => %{ test2 c=d },
        'custom_key' => %{ test2 a=b },
        'a' => 'b'
      },
      events[0][2]
    )
    assert_equal(
      {
      },
      events[1][2]
    )
  end

  def test_fields_key
    d = create_driver("fields_key output-key")

    orig_message = %{parse this num=-56.7 tok=abc%25 message=a+b}
    d.run(default_tag: 'orig.test.tag') do
      d.feed({'message' => orig_message})
    end

    events = d.events
    assert_equal 1, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'output-key' => {
          'num' => '-56.7',
          'tok' => 'abc%25',
          'message' => 'a+b',
        }
      },
      events[0][2]
    )
  end

  def test_custom_pattern
    d = create_driver("pattern (\\w+):(\\d+)")

    orig_message = %{parse this a:44 b:ignore-this h=7 bbb:999}
    d.run(default_tag: 'orig.test.tag') do
      d.feed({'message' => orig_message})
      d.feed({'message' => 'a'})
    end

    events = d.events
    assert_equal 2, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'a' => '44',
        'bbb' => '999',
      },
      events[0][2]
    )
    assert_equal(
      {
        'message' => 'a',
      },
      events[1][2]
    )
  end

  def test_strict_key_value
    d = create_driver("strict_key_value true")

    orig_message = %{msg="Audit log" user=Johnny action="add-user" dontignore=don't-ignore-this result=success iVal=23 fVal=1.02 bVal=true}
    d.run(default_tag: 'orig.test.tag') do
      d.feed({'message' => orig_message})
      d.feed({'message' => 'a'})
    end

    events = d.events
    assert_equal 2, events.size
    assert_equal "orig.test.tag", events[0][0]
    assert_equal(
      {
        'message' => orig_message,
        "msg"=>"Audit log",
        'user' => "Johnny",
        'action' => 'add-user',
        'dontignore' => "don't-ignore-this",
        'result' => 'success',
        'iVal' => 23,
        'fVal' => 1.02,
        'bVal' => "true"
      },
      events[0][2]
    )
    assert_equal(
      {
        'message' => 'a',
      },
      events[1][2]
    )
  end

end
