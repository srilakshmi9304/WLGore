import { LightningElement, track } from 'lwc';
import getDirections from '@salesforce/apex/GetDirectionsController.getDirections';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GetDirections extends LightningElement {
    @track origin = '';
    @track destination = '';
    @track directions = {
        distance: '',
        travelTime: '',
        transportationRates: {}
    };
    @track transportationRatesKeys = [];
    @track error;

    connectedCallback() {
        this.loadGoogleMapsScript();
    }

    loadGoogleMapsScript() {
        const googleMapsScript = document.createElement('script');
        googleMapsScript.src = `https://maps.googleapis.com/maps/api/js?key=AIzaSyCYfXEk_XcHNUPaVbuor6--H770xba28cQ&libraries=places&callback=whereAutocomplete`;
        googleMapsScript.onload = () => {
            this.setupAutocomplete();
        };
        document.head.appendChild(googleMapsScript);
    }

    setupAutocomplete() {
        const originInput = this.template.querySelector('#originInput');
        const destinationInput = this.template.querySelector('#destinationInput');
    
        const originAutocomplete = new google.maps.places.Autocomplete(originInput);
        const destinationAutocomplete = new google.maps.places.Autocomplete(destinationInput);
    
        originAutocomplete.addListener('place_changed', () => {
            const place = originAutocomplete.getPlace();
            this.origin = place.formatted_address;
        });
    
        destinationAutocomplete.addListener('place_changed', () => {
            const place = destinationAutocomplete.getPlace();
            this.destination = place.formatted_address;
        });
    }
    

   // handleOriginInputChange(event) {
       // this.origin = event.target.value;
   // }

   handleOriginInputChange(event) {
    const selectedOriginAddress = event.target.street + event.target.city + event.target.province +event.target.country + event.target.postalcode;
    this.origin = selectedOriginAddress;
    console.log("Origin Zipcode is :: "+event.target.postalcode);
    console.log("Origin address is :: "+this.origin);
    }   

    handleDestinationInputChange(event) {
        const selectedDestinationAddress = event.target.street + event.target.city + event.target.province +event.target.country + event.target.postalcode;
        this.destination = selectedDestinationAddress;
        console.log("destination address is :: "+this.destination);
    }

    getDirections() {
        if (this.origin && this.destination) {
            getDirections({ origin: this.origin, destination: this.destination })
                .then(result => {
                    // Update component properties with the response data
                    this.directions.distance = result.distance;
                    this.directions.travelTime = result.travelTime;
                    
                    // Convert transportation rates map to an array of objects
                    this.directions.transportationRates = [];
                    for (let mode in result.transportationRates) {
                        if (result.transportationRates.hasOwnProperty(mode)) {
                            this.directions.transportationRates.push({
                                mode: mode,
                                rate: result.transportationRates[mode]
                            });
                        }
                    }

                    this.error = undefined; // Clear any previous errors
                })
                .catch(error => {
                    console.error(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error occurred while fetching transportation rates.',
                            variant: 'error'
                        })
                    );
                    // Clear directions and transportation rates in case of error
                    this.directions = {
                        distance: '',
                        travelTime: '',
                        transportationRates: []
                    };
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter both origin and destination addresses.',
                    variant: 'error'
                })
            );
            // Clear directions and transportation rates in case of error
            this.directions = {
                distance: '',
                travelTime: '',
                transportationRates: []
            };
        }
    } 
}