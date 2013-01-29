require 'json'
require 'nokogiri'
require 'open-uri'
require 'logger'

module JenkinsRequest

  def getJSON(url_fragment)
    puts "Requesting #{url_fragment} from Jenkins"
    return JSON.parse(_get(url_fragment).read)
  end

  def get(url_fragment)
    return open("#{settings.jenkinsUri}#{url_fragment}", "Authorization" => "Basic " + settings.jenkinsAuth)
  end

end
