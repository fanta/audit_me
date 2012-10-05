require 'test_helper'

class AuditMeTest < ActiveSupport::TestCase
  test 'Sanity test' do
    assert_kind_of Module, AuditMe
  end

  test 'create with plain model class' do
    widget = Widget.create
    assert_equal 1, widget.audit_logs.length
  end

  test 'update with plain model class' do
    widget = Widget.create
    assert_equal 1, widget.audit_logs.length
    widget.update_attributes(:name => 'Bugle')
    assert_equal 2, widget.audit_logs.length
  end

  test 'destroy with plain model class' do
    widget = Widget.create
    assert_equal 1, widget.audit_logs.length
    widget.destroy
    audit_logs_for_widget = AuditLog.with_item_keys('Widget', widget.id)
    assert_equal 2, audit_logs_for_widget.length
  end
end