require 'json'
require 'open-uri'


def get(uri)
	JSON.parse(open(uri, "Authorization" => "Basic YnVpbGRtb25pdG9yOmJ1aWxkbW9uaXRvcg==").read)
end