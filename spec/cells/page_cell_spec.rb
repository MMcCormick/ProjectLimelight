require 'spec_helper'

describe PageCell do
  context "cell rendering" do 
    
    context "rendering sidebar_left" do
      subject { render_cell(:page, :sidebar_left) }
  
      it { should have_selector("h1", :content => "Page#sidebar_left") }
      it { should have_selector("p", :content => "Find me in app/cells/page/sidebar_left.html") }
    end
    
  end


  context "cell instance" do 
    subject { cell(:page) } 
    
      it { should respond_to(:sidebar_left) }
    
  end
end
