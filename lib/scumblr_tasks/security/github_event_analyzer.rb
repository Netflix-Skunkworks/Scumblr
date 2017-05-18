#     Copyright 2014 Netflix, Inc.
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



class ScumblrTask::GithubEventAnalyzer < ScumblrTask::Base
  def self.task_type_name
    "Github Event Analyzer"
  end

  def self.task_category
    "Security"
  end

  def self.options
    {
      :github_terms => {name: "System Metadata Github Search Terms",
                       description: "Use system metadata search strings.  Expectes metadata to be in JSON array format.",
                       required: true,
                       type: :system_metadata}
    }
  end

  def initialize(options={})
    puts "*****Initializing with options: " + options[:_params].to_s
    super
  end

  def run
    puts "*****Running with options: " + @options[:_params].to_s

  end

end
