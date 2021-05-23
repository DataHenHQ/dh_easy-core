module DhEasy
  module Core
    module Mock
      # Fake in memory database that emulates `DataHen` database objects' black box behavior.
      class FakeDb
        # Page id keys, analog to primary keys.
        PAGE_KEYS = ['gid'].freeze
        # Output id keys, analog to primary keys.
        OUTPUT_KEYS = ['_id', '_collection'].freeze
        # Job id keys, analog to primary keys.
        JOB_KEYS = ['job_id'].freeze
        # Job available status.
        JOB_STATUSES = {
          active: 'active',
          done: 'done',
          cancelled: 'cancelled',
          paused: 'paused'
        }
        # Default collection for saved outputs
        DEFAULT_COLLECTION = 'default'
        # Default page's fetch type
        DEFAULT_FETCH_TYPE = 'standard'
        # Default uuid algorithm
        DEFAULT_UUID_ALGORITHM = :md5
        # Valid uuid algorithms
        VALID_UUID_ALGORITHMS = [:md5, :sha1, :sha256]

        # Generate a smart collection with keys and initial values.
        #
        # @param [Array] keys Analog to primary keys, combination will be uniq.
        # @param [Hash] opts Configuration options (see DhEasy::Core::SmartCollection#initialize).
        #
        # @return [DhEasy::Core::SmartCollection]
        def self.new_collection keys, opts = {}
          DhEasy::Core::SmartCollection.new keys, opts
        end

        # Generate a fake UUID.
        #
        # @param seed (nil) Object to use as seed for uuid.
        # @param [Enumerator] algorithm (nil) Algorithm to use: sha256 (default), sha1, md5.
        #
        # @return [String]
        def self.fake_uuid seed = nil, algorithm = nil
          seed ||= (Time.new.to_f + rand)
          algorithm ||= DEFAULT_UUID_ALGORITHM
          case algorithm
          when :sha256
            Digest::SHA256.hexdigest seed.to_s
          when :sha1
            Digest::SHA1.hexdigest seed.to_s
          else
            Digest::MD5.hexdigest seed.to_s
          end
        end

        # Generate a fake UUID based on output fields without `_` prefix.
        #
        # @param [Hash] data Output data.
        # @param [Enumerator] algorithm (nil) Algorithm to use: sha256 (default), sha1, md5.
        #
        # @return [String]
        def self.output_uuid data, uuid_algorithm = nil
          seed = data.select{|k,v|k.to_s =~ /^[^_]/}.hash
          fake_uuid seed, uuid_algorithm
        end

        # Build a page with defaults by using FakeDb engine.
        #
        # @param [Hash] page Page initial values.
        # @param [Hash] opts ({}) Configuration options (see #initialize).
        #
        # @return [Hash]
        def self.build_page page, opts = {}
          opts = {
            allow_page_gid_override: true,
            allow_job_id_override: true
          }.merge opts
          temp_db = DhEasy::Core::Mock::FakeDb.new opts
          temp_db.pages << page
          temp_db.pages.first
        end

        # Build a fake page by using FakeDb engine.
        #
        # @param [Hash] opts ({}) Configuration options (see #initialize).
        # @option opts [String] :url ('https://example.com') Page url.
        #
        # @return [Hash]
        def self.build_fake_page opts = {}
          page = {
            'url' => (opts[:url] || 'https://example.com')
          }
          build_page page, opts
        end

        # Clean an URL to remove fragment, lowercase schema and host, and sort
        #   query string.
        #
        # @param [String] raw_url URL to clean.
        #
        # @return [URI::HTTPS]
        def self.clean_uri_obj raw_url
          url = URI.parse(raw_url)
          url.hostname = url.hostname.downcase
          url.fragment = nil

          # Sort query string keys
          unless url.query.nil?
            query_string = CGI.parse(url.query)
            keys = query_string.keys.sort
            data = []
            keys.each do |key|
              query_string[key].each do |value|
                data << "#{URI.encode key}=#{URI.encode value}"
              end
            end
            url.query = data.join('&')
          end
          url
        end

        # Clean an URL to remove fragment, lowercase schema and host, and sort
        #   query string.
        #
        # @param [String] raw_url URL to clean.
        #
        # @return [String]
        def self.clean_uri raw_url
          clean_uri_obj(raw_url).to_s
        end

        # Format headers for gid generation.
        # @private
        #
        # @param [Hash,nil] headers Headers hash.
        #
        # @return [Hash]
        def self.format_headers headers
          return '' if headers.nil?
          data = []
          headers.each do |key, value|
            unless value.is_a? Array
              data << "#{key.downcase}:#{value.to_s}"
              next
            end
            data << "#{key.downcase}:#{value.sort.join ','}"
          end
          data.sort.join ';'
        end

        # Identify whenever it has a default_fetch_type.
        # @private
        #
        # @param [String,nil] fetch_type Fetch type.
        #
        # @return [Boolean] `true` when default value, else `false`.
        def self.is_default_fetch_type? fetch_type
          return true if fetch_type.nil?
          return true if fetch_type === DEFAULT_FETCH_TYPE
          false
        end

        # Identify whenever a driver hash is empty.
        # @private
        #
        # @param [Hash,nil] driver Driver hash.
        #
        # @return [Boolean] `true` when empty, else `false`.
        def self.is_driver_empty? driver
          return true if driver.nil?
          return true unless driver.is_a? Hash
          return false if driver['name'].to_s.strip != ''
          return false if driver['code'].to_s.strip != ''
          return false if driver['pre_code'].to_s.strip != ''
          return false if !driver['stealth'].nil? && !!driver['stealth']
          return false if !driver['enable_images'].nil? && !!driver['enable_images']
          return false if !driver['goto_options'].nil? && driver['goto_options'].is_a?(Hash) && driver['goto_options'].keys.length > 0
          true
        end

        # Identify whenever a display hash is empty.
        # @private
        #
        # @param [Hash,nil] display Display hash.
        #
        # @return [Boolean] `true` when empty, else `false`.
        def self.is_display_empty? display
          return true if display.nil?
          return true unless display.is_a? Hash
          return false if !display['width'].nil? && display['width'].to_f.ceil > 0
          return false if !display['height'].nil? && display['height'].to_f.ceil > 0
          true
        end

        # Identify whenever a screenshot hash is empty.
        # @private
        #
        # @param [Hash,nil] screenshot Screenshot hash.
        #
        # @return [Boolean] `true` when empty, else `false`.
        def self.is_screenshot_empty? screenshot
          return true if screenshot.nil?
          return true unless screenshot.is_a? Hash
          return true if screenshot['take_screenshot'].nil? || !screenshot['take_screenshot']
          return true if !screenshot['options'].nil? && !screenshot['options'].is_a?(Hash)
          return false
        end

        # Identify whenever a hash is empty.
        # @private
        #
        # @param [Hash,nil] hash Hash to validate.
        #
        # @return [Boolean] `true` when empty, else `false`.
        def self.is_hash_empty? hash
          return true if hash.nil?
          return true unless hash.is_a? Hash
          return false if hash.keys.length > 0
          true
        end

        # Build a job with defaults by using FakeDb engine.
        #
        # @param [Hash] job Job initial values.
        # @param [Hash] opts ({}) Configuration options (see #initialize).
        #
        # @return [Hash]
        def self.build_job job, opts = {}
          temp_db = DhEasy::Core::Mock::FakeDb.new opts
          temp_db.jobs << job
          temp_db.jobs.last
        end

        # Build a fake job by using FakeDb engine.
        #
        # @param [Hash] opts ({}) Configuration options (see #initialize).
        # @option opts [String] :scraper_name (nil) Scraper name.
        # @option opts [Integer] :job_id (nil) Job id.
        # @option opts [String] :status ('done').
        #
        # @return [Hash]
        def self.build_fake_job opts = {}
          job = {
            'job_id' => opts[:job_id],
            'scraper_name' => opts[:scraper_name],
            'status' => (opts[:status] || 'done')
          }
          build_job job, opts
        end

        # Return a timestamp
        #
        # @param [Time] time (nil) Time from which to get time stamp.
        #
        # @return [String]
        def self.time_stamp time = nil
          time = Time.new if time.nil?
          time.utc.strftime('%FT%T.%6N').gsub(/[0.]+\Z/,'') << "Z"
        end

        # Get current job or create new one from values.
        #
        # @param [Integer] target_job_id (nil) Job id to ensure existance.
        #
        # @return [Hash]
        def ensure_job target_job_id = nil
          target_job_id = job_id if target_job_id.nil?
          job = jobs.find{|v|v['job_id'] == target_job_id}
          return job unless job.nil?
          job = {
            'job_id' => target_job_id,
            'scraper_name' => scraper_name,
          }
          job['status'] = 'active' unless target_job_id != job_id
          jobs << job
          jobs.last
        end

        # Fake scraper_name.
        # @return [String,nil]
        def scraper_name
          @scraper_name ||= 'my_scraper'
        end

        # Set fake scraper_name value.
        def scraper_name= value
          job = ensure_job
          @scraper_name = value
          job['scraper_name'] = scraper_name
        end

        # Fake job id.
        # @return [Integer,nil]
        def job_id
          @job_id ||= generate_job_id
        end

        # Set fake job id value.
        def job_id= value
          @job_id = value
          ensure_job
          job_id
        end

        # Current fake page gid.
        # @return [Integer,nil]
        def page_gid
          @page_gid ||= self.fake_uuid
        end

        # Set current fake page gid value.
        def page_gid= value
          @page_gid = value
        end

        # Current UUID algorithm.
        # @return [Enumerator,nil]
        def uuid_algorithm
          @uuid_algorithm ||= DEFAULT_UUID_ALGORITHM
        end

        # Set current UUID algorithm value.
        # @error [ArgumentError] Whenever an invalid algorithm is provided
        def uuid_algorithm= value
          unless value.nil? || VALID_UUID_ALGORITHMS.include?(value)
            raise ArgumentError.new("Invalid UUID algorithm, valid values are :md5, :sha1, :sha256")
          end
          @uuid_algorithm = value
        end

        # Enable page gid override on page or output insert.
        def enable_page_gid_override
          @allow_page_gid_override = true
        end

        # Disable page gid override on page or output insert.
        def disable_page_gid_override
          @allow_page_gid_override = false
        end

        # Specify whenever page gid overriding by user is allowed on page or
        #   output insert.
        #
        # @return [Boolean] `true` when allowed, else `false`.
        def allow_page_gid_override?
          @allow_page_gid_override ||= false
        end

        # Enable job id override on page or output insert.
        def enable_job_id_override
          @allow_job_id_override = true
        end

        # Disable job id override on page or output insert.
        def disable_job_id_override
          @allow_job_id_override = false
        end

        # Specify whenever job id overriding by user is allowed on page or
        #   output insert.
        #
        # @return [Boolean] `true` when allowed, else `false`.
        def allow_job_id_override?
          @allow_job_id_override ||= false
        end

        # Initialize fake database.
        #
        # @param [Hash] opts ({}) Configuration options.
        # @option opts [Integer,nil] :job_id Job id default value.
        # @option opts [String,nil] :scraper_name Scraper name default value.
        # @option opts [String,nil] :page_gid Page gid default value.
        # @option opts [Boolean, nil] :allow_page_gid_override (false) Specify
        #   whenever page gid can be overrided on page or output insert.
        # @option opts [Boolean, nil] :allow_job_id_override (false) Specify
        #   whenever job id can be overrided on page or output insert.
        # @option opts [Enumerator, nil] :uuid_algorithm (:md5) Specify the
        #   algorithm to be used to generate UUID values.
        def initialize opts = {}
          self.job_id = opts[:job_id]
          self.scraper_name = opts[:scraper_name]
          self.page_gid = opts[:page_gid]
          self.uuid_algorithm = opts[:uuid_algorithm]
          @allow_page_gid_override = opts[:allow_page_gid_override].nil? ? false : !!opts[:allow_page_gid_override]
          @allow_job_id_override = opts[:allow_job_id_override].nil? ? false : !!opts[:allow_job_id_override]
        end

        # Generate a fake UUID using the configured uuid algorithm.
        #
        # @param seed (nil) Object to use as seed for uuid.
        #
        # @return [String]
        def fake_uuid seed = nil
          self.class.fake_uuid seed, self.uuid_algorithm
        end

        # Generate a fake scraper name.
        #
        # @return [String]
        def generate_scraper_name
          Faker::Internet.unique.slug
        end

        # Generate a fake job_id.
        #
        # @return [Integer]
        def generate_job_id
          jobs.count < 1 ? 1 : (jobs.max{|a,b|a['job_id'] <=> b['job_id']}['job_id'] + 1)
        end

        # Get output keys with key generators to emulate saving on db.
        # @private
        #
        # @return [Hash]
        def job_defaults
          @job_defaults ||= {
            'job_id' => lambda{|job| generate_job_id},
            'scraper_name' => lambda{|job| generate_scraper_name},
            'status' => 'done',
            'created_at' => lambda{|job| Time.now}
          }
        end

        # Stored job collection
        #
        # @return [DhEasy::Core::SmartCollection]
        def jobs
          return @jobs unless @jobs.nil?
          collection = self.class.new_collection JOB_KEYS,
            defaults: job_defaults
          collection.bind_event(:before_defaults) do |collection, raw_item|
            DhEasy::Core.deep_stringify_keys raw_item
          end
          collection.bind_event(:before_insert) do |collection, item, match|
            item['job_id'] ||= generate_job_id
            item
          end
          @jobs ||= collection
        end

        # Generate a fake UUID based on page data:
        #   * url
        #   * method
        #   * headers
        #   * fetch_type
        #   * cookie
        #   * no_redirect
        #   * body
        #   * ua_type
        #
        # @param [Hash] page_data Page data.
        #
        # @return [String]
        def generate_page_gid page_data
          # ensure page url
          return "" if page_data['url'].nil? || page_data['url'].to_s.strip === ''

          # calculate extra fields, keep field order to match datahen
          data = []
          data << "method:#{page_data['method'].to_s.downcase}"
          no_url_encode = (!page_data['no_url_encode'].nil? && !!page_data['no_url_encode'])
          uri = self.class.clean_uri_obj(page_data['url'])
          url = (no_url_encode ? page_data['url'].to_s.lstrip : uri.to_s)
          data << "url:#{url}"
          headers = self.class.format_headers page_data['headers']
          data << "headers:#{headers}"
          data << "body:#{page_data['body'].to_s}"
          no_redirect = (!page_data['no_redirect'].nil? && !!page_data['no_redirect'])
          data << "no_redirect:#{no_redirect.to_s}"
          ua_type = (page_data['ua_type'].to_s === '') ? 'desktop' : page_data['ua_type']
          data << "ua_type:#{ua_type}"

          # complex fields
          data << "fetch_type:#{page_data['fetch_type']}" unless self.class.is_default_fetch_type? page_data['fetch_type']
          # keep this cookie logic to match datahen
          data << "cookie:#{page_data['cookie'].split(/;\s*/).sort.join(';')}" if page_data['cookie'].to_s.strip != ''
          data << "http2:true" if page_data.has_key?('http2') && !page_data['http2'].nil? && !!page_data['http2']
          data << "driverName:#{page_data['driver']['name']}" unless self.class.is_driver_empty? page_data['driver']
          unless self.class.is_display_empty? page_data['display']
            data << "display:#{page_data['display']['width']}x#{page_data['display']['height']}"
          end
          unless self.class.is_screenshot_empty? page_data['screenshot']
            checksum = self.fake_uuid JSON.generate(page_data['screenshot'])
            data << "screenshot:#{checksum}"
          end

          # generate GID
          seed = data.join('|')
          checksum = self.fake_uuid seed
          "#{uri.hostname}-#{checksum}"
        end

        # Get page keys with key generators to emulate saving on db.
        # @private
        #
        # @return [Hash]
        def page_defaults
          @page_defaults ||= {
            'job_id' => lambda{|page| job_id},
            'url' => nil,
            'status' => 'to_fetch',
            'page_type' => 'default',
            'method' => 'GET',
            'headers' => {},
            'fetch_type' => DEFAULT_FETCH_TYPE,
            'cookie' => nil,
            'no_redirect' => false,
            'body' => nil,
            'ua_type' => 'desktop',
            'no_url_encode' => false,
            'http2' => false,
            'priority' => 0,
            'parsing_try_count' => 0,
            'parsing_fail_count' => 0,
            'fetching_at' => '0001-01-01T00:00:00Z',
            'fetching_try_count' => 0,
            'refetch_count' => 0,
            'fetched_from' => '',
            'content_size' => 0,
            'force_fetch' => false,
            'driver' => {
              'name' => '',
              'pre_code' => '',
              'code' => '',
              'goto_options' => nil,
              'stealth' => false,
              'enable_images' => false
            },
            'display' => {
              'width' => 0,
              'height' => 0
            },
            'screenshot' => {
              'take_screenshot' => false,
              'options' => nil
            },
            'driver_log' => nil,
            'vars' => {}
          }
        end

        # Stored page collection.
        #
        # @return [DhEasy::Core::SmartCollection]
        #
        # @note Page gid will be replaced on insert by an auto generated uuid
        #   unless page gid overriding is enabled
        #   (see #allow_page_gid_override?)
        def pages
          return @pages unless @page.nil?

          defaults = self.page_defaults
          collection = self.class.new_collection PAGE_KEYS,
            defaults: defaults
          collection.bind_event(:before_defaults) do |collection, raw_item|
            item = DhEasy::Core.deep_stringify_keys raw_item
            if !item['driver'].nil? && item['driver'].is_a?(Hash)
              item['driver'] = defaults['driver'].merge item['driver']
            end
            if !item['display'].nil? && item['display'].is_a?(Hash)
              item['display'] = defaults['display'].merge item['display']
            end
            if !item['screenshot'].nil? && item['screenshot'].is_a?(Hash)
              item['screenshot'] = defaults['screenshot'].merge item['screenshot']
            end
            item.delete 'job_id' unless allow_job_id_override?
            item
          end
          collection.bind_event(:before_insert) do |collection, item, match|
            item['driver'] = nil if self.class.is_driver_empty? item['driver']
            item['display'] = nil if self.class.is_display_empty? item['display']
            item['screenshot'] = nil if self.class.is_screenshot_empty? item['screenshot']
            item['headers'] = nil if self.class.is_hash_empty? item['headers']
            item['vars'] = nil if self.class.is_hash_empty? item['vars']
            uri = self.class.clean_uri_obj(item['url'])
            item['hostname'] = uri.hostname
            uri = nil
            if item['gid'].nil? || !allow_page_gid_override?
              item['gid'] = generate_page_gid item
            end

            # 30 days = 60 * 60 * 24 * 30 = 2592000
            item['freshness'] ||= self.class.time_stamp (Time.now - 2592000)
            item['to_fetch'] ||= self.class.time_stamp
            item['created_at'] ||= self.class.time_stamp
            item
          end
          collection.bind_event(:after_insert) do |collection, item|
            ensure_job item['job_id']
          end
          @pages ||= collection
        end

        # Generate a fake UUID for outputs.
        #
        # @param [Hash] data Output data.
        #
        # @return [String]
        def generate_output_id data
          # Generate random UUID to match Datahen behavior
          self.fake_uuid
        end

        # Get output keys with key generators to emulate saving on db.
        # @private
        #
        # @return [Hash]
        def output_defaults
          @output_defaults ||= {
            '_collection' => DEFAULT_COLLECTION,
            '_job_id' => lambda{|output| job_id},
            '_created_at' => lambda{|output| self.class.time_stamp},
            '_gid' => lambda{|output| page_gid}
          }
        end

        # Stored output collection
        #
        # @return [DhEasy::Core::SmartCollection]
        def outputs
          return @outputs unless @outputs.nil?
          collection = self.class.new_collection OUTPUT_KEYS,
            defaults: output_defaults
          collection.bind_event(:before_defaults) do |collection, raw_item|
            item = DhEasy::Core.deep_stringify_keys raw_item
            item.delete '_job_id' unless allow_job_id_override?
            item.delete '_gid_id' unless allow_page_gid_override?
            item
          end
          collection.bind_event(:before_insert) do |collection, item, match|
            item['_id'] ||= generate_output_id item
            item
          end
          collection.bind_event(:after_insert) do |collection, item|
            ensure_job item['_job_id']
          end
          @outputs ||= collection
        end

        # Match data to filters.
        # @private
        #
        # @param data Hash containing data.
        # @param filters Filters to apply on match.
        #
        # @return [Boolean]
        #
        # @note Missing and `nil` values on `data` will match when `filters`'
        #   field is `nil`.
        def match? data, filters
          filters.each do |key, value|
            return false if data[key] != value
          end
          true
        end

        # Search items from a collection.
        #
        # @param [Symbol] collection Allowed values: `:outputs`, `:pages`.
        # @param [Hash] filter Filters to query.
        # @param [Integer] offset (0) Search results offset.
        # @param [Integer,nil] limit (nil) Limit search results count. Set to `nil` for unlimited.
        #
        # @raise ArgumentError On unknown collection.
        #
        # @note _Warning:_ It uses table scan to filter and should be used on test suites only.
        def query collection, filter, offset = 0, limit = nil
          return [] unless limit.nil? || limit > 0

          # Get collection items
          items = case collection
          when :outputs
            outputs
          when :pages
            pages
          when :jobs
            jobs
          else
            raise ArgumentError.new "Unknown collection #{collection}."
          end

          # Search items
          count = 0
          matches = []
          items.each do |item|
            next unless match? item, filter
            count += 1

            # Skip until offset
            next unless offset < count
            # Break on limit reach
            break unless limit.nil? || matches.count < limit
            matches << item
          end
          matches
        end

        # Refetch a page.
        #
        # @param [Integer] job_id Page's job_id to refetch.
        # @param [String] gid Page's gid to refetch.
        def refetch job_id, gid
          page = pages.find_match('gid' => gid, 'job_id' => job_id)
          raise Exception.new("Page not found with job_id \"#{job_id}\" gid \"#{gid}\"") if page.nil?
          page['status'] = 'to_fetch'
          page['freshness'] = self.class.time_stamp
          page['to_fetch'] = self.class.time_stamp
          page['fetched_from'] = nil
          page['fetching_at'] = '2001-01-01T00:00:00Z'
          page['fetched_at'] = nil
          page['fetching_try_count'] = 0
          page['effective_url'] = nil
          page['parsing_at'] = nil
          page['parsing_failed_at'] = nil
          page['parsed_at'] = nil
          page['parsing_try_count'] = 0
          page['parsing_fail_count'] = 0
          page['parsing_updated_at'] = '2001-01-01T00:00:00Z'
          page['response_checksum'] = nil
          page['response_status'] = nil
          page['response_status_code'] = nil
          page['response_headers'] = nil
          page['response_cookie'] = nil
          page['response_proto'] = nil
          page['content_type'] = nil
          page['content_size'] = 0
          page['failed_response_status_code'] = nil
          page['failed_response_headers'] = nil
          page['failed_response_cookie'] = nil
          page['failed_effective_url'] = nil
          page['failed_at'] = nil
          page['failed_content_type'] = nil
        end

        # Reparse a page.
        #
        # @param [Integer] job_id Page's job_id to reparse.
        # @param [String] gid Page's gid to reparse.
        def reparse job_id, gid
          page = pages.find_match('gid' => gid, 'job_id' => job_id)
          raise Exception.new("Page not found with job_id \"#{job_id}\" gid \"#{gid}\"") if page.nil?
          page['status'] = 'to_parse'
          page['parsing_at'] = nil
          page['parsing_failed_at'] = nil
          page['parsing_updated_at'] = '2001-01-01T00:00:00Z'
          page['parsed_at'] = nil
          page['parsing_try_count'] = 0
          page['parsing_fail_count'] = 0
        end
      end
    end
  end
end
