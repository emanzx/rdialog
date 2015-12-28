require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/mrdialog'

Minitest::Reporters.use!

class TestMRDialog < Minitest::Test

  attr_reader :dialog

  def setup
    @dialog = MRDialog.new
    @dialog.dry_run = false
    @dialog.logger = Logger.new(STDOUT)
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
    assert_includes(cmd, '--buildlist', cmd)
    assert_includes(cmd, '"\"buildlist\" test"', cmd)
    assert_includes(cmd, ' 24 80 12', cmd)
    assert_includes(cmd, '"1" "Item #1" "on" ')
    assert_includes(cmd, '"2" "Item #2" "off" ')
    assert_includes(cmd, '"3" "Item #3" "off" ')
  end

  def test_calendar
    dialog.calendar('"calendar" test', 0, 0, 25, 12, 2015)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--calendar', cmd)
    assert_includes(cmd, '"\"calendar\" test"', cmd)
    assert_includes(cmd, '0 0 25 12 2015', cmd)
    assert_includes(cmd, '2> "', cmd)
  end

  def test_checklist
    items = []
    items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
    items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
    items << dialog.list_item(tag: '3', item: 'Item #3', status: false)

    result = dialog.checklist('"checklist" test', items)
    cmd = dialog.last_cmd

    assert_equal(['1'], result)  
  end

  def test_dselect
    result = dialog.dselect(__FILE__, 0, 0)
    cmd = dialog.last_cmd
    assert_equal('test_mrdialog.rb', result, cmd)
    assert_includes(cmd, '--dselect')
    assert_includes(cmd, __FILE__, cmd)
    assert_includes(cmd, '0 0', cmd)
  end

  def test_editbox
    result = dialog.editbox(__FILE__, 0, 0)
    cmd = dialog.last_cmd
    assert_equal(result, IO.read(__FILE__), cmd)
    assert_includes(cmd, '--editbox', cmd)
    assert_includes(cmd, __FILE__, cmd)
    assert_includes(cmd, '0 0', cmd)
    tmp.close!
  end

  def test_form
    items = []
    items << dialog.form_item(label: 'Field #1', ly: 1, lx: 1, item: 'Value 1', iy: 1, ix: 10, flen: 20, ilen: 0)
    items << dialog.form_item(label: 'Field #2', ly: 2, lx: 1, item: 'Value 2', iy: 2, ix: 10, flen: 20, ilen: 0)
    items << dialog.form_item(label: 'Field #3', ly: 3, lx: 1, item: 'Value 3', iy: 3, ix: 10, flen: 20, ilen: 0)
    result = dialog.form('"Form" Test', items, 0, 0, 0)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--form', cmd)
    assert_includes(cmd, %q{"\"Form\" Test}, cmd)
    assert_includes(cmd, %q{"Field #1" 1 1 "Value 1" 1 10 20 0}, cmd)
    assert_includes(cmd, %q{"Field #2" 2 1 "Value 2" 2 10 20 0}, cmd)
    assert_includes(cmd, %q{"Field #3" 3 1 "Value 3" 3 10 20 0}, cmd)
  end

  def test_fselect
    dir = File.dirname(__FILE__)
    result = dialog.fselect(dir, 0, 0)
    cmd = dialog.last_cmd
    assert_equal('.,', result, cmd)
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
    assert_includes(cmd, '--gauge', cmd)
    assert_includes(cmd, '"\"gauge\" test"', cmd)
    assert_includes(cmd, ' 24 80 0', cmd)
  end

  def test_infobox
    dialog.infobox('"Infobox" Test', 24, 80)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--infobox', cmd)
    assert_includes(cmd, '"\"Infobox\" Test" 24 80', cmd)
  end

  def test_inputbox
    result = dialog.inputbox('"Inputbox" Test', 'inputbox test', 0, 0)
    cmd = dialog.last_cmd
    assert_equal('inputbox test', result, cmd)
    assert_includes(cmd, '--inputbox', cmd)
    assert_includes(cmd, '"\"Inputbox\" Test" 0 0 "inputbox test', cmd)
  end

  def test_menu
    items = []
    items << dialog.menu_item(tag: '1', item: 'Item #1')
    items << dialog.menu_item(tag: '2', item: 'Item #2')
    items << dialog.menu_item(tag: '3', item: 'Item #3')
    result = dialog.menu('"Menu" Test', items) 
    cmd = dialog.last_cmd
    assert_equal('1', result)
    assert_includes(cmd, '--menu', cmd)
    assert_includes(cmd, '"1" "Item #1"')
    assert_includes(cmd, '"2" "Item #2"')
    assert_includes(cmd, '"3" "Item #3"')
  end

  def test_msgbox
    dialog.msgbox('"Msgbox" Test', 24, 80)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--msgbox', cmd)
    assert_includes(cmd, '"\"Msgbox\" Test"', cmd)
    assert_includes(cmd, ' 24 80', cmd)
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