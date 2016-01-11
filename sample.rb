# -*- coding: utf-8 -*-
require 'faraday'
require 'faraday-cookie_jar'
require 'oga'
require 'nkf'
require 'json'

# Account for Health Planet
LOGIN_ID = ''
PASSWORD = ''

# Credentials for embulk-input-healthplanet, application type "Client Application"
CLIENT_ID = ''
CLIENT_SECRET = ''

# Default redirect URI for Client Application
REDIRECT_URI = 'https://www.healthplanet.jp/success.html'

# Default scope
DEFAULT_SCOPE = 'innerscan'

# Default response type
DEFAULT_RESPONSE_TYPE = 'code'

DEFAULT_GRANT_TYPE = 'authorization_code'

# Setup connection
conn = Faraday.new(:url => 'https://www.healthplanet.jp') do |faraday|
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.use      :cookie_jar
  faraday.adapter  Faraday.default_adapter
end

# API Reference
# http://www.healthplanet.jp/apis/api.html

# Request Authentication page: /oauth/auth
response = conn.get do |req|
  req.url '/oauth/auth'
  req.params[:client_id]     = CLIENT_ID
  req.params[:redirect_uri]  = REDIRECT_URI
  req.params[:scope]         = DEFAULT_SCOPE
  req.params[:response_type] = DEFAULT_RESPONSE_TYPE
end

response = conn.post 'login_oauth.do', { :loginId => LOGIN_ID, :passwd => PASSWORD, :send => '1', :url => "https://www.healthplanet.jp/oauth/auth?client_id=197.YvJT0sFdrb.apps.healthplanet.jp&redirect_uri=https://www.healthplanet.jp/success.html&scope=innerscan,sphygmomanometer,pedometer,smug&response_type=code" }

unless response.status == 302
  p "login failure"
end


# Get /oauth/auth again
response = conn.get do |req|
  req.url '/oauth/auth'
  req.params[:client_id]     = CLIENT_ID
  req.params[:redirect_uri]  = REDIRECT_URI
  req.params[:scope]         = DEFAULT_SCOPE
  req.params[:response_type] = DEFAULT_RESPONSE_TYPE
end

body = NKF.nkf('-Sw', response.body)

# Read oauth_token
document = Oga.parse_html(body)
oauth_token = document.at_xpath('//input[@name="oauth_token"]').get("value")

# Post /oauth/approval.do again
response = conn.post '/oauth/approval.do', { :approval => 'true', :oauth_token => oauth_token }

body = NKF.nkf('-Sw', response.body)

document = Oga.parse_html(body)
code = document.at_xpath('//textarea[@id="code"]').text


# Get request token
response = conn.post do |req|
  req.url '/oauth/token'
  req.params[:client_id]     = CLIENT_ID
  req.params[:client_secret] = CLIENT_SECRET
  req.params[:redirect_uri]  = REDIRECT_URI
  req.params[:code]          = code
  req.params[:grant_type]    = DEFAULT_GRANT_TYPE
end

tokens = JSON.parse(response.body)
access_token = tokens["access_token"]


# Get innerscan data
response = conn.get do |req|
  req.url 'status/innerscan.json'
  req.params[:access_token] = access_token
  # 0: registered time, 1: measured time
  req.params[:date] = 1
  req.params[:from] = '20160101000000'
  req.params[:to]   = '20160201000000'
  req.params[:tag]  = '6021,6022,6023,6024,6025,6026,6027,6028,6029'
end

data = JSON.parse(response.body)

print data['birth_date'].to_s + "\n"
print data['height'].to_s + "\n"
print data['sex'].to_s + "\n"

data['data']

result = {}

data['data'].each do |record|
  result[record['date']] ||= {}
  result[record['date']]['model'] = record['model']
  result[record['date']][record['tag']] = record['keydata']
end

p result

