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

require 'devise/strategies/base'

module Devise
  module Strategies
    class MTLSable < Base
      def valid?
        if Rails.configuration.try(:enable_mtls_auth) 
          return request.headers["HTTP-X-CLIENT-VERIFY"] == "SUCCESS"
        else
          return false
        end
      end

      def authenticate!
        user_dn = request.headers["HTTP-AUTH-CLIENT-DN"].to_s;
        if user_dn != ""
          authed_user = User.from_mtls(user_dn)
          puts "success in MTLS"
          return success!(authed_user)
        else
          puts "fail in MTLS"
          return fail!("No Valid Certificate Presented")
        end
      end
    end
  end
end