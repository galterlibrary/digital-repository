require "resque/failure/multiple"
require "resque/failure/redis"

config = YAML::load(
  ERB.new(IO.read(File.join(
    Rails.root, 'config', 'redis.yml'
  ))).result
)[Rails.env].with_indifferent_access

Resque.redis = Redis.new(
  host: config[:host], port: config[:port], thread_safe: true
)

Resque.inline = Rails.env.test?
Resque.redis.namespace = "#{Sufia.config.redis_namespace}:#{Rails.env}"
# Explicitly set default namespace for clarity, see #79
if Rails.env.staging? || Rails.env.production?
  Resque.redis.namespace = :resque
end

# https://gist.github.com/assaf/291329
module Resque
  module Failure
    # Logs failure messages.
    class Logger < Base
      def save
        Rails.logger.error detailed
      end

      def detailed
        <<-EOF
#{worker} failed processing "#{queue}":
Payload:
#{payload.inspect.split("\n").map { |l| "  " + l }.join("\n")}
Exception:
  #{exception}
#{exception.backtrace.map { |l| "  " + l }.join("\n")}
        EOF
      end
    end

    class Notifier < Logger
      def save
        text, msubject = detailed, "[Error] #{queue}: #{exception}"
        Mail.deliver do
          from 'do-no-reply@dev.null'
          to ENV['TECH_ADMIN_EMAIL']
          subject(msubject)
          text_part do
            body(text)
          end
        end
      rescue
        puts $!
      end
    end
  end
end

Resque::Failure::Multiple.configure do |multi|
  multi.classes = Resque::Failure::Redis, Resque::Failure::Logger
  multi.classes << Resque::Failure::Notifier if Rails.env.production? || Rails.env.staging?
end
