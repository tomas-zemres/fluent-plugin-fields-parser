require 'fluent/test'
require 'fluent/plugin/out_fields_parser'

class FieldsParserOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf='', tag='orig.test.tag')
    Fluent::Test::OutputTestDriver.new(Fluent::OutputFieldsParser, tag).configure(conf)
  end

  def test_config_defaults
    d = create_driver()

    orig_message = %{parse this num=-56.7 tok=abc%25 null=}
    d.run do
      d.emit({
        'message' => orig_message,
        'other_key' => %{ test2 a=b },
      })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'other_key' => %{ test2 a=b },
        'num' => '-56.7',
        'tok' => 'abc%25',
        'null' => '',
      },
      emits[0][2]
    )
  end

  def test_quoted_values
    d = create_driver()

    orig_message = %{blax dq="asd ' asd +3" sq='as " s " 4' s=yu 6}
    d.run do
      d.emit({
        'message' => orig_message,
      })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'dq' => "asd ' asd +3",
        'sq' => 'as " s " 4',
        's' => 'yu'
      },
      emits[0][2]
    )
  end

  def test_parsed_key_is_missing
    d = create_driver()

    d.run do
      d.emit({})
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {},
      emits[0][2]
    )
  end

  def test_existing_keys_are_not_overriden
    d = create_driver()

    orig_message = %{mock a=77 message=blax a=999 e=5}
    d.run do
      d.emit({'message' => orig_message, 'e' => nil })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'a' => '77',
        'e' => nil,
      },
      emits[0][2]
    )
  end

  def test_tag_prefixes
    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    })

    d.run do
      d.emit({ message => 'abc' })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "new.test.tag", emits[0][0]

    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    }, tag=nil)

    d.run do
      d.emit({ message => 'abc' })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "new", emits[0][0]

    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    }, tag='original')

    d.run do
      d.emit({ message => 'abc' })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "new.original", emits[0][0]

    d = create_driver(%{
      remove_tag_prefix   orig
      add_tag_prefix      new
    }, tag='orig')

    d.run do
      d.emit({ message => 'abc' })
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "new", emits[0][0]
  end

  def test_parse_key
    d = create_driver('parse_key  custom_key')

    d.run do
      d.emit({
        'message' => %{ test2 c=d },
        'custom_key' => %{ test2 a=b },
      })
      d.emit({})
    end

    emits = d.emits
    assert_equal 2, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {
        'message' => %{ test2 c=d },
        'custom_key' => %{ test2 a=b },
        'a' => 'b'
      },
      emits[0][2]
    )
    assert_equal(
      {
      },
      emits[1][2]
    )
  end

  def test_fields_key
    d = create_driver("fields_key output-key")

    orig_message = %{parse this num=-56.7 tok=abc%25 message=a+b}
    d.run do
      d.emit({'message' => orig_message})
    end

    emits = d.emits
    assert_equal 1, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'output-key' => {
          'num' => '-56.7',
          'tok' => 'abc%25',
          'message' => 'a+b',
        }
      },
      emits[0][2]
    )
  end

  def test_custom_pattern
    d = create_driver("pattern (\\w+):(\\d+)")

    orig_message = %{parse this a:44 b:ignore-this h=7 bbb:999}
    d.run do
      d.emit({'message' => orig_message})
      d.emit({'message' => 'a'})
    end

    emits = d.emits
    assert_equal 2, emits.size
    assert_equal "orig.test.tag", emits[0][0]
    assert_equal(
      {
        'message' => orig_message,
        'a' => '44',
        'bbb' => '999',
      },
      emits[0][2]
    )
    assert_equal(
      {
        'message' => 'a',
      },
      emits[1][2]
    )
  end

def test_strict_key_value
  d = create_driver("strict_key_value true")

  orig_message = %{msg="Audit log" user=Johnny action="add-user" dontignore=don't-ignore-this result=success iVal=23 fVal=1.02 bVal=true}
  d.run do
    d.emit({'message' => orig_message})
    d.emit({'message' => 'a'})
  end

  emits = d.emits
  assert_equal 2, emits.size
  assert_equal "orig.test.tag", emits[0][0]
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
    emits[0][2]
  )
  assert_equal(
    {
      'message' => 'a',
    },
    emits[1][2]
  )
end


end
