class Post < ActiveRecord::Base
  has_audit_me :class_name => "PostAuditLog"

end