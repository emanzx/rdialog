#!/usr/bin/env ruby

# muquit@muquit.com Apr-01-2014 
require [File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'rdialog'].join('/')
begin
  ME = File.basename($0)
  if ENV['CHANGE_TITLE']
    if ME =~ /(.+)\.rb$/
      base = $1
      puts "\033]0;mrdialog - #{base}\007"
    end
  end

  dialog = RDialog.new
  dialog.logger = Logger.new(ENV["HOME"] + "/dialog_" + ME + ".log")
  dialog.clear = true
  dialog.title = "MIXEDGAUGE BOX"

  text = <<EOF
This example is taken from dialog/samples/mixgauge

Hi, this is a mixedgauge box. You can use this to
present a list of progress for the user to
view. 
Process status that supported are [Suceeded, Failed, Passed, Completed, Done, Skipped, In Progress, Checked and 0-100 for percent.]
Try it now!

EOF
for percent in 0-100
  items = []
  process_list = Struct.new(:item, :status)
  data = process_list.new
  data.item = "Process One"
  data.status = "Succeded"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Two"
  data.status = "Failed"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Three"
  data.status = "Passed"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Four" 
  data.status = "Completed"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Five"
  data.status = "Done"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Six"  
  data.status = "Skipped"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Seven"
  data.status = "In Progress"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Eight"
  data.status = "Checked"
  items.push(data.to_a)

  data = process_list.new
  data.item = "Process Eight"
  data.status = "#{percent}"
  items.push(data.to_a)

  height = 0
  width = 0
  total_percent = 75
  
  selected_item = dialog.menu(text, items, height, width, percent_total)
end
  puts "Selected item: #{selected_item}"

rescue => e
  puts "#{$!}"
  t = e.backtrace.join("\n\t")
  puts "Error: #{t}"
end
