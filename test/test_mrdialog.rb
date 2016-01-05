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
    buildlist_items = []
    buildlist_items << dialog.list_item(tag: '1', item: 'Item ')
    { 
      buildlist: [ 'buildlist', [ ['1', 'Item #1', 'on'], ['2', 'Item #2', 'off'], ['3', 'Item #3', 'off']], 24, 80, 12 ],
      #calendar: [ 'calendar', 0, 0, 25, 12, 2015 ],
      infobox: [ 'infobox', 24, 80 ],
      msgbox: [ 'msgbox', 24, 80 ],
      yesno: [ 'yesno', 0, 0 ],
    }
  end


  #
  # Boxes
  #

  def test_buildlist
    dialog.title = 'BUILDLIST'
    items = []
    items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
    items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
    items << dialog.list_item(tag: '3', item: 'Item #3', status: false)
    dialog.buildlist('"Buildlist" Test', items, 24, 80, 12)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--buildlist', cmd)
    assert_includes(cmd, '"\"Buildlist\" Test"', cmd)
    assert_includes(cmd, ' 24 80 12', cmd)
    assert_includes(cmd, '"1" "Item #1" "on" ')
    assert_includes(cmd, '"2" "Item #2" "off" ')
    assert_includes(cmd, '"3" "Item #3" "off" ')
  end

  def test_calendar
    dialog.title = 'CALENDAR'
    dialog.calendar('"Calendar" Test', 0, 0, 25, 12, 2015)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--calendar', cmd)
    assert_includes(cmd, '"\"Calendar\" Test"', cmd)
    assert_includes(cmd, '0 0 25 12 2015', cmd)
    assert_includes(cmd, '2> "', cmd)
  end

  def test_checklist
    dialog.title = 'CHECKLIST'
    items = []
    items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
    items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
    items << dialog.list_item(tag: '3', item: 'Item #3', status: false)

    result = dialog.checklist('"checklist" test', items)
    cmd = dialog.last_cmd

    assert_equal(['1'], result)  
  end

  def test_dselect
    dialog.title = 'DSELECT'
    result = dialog.dselect(__FILE__, 0, 0)
    cmd = dialog.last_cmd
    assert_equal('test_mrdialog.rb', result, cmd)
    assert_includes(cmd, '--dselect')
    assert_includes(cmd, __FILE__, cmd)
    assert_includes(cmd, '0 0', cmd)
  end

  def test_editbox
    dialog.title = 'EDITBOX'
    result = dialog.editbox(__FILE__, 0, 0)
    cmd = dialog.last_cmd
    assert_equal(result, IO.read(__FILE__), cmd)
    assert_includes(cmd, '--editbox', cmd)
    assert_includes(cmd, __FILE__, cmd)
    assert_includes(cmd, '0 0', cmd)
    tmp.close!
  end

  def test_form
    dialog.title = 'FORM'
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
    dialog.title = 'FSELECT'
    dir = File.dirname(__FILE__)
    result = dialog.fselect(dir, 0, 0)
    cmd = dialog.last_cmd
    assert_equal('.,', result, cmd)
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
    result = dialog.inputbox('"Inputbox" Test', 'inputbox test', 0, 0)
    cmd = dialog.last_cmd
    assert_equal('inputbox test', result, cmd)
    assert_includes(cmd, '--inputbox', cmd)
    assert_includes(cmd, '"\"Inputbox\" Test" 0 0 "inputbox test', cmd)
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
    dialog.pause('"Pause" Test', 2, 10, 30)
    cmd = dialog.last_cmd
    assert_includes(cmd, '--pause')
    assert_includes(cmd, '"\"Pause\" Test" 10 30 2', cmd)
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

  #
  # Options 
  # 

  def option_test(method, option_string, false_value, true_value)
    dialog.dry_run = true
    dialog.send("#{method}=".to_sym, false_value)
    commands.each do |method, args|
      dialog.send(method, *args)
      refute_includes(dialog.last_cmd, option_string)
    end

    dialog.send("#{method}=".to_sym, true_value)
    commands.each do |method, arguments|
      dialog.send(method, *arguments)
      assert_includes(dialog.last_cmd, option_string)
    end
  end

  def test_ascii_lines
    option_test(:ascii_lines, '--ascii-lines', false, true)
  end

  def test_aspect
    option_test(:aspect, '--aspect 9', nil, 9)
  end

  def test_backtitle
    option_test(:backtitle, '--backtitle "Dialog"', nil, 'Dialog')
  end

  def test_begin_pos
    option_test(:begin_pos, '--begin 0 0', nil, [0, 0])
  end

  def test_cancel_label
    option_test(:cancel_label, '--cancel-label "Cancel"', nil, 'Cancel')
  end

  def test_clear
    option_test(:clear, '--clear', false, true)
  end

  def test_colors
    option_test(:colors, '--colors', false, true)
  end

  def test_column_separator
    option_test(:column_separator, '--column-separator "|"', nil, '|')
  end

  def test_cr_wrap
    option_test(:cr_wrap, '--cr-wrap', false, true)
  end

  def test_date_format
    option_test(:date_format, '--date-format', nil, '%Y%m%d-%H%MS')
  end

  def test_defaultno
    option_test(:defaultno, '--defaultno', false, true)
  end

  def test_default_button
    option_test(:default_button, '--default-button', nil, 'cancel')
  end

  def test_default_item
    option_test(:default_item, '--default-item', nil, 'Option')
  end

  def test_exit_label
    option_test(:exit_label, '--exit-label', nil, 'Continue')
  end

  def test_extra_button
    option_test(:extra_button, '--extra-button', nil, 'Continue')
  end

  def test_extra_label
    option_test(:extra_label, '--extra-label', nil, 'More')
  end

  def test_help_button
    option_test(:help_button, '--help-button', false, true)
  end

  def test_help_label
    option_test(:help_label, '--help-label', nil, 'Assistance')
  end

  def test_help_status
    option_test(:help_status, '--help-status', false, true)
  end

  def test_help_tags
      option_test(:help_tags, '--help-tags', false, true)
  end

  def test_hfile
    option_test(:hfile, '--hfile', nil, 'helpfile.txt')
  end

  def test_hline
    option_test(:hline, '--hline', nil, 'A string to display')
  end

  def test_ignore
    option_test(:ignore, '--ignore', false, true)
  end

  # TODO: not sure this test is correct
  def test_input_fd
    option_test(:input_fd, '--input-fd', nil, 'STDOUT')
  end

  def test_insecure
    option_test(:insecure, '--insecure', false, true)
  end

  def test_keep_tite
    option_test(:keep_tite, '--keep-tite', false, true)
  end

  def test_keep_window
    option_test(:keep_window, '--keep-window', false, true)
  end

  def test_last_key
    option_test(:last_key, '--last-key', false, true)
  end

  def test_max_input
    option_test(:max_input, '--max-input', nil, '1024')
  end

  def test_no_cancel
    option_test(:no_cancel, '--no-cancel', false, true)
  end

  def test_nocancel
    option_test(:nocancel, '--nocancel', false, true)
  end

  def test_no_collapse
    option_test(:no_collapse, '--no-collapse', false, true)
  end

  def test_no_items
    option_test(:no_items, '--no-items', false, true)
  end

  def test_no_kill
    option_test(:no_kill, '--no-kill', false, true)
  end

  def test_no_label
    option_test(:no_label, '--no-label', nil, 'Nope')
  end

  def test_no_lines
    option_test(:no_lines, '--no-lines', false, true)
  end

  def test_no_mouse
    option_test(:no_mouse, '--no-mouse', false, true)
  end

  def test_no_nl_expand
    option_test(:no_nl_expand, '--no-nl-expand', false, true)
  end

  def test_no_ok
    option_test(:no_ok, '--no-ok', false, true)
  end

  def test_nook
    option_test(:nook, '--nook', false, true)
  end

  def test_no_shadow
    option_test(:no_shadow, '--no-shadow', false, true)
  end

  def test_no_tags
    option_test(:no_tags, '--no-tags', false, true)
  end

  def test_ok_label
    option_test(:ok_label, '--ok-label', nil, 'Alright')
  end

  def test_output_fd
    option_test(:output_fd, '--output-fd', nil, 'STDOUT')
  end

  def test_separator
    option_test(:separator, '--separator', nil, '|')
  end

  def test_output_separator
    option_test(:output_separator, '--output-separator', nil, '||')
  end

  def test_print_maxsize
    option_test(:print_maxsize, '--print-maxsize', false, true)
  end

  def test_print_size
    option_test(:print_size, '--print-size', false, true)
  end

  def test_print_version
    option_test(:print_version, '--print-version', false, true)
  end

  def test_quoted
    option_test(:quoted, '--quoted', false, true)
  end

  def test_scrollbar
    option_test(:scrollbar, '--scrollbar', false, true)
  end

  def test_separate_output
    option_test(:separate_output, '--separate-output', false, true)
  end

  def test_separate_widget
    option_test(:separate_widget, '--separate-widget', nil, 'Separator')
  end

  def test_shadow
    option_test(:shadow, '--shadow', false, true)
  end

  def test_single_quoted
    option_test(:single_quoted, '--single-quoted', false, true)
  end

  def test_size_err
    option_test(:size_err, '--size-err', false, true)
  end

  def test_sleep
    option_test(:sleep, '--sleep', false, '2')
  end

  def test_stderr
    option_test(:stderr, '--stderr', false, true)
  end

  def test_stdout
    option_test(:stdout, '--stdout', false, true)
  end

  def test_tab_correct
    option_test(:tab_correct, '--tab-correct', false, true)
  end

  def test_tab_len
    option_test(:tab_len, '--tab-len', nil, '2')
  end

  def test_time_format
    option_test(:time_format, '--time-format', nil, '%Y%m%d-%H%M%S')
  end

  def test_timeout
    option_test(:timeout, '--timeout', nil, '10')
  end

  def test_title
    option_test(:title, '--title', nil, 'RDialog')
  end

  def test_trace
    option_test(:trace, '--trace', nil, 'tracefile.txt')
  end

  def test_trim
    option_test(:trim, '--trim', false, true)
  end

  def test_version
    option_test(:version, '--version', false, true)
  end

  def test_visit_items
    option_test(:visit_items, '--visit-items', false, true)
  end

  def test_yes_label
    option_test(:yes_label, '--yes-label', nil, 'Yup')
  end
end