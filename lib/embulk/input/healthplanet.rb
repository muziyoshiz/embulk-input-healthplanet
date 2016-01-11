require 'faraday'
require 'faraday-cookie_jar'
require 'oga'
require 'nkf'
require 'json'
require 'time'

module Embulk
  module Input

    class Healthplanet < InputPlugin
      Plugin.register_input("healthplanet", self)

      # Default redirect URI for Client Application
      REDIRECT_URI = 'https://www.healthplanet.jp/success.html'

      # Default scope
      DEFAULT_SCOPE = 'innerscan'

      # Default response type
      DEFAULT_RESPONSE_TYPE = 'code'

      # Default grant type
      DEFAULT_GRANT_TYPE = 'authorization_code'

      # All tags for innerscan
      ALL_TAGS = '6021,6022,6023,6024,6025,6026,6027,6028,6029'

      def self.transaction(config, &control)
        # configuration code:
        task = {
          # Account for Health Planet
          "login_id" => config.param("login_id", :string),
          "password" => config.param("password", :string),
          # Credential for embulk-input-healthplanet, application type "Client Application"
          "client_id" => config.param("client_id", :string),
          "client_secret" => config.param("client_secret", :string),
        }

        columns = [
          Column.new(0, "time", :timestamp),
          Column.new(1, "model", :string),
          Column.new(2, "weight", :double),
          Column.new(3, "body fat %", :double),
          Column.new(4, "muscle mass", :double),
          Column.new(5, "muscle score", :long),
          Column.new(6, "visceral fat level 2", :double),
          Column.new(7, "visceral fat level 1", :long),
          Column.new(8, "basal metabolic rate", :long),
          Column.new(9, "metabolic age", :long),
          Column.new(10, "estimated bone mass", :double),
          # Not supported by Health Planet API Ver. 1.0
#          Column.new(11, "body water mass", :string),
        ]

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}
        return next_config_diff
      end

      def init
        login_id = task["login_id"]
        password = task["password"]
        client_id = task["client_id"]
        client_secret = task["client_secret"]

        # Setup connection
        @conn = Faraday.new(:url => 'https://www.healthplanet.jp') do |faraday|
          faraday.request  :url_encoded
          faraday.response :logger
          faraday.use      :cookie_jar
          faraday.adapter  Faraday.default_adapter
        end

        # Request Authentication page: /oauth/auth
        response = @conn.get do |req|
          req.url '/oauth/auth'
          req.params[:client_id]     = client_id
          req.params[:redirect_uri]  = REDIRECT_URI
          req.params[:scope]         = DEFAULT_SCOPE
          req.params[:response_type] = DEFAULT_RESPONSE_TYPE
        end

        # Login and set session information
        response = @conn.post 'login_oauth.do', { :loginId => login_id, :passwd => password, :send => '1', :url => "https://www.healthplanet.jp/oauth/auth?client_id=#{client_id}&redirect_uri=#{REDIRECT_URI}&scope=#{DEFAULT_SCOPE}&response_type=#{DEFAULT_RESPONSE_TYPE}" }

        unless response.status == 302
          # TODO return error in Embulk manner
          p "login failure"
        end

        # Get auth page again with JSESSIONID
        response = @conn.get do |req|
          req.url '/oauth/auth'
          req.params[:client_id]     = client_id
          req.params[:redirect_uri]  = REDIRECT_URI
          req.params[:scope]         = DEFAULT_SCOPE
          req.params[:response_type] = DEFAULT_RESPONSE_TYPE
        end

        # Read oauth_token
        document = Oga.parse_html(NKF.nkf('-Sw', response.body))
        oauth_token = document.at_xpath('//input[@name="oauth_token"]').get("value")

        # Post /oauth/approval.do
        response = @conn.post '/oauth/approval.do', { :approval => 'true', :oauth_token => oauth_token }

        # Read code
        document = Oga.parse_html(NKF.nkf('-Sw', response.body))
        code = document.at_xpath('//textarea[@id="code"]').text

        # Get request token
        response = @conn.post do |req|
          req.url '/oauth/token'
          req.params[:client_id]     = client_id
          req.params[:client_secret] = client_secret
          req.params[:redirect_uri]  = REDIRECT_URI
          req.params[:code]          = code
          req.params[:grant_type]    = DEFAULT_GRANT_TYPE
        end

        tokens = JSON.parse(response.body)
        @access_token = tokens["access_token"]
      end

      def run
        response = @conn.get do |req|
          req.url 'status/innerscan.json'
          req.params[:access_token] = @access_token
          # 0: registered time, 1: measured time
          req.params[:date] = 1
          # req.params[:from] = '20160101000000'
          # req.params[:to]   = '20160201000000'
          req.params[:tag]  = ALL_TAGS
        end

        data = JSON.parse(response.body)

        result = {}

        data['data'].each do |record|
          date = Time.strptime(record['date'], '%Y%m%d%H%M')

          result[date] ||= {}
          result[date]['model'] ||= record['model']
          result[date][record['tag']]  = record['keydata']
        end

        result.keys.sort.each do |date|
          page = Array.new(11)
          page[0] = date
          result[date].each do |key, value|
            case key
            when 'model'
              page[1] = value
            when '6021'
              # weight
              page[2] = value.to_f
            when '6022'
              # body fat %
              page[3] = value.to_f
            when '6023'
              # muscle mass
              page[4] = value.to_f
            when '6024'
              # muscle score
              page[5] = value.to_i
            when '6025'
              # visceral fat level 2
              page[6] = value.to_f
            when '6026'
              # visceral fat level 1
              page[7] = value.to_i
            when '6027'
              # basal metabolic rate
              page[8] = value.to_i
            when '6028'
              # metabolic age
              page[9] = value.to_i
            when '6029'
              # estimated bone mass
              page[10] = value.to_f
            end
          end

          page_builder.add(page)
        end

        page_builder.finish

        task_report = {}
        return task_report
      end
    end

  end
end
