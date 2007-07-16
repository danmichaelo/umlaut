=begin

A ServiceResponse is a piece of data generated by a Service. It usually will
be displayed on the resolve menu.

ServiceResponses have a service type, represented by a string. When displaying, ServiceResponses are typically grouped into lists by service type. ServiceResponses are tied to the Service that created them, with the service accessor.

ServiceResponses have a few basic attributes stored in columns in the db: 'display_text' is the text to put in the hyperlink. 'notes' is available for longer explanatory text (\n in notes will be converted to <br> by view). 'url' can be used to store the url to link to (but see below on linking mechanism). 

[The legacy columns response_key, value_string, value_alt_string and value_text are deprecated and should not be used, but some legacy Services still use them, so they're still there for now].

In addition, there's a Hash (automatically serialized by ActiveRecord) that's stored in service_data, for arbitrary additional data that a Service can store--whatever you want, just put it in. However, there are conventions that may save you time when passing data to the View. See below. You can also access [] directly on teh ServiceResponse to get to this hash.

ServiceResponse is connected to a Request via the ServiceType join table. The data architecture allows a ServiceResponse to be tied to multiple requests, perhaps to support some kind of cacheing re-use in the future. But at present, the code doesn't do this, a ServiceResponse will really only be related to one request. However, a ServiceResponse can be related to a single Request more than once--once per each type of service response. ServiceType is really a three way join, representing a ServiceResponse, attached to a particular Request, with a particular ServiceTypeValue.  


View Display of ServiceResponse

The resolve menu View expects a Hash (or Hash-like) object with certain conventional keys, to display a particular ServiceResponse. You can provide code in your Service to translate a ServiceResponse to a Hash. But you often don't need to, becuase guess what, ServiceResponse itself implements [] and []= to be just such a Hash-like object. If the Service stores properties in there using conventional keys (see below), no further translation is needed.

However, if you need to do further translation you can implement methods on the Service, of the form: "to_[service type string](response)", for instance "to_fulltext". Umlaut will give it a ServiceResponse object, method should return a hash (or hash-like obj).  Service can also implement a method response_to_view_data(response), as a 'default' translation. This mechanism of various possible 'translations' is implemented by Service#view_data_from_service_type.

Url generation

At the point the user clicks on a ServiceResponse, Umlaut will attempt to find a url for the ServiceResponse, by calling response_url(response) on the relevant Service. The default implementation in service.rb just returns service_response['url'], so the easiest way to do this is just to put the url in service_response['url'].  However, your Service can over-ride this method to provide it's own implementation to generate to generate the url on demand in any way it wants.  If it does this, technically service_response['url'] doesn't need to include anything. But if you have a URL, you may still want to put it there, for Umlaut to use in guessing something about the destination, for de-duplication and possibly other future purposes.  

 Conventional keys:

 Absolute minimum: 
 :display_text

 Basic set (used by fulltext)
 :display_text
 :notes          [newlines converted to <br>]
 :coverage
 :authentication

 Holdings set adds:
 :source_name
 :call_number
 :status

 Some more used by Horizon holdings:
 :coverage_array (Array of coverage strings.)
 :due_date
 :collection_str
 :location_str

=end
class ServiceResponse < ActiveRecord::Base
  @@built_in_fields = [:display_text, :url, :notes]
  has_many :service_types
  serialize :service_data

  def initialize(params = nil)
    super(params)
    self.service_data = {} unless self.service_data
  end
  
  def service
    return ServiceList.get( self.service_id )
  end

  # Allows you to access ServiceResponse like a hash, either for the basic
  # included attributes, or for the the service_data hash! Symbols passed in
  # will be 'normalized' to strings before being used as keys. So symbols
  # and strings are interchangeable. Normally, keys should be symbols.  
  def [](key)        
    if @@built_in_fields.include?(key)
      return self.send(key)
    else
      return service_data[key]
    end
  end

  def []=(key, value)
    if(@@built_in_fields.include?(key))
      self.send(key+'=', value)
    else
      service_data[key] = value
    end
  end
end
