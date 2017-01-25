require 'test_helper'

class TasksControllerTest < ActionDispatch::IntegrationTest

  test "verfiy expand_all tasks no error rendering" do
    sign_in
    res = Task.all
    ids = ""
    res.each do |r|
      if ids != ""
        ids += ","
      end
      ids += r.id.to_s
    end
    xhr :get, "/tasks/expandall.js?result_ids=#{ids}"
    assert_response :success
  end

  test "verfiy events_tasks tasks no error rendering" do
    sign_in
    xhr :get, "/tasks/events.js"
    assert_response :success
  end

  test "verfiy get_metadata tasks no error rendering" do
    sign_in
    res = Task.first
    xhr :get, "/tasks/#{res.id}/get_metadata"
    assert_response :success
  end

  test "verfiy tasks index page no error rendering" do
    sign_in
    get "/tasks"
    assert_response :success
  end

  test "new task page no error rendering" do
    sign_in
    get "/tasks/new"
    assert_response :success
  end

  test "verfiy summary_tasks no error rendering" do
    sign_in
    res = Task.first
    xhr :get, "/tasks/#{res.id}/summary.js"
    assert_response :success
  end

  test "individual task loads with no error" do
    sign_in
    res = Task.first
    get "/tasks/#{res.id}"
    assert_response :success
  end

  test "individual task edit loads with no error" do
    sign_in
    res = Task.first
    get "/tasks/#{res.id}/edit"
    assert_response :success
  end

  test "bulk update tasks no error rendering" do
    sign_in
    ids = []
    res = Task.all
    #ids = ""
    res.each do |r|
      #if ids != ""
      #  ids += ","
      #end
      #ids += r.id.to_s
      ids.push r.id
    end
    ActiveSupport::Deprecation.silence do
      post "/tasks/bulk_update.html", {task_ids: ids, commit: "Disable"}
      assert_response :redirect
      post "/tasks/bulk_update.html", {task_ids: ids, commit: "Enable"}
      assert_response :redirect
    end
  end


  test "individual task disable and enable loads with no error" do
    sign_in
    res = Task.first
    post "/tasks/#{res.id}/disable"
    assert_response :redirect
    post "/tasks/#{res.id}/enable"
    assert_response :redirect
  end

  test "individual task run loads with no error" do
    sign_in
    res = Task.first
    get "/tasks/#{res.id}/run"
    assert_response :redirect
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

# options_tasks GET      /tasks/options(.:format)                                     task_types#options
#                     run_tasks GET      /tasks/run(.:format)                                         tasks#run
#             bulk_update_tasks POST     /tasks/bulk_update(.:format)                                 tasks#bulk_update
#                  events_tasks GET      /tasks/events(.:format)                                      tasks#events
#                      run_task GET      /tasks/:id/run(.:format)                                     tasks#run
#             get_metadata_task GET      /tasks/:id/get_metadata(.:format)                            tasks#get_metadata
#                   enable_task POST     /tasks/:id/enable(.:format)                                  tasks#enable
#                  disable_task POST     /tasks/:id/disable(.:format)                                 tasks#disable
#                  summary_task GET      /tasks/:id/summary(.:format)                                 tasks#summary
#                  options_task GET      /tasks/:id/options(.:format)                                 task_types#options
#                         tasks GET      /tasks(.:format)                                             tasks#index
#                               POST     /tasks(.:format)                                             tasks#create
#                      new_task GET      /tasks/new(.:format)                                         tasks#new
#                     edit_task GET      /tasks/:id/edit(.:format)                                    tasks#edit
#                          task GET      /tasks/:id(.:format)                                         tasks#show
#                               PATCH    /tasks/:id(.:format)                                         tasks#update
#                               PUT      /tasks/:id(.:format)                                         tasks#update
