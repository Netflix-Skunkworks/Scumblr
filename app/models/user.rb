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


class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable
  has_many :saved_filters, -> { order "name ASC" }
  has_many :user_saved_filters
  has_many :added_saved_filters, through: :user_saved_filters, :class_name=>"SavedFilter", :source=>:saved_filter
  has_many :subscriptions, :class_name=>"Subscriber"

  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  def to_s
    return email
  end


  def self.from_mtls(client_dn)
    where(provider: "mtls", uid: client_dn).first_or_create do |user|
      user.provider = "mtls"
      user.uid = client_dn
      user.email = client_dn
    end
  end

  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end

end
