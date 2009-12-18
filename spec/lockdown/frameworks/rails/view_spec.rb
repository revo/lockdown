require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

class TestAView
  def link_to
    "link_to"
  end

  def button_to
    "button_to"
  end

  def link_to_remote
    "link_to_remote"
  end

  def button_to_remote
    "button_to_remote"
  end

  include Lockdown::Frameworks::Rails::View
end

describe Lockdown::Frameworks::Rails::Controller do

  before do
    @view = TestAView.new

    @view.stub!(:url_for).and_return("posts/new")

    @options = {:controller => "posts", :action => "new"}
  end

  describe "#link_to_secured" do
    it "should return the link if authorized" do
      link = "<a href='http://a.com'>my_link</a>"
      @view.stub!(:authorized?).and_return(true)
      @view.stub!(:link_to_open).and_return(link)
      @view.link_to_secured("my link", @options).should == link
    end

    it "should return an empty string if authorized" do
      @view.stub!(:authorized?).and_return(false)
      @view.link_to_secured("my link", @options).should == ""
    end

    it "should attempt to remove a subdirectory if it exists" do
      @view.should_receive(:remove_subdirectory).once
      @view.stub!(:authorized?).and_return(false)
      @view.link_to_secured("my link", @options).should == ""
    end

  end

  describe "#link_to_remote_secured" do
    it "should return the link if authorized" do
      link = "<a href='http://a.com'>my_link</a>"
      @view.stub!(:authorized?).and_return(true)
      @view.stub!(:link_to_remote_open).and_return(link)
      @view.link_to_remote_secured("my link", @options).should == link
    end

    it "should return an empty string if authorized" do
      @view.stub!(:authorized?).and_return(false)
      @view.link_to_remote_secured("my link", @options).should == ""
    end

    it "should attempt to remove a subdirectory if it exists" do
      @view.should_receive(:remove_subdirectory).once
      @view.stub!(:authorized?).and_return(false)
      @view.link_to_remote_secured("my link", @options).should == ""
    end

  end


  describe "#button_to_secured" do
    it "should return the link if authorized" do
      link = "<a href='http://a.com'>my_link</a>"
      @view.stub!(:authorized?).and_return(true)
      @view.stub!(:button_to_open).and_return(link)

      @view.button_to_secured("my link", @options).should == link
    end

     it "should return an empty string if authorized" do
      @view.stub!(:authorized?).and_return(false)

      @view.button_to_secured("my link", @options).should == ""
     end

    it "should attempt to remove a subdirectory if it exists" do
      @view.should_receive(:remove_subdirectory).once
      @view.stub!(:authorized?).and_return(false)
      @view.button_to_secured("my link", @options).should == ""
    end


  end

  describe "#button_to_remote_secured" do
    it "should return the link if authorized" do
      link = "<a href='http://a.com'>my_link</a>"
      @view.stub!(:authorized?).and_return(true)
      @view.stub!(:button_to_remote_open).and_return(link)
      @view.button_to_remote_secured("my link", @options).should == link
    end

    it "should return an empty string if authorized" do
      @view.stub!(:authorized?).and_return(false)
      @view.button_to_remote_secured("my link", @options).should == ""
    end

    it "should attempt to remove a subdirectory if it exists" do
      @view.should_receive(:remove_subdirectory).once
      @view.stub!(:authorized?).and_return(false)
      @view.button_to_remote_secured("my link", @options).should == ""
    end

  end


  describe "#link_to_or_show" do
    it "should return the name if link_to returned an empty string" do
      @view.stub!(:link_to).and_return('')

      @view.link_to_or_show("my_link", @options).
        should == "my_link"
    end

    it "should return the link if access is allowed" do
      link = "<a href='http://a.com'>my_link</a>"
      @view.stub!(:link_to).and_return(link)

      @view.link_to_or_show("my_link", @options).
        should == link
    end
  end

  describe "#link_to_or_show" do
    it "should return links separated by | " do
      Lockdown::System.stub!(:fetch).with(:link_separator).and_return(' | ')
      links = ["link_one", "link_two"]
      @view.links(links).should == links.join(' | ')
    end

    it "should return links separated by | and handle empty strings" do
      Lockdown::System.stub!(:fetch).with(:link_separator).and_return(' | ')
      links = ["link_one", "link_two", ""]
      @view.links(links).should == links.join(' | ')
    end
  end

  describe "#remove_subdirectory" do

    before(:each) do
      Lockdown::System.should_receive(:fetch).with(:subdirectory).and_return 'test'
    end

    it "should remove subdirectory /test" do
      @view.send(:remove_subdirectory,'/test/posts/new').should == '/posts/new'
    end

    it "should remove subdirectory 'test' without a leading /" do
      @view.send(:remove_subdirectory,'test/posts/new').should == '/posts/new'
    end

    it "should leave the url untouched" do
      @view.send(:remove_subdirectory,'/posts/new').should == '/posts/new'
    end


  end

  describe "#url_from" do

    it "should derive the path from the :url if given with options" do
      options = { :url => 'test/test' }
      @view.should_receive(:url_for).with(options[:url])
      @view.should_not_receive(:url_for).with(options)
      @view.send(:url_from, options)
    end

    it "should derive the path from the options hash if no :url is given" do
      options = { :controller => 'test', :action => 'index' }
      @view.should_receive(:url_for).with(options)
      @view.send(:url_from, options)
    end


  end



end
