require 'capybara/dsl'
require 'capybara/poltergeist'

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.run_server = false
Capybara.app_host = "http://jenkins.corp.avvo.com"

class Crawler
  include Capybara::DSL


  def find_suites(job)
    visit "/job/#{job}/"
    p page.find("#matrix").all("a")
  end

  def crawl(path)

    visit path
    body = page.text

    # use source here b/c it includes newlines
    find_errors(source)
  end

  def find_errors(body)
    found_error = false
    source.each_line do |line|
      if found_error
        p line
        found_error = false
      end

      found_error = process_line(line)
    end
  end

  def process_line(line)
    return true if line =~ /\d\) Error:|\d\) Failure:/
  end

  def errors?(body)
    errors = body.match(/[^0] failures|[^0] errors/)
    p errors.inspect
  end

end

acceptance_suites = ["amos/advisor", "amos/content", "amos/directory", "amos/homepage", "amos/login", "amos/seo", "amos/services", "api", "advisor", "sales", "shed", "syndication", "services" ]
suites = acceptance_suites.map { |item| "SUITE=#{CGI::escape(item)},label_exp=phantomjs" }

suites.each do |suite|
 Crawler.new.crawl("http://jenkins.corp.avvo.com/job/avvo_acceptance-stag/lastBuild/#{suite}/consoleText")
end

# Crawler.new.find_suites("avvo_acceptance-stag")
