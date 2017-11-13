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


require 'aws-sdk'

class ScumblrTask::Route53Sync < ScumblrTask::Base
  def self.task_type_name
    "Route 53 Sync"
  end

  def self.task_category
    "Sync"
  end

  def self.description
    "Add results for entries in Route53. Requires the instance to have access to the Amazon API either through an IAM role or through credentials stored as required by the AWS SDK (http://docs.aws.amazon.com/sdkforruby/api/Aws/Route53/Client.html)"
  end

  def self.config_options
    {}
  end

  def self.options
    return super.merge({:tags => {name: "Tag Results",
               description: "Provide a tag for newly created results",
               required: false,
               type: :tag
              }
    })
  end


  def initialize(options={})
    super


  end

  def run



    client = AWS::Route53::Client.new

    zones = client.list_hosted_zones
    @results = []

    zones[:hosted_zones].each do |zone|
      zone_id = zone[:id]
      zone_name = zone[:name]
      zone_private = zone.try(:[],:config).try(:[],:private_zone) == "true"
      record_count = zone[:resource_record_set_count]

      puts "Syncing #{zone_id}"
      records = client.list_resource_record_sets(:hosted_zone_id=>zone_id)

      parse_records(records, zone_id, zone_name, zone_private)

      while(records[:next_record_identifier].present?)

        records = client.list_resource_record_sets(:hosted_zone_id=>zone_id,
          start_record_identifier:records[:next_record_identifier],
          start_record_type:records[:next_record_type],
          start_record_name:records[:next_record_name]
          )
        parse_records(records,zone_id, zone_name, zone_private)

      end






    end

    return @results

  end

  private

  def parse_records(records, zone_id, zone_name, zone_private)


    records[:resource_record_sets].each do |record|




      existing_record = @results.select{|r| r[:url] == "http://" + record[:name]}.first
      if(existing_record)
        existing_record[:metadata][:route53_metadata][:values] += record[:resource_records].map{|r| r[:value]}
      else
        @results << {url: "http://" + record[:name], title: record[:name], domain: record[:name],
          metadata:{
            route53_metadata:{
              record_type: record[:type],
              zone_id: zone_id,
              zone_name: zone_name,
              zone_private: zone_private,
              values: record[:resource_records].map{|r| r[:value]}
            }
          }
        }
      end
    end



  end





end
