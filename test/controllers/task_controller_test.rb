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

  # Scott Tests for task search ransack
  test "verfiy search endpoint returns json" do
    sign_in
    get "/tasks/search"
    assert response.body.include? "id"
    assert JSON.parse(response.body) ? true : false
  end

  test "verfiy search endpoint returns filtered json" do
    # we should get back some fixtures for this filter
    sign_in
    get "/tasks/search?q[task_type_eq]=ScumblrTask::GithubSyncAnalyzer"
    json_response = JSON.parse(response.body)
    assert json_response.count >= 0
  end

  test "verfiy search endpoint returns resolved system metadata when configured" do
    # we should get back expanded system metadata for this fixture
    sign_in
    get "/tasks/search?q[task_type_eq]=ScumblrTask::GithubEventAnalyzer&resolve_system_metadata=true"
    json_response = JSON.parse(response.body)
    asserted = false
    json_response.each do | response_object |
      if response_object["id"] == 70
        assert_equal("foo", response_object["options"]["github_terms"].first)
        asserted = true
      end
    end

    if asserted == false
      skip("no owner_metadata found for task search, maybe you changed a fixture?")
    end

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

  test "bulk schedule tasks no error" do
    sign_in
    ids = Task.ids
    ActiveSupport::Deprecation.silence do
      post "/tasks/schedule.html", {task_ids: ids, commit: "Schedule", hour: "1"}
      assert_response :redirect
    end
    schedule = Sidekiq.get_schedule
    assert_equal(Task.count, schedule.keys.count)
    schedule.each do |task, metadata|
      frequency = schedule[task]["cron"]
      assert_equal("* 1 * * *", frequency)
    end
  end

  test "bulk unschedule tasks no error" do
    sign_in
    ids = Task.ids
    ActiveSupport::Deprecation.silence do
      post "/tasks/schedule.html", {task_ids: ids, commit: "Unschedule"}
      assert_response :redirect
    end
    schedule = Sidekiq.get_schedule
    assert_equal(0, schedule.keys.count)
    schedule.each do |task, metadata|
      frequency = schedule[task]["cron"]
      assert_equal(nil, frequency)
    end
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
    get "/tasks/70/run"
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
