require 'json'
require 'nokogiri'
require 'open-uri'

class JenkinsRequest

  def getJSON(url_fragment)
    return JSON.parse(_get(url_fragment).read)
  end

  private

  def get(url_fragment)
    return open("#{settings.jenkinsUri}#{url_fragment}", "Authorization" => "Basic " + settings.jenkinsAuth)
  end

end
