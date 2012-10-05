class Widget < ActiveRecord::Base
  has_one :wotsit
  has_many :fluxors, :order => :name

  before_update :audit_a_decimal_change
  
  has_audit_me
  
  def audit_a_decimal_change
    self.custom_event =  'a_decimal_change' if a_decimal_changed?
  end
end