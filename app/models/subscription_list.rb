require 'httparty'
require 'json'

class SubscriptionList < ActiveRecord::Base
  attr_accessible :snhu_code, :mill33_list_id
  
  def self.updateLists()
      headers = {"AUTHORIZATION" => "Token token=\"#{ENV['MILL33_API_KEY']}\"", "Accept" => 'application/vnd.mill33.com; version=1'}
      @result = HTTParty.get('http://clients.mill33.com/api/subscriber_lists', :headers => headers)

      @result.each do |list|
        @list = SubscriptionList.where(:snhu_code => list['name']).first_or_create!(:mill33_list_id => list['id']) 
      end
  end
end
