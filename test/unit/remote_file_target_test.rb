require 'test_helper'

class RemoteFileTargetTest < Test::Unit::TestCase
  include SproutTestCase

  context "an improperly configured remote file target" do
  
    should "throw validation error on archive_type" do
      assert_raises Sprout::Errors::ValidationError do
        t = Sprout::RemoteFileTarget.new
        #t.archive_type = :zip # This causes the validation error
        t.md5          = 'abcd'
        t.url          = 'http://google.com'
        t.pkg_name     = 'google'
        t.pkg_version  = '1.0.0'

        t.resolve
      end
    end

    should "throw validation error on md5" do
      assert_raises Sprout::Errors::ValidationError do
        t = Sprout::RemoteFileTarget.new
        t.archive_type = :zip
        #t.md5          = 'abcd' # This causes the validation error
        t.url          = 'http://google.com'
        t.pkg_name     = 'google'
        t.pkg_version  = '1.0.0'

        t.resolve
      end
    end

    should "throw validation error on url" do
      assert_raises Sprout::Errors::ValidationError do
        t = Sprout::RemoteFileTarget.new
        t.archive_type = :zip
        t.md5          = 'abcd'
        #t.url          = 'http://google.com' # This causes the validation error
        t.pkg_name     = 'google'
        t.pkg_version  = '1.0.0'

        t.resolve
      end
    end
  end

  context "a correctly configured remote file target" do

    setup do
      @target = Sprout::RemoteFileTarget.new do |t|
        t.archive_type = :zip
        t.md5          = 'd41d8cd98f00b204e9800998ecf8427e'
        t.url          = 'http://github.com/downloads/lukebayes/project-sprouts/echochamber-test.zip'
        t.pkg_name     = 'echochamber'
        t.pkg_version  = '1.0.pre'
        t.add_executable :echochamber, 'bin/echochamber.sh'
      end

      @unpacked_file = File.join(temp_cache, 'unpacked')
      @target.stubs(:unpacked_file).returns @unpacked_file

      @downloaded_file = File.join(temp_cache, 'downloaded.zip')
      @target.stubs(:downloaded_file).returns @downloaded_file
	  
	  downloaded_bytes = File.join(fixtures, 'remote_file_target', 'echochamber-test.zip')
      @archive_bytes = File.open(downloaded_bytes, 'rb').read

      @target.stubs(:download_archive).returns @archive_bytes
	end

    teardown do
	  remove_file File.join(fixtures, 'sprout')
    end
	
    context "that has already been UNPACKED" do
      should "not be DOWNLOADED or unpacked" do
        create_file File.join(@unpacked_file, 'unpacked')
        @target.expects(:download_archive).never
        @target.expects(:unpack_archive).never
        @target.resolve
      end
    end

    context "that had an unpack failure" do
      should "still unpack the file" do
	    # Create the expected unpacked_file:
        FileUtils.mkdir_p @unpacked_file
        @target.stubs('should_unpack?').returns true
        @target.expects(:unpack_archive)
        @target.resolve
      end
    end

    context "that has been DOWNLOADED, but not UNPACKED" do

      should "not unpack if md5 doesn't match, and user responds in negative" do
        @target.stubs('should_unpack?').returns false
        @target.expects(:unpack_archive).never
        @target.resolve
      end

      should "unpack but not download" do
        @target.stubs('should_unpack?').returns true
        @target.resolve
        assert_not_empty @unpacked_file
      end
    end

    context "that has not yet been DOWNLOADED, or UNPACKED" do
      should "download and unpack the remote archive" do
	    @target.stubs('should_unpack?').returns true
		#@target.expects(:download_archive)
        #@target.expects(:unpack_archive)
        @target.resolve

        assert_file @downloaded_file
        assert_not_empty @unpacked_file
      end
    end

  end
end
