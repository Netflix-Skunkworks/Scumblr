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


class Subscriber < ActiveRecord::Base
  belongs_to :subscribable, polymorphic: true
  belongs_to :user

  validates :user_id, :uniqueness=> {scope: [:subscribable_id, :subscribable_type, :email]}

  def subscriber_email
    return user.present? ? user.email : email
  end
end
