/* 
 * ****************************************************************************************************
 * Author = 'U3JpIExha3NobWkgS29sbGE='
 * Technical Assessment Test
 * This Apex Class Handles The Following Calculations Based On Origin Address And Destination Address:
 * 1 - Travel Distance
 * 2 - Travel Time
 * 3 - Travel Cost
 * Google API Has Been Used To Calculate The Travel Distance And Travel Time
 * ****************************************************************************************************
 */

public with sharing class GetDirectionsController {
    private static String vHash = 'U3JpIExha3NobWkgS29sbGE='; //Encoded Full Name
    
    @AuraEnabled(cacheable=true)
    public static DirectionsResponse getDirections(String origin, String destination) {
        DirectionsResponse response = new DirectionsResponse();
        
		// Call Google Maps API to calculate distance based on origin and destination addresses
        String apiUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins=' + EncodingUtil.urlEncode(origin, 'UTF-8') +
                        '&destinations=' + EncodingUtil.urlEncode(destination, 'UTF-8') +
                        '&units=imperial' + // Specify unit system as imperial for miles and feet
                        '&key='+Label.GoogleAPIKey;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiUrl);
        request.setMethod('GET');

        Http http = new Http();
        HttpResponse httpResponse = http.send(request);

        if (httpResponse.getStatusCode() == 200) {
            
            // Parse the JSON response to get the distance, travel time, and transportation rates
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
            List<Object> rows = (List<Object>) jsonResponse.get('rows');
            Map<String, Object> firstRow = (Map<String, Object>) rows.get(0);
            List<Object> elements = (List<Object>) firstRow.get('elements');
            Map<String, Object> distanceInfo = (Map<String, Object>) elements.get(0);
            Map<String, Object> distance = (Map<String, Object>) distanceInfo.get('distance');
            Map<String, Object> durationInfo = (Map<String, Object>) elements.get(0);
            Map<String, Object> duration = (Map<String, Object>) durationInfo.get('duration');
            
            String distanceValue = String.valueOf(distance.get('value'));
            Decimal distanceValueMiles = Integer.valueOf(distanceValue) / 1609.344; // Convert meters to miles

            // Set distance and travel time in the response
            response.distance = (String) distance.get('text'); 
            response.travelTime = (String) duration.get('text');

            // Retrieve transportation rates from custom metadata types and set them in response object
            response.transportationRates = new Map<String, Decimal>();
            List<Transportation_Rates__mdt> rates = [SELECT Transportation_Mode__c, Rate_Per_Mile__c FROM Transportation_Rates__mdt];
            for (Transportation_Rates__mdt rate : rates) {
                response.transportationRates.put(rate.Transportation_Mode__c, (rate.Rate_Per_Mile__c * distanceValueMiles).setScale(2));
            }
        } else {
            // API error handling
            response.transportationRates = new Map<String, Decimal>();
            response.transportationRates.put('Error', 0);
        }

        return response;
    }
    
    //DirectionsResponse object to store distance, travelTime and transporationsRates
    public class DirectionsResponse {
        @AuraEnabled
        public String distance { get; set; }
        @AuraEnabled
        public String travelTime { get; set; }
        @AuraEnabled
        public Map<String, Decimal> transportationRates { get; set; }
    }
}