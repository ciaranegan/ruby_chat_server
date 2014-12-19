require 'socket'
require 'thread'

require_relative 'chatroom_handler.rb'

class Router

	def initialize()
		@chatroom = ChatroomHandler.new
	end

	def route(client, request)
		connection = true

		case request.chomp
		when "KILL_SERVICE\n"
			client.puts "Server shutdown"
			connection = false

		when /\AHELO\s*(\w.*)\s*\z*/
			local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
			client.puts "#{$1}IP:#{local_ip}\nPort:#{@port_no}\nStudentID:11450212"
			connection = false

		when /\AJOIN_CHATROOM:\s*(\w.*)\s*\z/
			puts "Chat name: #{$1}"
			@chatroom.join(client, $1)

		when /\ALEAVE_CHATROOM:\s*(\w.*)\s*\z/
			@chatroom.leave(client, $1)

		when /\ADISCONNECT:\s*(\w.*)\s*\z/
			@chatroom.disconnect(client)
			connection = false

		when /\ACHAT:\s*(\w.*)\s*\z/
			@chatroom.chat(client, $1)
		end


		if connection
			request = client.gets
			self.route(client, request)
		end
	end

end