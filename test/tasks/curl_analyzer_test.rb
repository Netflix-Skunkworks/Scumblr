require "test_helper"
require "byebug"

class GithubAnalyzerTest < ActiveSupport::TestCase
  sitemap_result = Result.where(id: 12).first
  http_server=nil

  puts "[*] Creating test files 1"
  tmp_folder = "/tmp/curl_test"

  FileUtils.rm_rf(tmp_folder)
  FileUtils::mkdir_p tmp_folder

  popen4("ruby -run -ehttpd . -p8000")
  Dir.chdir tmp_folder do
    http_server = popen4("ruby -run -ehttpd . -p8000;")
  end
  sleep(3)

  puts "[*] Killing for server"
  `kill -9 #{http_server[0]}`
  sleep(2)

end
