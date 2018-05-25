# frozen_string_literal: true

module GitCrecord
  class QuitAction < Proc
    def ==(other)
      other == :quit
    end
  end
end
