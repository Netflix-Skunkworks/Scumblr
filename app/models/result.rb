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
require 'csv'

class Result < ActiveRecord::Base
  belongs_to :status

  has_many :task_results
  has_many :tasks, :through=>:task_results
  has_many :taggings, as: :taggable, :dependent => :delete_all
  has_many :tags, through: :taggings

  has_many :result_flags
  has_many :flags, through: :result_flags
  has_many :stages, through: :result_flags
  has_many :subscribers, as: :subscribable

  has_many :events, as: :eventable

  has_many :result_attachments

  belongs_to :user

  #attr_accessible :title, :url, :status_id

  validates :url, uniqueness: true
  validates :url, presence: true
  validates_format_of :url, with: /\A#{URI::regexp}\z/

  # serialize :metadata, JSON

  # This field contains the old metadata that is "archived" when moving to jsonb
  # This data is not updated after the migration is run
  serialize :metadata_archive, Hash


  acts_as_commentable

  attr_accessor :current_user

  #before_validation :replace_special_chars
  before_create :set_status

  after_commit :flush_cache

  def flush_cache
    Rails.cache.delete([self.class.name, id])
  end

  # Uncommenting this line will cause a events to be created everytime
  # a result is saved. This can result in a large number of events being
  # stored in an active deployment
  # before_save :create_events

  def self.cached_find(id)
    Rails.cache.fetch([name, id]) { find(id) }
  end

  def add_tags(tags)

    tags.each do |the_tag|

      unless self.tags.include? the_tag
        self.tags << the_tag
      end
    end
  end


  def add_tags_by_id(tag_ids)
    Array(tag_ids).each do |tag_id|
        # Create a tagging and save only if valid
        # (tagging will be invalid if the result is already tagged with the given id)
        tagging = self.taggings.build(tag_id: tag_id)
        tagging.save if tagging.valid?
    end
  end

  def self.to_csv
    CSV.generate do |csv|

      attributes = all.try(:first).try(:attributes).try(:keys)
      csv << attributes
      all.each do |result|
        csv << result.attributes.values_at(*attributes)
      end
    end

  end


  def self.valid_column_names
    Result.column_names.reject{|c| c.starts_with("metadata") || c == "content" }+["screenshot", "link"]
  end

  def replace_special_chars
    # puts self.url.to_s
    self.url = self.url.gsub('{', '%7b').gsub('}', '%7d')
  end

  def set_status
    if(self.status.blank?)
      self.status = Status.find_by_default(true)
    end
  end

  after_create :create_task_event

  def create_task_event
    if(Thread.current[:current_task])
      #create an event linking the updated/new result to the task
      #calling_task = Task.where(id: Thread.current[:current_task]).first

      Thread.current["current_results"] ||={}
      Thread.current["current_results"]["created"] ||=[]
      Thread.current["current_results"]["created"] |= [self.id]


      #calling_task.save!
    elsif(Thread.current["sidekiq_job_id"])
      Sidekiq.redis do |redis|
        redis.sadd("#{Thread.current[:sidekiq_job_id]}:results:created",self.id)
      end
    end
  end

  after_update :update_task_event

  def update_task_event
    if(Thread.current[:current_task])

      #create an event linking the updated/new result to the task
      #calling_task = Task.where(id: Thread.current[:current_task]).first
      Thread.current["current_results"] ||={}
      Thread.current["current_results"]["updated"] ||=[]
      Thread.current["current_results"]["updated"] |= [self.id]

      #calling_task.save!
    elsif(Thread.current["sidekiq_job_id"].present?)
      Sidekiq.redis do |redis|
        redis.sadd("#{Thread.current["sidekiq_job_id"]}:results:updated",self.id)
      end
    else

    end
  end

  # Unused method, consider removing Janurary 12th (S.B.)
  # Removed June 21, 2017 (S.B.)
  # def create_events

  def to_s
    "Result #{id}"
  end

  # Unused methods and not fully implemented
  # Removed 1-12-17 (S.B.)
  # def self.tagged_with(name)
  #   Tagging.where({:tag_id=>Tag.find_all_by_name(name).map(&:id), :taggable_type=> "Result"}).map{|tagging| tagging.taggable}
  # end

  # def self.tag_counts
  #   Tag.select("tags.*, count(taggings.tag_id) as count").
  #     joins(:taggings).group("taggings.tag_id")
  # end

  def tag_list
    tags.map(&:name).join(", ")
  end

  def tag_list=(names)
    self.tags = names.split(",").map do |n|
      tag = Tag.where("lower(name) like lower(?)",n.strip).first_or_initialize
      tag.name = n.strip if tag.new_record?
      tag.save if tag.changed?
      tag
    end
  end

  def create_attachment_from_url(url)
    attachment = self.result_attachments.new
    attachment.attachment_remote_url = url
    attachment.save
  end

  def create_attachment_from_sketchy(url, status_code_only=false)
    Rails.logger.debug "Getting screenshot #{self.id} "
    sketchy_url = Rails.configuration.try(:sketchy_url)
    if(sketchy_url.blank?)
      Rails.logger.error "No sketch URL configured."
      return
    end

    uri = URI.parse(sketchy_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 75
    http.use_ssl = Rails.configuration.try(:sketchy_use_ssl) || false
    if(Rails.configuration.try(:sketchy_use_ssl) && (Rails.configuration.try(:sketchy_verify_ssl) == false || Rails.configuration.try(:sketchy_verify_ssl) == "false"))
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Post.new(uri.request_uri)
    request.add_field "Content-Type", "application/json"
    if(Rails.configuration.try(:sketchy_access_token).present?)
      request.add_field "Token", Rails.configuration.try(:sketchy_access_token).to_s
    end

    request.body = {:url=>url, :callback=>Rails.application.routes.url_helpers.update_screenshot_result_url(self.id), status_only: (status_code_only == true)}.to_json

    Rails.logger.debug "Sending request #{request.body.inspect}"
    attempts = 0
    begin
      response = http.request(request)

      Rails.logger.debug "Response received #{response.code}"


      if(response.code == "200" || response.code == "201")
        Rails.logger.debug "Sketch OK"
        if(!status_code_only)
          sketchy_id = JSON.parse(response.body).try(:[],"id")
          self.metadata["sketchy_ids"] ||= []

          self.metadata["sketchy_ids"] << sketchy_id
          self.save
        end

      else
        raise RuntimeError
      end

    rescue RuntimeError, EOFError => e
      Rails.logger.error "#{e.inspect}"
      if(attempts < 3)
        attempts += 1
        message = "Retrying due to response from sketchy. #{response.try(:code)}"
        Rails.logger.error message
        retry
      else
        message = "Final failure. Bad response from sketchy. #{response.try(:code)} #{response.try(message)} (#{url})"
        Rails.logger.error message
      end
    end

  rescue StandardError=>e

    Rails.logger.error "Error communicating with sketchy: #{e.inspect} #{e.message}: #{e.backtrace}"
  end

  def text_attachments
    self.result_attachments.where("result_attachments.attachment_content_type like 'text/%'")
  end



  def has_attachment?
    return (self.result_attachments.count > 0)
  end

  # Perform a ransack search against the events model
  # options:
  # => columns: which columns to select in the query (selected in addition to default columns)
  # => include_metadata_column: whether to return only the sql query text
  def self.perform_search(q, page=1, per=25, options={})

    options ||= {}
    include_metadata_column = options[:include_metadata_column] || false
    columns = options[:columns]

    q.delete("searches_id_in")
    options[:metadata_search] = q[:metadata_search]
    options[:saved_event_filter_id] = q[:id_in_saved_event_filter]
    options[:saved_event_filter_id] = nil if options[:saved_event_filter_id] == 0

    ransack_search = Result

    if(options.include?(:includes))
      if(options[:includes].present?)
        # Include the associations requested
        ransack_search = ransack_search.includes(options[:includes])
      end
    else
      ransack_search = ransack_search.includes(:status, :result_attachments)
    end

    ransack_search = ransack_search.search(q.except(:metadata_search,:id_in_saved_event_filter))



    metadata_sort = q.try(:[],"s").try(:match,/\Ametadata:([A-Za-z0-9:_]+) ?(asc|desc)?\z/)
    # if(metadata_sort && metadata_sort.length >= 2)

    #   result.sorts = "metadata#>>{#{metadata_sort[1].split(":").join(",")}} #{metadata_sort.try(:[],2) || "asc"}"
    # end

    ransack_search.sorts = 'created_at desc' if ransack_search.sorts.empty? && metadata_sort.blank?

    begin
      results = Result.filter_search_with_metadata(ransack_search, per, page, options)
    rescue => e
      if(per == nil)
        results = ransack_search.result.select(Result.column_names.reject{|c| (c.starts_with("metadata") && include_metadata_column!=true) || c == "content" }.map{|c| "results."+c.to_s})
      else
        results = ransack_search.result.page(page).per(per).select(Result.column_names.reject{|c| (c.starts_with("metadata") && include_metadata_column!=true)  || c == "content" }.map{|c| "results."+c.to_s})
      end

      @errors ||= []
      @errors << "Invalid metadata search: #{q.inspect}"
    end

    return ransack_search, results

  end

  def self.filter_search_with_metadata(ransack_search, limit, page, options={})
    options ||= {}
    include_metadata_column = options[:include_metadata_column] || false
    columns = options[:columns]
    metadata = options[:metadata_search]
    saved_event_filter_id = options[:saved_event_filter_id]
    select_additions=[]
    if(columns)
      columns.select{|v| v.match(/\Ametadata:[A-Za-z0-1:_]+\z/) }.each{|c| select_additions << "results.metadata#>>'{#{c.split(":")[1..-1].join(",")}}' as #{c.split(":").join("_")}"}
    end

    order = nil
    if(!ransack_search.sorts.empty? && ransack_search.sorts[0].name.match(/\Ametadata:([A-Za-z0-9:_]+) ?(asc|desc)?\z/))

      sort = ransack_search.sorts[0]
      if(select_additions.select{|x| x.starts_with("results.metadata#>'{#{sort.name.split(":")[1..-1].join(",")}}'")}.present?)
        order = "results.metadata#>'{#{sort.name.split(":")[1..-1].join(",")}}' #{sort.dir}"
      else
        select_additions << "results.metadata#>'{#{sort.name.split(":")[1..-1].join(",")}}' as #{sort.name.split(":").join("_")}"
        order = "results.metadata#>'{#{sort.name.split(":")[1..-1].join(",")}}' #{sort.dir}"
      end
    end

    begin

      if(metadata.present?)
        query = ""
        params = []
        metadata.split(",").each do |q|
          if(query.present?)
            query += " AND "
          end

          operator = nil
          if(q.match(/\=\=/))
            values = q.split("==")
            operator = "="
          elsif(q.match(/@>/))
            values = q.split("@>")
            operator = "@>"
          elsif(q.match(/>\=/))
            values = q.split(">=")
            operator = ">="
          elsif(q.match(/<\=/))
            values = q.split("<=")
            operator = "<="
          elsif(q.match(/>/))
            values = q.split(">")
            operator = ">"
          elsif(q.match(/</))
            values = q.split("<")
            operator = "<"
          elsif(q.match(/!\=/))
            values = q.split("!=")
            operator = "!="
          else

            values = q
          end

          if(operator.blank?)
            if(values[0] == "!")
              values = values[1..-1]
              params << "{#{values.split(":").join(",")}}"
              query += "(results.metadata \#> ?) IS NULL"
            else
              params << "{#{values.split(":").join(",")}}"
              query += "results.metadata \#>> ? != ''"
            end

          else
            params << "{#{values[0].split(":").join(",")}}"
            v = nil
            if(values[1].match(/\A\".+\"/))
              v = values[1][1...-1].to_s
            elsif(values[1].match(/\A\d+\Z/))
              v = values[1].to_i
            elsif(values[1].match(/\A\d+\.\d+\Z/))
              v = values[1].to_f
            elsif(values[1] == "true")
              v = true
            elsif(values[1] == "false")
              v = false
            else
              v = values[1].to_s
            end
            if(operator == "@>")
              params << v
            else
              params << "#{v.to_json}"
            end
            query += "(results.metadata \#> ?) #{operator} ?"

          end


        end
        if(limit == nil)
          result = ransack_search.result.order(order.to_s).where(query, *params).select(Result.column_names.reject{|c| (c.starts_with("metadata") && include_metadata_column!=true)  || c == "content" }.map{|c| "results."+c.to_s}+select_additions)
        else
          result = ransack_search.result.order(order.to_s).page(page).per(limit).where(query, *params).select(Result.column_names.reject{|c| (c.starts_with("metadata") && include_metadata_column!=true)  || c == "content" }.map{|c| "results."+c.to_s}+select_additions)
        end

        #result = ransack_search.result(distinct: true).page(page).per(limit).where(query, *params).select(Result.column_names.reject{|c| c == "content" }.map{|c| "results."+c.to_s})


      else
        if(limit == nil)
          result = ransack_search.result.order(order.to_s).select(Result.column_names.reject{|c| (c.starts_with("metadata") && include_metadata_column!=true)  || c == "content" }.map{|c| "results."+c.to_s}+select_additions)
        else
          result = ransack_search.result.order(order.to_s).page(page).per(limit).select(Result.column_names.reject{|c| (c.starts_with("metadata") && include_metadata_column!=true)  || c == "content" }.map{|c| "results."+c.to_s}+select_additions)
        end


        #result = ransack_search.result(distinct: true).page(page).per(limit).select(Result.column_names.reject{|c|  c == "content" }.map{|c| "results."+c.to_s})
      end

      if(saved_event_filter_id.present?)
        filter = SavedFilter.find(saved_event_filter_id.to_i).try(:perform_search,{eventable_type_eq: "Result"},nil,nil,{sql_only:true, columns:[:eventable_id]}).try(:[],1)
        if(filter)
          result = result.where("results.id in (#{filter})")
        end
      end

      # result.count
      result.load
    rescue=>e

      Rails.logger.error e.message
      Rails.logger.error e.backtrace
      raise "Invalid Metadata Search #{metadata}"

    end
    result

  end

  def traverse_metadata(keys)
    _traverse_metadata(self.metadata, keys, nil)
  end

  def traverse_and_update_metadata(keys, value)
    _traverse_and_update_metadata(self.metadata, keys.clone, value, nil)
  end

  # Allows filtering an array inside a JSON object based on a
  # (potentially nested) value or set of values
  # Params:
  # +data+:: The JSON object to filter
  # +keys+:: The key(s) under which a value is stored in the array element
  # +values+:: The values which are valid and should cause the element to be included in the filtered array
  #             if values is nil we will just test to see if the element exists
  # +filter_on+:: The key(s) under which the array to be filtered is stored in the JSON element (data)
  def filter_metadata(data, keys, values, filter_on=nil)

    filter_data = data

    # If filter_on is defined, iterate through the list and get the array
    # to filter
    if(filter_on)
      Array(filter_on).each do |f|
        filter_data = filter_data.try(:[],f)
      end
    end



    # Define a proc for filtering the array
    # +keys+:: The key(s) under which a value is stored in the array element
    # +v+:: Should contain the current element of the array we're testing
    # +values+:: The values which are valid and should cause the element to be included in the filtered array
    select_function = Proc.new { |keys,v, values|
      value = v
      Array(keys).each do |k|
        begin
          value = value.try(:[], k)
        rescue
          value = nil
        end
      end

      if(value.class == Array)
        (values & value).present?
      elsif(value.present?)
        Array(values).include?(value)
      else
        value.present?
      end

    }

    # Call the above proc
    if(filter_data.class==Hash)
      filter_data.select!{|hk,v|
        select_function.call(keys,v, values)
      }
    else
      filter_data.select!{|v|
        select_function.call(keys,v, values)

      }
    end





    return data
  end
  # filter_metadata({a:{b:{c:[{a:1},{a:2},3,4,5]}}},[:a],1,[:a,:b,:c])
  #Result.first.filter_metadata(Result.find(39145).metadata,["severity"],["Critical","Medium"],["vulnerabilities"])["vulnerabilities"].count
  #http://localhost:3000/results/39145/get_metadata.json?key[1]=vulnerabilities&filter[1][1]=severity&filter_values[1][1][]=Critical&filter_on[1][1]=vulnerabilities
  #http://localhost:3000/results/39145/get_metadata.json?key[1]=vulnerabilities&filter[1][1][]=reporter&filter[1][1][]=username&filter_values[1][1][]=mongo&filter_on[1][1]=vulnerabilities

  private


  # Walk through the metadata and update the key(s) requested to new value
  #

  def _traverse_and_update_metadata(data, keys, value, r=nil)
    # Initialize the results to an empty hash if not initialized
    r ||={}

    # Grab the next key
    k=keys.shift


    parent = data

    # Try to grab the data referenced by the key from the current position in the data
    begin

      # For an integer key, treat data like an array and pull the indexed value
      if(/\A\d+\z/.match(k))
        data = data.try(:[],k.to_i)

        # If the key starts with ":" treat data like a hash and get the value referenced by the
        # key
      elsif(k[0] == ":")
        data = data.try(:[],k.to_s)
        if(data.nil?)
          parent[k] = {}
          data[k] = nil
        end
        # If the key is in the form of an array (ex. [1,2,3]) get a list of elements requested
      elsif(k[0]=="[")
        # If there is more that "[]" in the key...
        if(k.length > 2)

          k2 = k[1..k.length-2].split(':')
          # If the key can be split by ":" (i.e. [id:1,2] we want to select elements from a hash based on an attribute
          if(k2.length > 1)
            field = k2[0]
            k2 = k2[1].split(",").map(&:to_s)


            k = data.each_with_index.select { |v,index| k2.include?(v.try(:[],field).to_s) }.map { |pair| pair.try(:[],1) }.join(",")
            k = "[#{k}]"

          end

          k2 = k[1..k.length-2].split(',')


          k2.each do |k3|
            # data = data[k.to_i]
            # For each of the subvalues identified, traverse and update
            r = _traverse_and_update_metadata(data, [k3]+keys,value, r)
          end
          return r
        end
        # Otherwise assume data is a hash
      else
        data = data.try(:[],k)
        # If data[k] is blank, make it a hash
        if(data.nil?)
          if(keys.count == 1 && keys[0] == "[]")
            parent[k] = []
          else
            parent[k] = {}
          end
          data = parent[k]
        end
      end
    rescue

      r[k]=nil
      return r
    end

    # If we haven't parsed all the keys, parse the remaining keys. Pass in the results we have so far to
    # be appended to (r[k])
    if(!keys.empty?)

      r[k] ||= {}
      r[k] = _traverse_and_update_metadata(data,keys,value,  r[k])

      # Otherwise we need to update
    else
      # Treat value as JSON if it starts and ends with brackets ("{" and  "}")
      if(value[0] == "{" && value[value.length-1] == "}")
        begin
          value = JSON.parse(value)
        rescue

        end
        # If the value is a hash, convert to json
      elsif(value.class == Hash)
        value = value.to_json
        # Convert "true"/"false" to booleans
      elsif(value == "true")
        value = true
      elsif(value == "false")
        value = false
      end

      # If the last key is "[]" then treat as an array
      if(k == "[]")

        parent ||= []
        # Only add the value if it's not already in the array.
        parent << value if(!parent.include?(value))

        r =[]
        r << value
      else

        parent[k] = value
        r[k] = value
      end
    end

    return r
  end

  # data = {"a"=>{"b"=>{"c"=>1,"d"=>2,"e"=>3}  }}
  # keys = ["a","b","[c,d]"]
  # value = 5
  # traverse_and_update_metadata(data, keys, value, nil)

  # data = {"a"=>{"b"=>{"c"=>{"f"=>1,"g"=>2},"d"=>{},"e"=>{"f"=>5,"g"=>5}}  }}
  # keys = ["a","b","[c,d]","f"]
  # value = 5
  # traverse_and_update_metadata(data, keys, value, nil)


  # data={"a"=>{"b"=>[1,2]}}
  # keys=["a","b","[]"]
  # value = "hello"
  # traverse_and_update_metadata(data, keys, value, nil)

  # data={"a"=>{"b"=>[1,2]}}
  # keys=["a","b","[]"]
  # value = "{\"status\":\"open\",\"assignee\":\"none\"}"
  # traverse_and_update_metadata(data, keys, value, nil)


  # Walk through the metadata and return the keys requested
  # r is the current set of data (should be nil)
  # Examples:
  # traverse_metadata(nil, {:a=>{b:1,c:2}},[:a,:b])
  # => {a: { b: 1 } }
  # traverse_metadata(nil, {:a=>["hello","there","foo", "bar"],[:a,[0,2]])
  # => {a: {0: "hello", 2: "foo"} }
  # traverse_metadata(nil, {:a=>[{z:1, s:1},{x: 5, s:3},{y:2, s:5}],[:a,[0,2],[z,s]])
  # => {a: {0: {z:1, s:1}, 2: {z: nil, s:5} }}
  def _traverse_metadata(data, keys, r=nil)

    # Initialize the results to an empty hash if not initialized
    r ||={}

    # Grab the next key
    k=keys.shift

    # Try to grab the data referenced by the key from the current position in the data
    begin

      # For an integer key, treat data like an array and pull the indexed value
      if(/\A\d+\z/.match(k))
        data = data.try(:[],k.to_i)

        # If the key starts with ":" treat data like a hash and get the value referenced by the
        # key
      elsif(k[0] == ":")
        data = data.try(:[],k.to_s)

        # If the key is in the form of an array (ex. [1,2,3]) get a list of elements requested
      elsif(k[0]=="[")
        if(k.length >2 )
          k2 = k[1..k.length-2].split(',')

          # For each element requested, continue to traverse from here
          k2.each do |k3|
            # data = data[k.to_i]
            r = _traverse_metadata(data, [k3]+keys, r)
          end

          # For an array, once we've traversed each element we can return
          return r
        elsif(k=="[]")
          (0..data.length-1).each do |j|
            r = _traverse_metadata(data, [j.to_s]+keys, r)
          end
          return r
        end

      else
        # For other key types, we'll try it as a hash
        data = data.try(:[],k)

      end
    rescue
      # If efforts to retrieve return the value as nil
      r[k]=nil
      return r
    end

    # If we haven't parsed all the keys, parse the remaining keys. Pass in the results we have so far to
    # be appended to (r[k])
    if(!keys.empty?)
      r[k] ||= {}
      r[k] = _traverse_metadata(data,keys, r[k])


      # If we have parsed all the keys r[k] is equal to the remaining data
    else
      r[k] = data
    end

    # Return what we found
    return r
  end





end
