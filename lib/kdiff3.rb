# string.present?
require 'active_support/core_ext/string'

module KDiff3

  # list of created Tempfiles
  TEMPFILES = []
  # so we don't accidentally mess up formatting when we remove these later,
  # we need to have a weird, non-stand sequence of characters to search
  # and replace
  NEWLINE = "\n\-"


  # performs a 3 way merge between base, a, and b
  # a 2 way merge will be performed if either yours
  # or theirs are left out
  #
  # @param [String] base string or file path for common ancestor
  # @param [String] yours string or file path for your changes
  # @param [String] theirs string or file path for their changes
  # @param [Boolean] html whether or not use an HTML diffing technique
  # @return [String] result of merge
  def self.merge(base: nil, yours: nil, theirs: nil, html: false)
    raise ArgumentError.new('base is required') unless base.present?
    raise ArgumentError.new('yours and/or theirs required') unless yours || theirs

    # since HTML is often compressed to conserve transfer space, and therefore
    # has few lines, we need to split up the HTML in to a multi-lined document
    if html
      base = add_new_lines(base)
      yours = add_new_lines(yours)
      theirs = add_new_lines(theirs)
    end

    base_path = tempfile(text: base, name: 'base')
    your_path = tempfile(text: yours, name: 'yours')
    their_path = tempfile(text: theirs, name: 'theirs')
    output_path = tempfile(name: 'output')

    # we don't need these open for anything
    close_tempfiles

    # the heavy lifting, courtesy of kdiff3
    exit_code = run("#{base_path} #{your_path} #{their_path} -m --auto --fail -o #{output_path}")
    conflicts_exist = exit_code == 1

    result = IO.read(output_path) unless conflicts_exist

    # clean up
    delete_tempfiles

    raise RuntimeError.new("Conflicts exist and could not be resolved") if conflicts_exist

    if html
      # remove the NEWLINES
      result.gsub!(NEWLINE, "")
    end

    result
  end

  private

  # @param [String] name of the file
  # @param [String] text content of file or path
  # @return [String] path of the Tempfile or Pre-existing file
  def self.tempfile(text: nil, name: nil)
    result = ""

    # if the file already exists,
    # don't add it to the tempfile list,
    # as we don't want it to be deleted
    if text && is_file_path?(text)
      result = text
    else
      t = Tempfile.new(name)
      t << text if text
      TEMPFILES << t
      result = t.path
    end

    result
  end

  def self.close_tempfiles
    TEMPFILES.map(&:close)
  end

  def self.delete_tempfiles
    TEMPFILES.map(&:delete)
  end

  # @param [String] path can be a file path or arbitrary string
  # @return [Boolean] if the given string is a path to a file
  def self.is_file_path?(path)
    File.exist?(path)
  end

  def self.run(args)
    %x(
      #{kdiff3_path} #{args}
    )
    $?.exitstatus
  end

  # ensures the local copy of kdiff3 is present, if not, download and compile it
  def self.kdiff3_path
    current_folder = File.dirname(__FILE__)
    path = "#{current_folder}/../ext/kdiff3/releaseQt/kdiff3"

    unless File.exist?(path)
      build_kdiff3
    end

    path
  end

  def self.build_kdiff3
    current_folder = File.dirname(__FILE__)

    kdiff3_repo_path = "#{current_folder}/../ext/kdiff3"

    if  File.exist?(kdiff3_repo_path)
      %x(
        git pull # origin optionally-fail-on-conflict
      )
    else
      %x(
        git clone git@github.com:NullVoxPopuli/kdiff3.git #{kdiff3_repo_path}
        cd #{kdiff3_repo_path} && git checkout optionally-fail-on-conflict
      )
    end

    # build
    %x(
      cd #{kdiff3_repo_path} && ./configure qt4
    )
  end

  # add newlines after every tag, and every character
  def self.add_new_lines(text)
    text = self.add_new_lines_to_non_tags(text)
    text = self.add_new_lines_after_tags(text)

    # trim accidental blank lines
    text.gsub!("#{NEWLINE}#{NEWLINE}", NEWLINE)

    text
  end

  # http://www.rubular.com/r/N2AHZgpPum
  # http://stackoverflow.com/questions/7540489/javascript-regex-match-text-not-part-of-a-html-tag
  def self.add_new_lines_after_tags(text)
    tag_selection_regex = /<[^>]*>/
    text.gsub(tag_selection_regex) do |match|
      match << NEWLINE
    end
  end

  # http://www.rubular.com/r/mpX6Ee2r0k
  # http://stackoverflow.com/questions/18621568/regex-replace-text-outside-html-tags
  def self.add_new_lines_to_non_tags(text)
    non_tags = /(?<=^|>)[^><]+?(?=<|$)/
    # non_tags = /([^<>]+)(?![^<]*>|[^<>]*<\/)/
    text.gsub(non_tags) do |match|
      # consecutive words
      match.gsub!(" ", " #{NEWLINE}")
      # end with NEWLINE
      match << NEWLINE
    end
  end


end
