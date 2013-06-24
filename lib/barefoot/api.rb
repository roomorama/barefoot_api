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

      if response.success?
        properties_xml = response[:get_property_response][:get_property_result]
        properties = Nori.parse(properties_xml)[:property_list][:property] rescue []
      end
    end

    def get_availabilities(property_id)
      response = client.request 'GetPropertyPartnerRent'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetPropertyPartnerRent"
        soap.body = credentials.merge('propertyId' => property_id)
      end
      if response.success?
        availabilities = response[:get_property_partner_rent_response][:get_property_partner_rent_result][:diffgram][:property][:property_rent] rescue []
        availabilities
      end
    end

    def get_unavailable_dates(property_id)
      response = client.request 'GetPropertyBookingDate'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetPropertyBookingDate"
        soap.body = credentials.merge('propertyId' => property_id)
      end
      if response.success?
        availabilities = response[:get_property_booking_date_response][:get_property_booking_date_result][:diffgram][:new_data_set][:table] rescue []
        availabilities = [availabilities] if availabilities.kind_of?(Hash)
        availabilities
      end
    end

    def get_images(property_id)
      response = client.request 'GetPropertyAllImgs'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/GetPropertyAllImgs"
        soap.body = credentials.merge('propertyId' => property_id)
      end
      if response.success?
        images = response[:get_property_all_imgs_response][:get_property_all_imgs_result][:diffgram][:property][:property_img] rescue []
        images = [images] if images.kind_of?(Hash)
        images
      end
    end

    #def check_availability(house_code, start_date, end_date, price = nil)
    #end

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