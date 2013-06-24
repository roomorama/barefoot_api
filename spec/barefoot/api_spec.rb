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
end