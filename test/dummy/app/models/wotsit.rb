class Wotsit < ActiveRecord::Base
  has_audit_me
  belongs_to :widget
end