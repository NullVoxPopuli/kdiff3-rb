require 'spec_helper'

describe KDiff3 do

  describe 'merge' do
    it { expect{KDiff3.merge}.to raise_error(ArgumentError) }
    it { expect{KDiff3.merge(base: "base")}.to raise_error(ArgumentError) }
    it { expect{KDiff3.merge(base: "base", yours: "yours")}.to_not raise_error }
    it { expect{KDiff3.merge(base: "base", yours: "yours", theirs: "theirs")}.to_not raise_error }

    describe 'by line' do
      before(:all) do
        @base = "#{File.dirname(__FILE__)}/support/base"
        @a = "#{File.dirname(__FILE__)}/support/a"
        @b = "#{File.dirname(__FILE__)}/support/b"
        @expected = "#{File.dirname(__FILE__)}/support/expected"
      end

      it 'completes a 3-way merge' do
        result = KDiff3.merge(
          base: @base,
          yours: @a,
          theirs: @b
        )
        expected = IO.read(@expected)

        expect(result).to eq expected
      end
    end

    describe 'by word (the html option)' do
      before(:all) do
        @base = "<p>1,2,<p>1,<p>2,</p></p>3</p>"
        @a = "<p>1,2,<p>1,</p>3</p>"
        @b = "<p>1,2,<p><p>2,</p></p>3</p>"
        @expected = "<p>1,2,<p></p>3</p>"
      end

      it 'completes a 3-way merge' do
        result = KDiff3.merge(
          base: @base,
          yours: @a,
          theirs: @b.
          html: true
        )
        expected = IO.read(@expected)

        expect(result).to eq expected
      end
    end
  end

  describe 'private methods' do

    describe 'is_file?' do
      it { expect(KDiff3.send(:is_file_path?, __FILE__)).to eq true }
      it { expect(KDiff3.send(:is_file_path?, "#{File.dirname(__FILE__)}/spec_helper.rb")).to eq true }
      it { expect(KDiff3.send(:is_file_path?, "not a file")).to eq false }
      it { expect(KDiff3.send(:is_file_path?, "not/a/file")).to eq false }
    end

    describe 'tempfile' do
      it 'returns path when path is a file' do
        expect(KDiff3.send(:tempfile, text: __FILE__, name: 'rspec')).to eq __FILE__
      end

      it 'creates a tempfile' do
        expect{
          KDiff3.send(:tempfile, name: 'base')
        }.to change(KDiff3::TEMPFILES, :size).by 1
      end

      it 'creates a tempfile with content' do
        path = KDiff3.send(:tempfile, name: 'base', text: 'content')
        # file must be closed before reading
        KDiff3.send(:close_tempfiles)
        expect(IO.read(path)).to eq 'content'
      end
    end

    describe 'kdiff3_path' do

    end

    describe 'add_new_lines' do
      after(:each) do
        result = KDiff3.send(:add_new_lines, @text)
        # remove special character
        # - this determines our line breaks from pre-existing ones
        result.gsub!(KDiff3::NEWLINE, "\n")
        expect(result).to eq @expected
      end

      it 'adds new lines to text' do
        @text = "something like this"
        @expected = "something \nlike \nthis\n"
      end

      it 'adds new lines to html' do
        @text = "<p>something maybe<p><span>like <a>this</a></span></p></p>"
        @expected = "<p>\nsomething \nmaybe\n<p>\n<span>\nlike \n<a>\nthis\n</a>\n</span>\n</p>\n</p>\n"
      end

    end

  end
