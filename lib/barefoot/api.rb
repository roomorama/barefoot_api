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
        soap.body = credentials.merge(
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

    def property_booking(property_id, start_date, end_date, customer_id, lease_id)
      logger.info("POST PropertyBooking")
      response = client.request 'PropertyBooking'  do
        http.headers["SOAPAction"] = "http://www.barefoot.com/Services/PropertyBooking"
        soap.body = credentials.merge(
          'Info' => {'string' => booking_params(property_id, start_date, end_date, customer_id, lease_id)}
        )
      end
      logger.debug("Result: #{response.inspect}")
      if response.success?
        result = responseresponse[:property_booking_response][:property_booking_result] rescue false
        result
      end
    end

    def booking_flow
      #quote_id = CreateQuoteByReztypeid
      #quote_id = r[:quote_info][:leaseid]
      #consumer_id = SetConsumerInfo
      #SetCommentsInfo(consumer_id)
      #PropertyBooking(quote_id, consumer_id, ...)
    end

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

    def booking_params(property_id, start_date, end_date, customer_id, lease_id)
      #isTest,strPayment,EzicAccount,propertyId,strADate,strDDate,tid,leaseid,cctranstype,cFName,cLName,
      #EzicTag,EzicTranstype,EzicPaytype,cardNum,expireMonth,expireYear,cvv,ccratetype,cctype
      # optional: street, city, state, zip, country

      test_mode = (self.class.mode != :production)
      info = []
      info << test_mode # isTest
      info << "0" # strAmount
      info << "" # EzicAccount
      info << property_id.to_s # propertyId
      info << start_date.to_date.strftime("%m/%d/%Y") # strADate
      info << end_date.to_date.strftime("%m/%d/%Y") # strDDate
      info << customer_id.to_s # tid
      info << lease_id.to_s # leaseid
      info << "" #cctranstype (empty if no EZIC)
      info << "Roomorama" # cFName
      info << "Payments" # cLName
      info << "" # EzicTag (empty if no EZIC)
      info << "S" # EzicTranstype
      info << "C" # EzicPaytype
      info << "" # carNum (test mode)
      info << "" # expireMonth (test mode)
      info << "" # expireYear (test mode)
      info << "" # cvv (test mode)
      info << "" # ccratetype (test mode)
      info << "" # cctype (test mode)
      info
    end
  end
end