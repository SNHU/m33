class SnhuConnectorController < ApplicationController
  respond_to :json
  before_filter :restrict_access, :except => [:status]
  def status
    render :template => "home/index"
  end

  def create
    if(params['ESM_Email'])
      email = params['ESM_Email']
      program_of = params['ESM_ProgramofInterest']
      market_seg = params['ESM_MarketSegment']
      stage_number = params['ESM_StageNum']

      @list = nil

      if ['UDD', 'INT'].include? market_seg
        @list = SubscriptionList.new(
          mill33_list_id: 42, #TODO - market_seg_list_id
          snhu_code: market_seg
        )
      elsif stage_number == 300
        @list = SubscriptionList.new(
          mill33_list_id: 4242, #TODO - stage_number_list_id
          snhu_code: 'stage_list'
        )
      end

      #
      # Map to a list for that particular course code
      #
      if @list.nil?
        @list = SubscriptionList.find_by_snhu_code(program_of)

        #
        # Double check that the lists are up to date and
        # re-run the search and either put it in the program
        # or in the generic programs list
        #
        unless @list      
          SubscriptionList.updateLists
          @list = SubscriptionList.find_by_snhu_code(program_of) || SubscriptionList.find_by_snhu_code('Generic Programs')
        end

        if @list
          list_id = @list.mill33_list_id
          headers = {"AUTHORIZATION" => "Token token=\"#{ENV['MILL33_API_KEY']}\"", "Accept" => 'application/vnd.mill33.com; version=1'}
          body = {
            email: email,
            custom_fields: params.reject {|k,v| k=='ESM_Email'}
          }
          @result = HTTParty.post("http://clients.mill33.com/api/subscriber_lists/#{list_id}/subscribers", :headers => headers, :body => body)
          
          if @result.success?
            head :created
          else
            head :internal_server_error
          end
        else
          head :not_found
        end
      end
    end
  end

  private

  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      token == ENV['MILL33_API_KEY']
    end
  end
end
