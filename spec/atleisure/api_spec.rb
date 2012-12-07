# encoding: UTF-8
require 'atleisure'

describe Atleisure::API do
  context "MockClient" do
    before do
      @mock_client = double('Jimson::Client')
      Jimson::Client.stub(:new).and_return(@mock_client)
      @api = Atleisure::API.new('dummy', 'pass')
    end

    describe "#place_booking" do
      before do
        @customer = {:surname=>"Hegmann", :initials=>"C", :street=>nil, :postal_code=>nil, :city=>"East Mckaylamouth", :country=>"SG", :email=>"sydni8@email.com", :language=>:en }
        @start_date = Date.new(2013, 1, 9)
        @end_date = Date.new(2013, 1, 11)
      end

      it "calls PlaceBookingV1" do
        @mock_client.should_receive('PlaceBookingV1').and_return({})
        @api.place_booking('XX-1234-02', @start_date, @end_date, 3, @customer, 100, 123)
      end

      it "handles errors" do
        @mock_client.should_receive('PlaceBookingV1').and_raise(Jimson::Client::Error::ServerError.new(-32002, 'Field WebsiteRentPrice, Value 100 is incorrect or unknown'))

        response = @api.place_booking('XX-1234-02', @start_date, @end_date, 3, @customer, 100, 123)
        expect(response[:error]).to eq('Server error -32002: Field WebsiteRentPrice, Value 100 is incorrect or unknown')
      end

      it "doesn't pass nil parameters" do
        expect(@customer[:phone_number]).to be_nil

        @mock_client.should_receive('PlaceBookingV1') do |params|
          expect(params).to_not have_key('CustomerTelephone1Number')
          {}
        end

        @api.place_booking('XX-1234-02', @start_date, @end_date, 3, @customer, 100, 123)
      end

      it "passes a valid locale (NL, FR, DE, EN, IT, ES, PL)" do
        [
          ['English', 'EN'], ['english', 'EN'],
          ['Italiano', 'IT'], ['it', 'IT'],
          ['Espagnol', 'ES'], ['Español', 'ES'],
          ['Français', 'FR'], ['French', 'FR'],  ['fr', 'FR'],
          ['Deutsch', 'DE'], ['de', 'DE'],
          ['NL', 'NL'],
          ['fasdfsadf', 'EN'], ['', 'EN'], [nil, 'EN']
        ].each do |lan_str, expected_locale|
          @mock_client.should_receive('PlaceBookingV1') do |params|
            locale = params['CustomerLanguage']
            expect(locale).to(eq(expected_locale), "#{lan_str} => #{locale} != #{expected_locale}")
            {}
          end
          @customer[:language] = lan_str
          @api.place_booking('XX-1234-02', @start_date, @end_date, 3, @customer, 100, 123)
        end
      end

      it "formats the response" do
        atleisure_response = {"BookingNumber"=>74920133, "MyAccountLoginURL"=>"https://www.belvilla.co.uk/my-belvilla", "FirstTermDateTime"=>"2012-12-08T05:34:15.565+01:00",
                              "FirstTermAmount"=>180.0, "WebPartnerCommissionBase"=>0.0, "WebPartnerBookingCode"=>"123"}
        @mock_client.should_receive('PlaceBookingV1').and_return(atleisure_response)

        response = @api.place_booking('XX-1234-02', @start_date, @end_date, 3, @customer, 100, 123)
        expect(response).to eq(booking_number: 74920133,
          my_account_login_url: "https://www.belvilla.co.uk/my-belvilla",
          first_term_date_time: "2012-12-08T05:34:15.565+01:00",
          first_term_amount: 180.0,
          web_partner_commission_base: 0.0,
          web_partner_booking_code: '123')
      end
    end
  end

  context "External Service", :remote_call => true do
    it "places a booking" do
      @api = Atleisure::API.new('lofty', 'tz5ql8')
      @customer = {:surname=>"Hegmann", :initials=>"C", :street=>nil, :postal_code=>nil, :city=>"East Mckaylamouth", :country=>"SG", :email=>"sydni8@email.com", :language=>:en }
      @start_date = Date.new(2013, 1, 14)
      @end_date = Date.new(2013, 1, 16)

      response = @api.place_booking('XX-1234-02', @start_date, @end_date, 3, @customer, 180, 123)
      debugger
      puts response
    end
  end
end