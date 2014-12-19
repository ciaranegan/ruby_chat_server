require 'socket'
require 'thread'

require_relative 'router.rb'

class ThreadPoolServer

	def initialize(size, port_no)

		@size = size # Number of threads in the thread pool
		@jobs = Queue.new # Queue of tasks for the threads to execute
		@port_no = port_no
		@router = Router.new

		@pool = Array.new(@size) do |i| # Create an array of threads
			Thread.new do
				Thread.abort_on_exception = true
				Thread.current[:id] = i # Give each thread an ID for easy access later
				loop do
					client, message = @jobs.pop # Get a job from the queue
					@router.route(client, message)
					client.close
				end
			end
		end
		# Set up TCPServer and start
		@server = TCPServer.new port_no
		@server_running = true
		self.run
	end

	def schedule(client, message)
		# Enqueues a client along with its message for the thread pool to handle
		@jobs << [client, message]
	end

	def shutdown
		sleep(0.5)
		# Kills all threads in the thread pool and closes the server
		@size.times do |i|
			Thread.kill(@pool[i])
		end
		@server.close
		puts "Server shutdown"
	end

	def run
		# Main loop to accept incoming messages
		puts "Server started"
		while @server_running == true do
			client = @server.accept
			message = client.gets
			puts message
			schedule(client, message)
			# Updates the loop condition based on the message
			@server_running = (message != "KILL_SERVICE\n")
		end
		# Shutsdown once a kill_service message is received
		self.shutdown
	end
end

if $0 == __FILE__
	if ARGV[0] == nil
		port_no = 8000
	else
		port_no = ARGV[0]
	end
	server = ThreadPoolServer.new(150, port_no)
end