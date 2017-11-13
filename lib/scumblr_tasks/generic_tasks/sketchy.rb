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

class ScumblrTask::Sketchy < ScumblrTask::Base
  def self.task_type_name
    "Sketchy Task"
  end

  def self.task_category
    "Generic"
  end

  def self.options
    return super.merge({
      :saved_result_filter=> {name: "Result Filter",
                              description: "Only screenshot results matching the given filter",
                              required: false,
                              type: :saved_result_filter
                              },
      :saved_event_filter => { name: "Event Filter",
                               description: "Only screenshot results with events matching the event filter",
                               required: false,
                               type: :saved_event_filter
                               },
      :limit_to_results_without_attachments => { name: "Limit to Results without Attachments",
                                                 description: "Only request screenshots for results with no attachments",
                                                 required: false,
                                                 type: :boolean,
                                                 default: true
                                                 },
      :status_code_only => { name: "Status Code Only",
                             description: "Have Sketchy check for status code changes without rendering a screenshot",
                             required: false,
                             type: :boolean,
                             default: false
                             }
    })
  end

  def self.description
    "Create request screenshots and/or status codes for results from Sketchy."
  end

  def self.config_options
    {:sketchy_url =>{ name: "Sketchy URL",
      description: "URL where Sketchy is deployed Example: https://sketchy.internal/api/v1.0/capture",
      required: true
      },
      :sketchy_use_ssl =>{ name: "Sketchy SSL",
      description: "Should Scumblr use SSL when connecting to Sketchy",
      required: false
      },
      :sketchy_access_token =>{ name: "Sketchy Access Token",
      description: "Access token required by Sketchy (if defined)",
      required: false
      },
      :sketchy_verify_ssl =>{ name: "Sketchy Verify SSL",
      description: "Should Scumblr verify the SSL certificate provided by Sketchy?",
      required: false
      }

    }


  end

  def initialize(options={})
    # Do setup

    @return_batched_results = false
    super
  end

  def run

    @options.each do |k,v|
      puts "Option #{k}: #{v}"
    end

    status_code_only = @options[:status_code_only] == 1 || @options[:status_code_only] == '1' || @options[:status_code_only] == true

    if(@options[:limit_to_results_without_attachments] == 1 || @options[:limit_to_results_without_attachments] == '1' || @options[:limit_to_results_without_attachments] == true)

      @results = @results.includes(:result_attachments).where('result_attachments.id is null').references(:result_attachments)
    end

    @results = @results.find_each(batch_size:10)

    result_ids = []
    @results.each do |r|
      result_ids << r.id
    end

    # puts "Result ids: #{result_ids}"
    ScreenshotSyncTaskRunner.perform_async(result_ids, status_code_only)

    return []

  end
end
