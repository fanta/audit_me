class Document < ActiveRecord::Base
  has_audit_me :audit_logs => :audit_me_logs,
                  :on => [:create, :update]
end