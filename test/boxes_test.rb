require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/rdialog'

Minitest::Reporters.use!

class TestRDialog < Minitest::Test

  attr_reader :dialog

  def setup
    @dialog = RDialog.new
    @dialog.dry_run = false
    @dialog.logger = Logger.new(STDOUT)
  end

  def test_buildlist
    dialog.title = 'BUILDLIST'
    items = []
    items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
    items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
    items << dialog.list_item(tag: '3', item: 'Item #3', status: false)
    items << dialog.list_item(tag: '4', item: 'Item #4', status: true)
    items << dialog.list_item(tag: '5', item: 'Item #5', status: false)

    text = %Q{"Buildlist" Test\n\nThis test makes sure items #1 and #4 are selected.}
    tags = dialog.buildlist(text, items, 24, 80, 12)
    assert_equal(['1', '4'], tags)
    assert_equal(dialog.dialog_ok, dialog.exit_code)

    cmd = dialog.last_cmd
    assert_includes(cmd, '--buildlist', cmd)
    assert_includes(cmd, ' 24 80 12', cmd)
    assert_includes(cmd, '"1" "Item #1" "on" ')
    assert_includes(cmd, '"2" "Item #2" "off" ')
    assert_includes(cmd, '"3" "Item #3" "off" ')
    assert_includes(cmd, '"4" "Item #4" "on" ')
    assert_includes(cmd, '"5" "Item #5" "off" ')
  end

  def test_calendar
    dialog.title = 'CALENDAR'
    text = %Q{"Calendar" Test\n\nThis test makes sure the date of December 25th, 2015 is selected.}
    date = dialog.calendar(text, 0, 0, 25, 12, 2015)
    assert_equal(2015, date.year)
    assert_equal(12, date.month)
    assert_equal(25, date.day)

    cmd = dialog.last_cmd
    assert_includes(cmd, '--calendar', cmd)
    assert_includes(cmd, '0 0 25 12 2015', cmd)
    assert_includes(cmd, '2> "', cmd)
  end

  def test_checklist
    dialog.title = 'CHECKLIST'
    items = []
    items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
    items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
    items << dialog.list_item(tag: '3', item: 'Item #3', status: false)
    items << dialog.list_item(tag: '4', item: 'Item #4', status: true)
    items << dialog.list_item(tag: '5', item: 'Item #5', status: false)

    text = %Q{"Checklist" Test\n\nThis test makes sure items #1 and #4 are selected.}

    tags = dialog.checklist('"checklist" test', items)
    assert_equal(['1', '4'], tags)
    assert_equal(dialog.dialog_ok, dialog.exit_code)

    cmd = dialog.last_cmd
    assert_includes(cmd, '--checklist', cmd)
  end

  def test_dselect
    dialog.title = 'DSELECT'
    result = dialog.dselect(File.expand_path('..', File.dirname(__FILE__)), 0, 0)
    cmd = dialog.last_cmd
    assert_includes(result, 'rdialog')
    assert_includes(cmd, '--dselect')
    assert_includes(cmd, '0 0', cmd)
  end

  def test_editbox
    dialog.title = 'EDITBOX'
    result = dialog.editbox(__FILE__, 0, 0)
    assert_equal(IO.read(__FILE__), result)

    cmd = dialog.last_cmd
    assert_includes(cmd, '--editbox', cmd)
    assert_includes(cmd, __FILE__, cmd)
    assert_includes(cmd, '0 0', cmd)
    tmp.close!
  end

  def test_form
    dialog.title = 'FORM'
    text = %Q{"Form" Test\n\nThis test ensures that Field #1 is equal to 'Value 1', Field #2 is equal to 'Value 2' and Field #3 is equal to 'Value 3'.}

    items = []
    items << dialog.form_item(label: 'Field #1', ly: 1, lx: 1, item: 'Value 1', iy: 1, ix: 10, flen: 20, ilen: 0)
    items << dialog.form_item(label: 'Field #2', ly: 2, lx: 1, item: 'Value 2', iy: 2, ix: 10, flen: 20, ilen: 0)
    items << dialog.form_item(label: 'Field #3', ly: 3, lx: 1, item: 'Value 3', iy: 3, ix: 10, flen: 20, ilen: 0)

    result = dialog.form(text, items, 0, 0, 0)
    assert_equal('Value 1', result['Field #1'])
    assert_equal('Value 2', result['Field #2'])
    assert_equal('Value 3', result['Field #3'])

    cmd = dialog.last_cmd
    assert_includes(cmd, '--form', cmd)
    assert_includes(cmd, %q{"Field #1" 1 1 "Value 1" 1 10 20 0}, cmd)
    assert_includes(cmd, %q{"Field #2" 2 1 "Value 2" 2 10 20 0}, cmd)
    assert_includes(cmd, %q{"Field #3" 3 1 "Value 3" 3 10 20 0}, cmd)
  end

  def test_fselect
    dialog.title = 'FSELECT'
    dir = File.expand_path('..', File.dirname(__FILE__))
    result = dialog.fselect(dir, 0, 0)
    assert_equal(dir, result)

    cmd = dialog.last_cmd
    assert_includes(cmd, '--fselect', cmd)
    assert_includes(cmd, ' 0 0', cmd)
  end

  def test_gauge
    dialog.title = 'GAUGE'
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
    dialog.title = 'INFOBOX'
    dialog.infobox('"Infobox" Test', 24, 80)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--infobox', cmd)
    assert_includes(cmd, '"\"Infobox\" Test" 24 80', cmd)
  end

  def test_inputbox
    dialog.title = 'INPUTBOX'
    text = %Q{"Inputbox" Test\n\nThis test ensures that the input box is equal to "Inputbox Test".}
    result = dialog.inputbox(text, 'Inputbox Test', 0, 0)
    assert_equal('Inputbox Test', result)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--inputbox', cmd)
    assert_includes(cmd, ' 0 0 "Inputbox Test', cmd)
  end

  def test_inputmenu
    dialog.title = 'INPUTMENU'
    dialog.visit_items = true
    dialog.quoted = true
    text = %Q{"Inputmenu" Test\n\nA test for inputmenu boxes.}

    items = []
    items << dialog.menu_item(tag: '1 2', item: 'Item #1')
    items << dialog.menu_item(tag: '2', item: 'Item #2')
    items << dialog.menu_item(tag: '3', item: 'Item #3')

    result = dialog.inputmenu(text, items, 0, 0, 9)
    dialog.debug(result.inspect)

  end

  def test_menu
    dialog.title = 'MENU'
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

  def test_mixedform
  end

  def test_mixedgauge
  end

  def test_msgbox
    dialog.title = 'MSGBOX'
    dialog.msgbox('"Msgbox" Test', 24, 80)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--msgbox', cmd)
    assert_includes(cmd, '"\"Msgbox\" Test"', cmd)
    assert_includes(cmd, ' 24 80', cmd)
  end

  def test_pause
    dialog.title = 'PAUSE'
    text = %Q{"Pause" Test\n\nThis test will pause for 2 seconds and exit.}
    dialog.pause(text, 2, 10, 60)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--pause')
    assert_includes(cmd, '"\"Pause\" Test" 10 30 2', cmd)
  end

  def test_passwordbox
  end

  def test_prgbox
    dialog.title = 'PRGBOX'
    command = 'ls'#;File.expand_path('shortlist', File.dirname(__FILE__))
    dialog.prgbox(command, 20, 70, '"Prgbox" Test')
    cmd = dialog.last_cmd
    assert_includes(cmd, '--prgbox')
  end

  def test_programbox
    dialog.title = 'PROGRAMBOX'
    dialog.programbox do |f|
      la = `ls -l1`.split("\n")
      la.each do |l|
        f.puts l
        sleep 0.1
      end
    end
    cmd = dialog.last_cmd
    assert_includes(cmd, '--programbox')
  end

  def test_progressbox
    dialog.title = "PROGRESSBOX"
    dialog.progressbox do |f|
      la = `ls -l1`.split("\n")
      la.each do |l|
        f.puts l
        sleep 0.1
      end
    end
    cmd = dialog.last_cmd
    assert_includes(cmd, '--progressbox')
  end

  def test_radiolist
    dialog.title = 'RADIOLIST'
    items = []
    items << dialog.list_item(tag: 'Apple', item: "It's an apple", status: false)
    items << dialog.list_item(tag: 'Dog', item: "No it's not my dog", status: true)
    items << dialog.list_item(tag: 'Orange', item: "Yeah! it is juicy", status: false)

    result = dialog.radiolist('"Radiolist" Test', items)
    cmd = dialog.last_cmd
    assert_equal('Dog', result)
    assert_includes(cmd, '--radiolist')
  end

  def test_rangebox
  end

  def test_tailbox
    dialog.title = 'TAILBOX'
    dialog.tailbox(__FILE__)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--tailbox')
    assert_includes(cmd, __FILE__)
  end

  def test_tailboxbg
    dialog.title = 'TAILBOXBG'
    dialog.tailboxbg(__FILE__)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--tailboxbg')
    assert_includes(cmd, __FILE__)
  end

  def test_textbox
    dialog.title = 'TEXTBOX'
    dialog.textbox(__FILE__)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--textbox')
    assert_includes(cmd, __FILE__)
  end

  def test_timebox
    dialog.title = 'TIMEBOX'
    dialog.timebox('"Timebox" Test')
    cmd = dialog.last_cmd
    assert_includes(cmd, '--timebox')
  end

  def test_treeview
    dialog.title = 'TREEVIEW'
    items = []
    items << dialog.tree_item(tag: '1', item: 'Item #1', status: false, depth: 0)
    items << dialog.tree_item(tag: '2', item: 'Item #2', status: false, depth: 1)
    items << dialog.tree_item(tag: '3', item: 'Item #3', status: true, depth: 2)
    items << dialog.tree_item(tag: '4', item: 'Item #4', status: false, depth: 1)
    result = dialog.treeview('"Treeview" Test', items)
    cmd = dialog.last_cmd
    assert_equal('3', result)
    assert_includes(cmd, '--treeview')
  end

  def test_yesno
    dialog.title = 'YESNO'
    result = dialog.yesno('Is Yes?')
    cmd = dialog.last_cmd
    assert result
    assert_includes(cmd, '--yesno') 
    dialog.defaultno = true
    result = dialog.yesno('Is Yes No?')
    refute result
  end
end