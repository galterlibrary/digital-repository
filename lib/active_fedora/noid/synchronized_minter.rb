require 'noid'
module ActiveFedora
  module Noid
    class SynchronizedMinter
      def mint
        Mutex.new.synchronize do
          while true
            pid = next_id
            begin
              ActiveFedora::Base.find(pid)
            rescue ActiveFedora::ObjectNotFoundError
              return pid
            rescue Ldp::Gone
            end
          end
        end
      end
    end
  end
end
