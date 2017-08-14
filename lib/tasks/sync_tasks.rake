#     Copyright 2016 Netflix, Inc.
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.

require 'open-uri'
require 'timeout'
require 'json'


task :run_tasks_and_email_updates => :environment do
  leader=nil

  # See if Sidekiq has defined a leader
  Sidekiq.redis {|r| leader = r.get("dear-leader")}

  # If sidekiq has elected a leader, see if we are the leader. If not, exit
  if(leader.present? && leader.to_s.split(":")[0] != Socket.gethostname.to_s)
    abort "Not the leader. Exiting."
  else
    puts "I am the leader. Continuing."
  end

  Rake::Task["run_tasks"].invoke
  Rake::Task["send_email_updates"].invoke
end

task :run_tasks => :environment do

  job = TaskRunner.perform_async

  while(Sidekiq::Status::status(job) && Sidekiq::Status::status(job) != :complete && Sidekiq::Status::status(job) != :failed && Sidekiq::Status::status(job) != :interrupted)
    puts "Running (#{job})"      
    puts
    sleep(2)
  end

end



task :send_email_updates => :environment do

  #Find results without content
  SavedFilter.all.each do |filter|
    summary = filter.summaries.order("timestamp desc").limit(1).first
    start_time = summary.try(:timestamp)
    end_time = Time.now

    results = filter.perform_search({"created_at_gt"=>start_time, "created_at_lt"=>end_time})[1].readonly(false)

    filter.summaries.create(:timestamp=>end_time)

    if(filter.subscriber_list.present? && results.length > 0)
      SummaryMailer.notification(filter.subscriber_list, filter,results).deliver
    end

  end

end


task :sync_all => :environment do

  # Run all searches
  Rake::Task["perform_searches"].invoke
  
  # Sleep 1 hours to ensure all search tasks have complete
  sleep(1.hour)

  # Generate screenshots
  Rake::Task["generate_screenshots"].invoke
  
end


task :perform_searches => :environment do
  TaskRunner.perform_async(nil)
end

task :generate_screenshots => :environment do

  #Find results without attachments 
  results = Result.find(:all, :include => "result_attachments", :conditions => ['result_attachments.id is null'], :order=>"results.created_at desc")
  ScreenshotSyncTaskRunner.perform_async(results.map{|r| r.id})

end


