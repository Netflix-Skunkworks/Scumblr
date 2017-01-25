require 'test_helper'

class ResultsControllerTest < ActionDispatch::IntegrationTest
  
  test "should get redirected to login" do
    host! 'localhost:3000'
    get '/'
    assert_response :redirect
  end

  test "results index page loads html" do
    sign_in
    get results_path
    assert_response :success
  end

  test "results index page loads json" do
    sign_in
    get "/results.json"
    parsed = JSON.parse(@response.body)
    assert parsed.size > 0
    assert_response :success
  end

  test "results index page loads csv" do
    sign_in
    get "/results.csv"
    assert_response :success
  end  

  test "test single result page load html" do
    sign_in
    res = Result.first

    #verify page for first result loads properly
    get "/results/#{res.id}"
    assert_response :success
    assert_match(/.*#{Regexp.escape(res.title)}.*/, @response.body)
  end

  test "test single result page load json" do
    sign_in
    res = Result.first
    #verify json for first result loads properly
    get "/results/#{res.id}.json"
    assert_response :success
    #parse the json to make sure it's valid
    JSON.parse(@response.body)
    assert_match(/.*#{Regexp.escape(res.title)}.*/, @response.body)
  end

  test "verify metadata json" do
    sign_in
    res = Result.first

    #verify metadata for first result loads properly
    get "/results/#{res.id}/get_metadata.json"
    assert_response :success

    #parse the json to make sure it's valid
    JSON.parse(@response.body)
    #assert_match(/.*#{Regexp.escape(res.title)}.*/, @response.body)
  end

  test "verfiy search by URL works" do
    sign_in
    #search by url
    post "/results/search", {"q[url_cont]" => "netflix"}
    assert_response :success
    assert_match(/.*netflix.*/, @response.body)
  end

  test "verfiy summary page html" do
    sign_in
    get "/results/dashboard"
    assert_response :success
  end

  test "verfiy expand_all no error rendering" do
    sign_in
    res = Result.all
    ids = ""
    res.each do |r|
      if ids != ""
        ids += ","
      end
      ids += r.id.to_s
    end
    xhr :get, "/results/expandall.js?result_ids=#{ids}"
    assert_response :success
  end

  test "verfiy summary no error rendering" do
    sign_in
    res = Result.first
    xhr :get, "/results/#{res.id}/summary.js"
    assert_response :success
  end

  test "verfiy render_metadata no error rendering" do
    sign_in
    res = Result.first
    xhr :get, "/results/#{res.id}/render_metadata_partial.js"
    assert_response :success
  end

  test "verfiy update_screenshot no error rendering" do
    sign_in
    res = Result.first
    get "/results/#{res.id}/update_screenshot"
    assert_response :success
  end

  test "verfiy post update_screenshot no error rendering" do
    sign_in
    res = Result.first
    post "/results/#{res.id}/update_screenshot", {sketch_url: "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png", scrape_url: "https://www.google.com"}  
    assert_response :success
  end

  test "verify edit_result get renders no errors" do
    sign_in
    res = Result.first
    get "/results/#{res.id}/edit"
    assert_response :success
  end

  test "verify new_result get renders no errors" do
    sign_in
    get "/results/new"
    assert_response :success
  end

  test "verify tag_results get renders no errors" do
    sign_in
    get "/results/tags/1"
    assert_response :success
  end

  test "trying to add a comment to a result" do
    sign_in

    res = Result.first
    post "/results/#{res.id}/comment", {comment: "this is a test"}, {"HTTP_REFERER" => "http://localhost:3000"}
    assert_response :redirect
  end

  test "trying to post to update_multiple_results" do
    sign_in
    res = Result.all
    ids = ""
    res.each do |r|
      if ids != ""
        ids += ","
      end
      ids += r.id.to_s
    end

    post "/results/update_multiple", {result_ids: ids, commit: "Update and Generate Screenshot"}
  end

  test "update metadata via post" do
    sign_in

    res = Result.first
    xhr :post, "/results/#{res.id}/update_metadata.js", {"key[0]"=> "vulnerabilities.[id:1}].severity", "value[0]"=> "high", "target[0]"=>"#drop_11_button"}, {"HTTP_REFERER" => "http://localhost:3000"}
  end



  #commented out until we get status in fixtures
  #test "update status result renders no errors" do
  #  sign_in
  #  res = Result.first
  #  post "/results/#{res.id}/change_status/1.js", {"q[url_cont]" => "netflix"}
  #  assert_response :success
  #  assert_match(/.*netflix.*/, @response.body)
  #end

end

#update_multiple_results POST     /results/update_multiple(.:format)                           results#update_multiple
#              bulk_add_results POST     /results/bulk_add(.:format)                                  results#bulk_add
#                search_results POST     /results/search(.:format)                                    results#index
# workflow_autocomplete_results GET      /results/workflow_autocomplete(.:format)                     results#workflow_autocomplete
#  update_table_columns_results POST     /results/update_table_columns(.:format)                      results#update_table_columns
#SHOULD REMOVE THIS ROUTE?     expandclosedvulns_results GET      /results/expandclosedvulns(.:format)                         results#expandclosedvulns
#  create_vulnerability_results POST     /results/create_vulnerability(.:format)                      results#create_vulnerability
#          update_status_result POST     /results/:id/change_status/:status_id(.:format)              results#update_status
#                comment_result POST     /results/:id/comment(.:format)                               results#comment
#                    tag_result POST     /results/:id/tag(.:format)                                   results#tag
#                   flag_result POST     /results/:id/flag(.:format)                                  results#flag
#                 action_result POST     /results/:id/action/:result_flag_id/step/:stage_id(.:format) results#action
#                 assign_result POST     /results/:id/assign(.:format)                                results#assign
#              subscribe_result POST     /results/:id/subscribe(.:format)                             results#subscribe
#            unsubscribe_result POST     /results/:id/unsubscribe(.:format)                           results#unsubscribe
#             delete_tag_result DELETE   /results/:id/tags/:tag_id(.:format)                          results#delete_tag
#         add_attachment_result POST     /results/:id/add_attachment(.:format)                        results#add_attachment
#      delete_attachment_result DELETE   /results/:id/attachment/:attachment_id(.:format)             results#delete_attachment
#    generate_screenshot_result POST     /results/:id/generate_screenshot(.:format)                   results#generate_screenshot
#      update_screenshot_result POST     /results/:id/update_screenshot(.:format)                     results#update_screenshot
#        update_metadata_result GET|POST /results/:id/update_metadata(.:format)                       results#update_metadata
#           get_metadata_result GET|POST /results/:id/get_metadata(.:format)                          results#get_metadata
#render_metadata_partial_result XGETX|POST /results/:id/render_metadata_partial(.:format)               results#render_metadata_partial
#                               POST     /results(.:format)                                           results#create
#                               PATCH    /results/:id(.:format)                                       results#update
#                               PUT      /results/:id(.:format)                                       results#update
#                               DELETE   /results/:id(.:format)                                       results#destroy