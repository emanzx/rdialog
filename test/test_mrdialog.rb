require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/mrdialog'

Minitest::Reporters.use!

class TestMRDialog < Minitest::Test

  attr_reader :dialog

  def setup
    @dialog = MRDialog.new
    @dialog.dry_run = false
  end

  def commands
    { 
      infobox: [ 'infobox', 24, 80 ],
      msgbox: [ 'msgbox', 24, 80 ],
    }
  end

  #
  # Boxes
  #

  def test_buildlist
    items = []
    items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
    items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
    items << dialog.list_item(tag: '3', item: 'Item #3', status: false)
    dialog.buildlist('"buildlist" test', items, 24, 80, 12)
    cmd = dialog.last_cmd
    assert_includes(cmd, '"\"buildlist\" test"', cmd)
    assert_includes(cmd, ' 24 80 12', cmd)
    assert_includes(cmd, '"1" "Item #1" "on" ')
    assert_includes(cmd, '"2" "Item #2" "off" ')
    assert_includes(cmd, '"3" "Item #3" "off" ')
  end

  def test_gauge
    dialog.gauge('"gauge" test', 24, 80, 0) do |f|
      1.upto(100) do |a|
        f.puts "XXX"
        f.puts a
        f.puts "The new\nmessage (#{a} percent)"
        f.puts "XXX"
        sleep 0.001
      end
    end
    cmd = dialog.last_cmd
    assert_includes(cmd, '"\"gauge\" test"', cmd)
    assert_includes(cmd, ' 24 80 0', cmd)
  end

  def test_infobox
    dialog.infobox('"infobox" test', 24, 80)
    assert_includes(dialog.last_cmd, '"\"infobox\" test"', dialog.last_cmd)
    assert_includes(dialog.last_cmd, ' 24 80', dialog.last_cmd)
  end

  def test_msgbox
    dialog.msgbox('"msgbox" test', 24, 80)
    assert_includes(dialog.last_cmd, '"\"msgbox\" test"')
    assert_includes(dialog.last_cmd, ' 24 80')
  end

  #
  # Options 
  # 
  def test_ascii_lines_option
    dialog.ascii_lines = false

    commands.each do |method, arguments|
      dialog.send(method, *arguments)
      refute_includes(dialog.last_cmd, '--ascii-lines')
    end

    dialog.ascii_lines = true
    commands.each do |method, arguments|
      dialog.send(method, *arguments)
      assert_includes(dialog.last_cmd, '--ascii-lines')
    end
  end
end