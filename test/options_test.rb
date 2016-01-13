require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/rdialog'

Minitest::Reporters.use!

class TestRDialogOptions < Minitest::Test

  attr_reader :dialog

  def setup
    @dialog = RDialog.new
    # Uncomment for debugging
    #@dialog.logger = Logger.new(STDOUT)
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