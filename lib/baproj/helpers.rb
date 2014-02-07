module Baproj
  module Helpers

    extend self

    def die(msg, val=2)
      puts msg.red
      exit val
    end

  end
end