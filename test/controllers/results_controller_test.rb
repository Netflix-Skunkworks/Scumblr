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
    assert_match(/.*#{Regexp.escape(res.title)}.*/, @response.body)
  end

  test "verfiy search by URL works" do
    sign_in
    #search by url
    post "/results/search", {"q[url_cont]" => "netflix"}
    assert_response :success
    assert_match(/.*netflix.*/, @response.body)
  end
end