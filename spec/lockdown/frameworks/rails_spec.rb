require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Lockdown::Frameworks::Rails do
  before do
    @rails = Lockdown::Frameworks::Rails

    @rails.stub!(:use_me?).and_return(true)

    @lockdown = mock("lockdown")        
  end


  describe "#included" do
    it "should extend lockdown with rails environment" do
      @lockdown.should_receive(:extend).
        with(Lockdown::Frameworks::Rails::Environment)

      @rails.should_receive(:mixin)

      @rails.included(@lockdown)
    end
  end

  describe "#mixin" do
    it "should perform class_eval on controller view and system to inject itself" do
      module ActionController; class Base; end end
      module ActionView; class Base; end end

      Lockdown.stub!(:controller_parent).and_return(ActionController::Base)
      Lockdown.stub!(:view_helper).and_return(ActionView::Base)

      ActionView::Base.should_receive(:class_eval)

      ActionController::Base.should_receive(:helper_method)
      ActionController::Base.should_receive(:before_filter)
      ActionController::Base.should_receive(:filter_parameter_logging)
      ActionController::Base.should_receive(:rescue_from)

      ActionController::Base.should_receive(:class_eval)
      ActionController::Base.should_receive(:hide_action)

      Lockdown::System.should_receive(:class_eval)


      @rails.mixin
    end

  end
end

describe Lockdown::Frameworks::Rails::Environment do

  RAILS_ROOT = "/shibby/dibby/do"
  before do
    @env = class Test; extend Lockdown::Frameworks::Rails::Environment; end
  end

  describe "#project_root" do
    it "should return rails root" do
      @env.project_root.should == "/shibby/dibby/do"
    end
  end

  describe "#init_file" do
    it "should return path to init_file" do
      @env.stub!(:project_root).and_return("/shibby/dibby/do")
      @env.init_file.should == "/shibby/dibby/do/lib/lockdown/init.rb"
    end
  end

  describe "#controller_class_name" do
    it "should add Controller to name" do
      @env.controller_class_name("user").should == "UserController"
    end

    it "should convert two underscores to a namespaced controller" do
      @env.controller_class_name("admin__user").should == "Admin::UserController"
    end
  end

  describe "#controller_parent" do
    it "should return ActionController::Base if not caching classes" do
      module ActionController; class Base; end end
      @env.should_receive(:caching_classes?).and_return(false)
      @env.controller_parent.should == ActionController::Base
    end

    it "should return ApplicationController if caching classes" do
      class ApplicationController; end
      @env.should_receive(:caching_classes?).and_return(true)
      @env.controller_parent.should == ApplicationController
    end

  end

  describe "#view_helper" do
    it "should return ActionView::Base" do
      module ActionView; class Base; end end
      
      @env.view_helper.should == ActionView::Base
    end
  end
end

describe Lockdown::Frameworks::Rails::System do
  class Test 
    extend Lockdown::Frameworks::Rails::System
  end

  before do
    @env = Test
  end

  describe "#skip_sync?" do
    it "should return true if env == skip sync" do
      Lockdown::System.stub!(:fetch).with(:skip_db_sync_in).and_return(['test'])
      @env.should_receive(:framework_environment).and_return("test")
      
      @env.skip_sync?.should == true
    end

    it "should return false if env not in skip_sync" do
      Lockdown::System.stub!(:fetch).with(:skip_db_sync_in).and_return(['test', 'ci'])
      @env.should_receive(:framework_environment).and_return("qa")
      
      @env.skip_sync?.should == false
    end
    
  end

end
