#!/usr/bin/env ruby

# ##############################################################################
# REQUIRED CLASSES/MODULES
# ##############################################################################
require 'fileutils'
require 'json'
require 'brl/util/util'
require 'brl/script/scriptDriver'

# @todo Convert/port to Ruby 2.1+ compatibility. Address PROPERLY (not copy-paste here, dammit, PORT library code sensibly).
# @todo * Begin a separately-maintained brl/ lib area for 2.1+. Ported / alternative code will go there.
# @todo * Isolate and employ ONLY those overrides/extensions needed from brl/util/util.rb and move them to brl/extensions/ 2.1+ lib area
# @todo * Ensure have NFS-compliant fcntl file locking (we used Matz' flock for 1.8.7)
# @todo * Of course, fix Hash :symbol=>value refs to be symbol: value
# @todo * Watch out for changed string[2] meaning; port and use our Numeric/String#chr and Numeric/String#ord to make this painless

module BRL ; module Genboree ; module Prequeue ; module Scripts
  class AcReleaseWagMoveTask < BRL::Script::ScriptDriver
    # ------------------------------------------------------------------
    # SUB-CLASS INTERFACE
    # - replace values for constants and implement abstract methods
    # ------------------------------------------------------------------
    # INTERFACE: provide version string
    VERSION = '0.1'
    # INTERFACE provide *specific* command line argument info
    # - Hash of '--longName' arguments to Array of: arg type, one-char arg name, description.
    COMMAND_LINE_ARGS = {
      '--taskConf' =>  [ :REQUIRED_ARGUMENT, '-t', "The location of the task's JSON config file." ]
    }
    # INTERFACE: Provide general program description, author list (you...), and 1+ example usages.
    DESC_AND_EXAMPLES = {
      :description => "Temporary/test script that handles doc-released messages by 'submitting' (moving) them to an output dir. Just to get structure/flow in place. Real version must submit to configured Kafka and have SSL truststore available for that etc.",
      :authors      => [ "Andrew R Jackson (andrewj@bcm.edu)" ],
      :examples => [
        "#{File.basename(__FILE__)} --taskConf=/some/dir/with/confs/test-ac-wag.json"
      ]
    }

    #------------------------------------------------------------------
    # CONSTANTS
    #------------------------------------------------------------------
    DEFAULT_MIN_MSG_AGE = ( 10 * 60 )
    # @todo Change to use to_f time in first field, and check what happens rapid fire
    MQ_FILENAME_RE = /^([^\-]+)-([0-9a-fA-F]{40,40})-(.+)$/

    #------------------------------------------------------------------
    # ACCESSORS
    #------------------------------------------------------------------

    # ------------------------------------------------------------------
    # IMPLEMENTED INTERFACE METHODS
    # ------------------------------------------------------------------
    # run()
    #  . MUST return a numerical exitCode (20-126). Program will exit with that code. 0 means success.
    #  . Command-line args will already be parsed and checked for missing required values
    #  . @optsHash contains the command-line args, keyed by --longName
    def run()
      @myPid = $$
      @startTime = Time.now()
      @msgsHandled = 0
      haveLock = fh = nil
      # First process args and init and stuff
      validateAndProcessArgs()
      $stderr.debugPuts(__FILE__, __method__, 'STATUS', "Done reading, validating, and processing config files (#{getTimeDelta(true)}")
      begin
        @err = nil
        @exitCode = EXIT_OK
        # Try to get file lock so we don't collide with other related auto-scripts.
        # We'll exit if we can't immediately get the lock (some other related script is running).
        # We'll open for appending-and-reading rather than the truncating 'w' modes.
        # - Conservatively help make sure we don't wipe the file inode or something that clears
        #   open locks as a side effect of "efficient file truncation" optimizations by the OS.
        # - So we use a+
        # Don't re-open our file handle regardless of have/don't have
        fh = File.open( @lockFile, 'a+' ) unless(fh)
        haveLock = fh.getLock(0)
        if( haveLock ) # proceed
          $stderr.debugPuts(__FILE__, __method__, 'STATUS', "About to process messages.")
          processMsgs()
          $stderr.debugPuts(__FILE__, __method__, 'STATUS', "Done 'processing' of #{@msgsHandled.inspect} messages (#{getTimeDelta(true)}")
        else
          $stderr.debugPuts(__FILE__, __method__, 'STATUS', "Could not get lock on file #{@lockFile.inspect}. Unexpected since message handling--even faked via file shuffling--should be very fast and there should never be any contention. Did the last run get -9'd and thus not get a chance to nicely release lock? *IF* there is not another task like this running [and WTH is it doing?] then you may need to delete the lock file.")
        end
      rescue Exception => err
        # May have lock still; ensure block should see it cleared, especially if we set haveLock
        haveLock = true
        $stderr.debugPuts(__FILE__, __method__, "ERROR", "Unexpected error.\n  Error Class: #{err.class}\n  Error Message: #{err.message}\n  Error Trace:\n\n#{err.backtrace.join("\n")}")
      ensure
        if(fh and haveLock) # Aggressively try to release lock (esp if Exception raised of some kind)
          fh.releaseLock() rescue nil
          fh.close rescue nil
          fh = nil
          $stderr.debugPuts(__FILE__, __method__, "STATUS", "RELEASED lock")
        end

      end

      @prevTime = nil # want total time, not incremental
      $stderr.debugPuts(__FILE__, __method__, 'STATUS', "ALL DONE (in #{getTimeDelta(true)}) - processed #{@msgsHandled.inspect} messages ; exit code #{@exitCode.inspect}")
      # Did we get an error for some jobs?
      unless(@exitCode == EXIT_OK)
        # Re-raise the @err that was saved within the job-loop above. We didn't re-raise before because then no subsequent jobs would be submitted!
        raise @err
      end
      # Must return a suitable exit code number
      return @exitCode
    end

    # ------------------------------------------------------------------
    # SCRIPT-SPECIFIC METHODS
    # - stuff needed to do actual program or drive 3rd party tools, etc
    # - repeatedly-used generic stuff is in library classes of course...
    # ------------------------------------------------------------------

    def processMsgs()
      @prevTime = nil

      mqDir = Dir.new( @mqPath.chomp('/') )
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Found entries in mqDir:\n\n#{mqDir.entries.inspect}\n\n")
      # Collect appropriate msg files in the dir. May need to time component of filename to help resolve rapid message production.
      msgFiles = []
      mqDir.each { |fn|
        #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Consider: #{fn.inspect}")
        if( fn =~ MQ_FILENAME_RE ) # Looks like msg file
          fnTime, fnToken, fnSubjFile = $1, $2, $3
          fnPath = "#{mqDir.path}/#{fn}"
          mtime = File.mtime( fnPath )
          #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Matched pattern. Have #{[$1, $2, $3].inspect} and full path:\n\n#{fnPath.inspect}\n\n")
          if( ( Time.now - mtime ) > @minMsgAge ) # Msg is older than min age
            msgFiles << { :fnPath => fnPath, :fnTime => fnTime, :fnToken => fnToken, :fnSubjFile => fnSubjFile, :mtime => mtime }
          end
        end
      }
      # Sort matching msg files appropriately. Mainly to resolve msgs which happened at same sec on same subject.
      msgFiles.sort! { |aa, bb|
        rv = ( aa[:fnSubjFile] <=> aa[:fnSubjFile] )
        if( rv == 0 ) # have msgs about same subj
          rv = ( aa[:mtime] <=> bb[:mtime] ) # check 1-sec resolution time
          if( rv == 0 )
            rv = ( Time.at( aa[:fnTime].to_f ) <=> Time.at( bb[:fnTime].to_f ) ) # try the time component of msg file name
          end
        end
        rv
      }
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Sorted msgFiles:\n\n") ; msgFiles.each { |mf| $stderr.puts mf.inspect } ; $stderr.puts ''
      $stderr.debugPuts(__FILE__, __method__, 'STATUS', "Gathered list of #{msgFiles.size} msg files...will 'process' messages by moving them to dest and doing a delete afterward if successfull, in case move was just copy to different disk partition.\n\n")
      # Process each message
      msgFiles.each { |msgFile|
        # Archive file if asked
        archive( msgFile[:fnPath] ) if(@archive)
        # Handle file...in this prototype, moves msg file to destination as fnSubjFile, so dest only has latest version of each subject.
        destFnPath = "#{@destPath}/#{msgFile[:fnSubjFile]}"
        # - move file
        mvOk = FileUtils.mv( msgFile[:fnPath], destFnPath, { :force => true, :verbose => true } ) rescue false
        # - ensure source is deleted (in case dest was different disk partition and only copy was done)
        FileUtils.rm( msgFile[:fnPath], { :force => true, :verbose => true } ) if( mvOk )
        @msgsHandled += 1
      }
      $stderr.puts ''

      return @msgsHandled
    end

    def archive( filePath )
      destPath = "#{@archivePath}/#{File.basename(filePath)}"
      FileUtils.cp( filePath, destPath, { :verbose => true } )
      if( @archiveGzip )
        gzStdout = `gzip -9 -f #{destPath} 2>&1`
        unless( $?.success? )
          $stderr.debugPuts(__FILE__, __method__, 'ERROR', "gzip of #{destPath.inspect} failed with exit status info #{$?.inspect}. Output from gzip was:\n\n#{gzStdout}\n\n")
        end
      end
    end

    # @note Almost all ScriptDriver subclasses should have this method and call it from
    #   their run() implementation. A place to go through command line options and extract
    #   needed settings and state.
    # @return [Boolean] Indicating setup using command line options was sucessful or not.
    def validateAndProcessArgs()
      retVal = @taskConf = @mqConf = @lockFile = @destPath = @mqPath = @archive = @archivePath = @archiveGzip = nil
      # Parse args
      taskConfFile = @optsHash['--taskConf'].strip
      mqConfFile = nil
      @verbose = @optsHash.key?('--verbose')
      # Load and inspect task config file
      if( taskConfFile.empty? or !File.readable?( taskConfFile ) )
        raise ArgumentError, "The task config file provided (#{@taskConf.inspect}) is not readable."
      else
        begin
          @taskConf  = JSON.parse( File.read( taskConfFile ) )
          @lockFile  = @taskConf['lock'].to_s
          mqConfFile = @taskConf['mqConf'].to_s
          @destPath  = @taskConf['task']['location'].to_s
          @minMsgAge = ( @taskConf['task']['minMsgAgeSec'] or DEFAULT_MIN_MSG_AGE )
          @archive    = @taskConf['task']['archive']['active'].to_s.autoCast(true) rescue false
          raise IOError, "Cannot read MQ conf file mentioned: #{mqConfFile.inspect}" unless( File.readable?( mqConfFile ) )
          raise ArgumentError, "The task type #{@taskConf['task']['type'].inspect} not exactly 'move'." unless( @taskConf['task']['type'] == 'move' )
          raise IOError, "Cannot write to task output location #{@destPath.inspect}." unless( File.writable?(@destPath ) )
          raise IOError, "Cannot write to lock file, therefore cannot use for locking (#{@lockFile.inspect})" unless( !File.exist?(@lockFile) or File.writable?( @lockFile ) )
          if( @archive )
            @archivePath = @taskConf['task']['archive']['location'].to_s
            @archiveGzip = @taskConf['task']['archive']['gzip']
            raise IOError, "Cannot write to archive location #{@archivePath.inspect}" unless( File.writable?(@archivePath ) )
          end
        rescue => err
          raise ArgumentError, "The task config file provided (#{taskConfFile.inspect}) is not parseable JSON or has inappropriate content. Specific error message was:\n\n\t#{err.message.inspect rescue '[NONE GIVEN!]'}\n\n"
        end
      end
      # Load and inspect MQ config file
      begin
        @mqConf = JSON.parse( File.read( mqConfFile ) )
        @mqPath = @mqConf['location'].to_s
        raise IOError, "Cannot read and execute MQ message dir #{@mqPath.inspect}" unless( File.readable?(@mqPath ) and File.executable?(@mqPath ) )
      rescue => err
        raise ArgumentError, "The MQ config file provided (#{mqConfFile.inspect}) is not parseable JSON or has inappropriate content. Specific error message was:\n\n#{err.message.inspect rescue '[NONE GIVEN!]'}\n\n"
      end

      retVal = true
      return retVal
    end

    def getTimeDelta(asStr=false)
      currTime = Time.now()
      @prevTime = @startTime unless(@prevTime)
      retVal = (currTime.to_f - @prevTime.to_f)
      @prevTime = currTime
      return (asStr ? ("#{'%.3f' % retVal} secs") : retVal)
    end
  end # class AcReleaseWagMoveTask
end ; end ; end ; end # module BRL ; module Genboree ; module Prequeue ; module Scripts

########################################################################
# MAIN - Provided in the scripts that implement ScriptDriver sub-classes
# - but would look exactly like this ONE LINE:
########################################################################
# IF we are running this file (and not using it as a library), run it:
if($0 and File.exist?($0) and BRL::Script::runningThisFile?($0, __FILE__, true))
  # Argument to main() is your specific class:
  BRL::Script::main(BRL::Genboree::Prequeue::Scripts::AcReleaseWagMoveTask)
end
