module Searchpass
  class CLI
    PROGRAM_NAME          = "searchpass".freeze
    CREDENTIALS_FILE      = File.join(File.dirname(__FILE__), "..", "..", "credentials.json")
    CREDENTIALS_SEPARATOR = "========================================================"

    class Error < StandardError; end
    class CredentialsFileError < Searchpass::CLI::Error; end
    class CredentialsFileNotReadable < Searchpass::CLI::CredentialsFileError; end
    class CredentialsFileCorrupt < Searchpass::CLI::CredentialsFileError; end

    def self.run!(args)
      @options = OpenStruct.new
      @options.case_sensitive = false
      @options.exact = false
      @opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{PROGRAM_NAME} [options] term [term2] ... [termN]"
        opts.program_name = PROGRAM_NAME
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-c", "--case", "Perform case sensitive matching") do |v|
          @options.case_sensitive = v
        end

        opts.on("-e", "--exact", "Perform exact matching") do |v|
          @options.exact = v
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
          puts Searchpass::VERSION
          exit
        end
      end
      @opt_parser.parse!(args)
      if args.empty?
        puts "No search terms given"
        puts "See -h or --help for usage"
        exit(1)
      end
      perform_search(args)
    rescue OptionParser::InvalidOption => e
      puts e.message
      puts "See -h or --help for usage"
      exit(1)
    rescue => e
      puts "ERROR: #{e.message}"
      exit(1)
    end

    protected

    def self.perform_search(args)
      matches = []
      credentials.each do |credential|
        haystack = "#{credential['Vendor']} #{credential['Name']} #{credential['Version']}"
        match    = true
        if !@options.case_sensitive
          haystack.downcase!
          args.map! { |a| a.downcase }
        end
        if @options.exact
          args = [args.join(" ")]
        end
        args.each do |arg|
          if @options.exact
            if haystack != arg
              match = false
              break
            end
          else
            if !haystack.include?(arg)
              match = false
              break
            end
          end
        end
        matches << credential if match
      end
      if matches.empty?
        puts "No matches for #{args.join(' ')}"
      else
        puts "Found #{matches.count} #{matches.count == 1 ? 'match' : 'matches'}:\n"
        matches.each do |match|
          output_credential(match)
        end
      end
    end

    def self.output_credential(credential)
      puts "\nVendor:   #{credential['Vendor']}"
      puts "Name:     #{credential['Name']}"
      if credential.key?("Version") && !credential["Version"].empty?
        puts "Version:  #{credential['Version']}"
      end
      if credential.key?("Method") && !credential["Method"].empty?
        puts "Method:   #{credential['Method']}"
      end
      if credential.key?("User ID") && !credential["User ID"].empty?
        puts "User ID:  #{credential['User ID']}"
      end
      if credential.key?("Password") && !credential["Password"].empty?
        puts "Password: #{credential['Password']}"
      end
      if credential.key?("Level") && !credential["Level"].empty?
        puts "Level:    #{credential['Level']}"
      end
      if credential.key?("Doc") && !credential["Doc"].empty?
        puts "Doc:      #{credential['Doc']}"
      end
      if credential.key?("Notes") && !credential["Notes"].empty?
        puts "Notes:    #{credential['Notes']}"
      end
      puts "\n#{CREDENTIALS_SEPARATOR}\n"
    end

    def self.credentials
      @credentials ||= read_credentials_file
    end

    def self.read_credentials_file
      if !File.exists?(CREDENTIALS_FILE)
        fail CredentialsFileNotReadable, "Credentials file does not exist"
      end

      if !File.readable?(CREDENTIALS_FILE)
        fail CredentialsFileNotReadable, "Credentials file is not readable"
      end
      credentials = JSON.parse(File.read(CREDENTIALS_FILE)).tap do |c|
        if !c.is_a?(Array)
          fail CredentialsFileCorrupt, "Credentials file is invalid"
        end
      end
    rescue JSON::ParserError
      raise CredentialsFileCorrupt, "Credentials file contains invalid JSON"
    end
  end
end
