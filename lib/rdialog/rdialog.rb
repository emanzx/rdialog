# = rdialog - A dialog gem for Ruby
#
# Homepage::  http://built-it.net/ruby/rdialog/
# Author::    Aleks Clark (http://built-it.net)
# Copyright:: (cc) 2004 Aleks Clark
# License::   BSD
#
# class RDialog::Dialog.new( array, str, array)
#

require 'logger'
require 'tempfile'
require 'date'
require 'time'
require 'shellwords'
require 'open3'

#
# MRDialog - Interface to ncurses dialog program
#
class RDialog 

  #
  # When `dry_run` is set to true, system calls are simply returned rather than
  # being run. This is provided for testing purposes.
  #
  #     dialog.dry_run = true
  #
  attr_accessor :dry_run

  #
  # This gets set by the program.
  # 
  attr_reader :last_cmd

  DIALOG_OK = 0
  DIALOG_CANCEL = 1
  DIALOG_HELP = 2
  DIALOG_EXTRA = 3
  DIALOG_ITEM_HELP = 4
  DIALOG_ESC = 255

  #
  # Rather than draw graphics lines around boxes, draw ASCII "+" and "-" in
  # the same place. See also "no_lines".
  #
  #     dialog.ascii_lines = false
  #
  attr_accessor :ascii_lines

  #
  # This gives you some control over the box dimensions when using auto sizing 
  # (specifying 0 for height and width). It represents width / height. The
  # default is 9, which means 9 characters wide to every 1 line high.
  #
  #     dialog.aspect = 9
  #
  attr_accessor :aspect

  #
  # Specifies a backtitle string to be displayed on the backdrop, at the top of
  # the screen.
  #
  #     dialog.backtitle = 'Backdrop Title'
  #
  attr_accessor :backtitle

  #
  # Specify the position of the upper left corner of a dialog box
  # on the screen as an array containing two integers.
  #
  #     dialog.begin = [0, 0]
  #
  attr_accessor :begin_pos

  #
  # Override the label used for "Cancel" buttons.
  #
  #     default.cancel_label = 'New Cancel'
  #
  attr_accessor :cancel_label

  #
  # Clears the widget screen, keeping only the screen_color background. Use
  # this when you combine widgets with "and_widget" to erase the contents of a
  # previous widget on the screen, so it won't be seen under the contents of a
  # following widget. Understand this as the complement of "keep_window".
  #
  attr_accessor :clear

  #
  # Interpet embedded "\Z" sequences in the dialog text by the following
  # character, which tells **dialog** to set colors or video attributes:
  #
  # * 0 through 7 are the ANSI color numbers used in curses: black, red, green
  #   yellow, blue, magenta, cyan and white respectively.
  # * Bold is set by 'b', reset by 'B'.
  # * Reverse is set by 'r', reset by 'R'.
  # * Underline is set by 'u', reset by 'U'.
  # * The settings are cumulative, e.g., "\Zb\Z1" makes the following text bold
  #   (perhaps bright) red.
  # * Restore normal settings with "\Zn".
  #
  attr_accessor :colors 

  #
  # Tell **dialog** to split data for radio/checkboxes and menus on the
  # occurrences of the given string, and to align the split data into columns.
  #
  #     dialog.column_separator = '|'
  #
  attr_accessor :column_separator

  #
  # Interpret embedded newlines in the dialog text as a newline 
  # on the screen. Otherwise, **dialog** will only wrap lines where 
  # needed to fit inside the text box.
  #
  # Even though you can control line breaks with this, dialog will still wrap
  # any lines that are too long for the width of the box. Without cr-wrap, the
  # layout of your text may be formatted to look nice in the source code of 
  # your script without affecting the way it will look in the dialog.
  #
  # See also the "`--no-collapse`" and "`--trim`" options.
  #
  #     dialog.cr_wrap = true
  #
  attr_accessor :cr_wrap

  #
  # If the host provides `strftime`, this option allows you to specify the
  # format of the date printed for the `--calendar` widget. The time of day
  # (hour, minute, second) are the current local time
  #
  #     default.date_format = "%h%m%s"
  #
  attr_accessor :date_format

  #
  # Make the default value of the `yes/no` box a `No`. Likewise, make the
  # default button of widgets that provide "OK" and "Cancel" a `Cancel`. If
  # `nocancel` or `visit_items` are given those options override this, making
  # the default button always "Yes" (internally the same as "OK").
  #
  #     dialog.defaultno = true
  #
  attr_accessor :defaultno

  #
  # Set the default (preselected) button in a widget. By preselecting a button,
  # a script makes it possible for the user to simply press "Enter" to proceed
  # through a dialog with minimum interaction.
  #
  # The option's value is the name of the button: "ok", "yes", "cancel", "no",
  # "help" or "extra".
  #
  # Normally the first button in each widget is the default. The first button
  # shown is determined by the widget together with the `nook` and `nocancel`
  # options. If this option is not given, there is no default button assigned.
  #
  #     dialog.default_button = 'ok'
  #
  # TODO: Should we be strict and throw an error if this is not set to one of
  #       the available options?
  attr_accessor :default_button

  #
  # Set the default item in a checklist, form or menu box. Normally the first
  # item in the box is the default.
  #
  #     dialog.default_item = 'Option'
  #
  attr_accessor :default_item

  #
  # Override the label used for "EXIT" buttons.
  #
  #     dialog.exit_label = 'Continue'
  #
  attr_accessor :exit_label

  #
  # Show an extra button, between "OK" and "Cancel" buttons.
  #
  #     dialog.extra_button = 'Continue'
  #
  attr_accessor :extra_button

  #
  # Override the label used for "Extra" buttons. For `inputmenu` widgets, this
  # defaults to "Rename".
  #
  #     dialog.extra_label = 'More'
  #
  attr_accessor :extra_label

  #
  # Show a help-button after "OK" and "Cancel" buttons, i.e., in checklist,
  # radiolist and menu boxes.
  #
  # On exit, the return status will indicate that the Help button was pressed.
  # MRDialog will also write a message to its output after the token "HELP":
  #
  # * If #item_help is also given, the item-help text will be written.
  # * Otherwise, the item's tag (the first field) will be written.
  # 
  # You can use the `--help-tags` option and/or set the DIALOG_ITEM_HELP
  # environment variable to modify these messages and exit-status.
  #
  #     dialog.help_button = true
  #
  attr_accessor :help_button

  #
  # Override the label used for "Help" buttons.
  #
  #     dialog.help_label = 'Assistance'
  #
  attr_accessor :help_label

  #
  # If the help-button is selected, writes the checklist, radiolist or form 
  # information after the item-help "HELP" information. This can be used to
  # reconstruct the state of a checklist after processing the request.
  #
  #     dialog.help_status = true
  #
  attr_accessor :help_status

  #
  # Modify the messages written on exit for `--help-button` by making them
  # always just the item's tag. This does not affect the exit status code.
  #
  #     dialog.help_tags = true
  #
  attr_accessor :help_tags

  #
  # Display the given file using a textbox when the user presses F1.
  #
  #     dialog.hfile = 'helpfile.txt'
  #
  attr_accessor :hfile 

  #
  # Display the given string centered at the bottom of the widget.
  #
  #     dialog.hline = 'A string to display'
  #
  attr_accessor :hline

  #
  # Ignore options that **dialog** does not recognize. Some well-known ones
  # such as "`--icon`" are ignored anyway, but this is a better choice for
  # compatability with other implementations.
  #
  #     dialog.ignore = true
  #
  attr_accessor :ignore

  #
  # Read keyboard input from the given file descriptor. Most **dialog** scripts
  # read from the standard input, but the gauge widget reads a pipe (which is
  # always standard input). Some configurations do not work properly when
  # **dialog** tries to reopen the terminal. Use this option (with appropriate
  # juggling of file-descriptors) if your script must work in that type of
  # environment.
  #
  #     dialog.input_fd = 'file.txt'
  #
  attr_accessor :input_fd

  #
  # Make the password widget friendlier but less secure, by echoing asterisks
  # for each character.
  #
  #     dialog.insecure = true
  #
  attr_accessor :insecure

  #
  # Interpret the tags data for checklist, radiolist and menuboxes 
  # adding a column which is displayed in the bottom line of the 
  # screen, for the currently selected item.
  #
  attr_accessor :item_help

  #
  # When built with **ncurses**, **dialog** normally checks to see if it is
  # running in an **xterm**, and in that case tries to suppress the
  # initialization strings that would make it switch to the alternate screen.
  #
  # Switching between te normal and alternate screens is visually distracting in
  # a script which runs **dialog** several times. Use this option to allow
  # **dialog** to use those initialization strings.
  #
  #     dialog.keep_tite = true
  #
  attr_accessor :keep_tite

  #
  # Normally when **dialog** performs several **tailboxbg** widgets connected by
  # #and_widget, it clears the old widget from the screen by painting over
  # it. Use this option to suppress that repainting.
  #
  # At exit, **dialog** repaints all of the widgets which have been marked with
  # #keep_window, even if they are not **tailboxbg** widgets. That causes
  # them to be repainted in reverse order. See the discussion of the #clear
  # option for examples.
  #
  #     dialog.keep_window = true
  #
  attr_accessor :keep_window

  #
  # At exit, report the last key which the user entered. This is the curses key
  # code rather than a symbol or literal character. It can be used by scripts to
  # distinguish between two keys which are bound to the same action.
  #
  #     dialog.last_key = true
  #
  attr_accessor :last_key

  #
  # Limit input strings to the given size. If not specified, the limit is 2048.
  #
  #     dialog.max_input = 1024
  #
  attr_accessor :max_input

  #
  # Suppress the "Cancel" button in checklist, inputbox and menubox 
  # modes. A script can still test if the user pressed the ESC key to 
  # cancel to quit.
  #
  attr_accessor :no_cancel
  attr_accessor :nocancel

  #
  # Normally **dialog** converts tabs to spaces and reduces multiple spaces to a
  # single space for text which is displayed in a message boxes, etc. Use this
  # option to disable that feature. Note that **dialog** will still wrap text,
  # subject to the #cr_wrap and #trim options.
  #
  #     dialog.no_collapse = true
  #
  attr_accessor :no_collapse

  #
  # Some widgets (checklist, inputmenu, radiolist, menu) display a list with two
  # columns (a "tag" and "item", i.e., "description"). This option tells
  # **dialog** to read shorter rows, omitting the "item" part of the list. This
  # is occasionally useful, e.g., if the tags provide enough information.
  #
  # See also #no_tags. If both options are given, this one is ignored.
  #
  #     dialog.no_items = true
  #
  attr_accessor :no_items

  #
  # Tells **dialog** to put the **tailboxbg** box in the background, printing its
  # process id to **dialog**'s output. SIGHUP is disabled for the background
  # process.
  #
  #     dialog.no_kill = true
  #
  attr_accessor :no_kill

  #
  # Override the label used for "No" buttons.
  #
  #     dialog.no_label = 'Nope'
  #
  attr_accessor :no_label

  #
  # Rather than draw lines around boxes, draw spaces in the same place. See also
  # #ascii_lines. 
  #
  #     dialog.no_lines = true
  #
  attr_accessor :no_lines

  #
  # Do not enable the mouse.
  #
  #     dialog.no_mouse = true
  #
  attr_accessor :no_mouse

  #
  # Do not convert "\n" substrings of the message/prompt text into literal
  # newlines.
  #
  #     dialog.no_nl_expand = true
  #
  attr_accessor :no_nl_expand

  #
  # Suppress the "OK" button in checklist, inputbox and menu box modes. A script
  # can still test if the user pressed the "Enter" key to accept the data.
  #
  #     dialog.no_ok = true
  #
  attr_accessor :no_ok
  attr_accessor :nook

  #
  # Suppress shadows that would be drawn to the right and bottom of each dialog
  # box.
  #
  #     dialog.no_shadow = true
  #
  attr_accessor :no_shadow

  #
  # Some widgets (checklist, inputmenu, radiolist, menu) display a list with two
  # columns (a "tag" and "description"). The tag is useful for scripting, but may
  # not help the user. The #no_tags option (from Xdialog) may be used to suppress
  # the column of tags from the display. Unlike the #no_items option, this does
  # not affect the data which is read from the script.
  #
  # Xdialog does not display the tag column for the analogous buildlist and
  # treeview widgets; **dialog** does the same.
  #
  # Normally **dialog** allows you to quickly move to entries on the displayed
  # list, by matching a single character to the first character of the tag. When
  # the #no_tags option is given, **dialog** matches against the first character
  # of the description. In either case, the matchable character is high-lighted.
  #
  #     dialog.no_tags = true
  #
  attr_accessor :no_tags

  #
  # Override the label used for "OK" buttons.
  #
  #     dialog.ok_label = 'Alright'
  #
  attr_accessor :ok_label

  # 
  # Direct output to the given file descriptor. Most **dialog** scripts write to
  # the standard error, but error messages may also be written there, depending
  # on your script.
  #
  #     dialog.output_fd = 'dialogoutput.txt'
  # 
  attr_accessor :output_fd

  #
  # Specify a string that will separate the output on **dialog**'s output from 
  # checklists, rather than a newline (for #separate_output) or a space. This
  # applies to other widgets such as forms and editboxes which normally use a
  # newline.
  #
  #     dialog.separator = '|'
  #
  attr_accessor :separator
  attr_accessor :output_separator

  #
  # Print the maximum size of dialog boxes, i.e., the screen size, to
  # **dialog**'s output. This may be used alone, without other options.
  #
  #     dialog.print_maxsize = true
  #
  attr_accessor :print_maxsize

  #
  # Prints the size of each dialog box to **dialog**'s output.
  #
  #     dialog.print_size = true
  #
  attr_accessor :print_size

  #
  # Prints **dialog**'s version to **dialog**'s output. This may be used alone,
  # without other options. It does not cause **dialog** to exit by itself.
  #
  #     dialog.print_version = true
  #
  attr_accessor :print_version

  #
  # Normally **dialog** quotes the strings returned by checklist's as well as
  # the item-help text. Use this option to quote all string results.
  #
  #     dialog.quoted = true
  #
  attr_accessor :quoted

  #
  # For widgets holding a scrollable set of data, draw a scrollbar on its right
  # margin. This does not respond to the mouse.
  #
  #     dialog.scrollbar = true
  #
  attr_accessor :scrollbar

  #
  # For certain widgets (buildlist, checklist, treeview), output result one
  # line at a time, with no quoting. This facilitates parsing by another
  # program.
  #
  #     dialog.separate_output = true
  #
  attr_accessor :separate_output

  # 
  # Specify a string that will separate the output on **dialog**'s output from
  # each widget. This is used to simplify parsing the result of a dialog with
  # several widgets. If this option is not given, the default separator string
  # is a tab character.
  #
  #     dialog.separate_widget = "\t"
  #
  attr_accessor :separate_widget

  #
  # Draw a shadow to the right and bottom of each dialog box.
  # 
  #     dialog.shadow = true
  #
  attr_accessor :shadow

  #
  # Use single-quoting as needed (and no quotes if unneeded) for the output of
  # checklist's as well as the item-help text. If this option is not set,
  # **dialog** uses double quotes around each item. In either case, **dialog**
  # adds backslashes to make the output useful in shell scripts.
  #
  #     dialog.single_quoted = true
  #
  attr_accessor :single_quoted

  #
  # Check the resulting size of a dialog box before trying to use it, printing
  # the resulting size if it is larger than the screen. (This option is obsolete,
  # since all new-window calls are checked).
  #
  #     dialog.size_err = true
  #
  attr_accessor :size_err

  #
  # Sleep (delay) for the given integer of seconds after processing 
  # a dialog box.
  #
  attr_accessor :sleep

  #
  # Direct output to the standard error. This is the default, since curses
  # normally writes screen updates to the standard output.
  #
  #     dialog.stderr = true
  #
  attr_accessor :stderr

  #
  # Direct output to the standard output. This option is provided for
  # compatability with Xdialog, however using it in portable scripts is not
  # recommended, since curses normally writes its screen updates to the
  # standard output. If you use this option, **dialog** attempts to reopen the
  # terminal so it can write to the display. Depending on the platform and your
  # environment, that may fail.
  #
  #     dialog.stdout = true
  #
  attr_accessor :stdout

  #
  # Convert each tab character to one or more spaces. 
  # Otherwise, tabs are rendered according to the curses library's 
  # interpretation.
  #
  #     dialog.tab_correct = true
  #
  attr_accessor :tab_correct

  #
  # Specify the number(int) of spaces that a tab character occupies 
  # if the tabcorrect option is set true. The default is 8.
  #
  #     dialog.tab_len = '2'
  #
  attr_accessor :tab_len

  #
  # If the host provides **strftime**, this option allows you to specify the
  # format of the time printed for the #timebox widget. The day, month, year
  # values in this case are for the current local time.
  #
  #     dialog.time_format = '%H%M%S'
  #
  attr_accessor :time_format

  #
  # Timeout (exit with error code) if no user response within the given number
  # of seconds. A timeout of zero seconds is ignored.
  #
  #     dialog.timeout = 10
  #
  attr_accessor :timeout

  #
  # Title string to be displayed at the top of the dialog box.
  #
  #     dialog.title = 'RDialog'
  #
  attr_accessor :title

  #
  # Logs the command-line parameters, keystrokes and other information to the
  # given file. If **dialog** reads a configure file, it is logged as well.
  # Piped input to the #gauge widget is logged. Use control/T to log a picture
  # of the current dialog window.
  #
  #     dialog.trace = 'tracefile.txt'
  #
  attr_accessor :trace

  #
  # Eliminate leading blanks, trim literal newlines and repeated blanks from
  # message text.
  # 
  # See also the #cr_wrap and #no_collapse options.
  #
  #     dialog.trim = true
  #
  attr_accessor :trim

  #
  # Prints **dialog**'s version to the standard output, and exits. See also
  # #print_version.
  #
  #     dialog.version = true
  #
  attr_accessor :version

  #
  # Modify the tab-traversal of checklist, radiolist, menubox and inputmenu to
  # include the list of items as one of the states. This is useful as a visual
  # aid, i.e., the cursor positon helps some users.
  #
  # When this option is given, the cursor is initially placed on the list.
  # Abbreviations (the first letter of the tag) apply to the list items. If you
  # tab to the button row, abbreviations apply to the buttons.
  #
  #     dialog.visit_items = true
  #
  attr_accessor :visit_items

  #
  # Override the label used for "Yes" buttons.
  #
  #     dialog.yes_label = 'Alright'
  #
  attr_accessor :yes_label

  # 
  #
  # Alternate path to dialog. If this is not set, environment path
  # is used.
  #
  attr_accessor :path_to_dialog

    
  # Exit Codes
  attr_accessor :dialog_ok
  attr_accessor :dialog_cancel
  attr_accessor :dialog_help
  attr_accessor :dialog_extra
  attr_accessor :dialog_item_help
  attr_accessor :dialog_esc

  #
  # ruby logger
  attr_accessor :logger


  # set it to true for passwordform.
  attr_accessor :password_form

  # Returns a new RDialog Object
  def initialize
    $stdout.sync = true
    $stderr.sync = true
    @dialog_ok = DIALOG_OK
    @dialog_cancel = DIALOG_CANCEL
    @dialog_help = DIALOG_HELP
    @dialog_extra = DIALOG_EXTRA
    @dialog_item_help = DIALOG_ITEM_HELP
    @dialog_esc = DIALOG_ESC
    @exit_code = 0
  end

  #
  # Run a command.
  #
  def run(cmd, tmp=nil)
    success, result = 'debug', 'debug'
    @last_cmd = cmd
    debug("Command: #{cmd.inspect}")
    if dry_run
      @exit_code = 0
    else
      if block_given?
        result = IO.popen(cmd, 'w') { |fh| yield fh }
      else
        success = system(cmd)
        if tmp.nil?
          result = success
        else
          begin
            result = tmp.read
          rescue EOFError
            result = success
          end
        end
      end
      @exit_code = $?.exitstatus
    end 
    debug("Result: #{result.inspect}")
    debug("Success: #{success.inspect}")
    debug("Exit Code: #{exit_code.inspect}")
    return tmp.nil? ? result : [result, success]
  end


  ##---- muquit@muquit.com mod starts---
 
  ##--------------------------------------------------- 
  # if @logger is set, log
  ##--------------------------------------------------- 
  def log_debug(msg)
    if @logger
        @logger.debug("#{msg}")
    end
  end
  alias_method :debug, :log_debug

  #  return the exit code of the dialog
  def exit_code
    return @exit_code
  end

  ##---------------------------------------------------
  # return the path of the executable which exists
  # in the PATH env variable
  # return nil otherwise
  # arg is the name of the program without extensin
  # muquit@muquit.com
  ##---------------------------------------------------
  def which(prog)
    path_ext = ENV['PATHEXT']
    exts = ['']
    if path_ext # WINDOW$
      exts = path_ext.split(';')
    end
    path = ENV['PATH']
    path.split(File::PATH_SEPARATOR).each do |dir|
      exts.each do |ext|
        candidate = File.join(dir, "#{prog}#{ext}")
        return candidate if File.executable?(candidate)
      end
    end
    return nil
  end

  #
  # A **buildlist** dialog displays two lists, side-by-side. The list on the left
  # shows unselected items. The list on the right shows selected  items. As
  # items are selected or unselected, they move between the lists. Use SPACE bar
  # to select/unselect an item.
  # 
  # Use a carriage return or the "OK" button to accept the current value in the
  # selected-window and exit. The results are written using the order displayed
  # in the selected-window.
  #
  # The initial on/off state of each entry is specified by _status_.
  #
  # The dialog behaves like a **menu**, using the `visit-items` to control
  # whether the cursor is allowed to visit the lists directly.
  #
  #   * If `visit-items` is not given, tab-traversal uses two states
  #     (OK/Cancel).
  #   * If `visit-items` is given, tab-traversal uses four states
  #     (Left/Right/OK/Cancel).
  #
  # Whether or not `visit-items` is given, it is possible to move the highlight
  # between the two lists using the default "^" (left-column) and "$"
  # (right-column) keys.
  #
  # On exit, a list of the _tag_ strings of those entries that are turned on
  # will be printed on **dialog**'s output.
  #
  # If the `separate-output` option is not given, the strings will be quoted
  # as needed to make it simple for scripts to separate them. By default, this
  # uses double-quotes. See the `single-quoted` option, which modifies the
  # quoting behavior.
  #
  # The caller is responsile for creating the items properly. Please look at
  # `samples/buildlist.rb` for an example.
  #
  # Returns an array of selected tags.
  #
  #     items = []
  #     items << dialog.list_item(tag: '1', item: 'Item #1', status: true)
  #     items << dialog.list_item(tag: '2', item: 'Item #2', status: false)
  #     dialog.buildlist('Buildlist Box', items)
  #
  def buildlist(text, items, height=0, width=0, listheight=0)
    tmp = Tempfile.new('dialog') 
    selected_tags = []

    itemlist = []
    items.each do |item|
      itemlist << item.map { |i| "#{i.inspect}" }.join(' ')
    end
    debug "Items: #{itemlist.inspect}"

    cmd = [ option_string(),
      '--buildlist',
      %Q(#{text.inspect} #{height} #{width} #{listheight} ),
      itemlist.join(' '), "2> #{tmp.path.inspect}" ].join(' ')

    run(cmd)
    if exit_code == 0
      last_result = tmp.read
      debug "result: #{last_result.inspect}"
      lines = last_result
      sep = separator || output_separator || ' '
      sep = Shellwords.escape(sep)
      a = lines.split(/#{sep}/)
      a.each do |tag|
        selected_tags << tag if tag.to_s.length > 0
      end
    end
    tmp.close!
    return selected_tags
  end

  #
  # A calendar box displays  month,  day  and  year  in  separately adjustable
  # windows. If the values for day, month or year are missing or negative, the
  # current date's corresponding values are used. You can increment or decrement
  # any of those using the left-, up-, right-, and down-arrows. Use vi-style h,
  # j, k and l for moving around the arrays of days in a month. Use tab or
  # backtab to move between windows. If the year is given as zero, the current
  # date is used as an initial value.
  #
  # Returns a Date object with the selected date.
  #
  def calendar(text="Select a Date", height=0, width=0, day=Date.today.mday(), month=Date.today.mon(), year=Date.today.year())
    tmp = Tempfile.new('tmp')
    cmd = [ option_string(),
      '--calendar',
      "#{text.inspect} #{height} #{width} #{day} #{month} #{year} 2> #{tmp.path.inspect}" ].join(' ')
    success = run(cmd)
    if success
      date = Date::civil(*tmp.readline.split('/').collect {|i| i.to_i}.reverse)
      tmp.close!
      return date
    else
      tmp.close!
      return success
    end  
  end

  #
  # A checklist box is similar to a **menu** box; there are multiple entries
  # presented in the form of a menu. Another difference is that you can indicate
  # which entry is currently selected, by setting its _status_ to `true`.
  # Instead of choosing one entry among the entries, each entry can be turned on
  # or off by the user. The initial on/off state of each entry is specified by
  # _status_.
  #
  # Returns an array of selected items.
  #
  def checklist(text, items, height=0, width=0, listheight=0)
    tmp = Tempfile.new('tmp')
    items.map!{|item| item.map{|i| i.inspect}}.join(' ')
    cmd = [ option_string(), '--checklist',
      text.inspect, height, width, listheight, items, '2>', tmp.path.inspect ].join(' ')

    success = run(cmd)
    selected_items = []
    if success
      # TODO: Enclose in a begin/rescue clause? See #dselect method for an example.
      selected_string = tmp.readline
      tmp.close!
      sep = separator || output_separator || ' '
      sep = Shellwords.escape(sep)
      a = selected_string.split(/#{sep}/)
      a.each do |item|
        log_debug ">> #{item}"
        selected_items << item if item && item.to_s.length > 0
      end
      return selected_items
    else
      tmp.close!
      return success
    end
  end

  # 
  # The directory-selection dialog displays a text-entry window in which you can
  # type a directory, and above that a windows with directory names.
  #
  # Here **filepath** can be a filepath in which case the directory window will
  # display the contents of the path and the text-entry window will contain the
  # preselected directory.
  #
  # Use tab or arrow keys to move between the windows. Within the directory
  # window, use the up/down arrow keys to scroll the current selection. Use the
  # space-bar to copy the current selection into the text-entry window.
  #
  # Typing any printable characters switches focus to the text-entry window,
  # entering that character as well as scrolling the directory window to the
  # closest match.
  #
  # Use a carriage return or the "OK" button to accept the current value in the
  # text-entry window and exit.
  #
  # On exit, returns the contents of the text-entry window.
  #
  def dselect(filepath, height=0, width=0)
    tmp = Tempfile.new('tmp')

    cmd = [ option_string(), '--dselect',
      "#{filepath.inspect} #{height} #{width} 2> #{tmp.path.inspect}" ].join(' ')
    if run(cmd)
      begin
        selected_string = tmp.readline
      rescue EOFError
        selected_string = ''
      end
      tmp.close!
      return selected_string
    else
      tmp.close!
      return success
    end
  end

  #
  # The edit-box dialog displays a copy of the file. You may edit it using the
  # _backspace_, _delete_ and cursor keys to correct typing errors. It also 
  # recognizes pageup/pagedown. Unlike the `--inputbox`, you must tab to the
  # "OK" or "Cancel" buttons to close the dialog. Pressing the "Enter" key
  # within the box will split the corresponding line.
  #
  # Returns the contents of the window.
  #
  def editbox(filepath, height=0, width=0)
    tmp = Tempfile.new('dialog') 

    cmd = [ option_string(), '--editbox', 
      filepath.inspect, height, width, '2>', tmp.path.inspect ].join(' ')

    run(cmd)
    result = ''
    if exit_code == 0
      result = tmp.read
      log_debug(result)
    end
    tmp.close!
    return result
  end

  #
  # The **form** dialog displays a form consisting of labels and fields, which
  # are positioned on a scrollable window by coordinates given in the scripts.
  # The field length `flen` and input-length `ilen` tell how long the field can
  # be. The former defines the length shown for a selected field, while the
  # latter defines the permissible length of the data entered in the field.
  #
  # * If `flen` is zero, the corresponding field cannot be altered and the
  #   contents of the field determine the displayed-length.
  #
  # * If `flen` is negative, the corresponding field cannot be altered and the
  #   negated value of `flen` is used as the displayed-length.
  #
  # * If `ilen` is zero, it is set to `flen`.
  #
  # Use up/down arrows (or control/N, control/P) to move between fields. Use tab
  # to move between windows.
  #
  # Returns the contents of the form-fields in a Hash.
  #
  def form(text, items, height=0, width=0, formheight=0)
    res_hash = {}
    tmp = Tempfile.new('dialog') 
    mixed_form = false
    item_size = items[0].size
    log_debug "Item size:#{item_size}"
    # if there are 9 elements, it's a mixedform
    if item_size == 9
        mixed_form = true
    end
    itemlist = []
    items.each do |item|
      itemlist << item.map {|i| i.inspect}.join(' ')
    end

    box = '--form'
    if mixed_form
      box = '--mixedform'
    else
      box = '--passwordform' if password_form
    end

    cmd = [ option_string(), box, 
      text.inspect, height, width, formheight, itemlist.join(' '), '2>', tmp.path.inspect ].join(' ')

    log_debug("Number of items: #{items.size}")
    run(cmd)

    if item_size == 8
      delete_items_index = []
      items.each_with_index do |item, idx|
        if item[7] < 1 
          delete_item_index.push(idx)
        end
        delete_items_index.each do |idx|
          items.delete_at(idx)
        end
      end
    end
    if exit_code == 0
      lines = tmp.readlines
      lines.each_with_index do |val, idx|
        key = items[idx][0]
        res_hash[key] = val.chomp
      end
    end

    tmp.close!
    return res_hash
  end

  def form_item(args={})
    item = [ args[:label], args[:ly], args[:lx], 
      args[:item], args[:iy], args[:ix], args[:flen], args[:ilen] ]
    item << args[:itype] if args[:itype]
    return item.to_a
  end

  #      The file-selection dialog displays a text-entry window in which
  #      you can type a filename (or directory), and above that two win-
  #      dows with directory names and filenames.

  #      Here  filepath  can  be  a  filepath in which case the file and
  #      directory windows will display the contents of the path and the
  #      text-entry window will contain the preselected filename.
  #
  #      Use  tab or arrow keys to move between the windows.  Within the
  #      directory or filename windows, use the up/down  arrow  keys  to
  #      scroll  the  current  selection.  Use the space-bar to copy the
  #      current selection into the text-entry window.
  #
  #      Typing any printable characters switches  focus  to  the  text-
  #      entry  window, entering that character as well as scrolling the
  #      directory and filename windows to the closest match.
  #
  #      Use a carriage return or the "OK" button to accept the  current
  #      value in the text-entry window and exit.
  def fselect(filepath, height=0, width=0)
    tmp = Tempfile.new('tmp')

    cmd = [ option_string(), '--fselect',
      filepath.inspect, height, width, '2>', tmp.path.inspect ].join(' ')

    if run(cmd)
      selected_string = ''
      begin
        selected_string = tmp.readline
      rescue EOFError
      ensure
        tmp.close!
      end
      return selected_string
    else
      tmp.close!
      return success
    end
  end


  # 
  # A gauge box displays a meter along the bottom of the box.   The  
  # meter  indicates  the percentage.   New percentages are read from 
  # standard input, one integer per line.  The meter is updated to 
  # reflect each new percentage.  If  the  standard  input  reads  the 
  # string  "XXX",  then  the first line following is taken as an 
  # integer percentage, then subsequent lines up to another "XXX" are 
  # used for a new prompt.  The gauge exits  when EOF is reached on 
  # the standard input.
  #
  # The  percent  value  denotes the initial percentage shown in the 
  # meter.  If not speciied, it is zero.
  #
  # On exit, no text is written to dialog's output.  The widget 
  # accepts no input,  so  the exit status is always OK.  
  #
  # The caller will write the text markers to stdout 
  # as described above inside a block and will pass the block to the
  # method. Look at samples/gauge for
  # an example on how the method is called. Thanks to Mike Morgan
  # for the idea to use a block.
  #
  # Author:: muquit@muquit.com Apr-02-2014 
  ##---------------------------------------------------  
  def gauge(text, height=0, width=0, percent=0)
    run([option_string(), '--gauge', text.inspect,
      height, width, percent].join(' ')) { |fh| yield fh }
  end

  #
  # An info box is basically a message box.  However, in this case,
  # dialog  will  exit  immediately after displaying the message to
  # the user.  The screen is not cleared when dialog exits, so that
  # the  message  will remain on the screen until the calling shell
  # script clears it later.  This is useful when you want to inform
  # the  user that some operations are carrying on that may require
  # some time to finish.
  #
  # Returns false if esc was pushed
  #
  def infobox(text, height=0, width=0)
    run [option_string(), '--infobox', text.inspect, height, width].join(' ')
  end

  #
  # An **input** box is useful when you want to ask questions that require the
  # user to input a string as the answer. If init is is supplied it is used to
  # initialize the input string. When entering the string, the backspace, delete
  # and cursor keys can be used to correct typing errors. If the input string is
  # longer than can fit in the dialog box, the input field will be scrolled.
  #
  # Returns the input string.
  #
  def inputbox(text, init='', height=0, width=0)
    tmp = Tempfile.new('tmp')

    cmd = [ option_string(), '--inputbox',
      text.inspect, height, width, init.inspect, '2>', tmp.path.inspect ].join(' ')

    success = run(cmd)
    if success
      selected_string = ''
      begin
        selected_string = tmp.readline
      rescue EOFError
      ensure
        tmp.close!
      end
      return selected_string
    else
      tmp.close!
      return success
    end
  end

  # An **inputmenu** box is very similar to an ordinary **menu** box. There are
  # only a few differences between them:
  #
  # 1. The entries are not automatically centered but left adjusted.
  # 2. An extra button (called `Rename`) is implied to rename the current item
  #    when it is pressed.
  # 3. It is possible to rename the current entry by pressing the `Rename`
  #    button. Then **rdialog** will return 
  #
  # TODO: finish up the logic here.
  def inputmenu(text, items, height=0, width=0, menu_height=0)
    tmp = Tempfile.new('tmp')

    tags = items.map{|i| i.first}
    debug(tags.inspect)
    items.map!{|item| item.map{|i| i.inspect}}.join(' ')
    debug(items.inspect)

    # Set quoted option for parsing purposes.
    @quoted = true
    cmd = [ option_string(), '--inputmenu',
      text.inspect, height, width, menu_height, items, '2>', tmp.path.inspect ].join(' ')

    result, success = run(cmd, tmp)
    debug(result)
    result = Shellwords.escape(result)
    debug(result)

    if exit_code == 3
      debug "Caught it"
      match = result.match(/RENAMED (.*) ww(.*)/)
      debug(match.inspect)
    end
    tmp.close!
    return result
  end

  #
  # As its name suggests, a **menu** box is a dialog box that can be used to
  # present a list of choices in the form of a menu for the user to choose.
  # Choices are displayed in the order given. Each menu entry consists of a
  # `tag` string and an `item` string. The `tag` gives the entry a name to
  # distinguish it from the other entries in the menu. The `item` is a short
  # description of the option that the entry represents. The user can move
  # between the menu entries by pressing the cursor keys, the first letter of
  # the `tag` as a hot-key, or the number keys `1` through `9`. There are
  # `menu-height` entries displayed in the menu at one time, but the menu will
  # be scrolled if there are more entries than that.
  #
  # Returns a string containing the tag of the chosen menu entry.
  #
  def menu(text, items, height=0, width=0, listheight=0)
    tmp = Tempfile.new('tmp')

    items.map!{|item| item.map{|i| i.inspect}}.join(' ')
    cmd = [ option_string(), '--menu',
      text.inspect, height, width, listheight, items, '2>', tmp.path.inspect ].join(' ')

    success = run(cmd)

    if success
      selected_string = tmp.readline
      tmp.close!
      return selected_string
    else
      tmp.close!
      return success
    end

  end

  def menu_item(args={})
    item = [ args[:tag], args[:item] ]
    item << args[:help] if item_help
    return item
  end

  def mixedform
    raise NotImplementedError
  end

  def mixedgauge
    raise NotImplementedError
  end

  #
  # A message box is very similar to a yes/no box.  The  only  dif-
  # ference  between  a message box and a yes/no box is that a mes-
  # sage box has only a single OK button.  You can use this  dialog
  # box  to  display  any message you like.  After reading the mes-
  # sage, the user can press the ENTER key so that dialog will exit
  # and the calling shell script can continue its operation.
  #
  def msgbox(text="Text Goes Here", height=0, width=0)
    run [option_string, '--msgbox', text.inspect, height, width].join(' ')
  end

  #
  # A **pause** box displays a meter along the bottom of the box. The meter
  # indicates how many seconds remain until the end of the pause. The pause
  # exits when timeout is reached or the user presses the OK button (status OK)
  # or the user presses the CANCEL button or Esc key.
  #
  def pause(text, seconds, height=0, width=0)
    run [option_string, '--pause', text.inspect, height, width, seconds].join(' ')
  end

  def passwordbox
    raise NotImplementedError
  end

  def passwordform
    raise NotImplementedError
  end

  #
  # A prgbox is very similar to a programbox.
  #
  # This  dialog box is used to display the output of a command that
  # is specified as an argument to prgbox.
  #
  # After the command completes, the user can press the ENTER key so
  # that  dialog will exit and the calling shell script can continue
  # its operation.
  #
  # If three parameters are given, it displays the  text  under  the
  # title,  delineated  from the scrolling file's contents.  If only
  # two parameters are given, this text is omitted.
  #
  def prgbox(command, height=0, width=0, text='')
    cmd = [ option_string(), '--prgbox' ]
    cmd << text.inspect unless text.empty?
    cmd << command.inspect << height << width
    cmd = cmd.join(' ')
    run(cmd)
  end

  # same as progressbox but displays OK button at the end
  def programbox(description='', height=0, width=0)
    cmd = [ option_string(), '--programbox' ]
    cmd << description.inspect unless description.empty?
    cmd << height << width
    cmd = cmd.join(' ')
    run(cmd) { |fh| yield fh }
  end

  #
  # Progressbox is used to display the piped output of a command.  
  # After  the  command completes,  the  user can press the ENTER key so 
  # that dialog will exit and the calling shell script can continue its operation.
  # If three parameters are given, it displays the text under the title,
  # delineated  from the  scrolling  file's contents.  If only two 
  # parameters are given, this text is omitted.
  # 
  # The caller will write the progress string on stdout in a block
  # and will pass the block to the method. Please look at samples/
  # progress.rb for an example.
  # Author: muquit@muquit.com Apr-02-2014 
  #
  def progressbox(description='', height=0, width=0)
    cmd = [ option_string(), '--progressbox' ]
    cmd << description.inspect unless description.empty?
    cmd << height << width
    cmd = cmd.join(' ')
    run(cmd) { |fh| yield fh }
  end

  #
  # A **radiolist** box is similar to a **menu** box. The only difference is
  # that you can indicate which entry is currently selected by settings its
  # `status` to `on`.
  #
  # Returns the `tag` of the selected item.
  #
  def radiolist(text, items, height=0, width=0, listheight=0)
    tmp = Tempfile.new('tmp')
    items.map!{|item| item.map{|i| i.inspect}.join(' ')}
    cmd = [ option_string(), '--radiolist',
      text.inspect, height, width, listheight, items, '2>', tmp.path.inspect ].join(' ')
    success = run(cmd)

    if success
      selected_string = tmp.readline
      tmp.close!
      return selected_string
    else
      tmp.close!
      return success
    end

  end

  def rangebox
    raise NotImplementedError
  end

  #
  # Display text from a file in a dialog box, as in a "tail -f" command. Scroll
  # left/right using vi-style 'h' and 'l', or arrow-keys. A '0' resets the
  # scrolling.
  #
  def tailbox(file, height=0, width=0)
    run([ option_string(), '--tailbox', file.inspect, height, width ].join(' '))
  end

  #
  # Display text from a file in a dialog box as a background task, as in a
  # "tail -f &" command. Scroll left/right using vi-styl 'h' and 'l', or arrow-
  # keys. A '0' resets the scrolling.
  #
  # Dialog treats the background task specially if there are other widgets
  # (`--and-widget`) on the screen concurrently. Until those widgets are closed
  # (e.g., an "OK"), **dialog** will perform all of the tailboxbg widgets in the
  # same process, polling for updates. You may use a tab to traverse between the
  # widgets on the screen, and close them individually, e.g. by pressing "Enter".
  # Once the non-tailboxbg widgets are closed, **dialog** forks a copy of itself
  # into the background, and prints its process id if the `--no-kill` option is
  # given.
  #
  def tailboxbg(file, height=0, width=0)
    run([ option_string(), '--tailboxbg', file.inspect, height, width ].join(' '))
  end

  #
  # A **text** box lets you display the contents of a text file in a dialog box.
  # It is like a simple text file viewer. The user can move through the file by
  # using the cursor, page-up, page-down and **HOME/END** keys available on most
  # keyboards. If the lines are too long to be displayed in the box, the **LEFT/
  # RIGHT** keys can be used to scroll the text region horizontally. You may
  # also use vi-style keys h, j, k, and l in place of the cursor keys, and B or
  # N in place ofthe page-up and page-down keys. Scroll up/down using vi-style 
  # 'k' and 'j', or arrow-keys. Scroll left/right using vi-style 'h' and 'l' or
  # arrow-keys. A '0' resets the left/right scrolling. For more convenience, vi-
  # style forward and backward searching functions are also provided.
  #
  def textbox(file, height=0, width=0)
    run([ option_string(), '--textbox', file.inspect, height, width ].join(' '))
  end

  # A dialog is displayed which allows you to select hour, minute and second.
  # If the values for hour, minute or second are missing or negative, the
  # current date's  corresponding values are used. You can increment or
  # decrement any of those using the left-, up-, right- and down-arrows. Use
  # tab or backtab to move between windows.
  #
  # Returns a Time object.
  #
  def timebox(text, height=0, width=0, time=Time.now)
    tmp = Tempfile.new('tmp')
    cmd = [ option_string(), '--timebox',
      text.inspect, height, width, time.hour, time.min, time.sec,
      '2>', tmp.path.inspect ].join(' ')
    success = run(cmd)
    if success
      time = Time.parse(tmp.readline)
      tmp.close!
      return time
    else
      tmp.close!
      return success
    end
    
  end
  # 
  # Display data organized as a tree.  Each group of data contains a
  # tag, the text to display for  the  item,  its  status  ("on"  or
  # "off") and the depth of the item in the tree.
  # 
  # Only  one item can be selected (like the radiolist).  The tag is
  # not displayed.
  # 
  # On exit, the tag of the selected item  is  written  to  dialog's
  # output.
  def treeview(text="Text Goes Here", items=nil, height=0, width=0, listheight=0)
    tmp = Tempfile.new('dialog') 
    items.map!{|item| item.map{|i| i.inspect}}.join(' ')
    cmd = [ option_string(), '--treeview',
      text.inspect, height, width, listheight, items,
      '2>', tmp.path.inspect ].join(' ')
    log_debug "Number of items: #{items.size}"
    run(cmd)
    tag = ''
    if @exit_code == 0
      tag = tmp.read
    end
    tmp.close!
    return tag
  end
   

  def list_item(args={})
    item = [ args[:tag], args[:item], args[:status] ? 'on' : 'off' ] 
    item << args[:help] if item_help
    return item
  end

  def tree_item(args={})
    item = [ args[:tag], args[:item], args[:status] ? 'on' : 'off', args[:depth] ]
    item << args[:help] if item_help
    return item
  end

  #
  # A mixedform dialog displays a form consisting of labels and fields,  
  # much  like  the --form  dialog.   It differs by adding a field-type 
  # parameter to each field's description.  Each bit in the type denotes 
  # an attribute of the field:
  # *     1    hidden, e.g., a password field.
  # *     2    readonly, e.g., a label.#
  # Author:: muquit@muquit.com 
  def mixedform(text, items, height=0, width=0, formheight=0)
    item_size = items[0].size
    log_debug "Item size:#{item_size}"
    if item_size == 9
      return form(text, items, height, width, formheight)
    end
    return nil
  end

  #
  # This is identical to --form except  that  all  text  fields  are
  # treated as password widgets rather than inputbox widgets.
  def passwordform(text, items, height=0, width=0, formheight=0)
    @password_form = true
    return form(text, items, height, width, formheight)
  end

  ##---- muquit@muquit.com mod ends---





  #      A password box is similar to an input box, except that the text
  #      the user enters is not displayed.  This is useful when  prompt-
  #      ing  for  passwords  or  other sensitive information.  Be aware
  #      that if anything is passed in "init", it will be visible in the
  #      system's  process  table  to casual snoopers.  Also, it is very
  #      confusing to the user to provide them with a  default  password
  #      they  cannot  see.   For  these reasons, using "init" is highly
  #      discouraged.

  def passwordbox(text="Please enter some text", height=0, width=0, init="")
    tmp = Tempfile.new('tmp')
    command = option_string() + "--passwordbox \"" + text.to_s +
    "\" " + height.to_i.to_s + " " + width.to_i.to_s + " "

    unless init.empty?
      command += init.to_s + " "
    end

    command += "2> " + tmp.path
    log_debug(command)
    success = system(command)

    if success
      begin
        selected_string = tmp.readline
      rescue EOFError
        selected_string = ""
      end
      tmp.close!
      return selected_string
    else
      tmp.close!
      return success
    end
  end

  #
  # A **yes/no** dialog box of size `height` rows by `width` columns will be
  # displayed. The string specified by `text` is displayed inside the dialog 
  # box. If this string is too long to fit in one line, it will be automatically
  # divided into multiple lines at appropriate places. The `text` string can
  # also contain the sub-string "`\n`" or newline characters `\n` to control
  # line breaking explicitly. This dialog box is useful for asking questions
  # that require the user to answer either yes or no. The dialog box has a
  # **Yes** button and a **No** button, in which the user can switch between
  # by pressing the _TAB_ key.
  #
  # Returns the exit code.
  #
  def yesno(text, height=0, width=0)
    return run([ option_string(), '--yesno', text.inspect, height, width ].join(' '))
  end

  private  

    def option_string
      # make sure 'dialog' is installed
      # muquit@muquit.com 
      exe_loc = ''
      unless @path_to_dialog
        exe_loc = which("dialog")
        ostring = exe_loc
      else
        exe_loc = @path_to_dialog
        if !File.exists?(exe_loc)
          raise "Specified path of dialog '#{exe_loc}' does not exist"
        end
        if !File.executable?(exe_loc)
          raise "The program #{exe_loc} is not executable"
        end
      end
      raise "'dialog' executable not found in path" unless exe_loc

      options = [ exe_loc ]

      (options << "--ascii-lines") if ascii_lines
      (options << "--aspect #{aspect}") if aspect
      (options << "--backtitle #{backtitle.inspect}") if backtitle
      (options << "--begin #{begin_pos[0..1].join(' ')}") if begin_pos
      (options << "--cancel-label #{cancel_label.inspect}") if cancel_label
      (options << "--clear") if clear
      (options << "--colors") if colors
      (options << "--column-separator #{column_separator.inspect}") if column_separator
      (options << "--cr-wrap") if cr_wrap
      (options << "--date-format #{date_format.inspect}") if date_format
      (options << "--defaultno") if defaultno
      (options << "--default-button #{default_button.inspect}") if default_button
      (options << "--default-item #{default_item.inspect}") if default_item
      (options << "--exit-label #{exit_label.inspect}") if exit_label
      (options << "--extra-button #{extra_button.inspect}") if extra_button
      (options << "--extra-label #{extra_label.inspect}") if extra_label
      (options << "--help-button") if help_button
      (options << "--help-label #{help_label.inspect}") if help_label
      (options << "--help-status") if help_status
      (options << "--help-tags") if help_tags
      (options << "--hfile #{hfile.inspect}") if hfile
      (options << "--hline #{hline.inspect}") if hline
      (options << "--ignore") if ignore
      (options << "--input-fd #{input_fd.inspect}") if input_fd
      (options << "--insecure") if insecure
      (options << "--item-help") if item_help
      (options << "--keep-tite") if keep_tite
      (options << "--keep-window") if keep_window
      (options << "--last-key") if last_key
      (options << "--max-input #{max_input.inspect}") if max_input
      (options << "--no-cancel") if no_cancel
      (options << "--nocancel") if nocancel
      (options << "--no-collapse") if no_collapse
      (options << "--no-items") if no_items
      (options << "--no-kill") if no_kill
      (options << "--no-label #{no_label.inspect}") if no_label
      (options << "--no-lines") if no_lines
      (options << "--no-mouse") if no_mouse
      (options << "--no-nl-expand") if no_nl_expand
      (options << "--no-ok") if no_ok
      (options << "--nook") if nook
      (options << "--no-shadow") if no_shadow
      (options << "--no-tags") if no_tags
      (options << "--ok-label #{ok_label.inspect}") if ok_label
      (options << "--output-fd #{output_fd.inspect}") if output_fd
      (options << "--separator #{separator.inspect}") if separator
      (options << "--output-separator #{output_separator.inspect}") if output_separator
      (options << "--print-maxsize") if print_maxsize
      (options << "--print-size") if print_size
      (options << "--print-version") if print_version
      (options << "--quoted") if quoted
      (options << "--scrollbar") if scrollbar
      (options << "--separate-output") if separate_output
      (options << "--separate-widget #{separate_widget.inspect}") if separate_widget
      (options << "--shadow") if shadow
      (options << "--single-quoted") if single_quoted
      (options << "--size-err") if size_err
      (options << "--sleep #{sleep.inspect}") if sleep
      (options << "--stderr") if stderr
      (options << "--stdout") if stdout
      (options << "--tab-correct") if tab_correct
      (options << "--tab-len #{tab_len.inspect}") if tab_len
      (options << "--time-format #{time_format.inspect}") if time_format
      (options << "--timeout #{timeout.inspect}") if timeout
      (options << "--title #{title.inspect}") if title
      (options << "--trace #{trace.inspect}") if trace
      (options << "--trim") if trim
      (options << "--version") if version
      (options << "--visit-items") if visit_items
      (options << "--yes-label #{yes_label.inspect}") if yes_label

      return options.join(' ')
    end
end

#Dir[File.join(File.dirname(__FILE__), 'rdialog/**/*.rb')].sort.each { |lib| require lib }
