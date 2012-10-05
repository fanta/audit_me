class LegacyWidget < ActiveRecord::Base
  has_audit_me :ignore => :version,
                  :version => 'custom_version'
end