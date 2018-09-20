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


Ransack.configure do |config|
  config.add_predicate 'includes_closed', # Name your predicate
    # What non-compound ARel predicate will it use? (eq, matches, etc)
    :arel_predicate => 'not_in',
    # Format incoming values as you see fit. (Default: Don't do formatting)
    #:formatter => proc {|v| ""},
    :formatter => proc {|v| Status.where(closed: true).map(&:id) },
    # Validate a value. An "invalid" value won't be used in a search.
    # Below is default.
    :validator => proc {|v| false },
    # Should compounds be created? Will use the compound (any/all) version
    # of the arel_predicate to create a corresponding any/all version of
    # your predicate. (Default: true)
    :compounds => true,
    # Force a specific column type for type-casting of supplied values.
    # (Default: use type from DB column)
    :type => :boolean

  config.add_predicate 'in_saved_result_filter', # Name your predicate
    # What non-compound ARel predicate will it use? (eq, matches, etc)
    :arel_predicate => 'in_any',
    # Format incoming values as you see fit. (Default: Don't do formatting)
    #:formatter => proc {|v| ""},
    :formatter => proc {|v| puts "v1: #{v}"; z = SavedFilter.where(id: v, saved_filter_type: "Result").try(:first).try(:perform_search,nil,1,100000000).try(:[],1).try(:map, &:id).try(:uniq); puts "Z: #{z}"; z },
    # Validate a value. An "invalid" value won't be used in a search.
    # Below is default.
    :validator => proc {|v| true },
    # Should compounds be created? Will use the compound (any/all) version
    # of the arel_predicate to create a corresponding any/all version of
    # your predicate. (Default: true)
    :compounds => true,
    # Force a specific column type for type-casting of supplied values.
    # (Default: use type from DB column)
    :type => :integer


end
