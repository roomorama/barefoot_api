require 'benchmark'
require 'logger'

module Barefoot
  class API
    include CoreExtensions

    def self.mode=(mode)
      @@mode = mode
    end

    def self.mode
      @@mode
    end

    self.mode = :test

    attr_accessor :logger

    def initialize(user, password, account, partneridx)
      @user = user
      @password = password
      @account = account
      @partneridx = partneridx
      @logger = Logger.new("/dev/null")
      #@logger.level = Logger::INFO
    end

    def client
      @client ||= Savon.client("http://agent.barefoot.com/BarefootWebService/bookingaccess3.asmx?WSDL")
    end

    def get_properties
      logger.info("POST GetProperty")
      response = client.request 'GetProperty'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetProperty"
        soap.body = credentials
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        properties_xml = response[:get_property_response][:get_property_result]
        properties = Nori.parse(properties_xml)[:property_list][:property] rescue []
      end
    end

    def get_availabilities(property_id)
      logger.info("POST GetPropertyPartnerRent")
      response = client.request 'GetPropertyPartnerRent'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetPropertyPartnerRent"
        soap.body = credentials.merge('propertyId' => property_id)
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        availabilities = response[:get_property_partner_rent_response][:get_property_partner_rent_result][:diffgram][:property][:property_rent] rescue []
        availabilities
      end
    end

    def get_unavailable_dates(property_id)
      logger.info("POST GetPropertyBookingDate")
      response = client.request 'GetPropertyBookingDate'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetPropertyBookingDate"
        soap.body = credentials.merge('propertyId' => property_id)
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        availabilities = response[:get_property_booking_date_response][:get_property_booking_date_result][:diffgram][:new_data_set][:table] rescue []
        availabilities = [availabilities] if availabilities.kind_of?(Hash)
        availabilities
      end
    end

    def get_images(property_id)
      logger.info("POST GetPropertyAllImgs")
      response = client.request 'GetPropertyAllImgs'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetPropertyAllImgs"
        soap.body = credentials.merge('propertyId' => property_id)
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        images = response[:get_property_all_imgs_response][:get_property_all_imgs_result][:diffgram][:property][:property_img] rescue []
        images = [images] if images.kind_of?(Hash)
        images
      end
    end

    def is_property_available(property_id, start_date, end_date)
      logger.info("POST IsPropertyAvailability")
      response = client.request 'IsPropertyAvailability'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/IsPropertyAvailability"
        soap.body = credentials.merge(
          'propertyId' => property_id,
          'date1' => start_date.to_date.strftime("%m/%d/%Y"),
          'date2' => end_date.to_date.strftime("%m/%d/%Y")
          )
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        response[:is_property_availability_response][:is_property_availability_result] rescue false
      end
    end

    def get_quote(property_id, start_date, end_date, guests)
      partneridx = @partneridx
      logger.info("POST GetQuoteRatesDetail")
      response = client.request 'GetQuoteRatesDetail'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetQuoteRatesDetail"
        soap.body = credentials.merge(
          'propertyId' => property_id,
          'strADate' => start_date.to_date.strftime("%m/%d/%Y"),
          'strDDate' => end_date.to_date.strftime("%m/%d/%Y"),
          'num_adult' => guests,
          'num_pet' => 0,
          'num_baby' => 0,
          'num_child' => 0,
          'reztypeid' => partneridx
        )
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        Nori.parse(response[:get_quote_rates_detail_response][:get_quote_rates_detail_result])[:propertyratesdetails] rescue false
      end
    end

    def create_quote(property_id, start_date, end_date, guests)
      partneridx = @partneridx
      logger.info("POST CreateQuoteByReztypeid")
      response = client.request 'CreateQuoteByReztypeid'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/CreateQuoteByReztypeid"
        soap.body = credentials.merge(
          'propertyId' => property_id,
          'strADate' => start_date.to_date.strftime("%m/%d/%Y"),
          'strDDate' => end_date.to_date.strftime("%m/%d/%Y"),
          'num_adult' => guests,
          'num_pet' => 0,
          'num_baby' => 0,
          'num_child' => 0,
          'reztypeid' => partneridx
        )
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        Nori.parse(response[:create_quote_by_reztypeid_response][:create_quote_by_reztypeid_result])[:output_list] rescue false
      end
    end

    def set_consumer_info(customer)
      logger.info("POST SetConsumerInfo")
      response = client.request 'SetConsumerInfo'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/SetConsumerInfo"
        params = credentials
        params.delete('partneridx')
        logger.info customer_params(customer)
        soap.body = params.merge(
          'Info' => {'string' => customer_params(customer)}
        )
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        info_id = response[:set_consumer_info_response][:set_consumer_info_result].to_i rescue false
        info_id = false if info_id == 0
        info_id
      end
    end

    #def place_booking(house_code, start_date, end_date, number_of_guests, customer, price, inquiry_id)
    #end

    protected

    def credentials
      {
        'username' => @user,
        'password' => @password,
        'barefootAccount' => @account,
        'partneridx' => @partneridx
      }
    end

    def customer_params(customer)
      info = []
      info << customer[:street_address] # street1
      info << '' # street2
      info << customer[:city] # city
      info << '' # state
      info << customer[:postal_code] # zip
      info << customer[:country] # country
      info << customer[:last_name] # lastname
      info << customer[:first_name] # firstname
      info << customer[:phone_number] # homephone
      info << '' # bizphone
      info << '' # fax
      info << '' # mobile
      info << customer[:email] # email (Required)
      info << '0' # PropertyID
      #info << 'Roomorama.com' # SourceOfBusiness
      info
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

  end
end