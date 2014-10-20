require 'spec_helper'

describe 'duplicity::packages', :type => :class do
  it "should compile" do
    be true
  end

  it "should install required packages" do
    [ 'duplicity', 'python-boto', 'gnupg' ].each do |package|
      should contain_package package
    end
  end
end
