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


# Support for legacy search providers
require 'search_providers/provider'
Dir[Rails.root + "lib/search_providers/*.rb"].each {|file| require file }
Dir[Rails.root + "custom/lib/search_providers/*.rb"].each {|file| require file }
Dir[Rails.root + "../custom/lib/search_providers/*.rb"].each {|file| require file }


require 'scumblr_tasks/base.rb'
require 'scumblr_tasks/async.rb'
require 'scumblr_tasks/async_sidekiq.rb'

Dir[Rails.root + "lib/scumblr_tasks/**/*.rb"].each {|file| require file }
Dir[Rails.root + "custom/lib/scumblr_tasks/**/*.rb"].each {|file| require file }
Dir[Rails.root + "../custom/lib/scumblr_tasks/**/*.rb"].each {|file| require file }


Dir[Rails.root + "lib/helpers/**/*.rb"].each {|file| require file }
Dir[Rails.root + "custom/lib/helpers/**/*.rb"].each {|file| require file }
Dir[Rails.root + "../custom/lib/helpers/**/*.rb"].each {|file| require file }
