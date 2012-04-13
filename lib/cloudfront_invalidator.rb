require 'rubygems' # may not be needed
require 'openssl'
require 'digest/sha1'
require 'net/https'
require 'base64'

class CloudfrontInvalidator

	def initialize(aws_account, aws_secret, distribution)
		@aws_account = aws_account
		@aws_secret = aws_secret
		@distribution = distribution
	end

	def invalidate(path)
		date = Time.now.strftime("%a, %d %b %Y %H:%M:%S %Z")
		digest = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), @aws_secret, date)).strip
		uri = URI.parse("https://cloudfront.amazonaws.com/2010-08-01/distribution/#{@distribution}/invalidation")

		req = Net::HTTP::Post.new(uri.path)
		req.initialize_http_header({
		  'x-amz-date' => date,
		  'Content-Type' => 'text/xml',
		  'Authorization' => "AWS %s:%s" % [@aws_account, digest]
		})
		req.body = %|<InvalidationBatch><Path>#{path}</Path><CallerReference>SOMETHING_SPECIAL_#{Time.now.utc.to_i}</CallerReference></InvalidationBatch>|
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		res = http.request(req)

		# it was successful if response code was a 201
		return res.code == '201'
	end
end