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
    { msgbox: [ 'Test text', 24, 80 ],
    }
  end

  #
  # Commands
  #

  def test_msgbox_command
    dialog.msgbox('Test text', 24, 80)
    assert_includes(dialog.last_cmd, 'Test text')
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