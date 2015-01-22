require 'ldap'

class Nuldap
  def initialize
    @ldap_server = ENV['LDAP_SERVER']
    @ldap_port = ENV['LDAP_PORT']
    @ldap_username = ENV['LDAP_USERNAME']
    @ldap_password = ENV['LDAP_PASSWORD']
    ldap_type = eval(ENV['LDAP_CONNECTION'].to_s) || LDAP::SSLConn
    @ldap_connection = ldap_type.new(@ldap_server, @ldap_port.to_i)
                                .set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
  end

  def ldap_server_up?
    # There's no good way to check Ruby/LDAP timeout, so we do this...
    timeout(5) do
      TCPSocket.open(@ldap_server, @ldap_port)
    end
    true
  rescue Timeout::Error
    message = 'LDAP server is down or taking too long to respond'
    Rails.logger.error(message)
    NewRelic::Agent.notice_error(message)
    false
  end
  private :ldap_server_up?

  def ldap_server_status_throwing
    # There's no good way to check Ruby/LDAP timeout, so we do this...
    timeout(5) do
      TCPSocket.open(@ldap_server, @ldap_port)
    end
  end
  private :ldap_server_status_throwing

  def bind_ldap_connection(user = @ldap_username, password = @ldap_password)
    ldap_server_status_throwing
    @ldap_connection.bind(user.to_s, password.to_s, LDAP::LDAP_AUTH_SIMPLE)
  end
  private :bind_ldap_connection

  def authenticate(netid, password)
    ldap_user = "uid=#{netid},ou=people,dc=northwestern,dc=edu"
    bind_ldap_connection(ldap_user, password)
    netid
  # This block's content serves informational purpose only
  rescue LDAP::ResultError => e
    # Bad NetID:
    nil if e.to_s == 'No such object'
    # Bad password:
    nil if e.to_s == 'Invalid credentials'
  end

  def search(filter)
    return false, {} unless ldap_server_up?
    conn = LDAP::SSLConn.new(@ldap_server, @ldap_port.to_i, nil, nil, nil)
    conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    conn.bind(@ldap_username, @ldap_password, LDAP::LDAP_AUTH_SIMPLE) do
      @ldap_user = {}

      begin
        conn.search('dc=northwestern,dc=edu', LDAP::LDAP_SCOPE_SUBTREE,
                    filter, []) { |entry| @ldap_user =  entry.to_hash }
      rescue LDAP::ResultError
        Rails.logger.error("LDAP eror: #{conn.perror('search')}")
        return false, {}
      end
    end

    [true, @ldap_user]
  end
end
