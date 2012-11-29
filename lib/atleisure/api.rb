module Atleisure
  class API
    def initialize(user, password)
      @user = user
      @password = password
    end

    def get_properties
      retry_times(3) do
        @client = Jimson::Client.new("https://listofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
        result = @client.ListOfHousesV1(credentials)
      end
    end

    def get_properties_data(identifiers, items = ['BasicInformationV3'])
      identifiers = [identifiers] if identifiers.is_a?(String)

      result = nil
      time = Benchmark.measure do
        @client = Jimson::Client.new("https://dataofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
        result = @client.DataOfHousesV1({
          'HouseCodes' => identifiers,
          'Items' => items}.merge(credentials))
      end
      time_ms = "%.2f" % (time.real * 1000)
      #Ingest::Base.say "[#{time_ms}ms] Fetching properties data (#{identifiers[0..10].join(', ')})"

      result
    end

    def get_full_properties_data(identifiers)
      get_properties_data(identifiers, [
        "BasicInformationV3",
        "MediaV1",
        "LanguagePackNLV3",
        "LanguagePackFRV3",
        "LanguagePackDEV3",
        "LanguagePackENV3",
        "LanguagePackITV3",
        "LanguagePackESV3",
        "LanguagePackPLV3",
        "PropertiesV1",
        "LayoutExtendedV2",
        "DistancesV1",
        "AvailabilityPeriodV1"
       ])
    end

    def get_layout_items
      @layout_items ||= begin
        #puts "Fetching layout items"
        retry_times(3) do
          @client = Jimson::Client.new("https://referencelayoutitemsv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
          result = @client.ReferenceLayoutItemsV1(credentials)
        end
      end
    end

    protected

    def credentials
      { 'WebpartnerCode' => @user,
        'WebpartnerPassword' => @password }
    end

    def retry_times(max_retries)
      retries_left = max_retries
      begin
        yield
      rescue Exception => e
        if retries_left > 0
          retries_left -= 1
          puts "WARNING: Retrying - #{e.inspect}"
          retry
        else
          raise
        end
      end
    end
  end
end