class Animal < ActiveRecord::Base
  has_audit_me
  self.inheritance_column = 'species'
end