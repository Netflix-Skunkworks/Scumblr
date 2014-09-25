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


class Search < ActiveRecord::Base
  #  attr_accessible :description, :name, :options, :provider, :query, :tag_list

  has_many :taggings, as: :taggable, :dependent => :delete_all
  has_many :tags, through: :taggings
  has_many :subscribers, as: :subscribable
  has_many :search_results
  has_many :results, through: :search_results

  serialize :options, Hash


  validates :name, presence: true
  validates :name, uniqueness: true
  validate :validate_search



  accepts_nested_attributes_for :taggings, :tags


  def validate_search
    begin
      if(!SearchProvider::Provider.subclasses.include?(self.provider.try(:to_s).try(:constantize)))
        errors.add :search_provider, " must be specified"
        return
      end
    rescue
      errors.add :search_provider, " must be specified"
      return
    end


    provider_options = self.provider.constantize.options
    if(self.options.blank?)
      self.options = {}
    end
    self.options.slice!(*provider_options.keys)
    provider_options.each do |key, value|
      if value[:required] && options[key].blank?
        errors.add value[:name], " can't be blank"
      end
    end
  end


  def provider_name
    begin
      self.provider.to_s.constantize.provider_name
    rescue
      ""
    end
  end

  def provider_options
    begin
      self.provider.try(:constantize).try(:options) || {}
    rescue
      {}
    end
  end

  def tag_list
    tags.map(&:name).join(",")
  end

  def tag_list=(names)
    self.tags = names.split(",").map do |n|
      tag = Tag.where("lower(name) like lower(?)",n.strip).first_or_initialize
      tag.name = n if tag.new_record?
      tag.save if tag.changed?
      tag
    end
  end

  def subscriber_list
    subscribers.where(:user_id=>nil).map(&:email).join(",")
  end

  def subscriber_list=(emails)
    self.subscribers = emails.split(",").map do |email|
      self.subscribers.where(:email=>email.downcase.strip).first_or_initialize
    end
  end

  def perform_search
    search = self
    Rails.logger.warn "Searching #{search}"
    provider = search.provider.constantize
    results = provider.new(search.query, search.options).run
    Rails.logger.warn "Results #{results}"
    new_status = Status.find_by_default(true).try(:id)
    results.each do |r|

      result = Result.where(:url=>r[:url]).first_or_initialize
      result.title = r[:title]
      result.domain = r[:domain]
      result.metadata = r[:metadata] || {}
      result.status_id = new_status if !result.status_id && new_status

      result.save if result.changed?
      search.tags.each do |tag|
        tagging = result.taggings.where(:tag_id=>tag.id).first_or_initialize
        tagging.save if tagging.changed?
      end
      Rails.logger.warn "Result saved #{result}"

      search_result = SearchResult.where({:search_id=>search.id, :result_id=> result.id}).first_or_initialize
      search_result.save
      Rails.logger.warn "Search result saved #{search_result}"
    end

  end



end
