module AuditMe
  class Config
    include Singleton
    attr_accessor :enabled
 
    def initialize
      # Indicates whether AuditMe is on or off.
      @enabled = true
    end
  end
end