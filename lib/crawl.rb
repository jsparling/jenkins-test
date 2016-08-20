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
    suites = []
    page.find("#matrix").all("a").each do |link|
      suites << link.text
    end

    suites
  end

  def build_numbers()
    visit "/job/avvo_acceptance-stag/api/json"

    p page.text
    return_array = []
    builds = JSON(page.text).fetch("builds")
    builds.each do |build|
      return_array << build.fetch("number")
    end

    return_array
  end

  def crawl(path, build, suite, suite_query)
    visit path

    # use source here b/c it includes newlines
    errors = find_errors(source)
    unless errors.empty?
      link = "http://jenkins.corp.avvo.com/view/Acceptance/job/avvo_acceptance-stag/#{suite_query}/#{build}/console"
      p "#{build} - #{suite} - #{link}"
      p errors.inspect
    end

  end

  def find_errors(body)
    errors = []
    found_error = false
    source.each_line do |line|
      if found_error
        errors << line
        found_error = false
      end

      found_error = process_line(line)
    end
    errors
  end

  def print_error(line)
    p line
  end

  def process_line(line)
    return true if line =~ /\d\) Error:|\d\) Failure:/
  end

  def errors?(body)
    errors = body.match(/[^0] failures|[^0] errors/)
    p errors.inspect
  end

end

builds = Crawler.new.build_numbers
p builds

acceptance_suites = Crawler.new.find_suites("avvo_acceptance-stag")
# suites = acceptance_suites.map { |item| "#{CGI::escape(item)},label_exp=phantomjs" }
builds.first(10).each do |build|
  acceptance_suites.each do |suite|
    suite_query= "#{CGI::escape(suite)},label_exp=phantomjs"
    Crawler.new.crawl("/job/avvo_acceptance-stag/#{build}/#{suite_query}/consoleText", build, suite, suite_query )
  end
end

Crawler.new.find_suites("avvo_acceptance-stag")
