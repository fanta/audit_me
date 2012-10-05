require 'test_helper'

class ControllerTest < ActionController::TestCase
  tests WidgetsController

  setup do
    @request.env['REMOTE_ADDR'] = '127.0.0.1'
  end

  teardown do
    AuditMe.enabled_for_controller = true
  end

  test 'disable on create' do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, :widget => { :name => 'Flugel' }
    assert_equal 0, assigns(:widget).audit_logs.length
  end

  test 'disable on update' do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, :widget => { :name => 'Flugel' }
    w = assigns(:widget)
    assert_equal 0, w.audit_logs.length
    put :update, :id => w.id, :widget => { :name => 'Bugle' }
    widget = assigns(:widget)
    assert_equal 0, widget.audit_logs.length
  end

  test 'disable on destroy' do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, :widget => { :name => 'Flugel' }
    w = assigns(:widget)
    assert_equal 0, w.audit_logs.length
    delete :destroy, :id => w.id
    widget = assigns(:widget)
    assert_equal 0, AuditLog.with_item_keys('Widget', w.id).size
  end

  test 'create' do
    post :create, :widget => { :name => 'Flugel' }
    widget = assigns(:widget)
    assert_equal 1, widget.audit_logs.length
    assert_equal 153, widget.audit_logs.last.whodunnit.to_i
    assert_equal '127.0.0.1', widget.audit_logs.last.ip
    assert_equal 'Rails Testing', widget.audit_logs.last.user_agent
  end

  test 'update' do
    w = Widget.create :name => 'Duvel'
    assert_equal 1, w.audit_logs.length
    put :update, :id => w.id, :widget => { :name => 'Bugle' }
    widget = assigns(:widget)
    assert_equal 2, widget.audit_logs.length
    assert_equal 153, widget.audit_logs.last.whodunnit.to_i
    assert_equal '127.0.0.1', widget.audit_logs.last.ip
    assert_equal 'Rails Testing', widget.audit_logs.last.user_agent
  end

  test 'destroy' do
    w = Widget.create :name => 'Roundel'
    assert_equal 1, w.audit_logs.length
    delete :destroy, :id => w.id
    widget = assigns(:widget)
    audit_logs_for_widget = AuditLog.with_item_keys('Widget', w.id)
    assert_equal 2, audit_logs_for_widget.length
    assert_equal 153, audit_logs_for_widget.last.whodunnit.to_i
    assert_equal '127.0.0.1', audit_logs_for_widget.last.ip
    assert_equal 'Rails Testing', audit_logs_for_widget.last.user_agent
  end
end