require 'open-uri'
require 'timeout'
require 'json'


task :sync_all => :environment do
  # Run all searches
  Rake::Task["perform_searches"].invoke
  
  # Sleep 1 hours to ensure all search tasks have complete
  sleep(1.hour)

  # Generate screenshots
  Rake::Task["generate_screenshots"].invoke
  
end


task :perform_searches => :environment do
  SearchRunner.perform_async(nil)
end



task :generate_screenshots => :environment do

  #Find results without attachments 
  results = Result.find(:all, :include => "result_attachments", :conditions => ['result_attachments.id is null'], :order=>"results.created_at desc")
  ScreenshotSyncTaskRunner.perform_async(results.map{|r| r.id})

end

task :send_email_updates => :environment do

  #Find results without content
  SavedFilter.all.each do |filter|
    summary = filter.summaries.order("created_at desc").limit(1).first
    start_time = summary.try(:timestamp)
    end_time = Time.now

    results = filter.perform_search({"created_at_gt"=>start_time, "created_at_lt"=>end_time}).result(:distinct=>true)
    filter.summaries.create(:timestamp=>end_time)

    if(filter.subscriber_list.present? && results.count > 0)
      SummaryMailer.notification(filter.subscriber_list, filter,results).deliver
    end

  end

end

