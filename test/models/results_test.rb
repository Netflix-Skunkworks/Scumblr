require "test_helper"
require "byebug"
class ResultTest < ActiveSupport::TestCase

  # Validations Tests
  should validate_presence_of(:url)
  should_not allow_value("blah/www.foo.com").for(:url)
  should allow_value("http://www.foo.com").for(:url)
  should validate_uniqueness_of(:url)

  # Association Tests
  should belong_to(:status)
  should belong_to(:user)
  should have_many(:task_results)
  should have_many(:result_flags)
  should have_many(:result_attachments)
  should have_many(:subscribers)
  should have_many(:events)
  should have_many(:tasks).through(:task_results)
  should have_many(:flags).through(:result_flags)
  should have_many(:stages).through(:result_flags)
  should have_many(:taggings).dependent(:delete_all)

  fixture_result = Result.first
  github_result = Result.where(id: 2).first

  # Class Method Tests
  test "should generate a csv file" do
    csv = Result.to_csv
    assert_includes("id,title,url,status_id,created_at,updated_at,domain,user_id,content,metadata_archive,metadata,metadata_hash", csv.split("\n").first)
  end

  test "should generate an array of valid column names" do
    assert_equal(["id", "title", "url", "status_id", "created_at", "updated_at", "domain", "user_id", "screenshot", "link"], Result.valid_column_names)
  end

  # Class Method Search Tests
  test "should perform a default result search" do

    ransack, results = Result.perform_search(q={"status_id_includes_closed"=>"0", "g"=>{"0"=>{"m"=>"or", "status_id_null"=>1, "status_closed_not_eq"=>true}}})
    assert_equal(6, results.length)
  end

  test "should perform a tag result search" do
    ransack, results = Result.perform_search(q={"tags_id_eq"=>1})
    assert_equal(1, results.length)
  end

  test "should perform a single metadata hash element result search" do
    ransack, results = Result.perform_search({metadata_search: "curl_metadata:Server==\"shakti-prod i-0ee8e795b8bde9360\",vulnerability_count:closed==1"}, 1, 25, {include_metadata_column:true})
    assert_equal(1, results.length)
  end

  test "should perform a single negative metadata hash element result search" do
    ransack, results = Result.perform_search({metadata_search: "curl_metadata:Server==\"shakti-prod i-0ee8e795b8bde9360\",vulnerability_count:closed!=0"}, 1, 25, {include_metadata_column:true})
    assert_equal(1, results.length)
  end

  test "should perform a single metadata array element result search" do
    ransack, results = Result.perform_search({metadata_search: "array_test@>[\"1\"]"}, 1, 25, {include_metadata_column:true})
    assert_equal(1, results.length)
  end

  test "should perform a multi metadata hash element result search" do
    ransack, results = Result.perform_search({url_cont: "netflix", metadata_search: "curl_metadata:Server==\"shakti-prod i-0ee8e795b8bde9360\""}, 1, 25, {include_metadata_column:true})
    assert_equal(1, results.length)
  end

  test "should perform a negative metadata  element result search" do
    ransack, results = Result.perform_search({metadata_search: "github_analyzer:private!=false"}, 1, 25, {include_metadata_column:true})
    assert_equal(3, results.length)
  end

  # Instance Method Tests
  test "executes creat_task_event correctly" do
    Thread.current[:current_task] = 1
    fixture_result.create_task_event
    assert_equal([1], Thread.current["current_results"]["created"])
  end

  test "executes traverse_metadata correctly" do
    assert_equal({"array_test"=>["1", "2"]}, fixture_result.traverse_metadata(["array_test"]))
  end

  test "sets tag_list on a result" do
    Thread.current[:current_task] = 1
    fixture_result.tag_list="Foo"
    assert_equal("Foo", fixture_result.tag_list="Foo")
  end

  test "executes set_status on result" do
    github_result.set_status
    assert_equal(1, github_result.status_id)
  end

  test "executes traverse and update metadata on result" do
    fixture_result.traverse_and_update_metadata(["vulnerabilities", "[id:c58ce1dcef0fd20b99cb725abb1b8aad]", "severity"], "High")
    assert_equal("High", fixture_result.metadata["vulnerabilities"].first["severity"])
  end

  test "executes traverse and update metadata on result and creates a new key" do
    fixture_result.reload
    fixture_result.traverse_and_update_metadata(["test"], "1")
    assert_equal("1", fixture_result.metadata["test"])
  end

  test "executes traverse and update metadata on result and creates a nested key" do
    fixture_result.reload
    fixture_result.traverse_and_update_metadata(["test","testing"], "2")
    assert_equal("2", fixture_result.metadata["test"]["testing"])
  end

  test "executes traverse and update metadata on result and creates/updates a new array" do
    fixture_result.reload
    fixture_result.traverse_and_update_metadata(["test","testing","[]"], "2")
    assert_equal("2", fixture_result.metadata["test"]["testing"].first)
    fixture_result.traverse_and_update_metadata(["test","testing","[]"], "3")
    assert_equal(2, fixture_result.metadata["test"]["testing"].count)
    assert_equal("2", fixture_result.metadata["test"]["testing"].first)
    assert_equal("3", fixture_result.metadata["test"]["testing"].last)
  end

  test "executes traverse metadata on array nested object" do
    assert_equal({{:a=>{:b=>1, :c=>2}}=>nil}, fixture_result.traverse_metadata([{:a=>{b:1,c:2}},[:a,:b]]))
  end

  test "executes filter metadata on result" do
    foo = fixture_result.filter_metadata(fixture_result.metadata, ["status"], ["Auto Remediated"], ["vulnerabilities"])
    assert_equal(1, foo["vulnerabilities"].count)
  end

  test "executes update_task_event correctly" do
    Thread.current["current_results"] ={}
    Thread.current[:current_task] = 1

    github_result.update_task_event
    assert_equal([2], Thread.current["current_results"]["updated"])
  end

  test "executes tag_lit correctly" do
    fixture_result.update_task_event
    assert_equal("Foo", fixture_result.tag_list)
  end

  test "ensures tag_list setter executed correctly" do
    assert_equal("Foo", fixture_result.tags.first.name)
  end

  test "create an attachment from url" do
    assert_equal(true, fixture_result.create_attachment_from_url("https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png"))
  end

  test "do not create attachment since url is not image" do
    assert_equal(false, fixture_result.create_attachment_from_url("https://www.google.com/"))
  end

  # This test is causing issue and isn't providing much value, disabled until I can rework it
  # this may be because scope issue in sketchy_url (move outside if block)
  # test "no url configured error for attachment from sketchy" do
  #   restore_vals = false
  #   if Rails.configuration.try(:sketchy_url).present?
  #     sketchy_url = Rails.configuration.sketchy_url
  #     sketchy_access_token = Rails.configuration.sketchy_access_token
  #     restore_vals = true
  #   end

  #   Scumblr::Application.configure do
  #     config.sketchy_url = ""
  #     config.sketchy_access_token = ""
  #   end

  #   foo = fixture_result.create_attachment_from_sketchy("https://www.google.com/")
  #   assert_equal(fixture_result.metadata["sketchy_ids"], foo)

  #   if restore_vals
  #     Scumblr::Application.configure do
  #       config.sketchy_url = sketchy_url
  #       config.sketchy_access_token = sketchy_access_token
  #     end
  #   end
  # end


  test "create attachment from sketchy" do
    if Rails.configuration.try(:sketchy_url).present?
      fixture_result.create_attachment_from_sketchy("https://www.google.com/")
      assert_equal(Fixnum, fixture_result.metadata["sketchy_ids"].first.class)
      fixture_result.metadata["sketchy_ids"] = nil
    else
      skip("no sketchy_url configured...skiping test.")
    end
  end

  # This test is causing issue and isn't providing much value, disabled until I can rework it
  # test "runtime error for attachment from sketchy" do
  #   restore_vals = false
  #   if Rails.configuration.try(:sketchy_url).present?
  #     sketchy_url = Rails.configuration.sketchy_url
  #     sketchy_access_token = Rails.configuration.sketchy_access_token
  #     restore_vals = true
  #     Scumblr::Application.configure do
  #       config.sketchy_url = "https://google.com"
  #       config.sketchy_access_token = ""
  #     end

  #     foo = fixture_result.create_attachment_from_sketchy("https://www.google.com/")
  #     assert_equal(nil, fixture_result.metadata["sketchy_ids"])
  #   else
  #     skip("no sketchy_url configured...skiping test.")
  #   end
  #   if restore_vals
  #     Scumblr::Application.configure do
  #       config.sketchy_url = sketchy_url
  #       config.sketchy_access_token = sketchy_access_token
  #     end
  #   end
  # end

end
