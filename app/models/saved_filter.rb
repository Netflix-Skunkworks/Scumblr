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


class SavedFilter < ActiveRecord::Base
  belongs_to :user
  serialize :query
  has_many :user_saved_filters, :dependent=>:delete_all
  has_many :users, :through=> :user_saved_filters
  has_many :subscribers, as: :subscribable
  has_many :summaries, as: :summarizable

  validates :name, :presence => true

  def subscriber_list
    subscribers.where(:user_id=>nil).map(&:email).join(",")
  end

  def subscriber_list=(emails)
    self.subscribers = emails.split(",").map do |email|
      self.subscribers.where(:email=>email.downcase.strip).first_or_initialize
    end
  end

  def perform_search(query_overrides={})
    Result.perform_search(self.query.merge(query_overrides))

  end


end
