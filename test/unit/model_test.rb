require 'test_helper'

class HasAuditMeModelTest < ActiveSupport::TestCase

  context 'A record with defined "only" and "ignore" attributes' do
    setup { @article = Article.create }

    context 'which updates an ignored column' do
      setup { @article.update_attributes :title => 'My first title' }
      should_not_change('the number of audit logs') { AuditLog.count }
    end

    context 'which updates an ignored column and a selected column' do
      setup { @article.update_attributes :title => 'My first title', :content => 'Some text here.' }
      should_change('the number of audit logs', :by => 1) { AuditLog.count }

      should 'have stored only non-ignored attributes' do
        assert_equal ({'content' => [nil, 'Some text here.']}), @article.audit_logs.last.changeset
      end
    end

    context 'which updates a selected column' do
      setup { @article.update_attributes :content => 'Some text here.' }
      should_change('the number of audit logs', :by => 1) { AuditLog.count }
    end

    context 'which updates a non-ignored and non-selected column' do
      setup { @article.update_attributes :abstract => 'Other abstract'}
      should_not_change('the number of audit logs') { AuditLog.count }
    end

    context 'which updates a skipped column' do
      setup { @article.update_attributes :file_upload => 'Your data goes here' }
      should_not_change('the number of audit logs') { AuditLog.count }
    end

    context 'which updates a skipped column and a selected column' do
      setup { @article.update_attributes :file_upload => 'Your data goes here', :content => 'Some text here.' }
      should_change('the number of audit logs', :by => 1) { AuditLog.count }

      should 'have stored only non-skipped attributes' do
        assert_equal ({'content' => [nil, 'Some text here.']}), @article.audit_logs.last.changeset
      end

      context 'and when updated again' do
        setup do
          @article.update_attributes :file_upload => 'More data goes here', :content => 'More text here.'
          @audit_log = @article.audit_logs.last
        end

        should 'have removed the skipped attributes when saving the record' do
          assert_equal nil, YAML::load(@audit_log.object_changes)['file_upload']
        end

        should 'have kept the non-skipped attributes in the audit log' do
          assert_equal 'More text here.', YAML::load(@audit_log.object_changes)['content'].last
        end
      end
    end
  end

  context 'A record with defined "ignore" attribute' do
    setup { @legacy_widget = LegacyWidget.create }

    context 'which updates an ignored column' do
      setup { @legacy_widget.update_attributes :version => 1 }
      should_not_change('the number of audit logs') { AuditLog.count }
    end
  end

  context 'A record with defined "if" and "unless" attributes' do
    setup { @translation = Translation.new :headline => 'Headline' }

    context 'for non-US translations' do
      setup { @translation.save }
      should_not_change('the number of audit logs') { AuditLog.count }

      context 'after update' do
        setup { @translation.update_attributes :content => 'Content' }
        should_not_change('the number of audit logs') { AuditLog.count }
      end
    end

    context 'for US translations' do
      setup { @translation.language_code = "US" }

      context 'that are drafts' do
        setup do
          @translation.type = 'DRAFT'
          @translation.save
        end

        should_not_change('the number of audit logs') { AuditLog.count }

        context 'after update' do
          setup { @translation.update_attributes :content => 'Content' }
          should_not_change('the number of audit logs') { AuditLog.count }
        end
      end

      context 'that are not drafts' do
        setup { @translation.save }

        should_change('the number of audit logs', :by => 1) { AuditLog.count }

        context 'after update' do
          setup { @translation.update_attributes :content => 'Content' }
          should_change('the number of audit logs', :by => 1) { AuditLog.count }
        end
      end
    end
  end

  context 'A new record' do
    setup { @widget = Widget.new }

    should 'not have any audit logs' do
      assert_equal [], @widget.audit_logs
    end

    context 'which is then created' do
      setup { @widget.update_attributes :name => 'Henry' }

      should 'have one audit log' do
        assert_equal 1, @widget.audit_logs.length
      end

      should 'record the correct event' do
        assert_match /create/i, @widget.audit_logs.first.event
      end

      should 'not have changes' do
        assert_equal Hash.new, @widget.audit_logs.last.changeset
      end

      context 'and then updated without any changes' do
        setup { @widget.save }

        should 'not create a new audit log' do
          assert_equal 1, @widget.audit_logs.length
        end
      end


      context 'and then updated with changes' do
        setup { @widget.update_attributes :name => 'Harry' }

        should 'have two audit logs' do
          assert_equal 2, @widget.audit_logs.length
        end

        should 'record the correct event' do
          assert_match /update/i, @widget.audit_logs.last.event
        end

        should 'have stored changes' do
          assert_equal ({'name' => ['Henry', 'Harry']}), YAML::load(@widget.audit_logs.last.object_changes)
          assert_equal ({'name' => ['Henry', 'Harry']}), @widget.audit_logs.last.changeset
        end

        should 'return changes with indifferent access' do
          assert_equal ['Henry', 'Harry'], @widget.audit_logs.last.changeset[:name]
          assert_equal ['Henry', 'Harry'], @widget.audit_logs.last.changeset['name']
        end
        
        context 'and is updated but has custom event' do
          setup { @widget.update_attributes(:a_decimal => 1.5)}
          
          should 'record the correct event' do
            assert_match /a_decimal_change/i, @widget.audit_logs.last.event
          end
        end

        context 'and then destroyed' do
          setup do
            @fluxor = @widget.fluxors.create :name => 'flux'
            @widget.destroy
          end

          should 'record the correct event' do
            assert_match /destroy/i, AuditLog.last.event
          end

          should 'have three audit logs' do
            assert_equal 3, AuditLog.with_item_keys('Widget', @widget.id).length
          end
        end
        
      end
    end
  end

  context 'A record' do
    setup { @widget = Widget.create :name => 'Zaphod' }

    context 'with AuditMe globally disabled' do
      setup do
        AuditMe.enabled = false
        @count = @widget.audit_logs.length
      end

      teardown { AuditMe.enabled = true }

      context 'when updated' do
        setup { @widget.update_attributes :name => 'Beeblebrox' }

        should 'not add to its trail' do
          assert_equal @count, @widget.audit_logs.length
        end
      end
    end

    context 'with its audit me turned off' do
      setup do
        Widget.audit_me_off
        @count = @widget.audit_logs.length
      end

      teardown { Widget.audit_me_on }

      context 'when updated' do
        setup { @widget.update_attributes :name => 'Beeblebrox' }

        should 'not add to its trail' do
          assert_equal @count, @widget.audit_logs.length
        end
      end

      context 'when destroyed "without auditing"' do
        should 'leave audit me off after call' do
          @widget.without_auditing :destroy
          assert !Widget.audit_me_enabled_for_model
        end
      end

      context 'and then its audit me turned on' do
        setup { Widget.audit_me_on }

        context 'when updated' do
          setup { @widget.update_attributes :name => 'Ford' }

          should 'add to its trail' do
            assert_equal @count + 1, @widget.audit_logs.length
          end
        end

        context 'when updated "without auditing"' do
          setup do
            @widget.without_auditing do
              @widget.update_attributes :name => 'Ford'
            end
          end

          should 'not create new audit log' do
            assert_equal 1, @widget.audit_logs.length
          end

          should 'enable audit me after call' do
            assert Widget.audit_me_enabled_for_model
          end
        end
      end
    end
  end


  context 'A auditme with somebody making changes' do
    setup do
      @widget = Widget.new :name => 'Fidget'
    end

    context 'when a record is created' do
      setup do
        AuditMe.whodunnit = 'Alice'
        @widget.save
        @audit_log = @widget.audit_logs.last # only 1 audit log
      end

      should 'track who made the change' do
        assert_equal 'Alice', @audit_log.whodunnit
      end

      context 'when a record is updated' do
        setup do
          AuditMe.whodunnit = 'Bob'
          @widget.update_attributes :name => 'Rivet'
          @audit_log = @widget.audit_logs.last
        end

        should 'track who made the change' do
          assert_equal 'Bob', @audit_log.whodunnit
        end

        context 'when a record is destroyed' do
          setup do
            AuditMe.whodunnit = 'Charlie'
            @widget.destroy
            @audit_log = AuditLog.last
          end

          should 'track who made the change' do
            assert_equal 'Charlie', @audit_log.whodunnit
          end
        end
      end
    end
  end

  context 'An item' do
    setup { @article = Article.new }

    context 'which is created' do
      setup { @article.save }

      should 'store fixed meta data' do
        assert_equal 42, @article.audit_logs.last.answer
      end

      should 'store dynamic meta data which is independent of the item' do
        assert_equal '31 + 11 = 42', @article.audit_logs.last.question
      end

      should 'store dynamic meta data which depends on the item' do
        assert_equal @article.id, @article.audit_logs.last.article_id
      end

      should 'store dynamic meta data based on a method of the item' do
        assert_equal @article.action_data_provider_method, @article.audit_logs.last.action
      end


      context 'and updated' do
        setup { @article.update_attributes! :content => 'Better text.' }

        should 'store fixed meta data' do
          assert_equal 42, @article.audit_logs.last.answer
        end

        should 'store dynamic meta data which is independent of the item' do
          assert_equal '31 + 11 = 42', @article.audit_logs.last.question
        end

        should 'store dynamic meta data which depends on the item' do
          assert_equal @article.id, @article.audit_logs.last.article_id
        end
      end


      context 'and destroyed' do
        setup { @article.destroy }

        should 'store fixed meta data' do
          assert_equal 42, @article.audit_logs.last.answer
        end

        should 'store dynamic meta data which is independent of the item' do
          assert_equal '31 + 11 = 42', @article.audit_logs.last.question
        end

        should 'store dynamic meta data which depends on the item' do
          assert_equal @article.id, @article.audit_logs.last.article_id
        end

      end
    end
  end

  context 'A new model instance which uses a custom AuditLog class' do
    setup { @post = Post.new }

    context 'which is then saved' do
      setup { @post.save }
      should_change('the number of post audit logs') { PostAuditLog.count }
      should_not_change('the number of audit logs') { AuditLog.count }
    end
  end

  context 'An existing model instance which uses a custom AuditLog class' do
    setup { @post = Post.create }

    should 'have audit logs of the custom class' do
      assert_equal "PostAuditLog", @post.audit_logs.first.class.name
    end

    context 'which is modified' do
      setup { @post.update_attributes({ :content => "Some new content" }) }
      should_change('the number of post audit logs') { PostAuditLog.count }
      should_not_change('the number of audit logs') { AuditLog.count }
      should "not have stored changes when object_changes column doesn't exist" do
        assert_nil @post.audit_logs.last.changeset
      end
    end
  end

  context 'An unsaved record' do
    setup do
      @widget = Widget.new
      @widget.destroy
    end
    should 'not have a audit log created on destroy' do
      assert @widget.audit_logs.empty?
    end
  end

  context 'A model with a custom association' do
    setup do
      @doc = Document.create
      @doc.update_attributes :name => 'Doc 1'
    end

    should 'not respond to audit_logs method' do
      assert !@doc.respond_to?(:audit_logs)
    end

    should 'create a new audit log record' do
      assert_equal 2, @doc.audit_me_logs.length
    end
  end

  context 'The `on` option' do
    context 'on create' do
      setup do
        Fluxor.instance_eval <<-END
has_audit_me :on => [:create]
END
        @fluxor = Fluxor.create
        @fluxor.update_attributes :name => 'blah'
        @fluxor.destroy
      end
      should 'only have an audit log for the create event' do
        assert_equal 1, @fluxor.audit_logs.length
        assert_equal 'create', @fluxor.audit_logs.last.event
      end
    end
    context 'on update' do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
has_audit_me :on => [:update]
END
        @fluxor = Fluxor.create
        @fluxor.update_attributes :name => 'blah'
        @fluxor.destroy
      end
      should 'only have an audit log for the update event' do
        assert_equal 1, @fluxor.audit_logs.length
        assert_equal 'update', @fluxor.audit_logs.last.event
      end
    end
    context 'on destroy' do
      setup do
        Fluxor.reset_callbacks :create
        Fluxor.reset_callbacks :update
        Fluxor.reset_callbacks :destroy
        Fluxor.instance_eval <<-END
has_audit_me :on => [:destroy]
END
        @fluxor = Fluxor.create
        @fluxor.update_attributes :name => 'blah'
        @fluxor.destroy
      end
      should 'only have an audit log for the destroy event' do
        assert_equal 1, @fluxor.audit_logs.length
        assert_equal 'destroy', @fluxor.audit_logs.last.event
      end
    end
  end

end