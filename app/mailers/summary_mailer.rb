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


class SummaryMailer < ActionMailer::Base

  default from: Rails.configuration.try(:email_source_address) || "scumblr@localhost"


  def notification(recipients, filter, results)
    attachments['logo.png'] = File.read("#{Rails.root}/app/assets/images/scumblr_logo.png")

    @results = results
    @filter = filter
    subject = "Scumblr: Daily update for: #{@filter.name}"
    mail(:to=> "", :bcc=> recipients, :subject=>subject)

  end



end
