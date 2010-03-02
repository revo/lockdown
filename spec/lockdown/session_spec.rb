require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class TestAController
  include Lockdown::Session
end

describe Lockdown::Session do
  before do
    @controller = TestAController.new

    @actions = %w(posts/index posts/show posts/new posts/edit posts/create posts/update posts/destroy)

    @session = {:access_rights => @actions}

    @controller.stub!(:session).and_return(@session)
  end
  
  describe "#logged_in?" do
    it "should return false withou current_user_id" do
      @controller.send(:logged_in?).should == false
    end
  end

  describe "#current_user_id" do
    it "should return false withou current_user_id" do
      @session[:current_user_id] = 2
      @controller.send(:current_user_id).should == 2
    end
  end

  describe "#nil_lockdown_values" do
    it "should nil access_rights" do
      @controller.send :nil_lockdown_values
      @session[:access_rights].should == nil
    end
  end

  describe "#current_user_is_admin?" do
    it "should return true if access_rights == :all" do
      @actions = :all
      @session = {:access_rights => @actions}
      @controller.stub!(:session).and_return(@session)

      @controller.send(:current_user_is_admin?).should == true
    end
  end

end
