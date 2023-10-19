/* 
* ****************************************************************************************************
* Author = 'U3JpIExha3NobWkgS29sbGE='
* Technical Assessment Test
* Test Class For 'GetDirectionsController' Apex Class
* ****************************************************************************************************
*/
@isTest
private class GetDirectionsControllerTest {
    
    // Mock implementation for HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"rows": [{"elements": [{"distance": {"text": "2,218 mi", "value": 3569525}, "duration": {"text": "1 day 9 hours"}}]}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testGetDirectionsMethod() {
        // Set the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Test data
        String origin = '555 Paper Mill RdNewark, DE 19711';
        String destination = '1500 N Fourth StFlagstaff, AZ 86004';
        
        // Retrieve Transportation_Rates__mdt records
        Map<String, Decimal> transportationRatesMap = new Map<String, Decimal>();
        for (Transportation_Rates__mdt rate : [SELECT Transportation_Mode__c, Rate_Per_Mile__c FROM Transportation_Rates__mdt]) {
            transportationRatesMap.put(rate.Transportation_Mode__c, rate.Rate_Per_Mile__c);
        }
        
        // Call the method to be tested
        GetDirectionsController.DirectionsResponse response = GetDirectionsController.getDirections(origin, destination);
        
        // Verify the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.distance, 'Distance should not be null');
        System.assertNotEquals(null, response.travelTime, 'Travel time should not be null');
        System.assertNotEquals(null, response.transportationRates, 'Transportation rates should not be null');
        System.assertEquals(2, response.transportationRates.size(), 'There should be one transportation rate');
        
        // Verify the transportation rate
        Decimal expectedFlyingRate =  2218*transportationRatesMap.get('Flying');
        Decimal expectedDrivingRate =  2218*transportationRatesMap.get('Driving');
        Decimal actualFlyingRate = response.transportationRates.get('Flying');
        Decimal actualDrivingRate = response.transportationRates.get('Driving');
        System.assertEquals(expectedFlyingRate.setScale(2), actualFlyingRate, 'Flying Transportation rate should match the expected Flying rate');
        System.assertEquals(expectedDrivingRate.setScale(2), actualDrivingRate, 'Driving Transportation rate should match the expected Driving rate');
    }
}