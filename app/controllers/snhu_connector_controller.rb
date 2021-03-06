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

      # Fix to allow for poorly encoded addreses that contain '+'
      email.strip!
      email.gsub!(/\s+/, '+')


      if (['UDD', 'INT'].include? market_seg) || (stage_number.to_s == '300')
        
        #
        # Ignore these posts, return 200 code
        #
        head :ok

      else
        #
        # Map special prefix codes for lists that handle multiple POIs
        #
        if (program_of.match /^(MED|MSN)/i)
          program_of = program_of[0..2]
        end

        #
        # Map to a list for that particular course code
        #
        @list = SubscriptionList.find_by_snhu_code('Generic Programs')#(program_of)

        #
        # If we didn't find the list, double check that the lists are up to date and
        # re-run the search.  If still not found put it in the generic programs list.
        #
        unless @list      
          SubscriptionList.updateLists
          @list = SubscriptionList.find_by_snhu_code(program_of) || SubscriptionList.find_by_snhu_code('Generic Programs')
        end

        if @list
          list_id = @list.mill33_list_id
          headers = {"AUTHORIZATION" => "Token token=\"#{ENV['MILL33_API_KEY']}\"", "Accept" => 'application/vnd.mill33.com; version=1'}
          body = {
            email: email.strip,
            custom_fields: params.reject {|k,v| k=='ESM_Email'}
          }
          puts "email: #{email}----------------------"
          puts "body-email: #{body[:email]}"
          @result = HTTParty.post("http://clients.mill33.com/api/subscriber_lists/#{list_id}/subscribers", :headers => headers, :body => body)
          
          if @result.success?
            #
            # We created the subscriber
            #
            head :created
          else
            #
            # There was an error with the post.
            #
            head :internal_server_error
          end
        else
          #
          # Could not find an appropriate list
          #
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
