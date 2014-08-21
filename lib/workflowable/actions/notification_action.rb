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


class Workflowable::Actions::NotificationAction < Workflowable::Actions::Action
  include ERB::Util

  NAME="Notifcation Action"
  OPTIONS = {
    :recipients => {
      :required=>true,
      :type=>:text,
      :description=>"The recipients of the message"
    },

    :subject => {
      :required=>true,
      :type=>:string,
      :description=>"The subject of the message"
    },
    :contents => {
      :required=>true,
      :type=>:text,
      :description=>"The contents of the message"
    }
  }

  def run

    ::NotificationMailer.notification(@options[:recipients][:value], @options[:subject][:value], @options[:contents][:value]).deliver

  end

end
