class UpdateGithubSearchTaskOptions < ActiveRecord::Migration
  def up
    Task.where(task_type: "ScumblrTask::GithubAnalyzer").each do |t|
      if(t.options[:members] == "1")

        t.options[:members] = "both"
        t.save
      end
      if(t.options[:members] == "0")
        t.options[:members] = "organization_only"
        t.save
      end
    end
  end

  def up
    Task.where(task_type: "ScumblrTask::GithubAnalyzer").each do |t|
      if(t.options[:members] == "both" or t.options[:members] == "members_only")

        t.options[:members] = "1"
        t.save
      end
      if(t.options[:members] == "organization_only")
        t.options[:members] = "0"
        t.save
      end
    end
  end
end
