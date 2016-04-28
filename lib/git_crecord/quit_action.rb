
module GitCrecord
  class QuitAction < Proc
    def ==(other)
      :quit == other
    end
  end
end
