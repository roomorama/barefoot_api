require 'benchmark'
require 'logger'

module Atleisure
  class API
    include CoreExtensions

    attr_accessor :logger

    def initialize(user, password)
      @user = user
      @password = password
      @logger = Logger.new("/dev/null")
      #@logger.level = Logger::INFO
    end

    def get_properties
      retry_times(3) do
        client = Jimson::Client.new("https://listofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
        logger.info("POST ListOfHousesV1")
        result = client.ListOfHousesV1(credentials)
      end
    end

    def get_properties_data(identifiers, items = ['BasicInformationV3'])
      identifiers = [identifiers] if identifiers.is_a?(String)

      result = nil
      time = Benchmark.measure do
        client = Jimson::Client.new("https://dataofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
        logger.info("POST DataOfHousesV1")
        result = client.DataOfHousesV1({
          'HouseCodes' => identifiers,
          'Items' => items}.merge(credentials)
        )
      end
      time_ms = "%.2f" % (time.real * 1000)
      #puts "[#{time_ms}ms] Fetching properties data (#{identifiers[0..10].join(', ')})"

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
          client = Jimson::Client.new("https://referencelayoutitemsv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
          logger.info("POST ReferenceLayoutItemsV1")
          raw_result = client.ReferenceLayoutItemsV1(credentials)
          logger.debug("Result: #{raw_result}")
          raw_result
        end
      end
    end

    def check_availability(house_code, start_date, end_date, price = nil)
      client = Jimson::Client.new("https://checkavailabilityv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")

      params = {
        'HouseCode' => house_code,
        'ArrivalDate' => start_date.to_date.to_s,
        'DepartureDate' => end_date.to_date.to_s,
        'Price' => price || ''
      }

      logger.info("POST CheckAvailabilityV1 #{params}")
      raw_result = client.CheckAvailabilityV1(params.merge(credentials))
      logger.debug("Result: #{raw_result}")
      result = {
        available: raw_result['Available'] == 'Yes' && raw_result['OnRequest'] == 'No'
      }
      if result[:available]
        result[:price] = raw_result['CorrectPrice'].to_i
        result[:price_message] = raw_result['PriceMessage']
      end
      result
    end

    # Retrieve the additions before a booking
    def booking_additions(house_code, start_date, end_date, number_of_guests, customer_country_code)
      client = Jimson::Client.new("https://checkavailabilityv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")

      params = {
        'HouseCode' => house_code,
        'ArrivalDate' => start_date.to_date.to_s,
        'DepartureDate' => end_date.to_date.to_s,
        'NumberOfAdults' => number_of_guests,
        'NumberOfChildren' => '0',
        'NumberOfBabies' => '0',
        'NumberOfPets' => '0',
        'CustomerCountry' => customer_country_code
      }

      logger.info("POST BookingAdditionsV1 #{params}")
      raw_result = client.BookingAdditionsV1(params.merge(credentials))
      logger.debug("Result: #{raw_result}")
      raw_result
    end

    def place_booking(house_code, start_date, end_date, number_of_guests, customer, price, inquiry_id)
      client = Jimson::Client.new("https://placebookingv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")

      params = {
        'WebpartnerBookingCode' => inquiry_id,
        'BookingOrOption' => 'Booking',
        'HouseCode' => house_code,
        'ArrivalDate' => start_date.to_date.to_s,
        'DepartureDate' => end_date.to_date.to_s,
        'NumberOfAdults' => number_of_guests,
        'NumberOfChildren' => '0',
        'NumberOfBabies' => '0',
        'NumberOfPets' => '0',
        'WebsiteRentPrice' => price,
        'Test' => 'Yes'
      }

      customer_params = {
        'CustomerSurname' => pad_customer_surname(customer[:surname]),
        'CustomerInitials' => customer[:initials],
        'CustomerStreet' => customer[:street],
        'CustomerHouseNumber' => customer[:house_number],
        'CustomerZipCode' => customer[:postal_code],
        'CustomerCity' => customer[:city],
        'CustomerCountry' => customer[:country] || "US",
        'CustomerTelephone1Number' => customer[:phone_number],
        'CustomerEmail' => customer[:email],
        'CustomerLanguage' => guess_customer_locale(customer[:language])
      }

      params.merge!(customer_params)
      params.delete_if { |k,v| v.nil? }

      begin
        logger.info("POST PlaceBookingV1 #{params}")
        raw_result = client.PlaceBookingV1(params.merge(credentials))
        logger.info("Result: #{raw_result}")
      rescue Exception => e
        logger.error("Error: #{e.message}")
        {error: e.message}
      else
        result = {}
        raw_result.each{|k,v| result[underscore(k)] = v}
        symbolize_keys!(result)
      end
    end

    def details_of_one_booking(booking_number)
      client = Jimson::Client.new("https://detailsofonebookingv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm")
      params = {
        'BookingNumber' => booking_number
      }
      logger.info("POST DetailsOfOneBookingV1 #{params}")
      raw_result = client.DetailsOfOneBookingV1(params.merge(credentials))
      logger.debug("Result: #{raw_result}")
      raw_result
    end

    protected

    def credentials
      { 'WebpartnerCode' => @user,
        'WebpartnerPassword' => @password }
    end

    def pad_customer_surname(surname)
      if surname.nil? || surname.length.zero?
        "Guest"
      elsif surname.length == 1
        surname + "."
      else
        surname
      end
    end

    def guess_customer_locale(language)
      languages = %w(NL FR DE EN IT ES PL)

      # Valid values
      if language && languages.include?(language.upcase)
        return language.upcase
      end

      # Try to guess
      case language
        when /^en/i
          'EN'
        when /^it/i
          'IT'
        when /^es/i
          'ES'
        when /^fr/i
          'FR'
        when /^de/i
          'DE'
        else
          'EN'
      end
    end

    def retry_times(max_retries)
      retries_left = max_retries
      begin
        yield
      rescue Exception => e
        if retries_left > 0
          retries_left -= 1
          logger.warn "WARNING: Retrying - #{e.inspect}"
          retry
        else
          raise
        end
      end
    end
  end
end