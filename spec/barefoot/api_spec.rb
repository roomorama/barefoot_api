# encoding: UTF-8
require 'barefoot'

describe Barefoot::API do
  context "MockClient" do
    before do
      @mock_client = double('Savon::Client')
      Savon.stub(:client).and_return(@mock_client)
      @api = Barefoot::API.new('dummy', 'pass', 'account', 'partneridx')
      #@api.logger = Logger.new("./bla.log")
    end

    describe "#get_property" do
    end
  end

  context "External Calls" do
    before do
      @api = Barefoot::API.new('Roomorama', '#Room0514$', 'v3cdemo', '1030')
    end

    it "creates quotes" do
      d1 = Date.today + 30
      d2 = d1 + 10
      r = @api.create_quote(7520, d1, d2, 2)
      r2 = @api.get_quote(7520, d1, d2, 2)
      debugger
      puts r.inspect
    end

    it "sets consumer info" do
      customer = {
        first_name: 'Mr',
        last_name: 'Test',
        street_address: '115 Amoy St',
        city: 'Singapore',
        postal_code: '069935',
        country: 'Singapore',
        phone_number: '+65 6534 2312',
        email: "barefoot@roomorama.com"
      }
      r = @api.set_consumer_info(customer)

      debugger
      puts r.inspect
    end

    it "created full booking" do
      d1 = Date.today + 30
      d2 = d1 + 10
      # r = @api.create_quote(7520, d1, d2, 2)
      # quote_id = r[:quote_info][:leaseid]

      # customer = {
      #   first_name: 'Mr',
      #   last_name: 'Test',
      #   street_address: '115 Amoy St',
      #   city: 'Singapore',
      #   postal_code: '069935',
      #   country: 'Singapore',
      #   phone_number: '+65 6534 2312',
      #   email: "barefoot@roomorama.com"
      # }
      # customer_id = @api.set_consumer_info(customer)

      customer_id = 7771
      quote_id = 9129
      r = @api.property_booking(7520, d1, d2, customer_id, quote_id)
      debugger
      puts r
    end
  end
end