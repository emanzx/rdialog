require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/mrdialog'

Minitest::Reporters.use!

class TestMRDialog < Minitest::Test

  attr_reader :dialog

  def setup
    @dialog = MRDialog.new
    @dialog.dry_run = true
  end

  def commands
    { 
      infobox: [ 'infobox test', 24, 80 ],
      msgbox: [ 'msgbox test', 24, 80 ],
    }
  end

  #
  # Commands
  #

  def test_infobox_command
    dialog.infobox('infobox test', 24, 80)
    assert_includes(dialog.last_cmd, 'infobox test')
    assert_includes(dialog.last_cmd, ' 24 80')
  end

  def test_msgbox_command
    dialog.msgbox('msgbox test', 24, 80)
    assert_includes(dialog.last_cmd, 'msgbox test')
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