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

require 'open-uri'
require 'net/https'
require 'open3'
require 'posix/spawn'
include POSIX::Spawn
require 'scumblr_tasks'




# Configure a timeout command
Scumblr::Application.configure do
  config.timeout_cmd = ""
  begin
    ["timeout", "gtimeout"].each do |cmd|
      pid, stdin, stdout, stderr = popen4(cmd)
        data = stdout.read

      [stdin, stdout, stderr].each { |io| io.close if !io.closed? }
      process, exit_status_wrapper = Process::waitpid2(pid)
      exit_status = exit_status_wrapper.exitstatus.to_i
      if exit_status == 125
        config.timeout_cmd = cmd
        break
      end
    end
  rescue
    puts "no timeout command found, consider installing coreutils for better handling of task timeouts"
  end
end


