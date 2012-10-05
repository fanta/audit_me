class Translation < ActiveRecord::Base
  has_audit_me :if => Proc.new { |t| t.language_code == 'US' },
                  :unless => Proc.new { |t| t.type == 'DRAFT' }
end