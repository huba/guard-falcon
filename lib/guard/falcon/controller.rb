# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'guard/compat/plugin'

require 'rack/builder'
require 'rack/server'

require 'async/container/forked'
require 'falcon/server'

module Guard
	module Falcon
		class Controller < Plugin
			def self.default_env
				ENV.fetch('RACK_ENV', 'development')
			end

			DEFAULT_OPTIONS = {
				:bind => "tcp://localhost:9000",
				:environment => default_env,
				:config => 'config.ru',
			}

			def initialize(**options)
				super
				
				@options = DEFAULT_OPTIONS.merge(options)
				@container = nil
			end

			def run_server
				begin
					app, options = Rack::Builder.parse_file(@options[:config])
				rescue
					# Compat::UI.error "Failed to load #{@options[:config]}: #{$!}"
					# Compat::UI.error $!.backtrace
				end
				
				# Compat::UI.info("Starting Falcon HTTP server on #{@options[:bind]}.")
				
				Async::Container::Forked.new(concurrency: 2) do
					server = ::Falcon::Server.new(app, [
						Async::IO::Address.parse(@options[:bind], reuse_port: true)
					])
					
					server.run
				end
			end

			def start
				@container = run_server
			end

			def running?
				!@container.nil?
			end

			def reload
				stop
				start
			end

			def stop
				if @container
					@container.stop
					@container = nil
				end
			end

			def run_on_change(paths)
				reload
			end
		end
	end
end