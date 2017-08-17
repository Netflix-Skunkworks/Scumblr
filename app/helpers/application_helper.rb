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


module ApplicationHelper
  # def link_to_add_fields(name, f, association)
  #   new_object = f.object.send(association).klass.new
  #   id = new_object.object_id
  #   fields = f.fields_for(association, new_object, child_index: id) do |builder|
  #     render(association.to_s.singularize + "_fields", f: builder)
  #   end
  #   link_to(name, '#', class: "add_fields button tiny", data: {id: id, fields: fields.gsub("\n", "")})
  # end



  # def json_for(target, options = {})
  #   options[:scope] ||= self
  #   options[:url_options] ||= url_options
  #   target.active_model_serializer.new(target, options).to_json
  # end


  def split_button(labels, options={})
    uuid= options[:uuid] || SecureRandom.uuid

    html = ""
    html << "<a href='#' class='split_button_submit button split #{options[:button_class]} #{options[:link_class]}'>#{labels.shift} <span data-dropdown='drop_#{uuid}'></span></a>"
    html << "<ul id='drop_#{uuid}' class='f-dropdown f-dropdown-wide' data-dropdown-content>"
    labels.each do |l|
      html << "<li><a href='#' class='split_button_submit #{options[:link_class]}'>#{l}</a></li>"
    end
    html << "</ul>"
    html.html_safe
  end

  def hint_icon(text, blank_on_nil=true)
    if(text.blank? && blank_on_nil)
      ""
    else
      return ('<span data-tooltip aria-haspopup="true" class="has-tip tip-left" title="'+ CGI::escapeHTML(text.to_s) +'"><i class="fi-info"></i></span>').html_safe
    end
    
  end


  def time_string_time_ago_in_words(value)
    begin
      return time_ago_in_words(Time.parse(value)) + " ago"
    rescue
      return ""
    end
  end

  def link_icon(url)
    return "<a href='#{CGI::escapeHTML(url)}'target='_blank' class='fi-page-export'></a>".html_safe
  end

  def task_link_icon(task_id)
    return link_icon(task_path(task_id))
  end

  def pretty_time(value)
    begin
      return Time.parse(value).to_s
    rescue
      return ""
    end  
  end


end
