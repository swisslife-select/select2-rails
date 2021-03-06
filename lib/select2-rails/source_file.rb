require "thor"
require "json"
require "httpclient"

class SourceFile < Thor
  include Thor::Actions

  DestinationRoot = "app/assets"
  GitHub          = 'https://github.com/ivaynberg/select2'


  desc "fetch source files", "fetch source files from GitHub"
  def fetch
    filtered_tags = fetch_tags
    tag = select("Which tag do you want to fetch?", filtered_tags)
    self.destination_root = DestinationRoot

    get "#{GitHub}/raw/#{tag}/select2.png", "images/select2.png"
    get "#{GitHub}/raw/#{tag}/select2-spinner.gif", "images/select2-spinner.gif"
    get "#{GitHub}/raw/#{tag}/select2.css", "stylesheets/select2.css"
    get "#{GitHub}/raw/#{tag}/select2.js", "javascripts/select2.js"
  end

  desc "fetch all translation files", "fetch all translation files"
  def fetch_translation_files
    self.destination_root = DestinationRoot

    list_translation_files.each do |translation_file|
      get "#{GitHub}/raw/master/#{translation_file}", "javascripts/#{translation_file}"
    end
  end

  desc "convert css to scss file", "convert css to scss file"
  def convert
    self.destination_root = "app/assets"
    inside destination_root do
      run("cp stylesheets/select2.css stylesheets/select2.css.scss")
      gsub_file 'stylesheets/select2.css.scss', '(select2-spinner.gif)', "('select2-spinner.gif')"
      gsub_file 'stylesheets/select2.css.scss', '(select2.png)', "('select2.png')"
      gsub_file 'stylesheets/select2.css.scss', ' url', ' image-url'
    end
  end

  desc "clean up useless files", "clean up useless files"
  def cleanup
    self.destination_root = "app/assets"
    remove_file "stylesheets/select2.css"
  end
  private
  def fetch_tags
    http = HTTPClient.new
    response = JSON.parse(http.get("https://api.github.com/repos/ivaynberg/select2/tags").body)
    response.map{|tag| tag["name"]}.sort
  end
  def select msg, elements
    elements.each_with_index do |element, index|
      say(block_given? ? yield(element, index + 1) : ("#{index + 1}. #{element.to_s}"))
    end
    result = ask(msg).to_i
    elements[result - 1]
  end
  def list_translation_files
    http             = HTTPClient.new
    response         = JSON.parse(http.get("https://api.github.com/repos/ivaynberg/select2/contents/").body)
    translation_files = response.select { |e| e['type'] == 'file' && e['name'] =~ /^select2_locale_.*\.js$/ }

    translation_files.map { |e| e['path']  }
  end
end
