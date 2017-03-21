define(["./customer.js"], function (customer) {

    var delay = 100;
    var nextAddress = 0;
    var cust = customer;

    function GetInfoWindowContent (Title, Address, Contacts) {
        // Develop the HTML for the customer contacts
        var contactHtml = '<br><h4>Contacts</h4>';
        var contacts = $.parseXML(Contacts);
        var contactsXml = $(contacts);

        contactsXml.find('Contact').each(function(index){
            var cntName = $(this).find('ContactName').text();
            var cntEmail = $(this).find('EMailAddress').text();
            var title = $(this).find('ContactTitle').text();
            var phoneNum = $(this).find('PhoneNum').text();

            if (title) {
            contactHtml += '<b>' + title + '</b>';
            }

            if (cntName) {
            contactHtml += '<br>' + cntName;
            }

            if (phoneNum) {
            contactHtml += '<br>Phone: <a href=\"tel:' + phoneNum + '\">' + phoneNum + '</a>';
            }

            if (cntEmail) {
            contactHtml += '<br>Email: <a href=\"mailto:' + cntEmail + '\">' + cntEmail + '</a>';
            }

            contactHtml += '<br>';
        });

        var contentString = 
            '<div id="content">'+
                '<div id="siteNotice">'+
                '</div>'+
                '<h4 id="firstHeading" class="firstHeading">' + Title + '</h4>'+
                '<div id="bodyContent">'+
                    '<a href=\"http://maps.google.com/maps?q=' + encodeURI(Address) + '\" target=\"_blank\">' + Address + '</a>' +
                    ((contacts) ? contactHtml : '')
                '</div>'+
            '</div>';
        
        return contentString;
    }

     function theNext(bezl) {
        if (nextAddress < bezl.vars.customers.length - 1) {
            if(bezl.vars.customers[nextAddress].data.Geocode_Location == '' || bezl.vars.customers[nextAddress].data.Geocode_Location == null)
            {
                setTimeout(function(){getAddress({ 
                                    streetAddress: bezl.vars.customers[nextAddress].data.Address, 
                                    title: bezl.vars.customers[nextAddress].data.Name, 
                                    custNum: bezl.vars.customers[nextAddress].data.CustNum,
                                    shipToNum: bezl.vars.customers[nextAddress].data.ShipToNum,
                                    data: bezl.vars.customers[nextAddress].data 
                                }, theNext, bezl)}, delay);
            }
          nextAddress++;
        } else {
          // We're done. 
         bezl.vars.geoTracker = 100;
         // Forces update of DOM
            setTimeout(function(){ 
                progressBar.style.width= bezl.vars.geoTracker + '%';
            }, 200);
         bezl.vars.loading.customerList = false;
         //Updates list
         cust.runQuery(bezl, "CustList");
         
        }
      }

      // ====== Geocoding ======
      function getAddress(customerRecord, next, bezl) {
        bezl.vars.geocoder.geocode({address:`${customerRecord.streetAddress}`}, function (results,status)
          { 
            // If that was successful
            if (status == google.maps.GeocoderStatus.OK) {
              // Output the data
               if (results != null && results.length > 0) {

                var marker = new bezl.vars.client.Marker({
                position: results[0].geometry.location,
                map: bezl.vars.map,
                title: customerRecord.title,
                data: customerRecord.data,
                lat: results[0].geometry.location.lat(),
                lng: results[0].geometry.location.lng()
            });
               }
             bezl.vars.markers[customerRecord.custNum] = marker;

              var g = JSON.stringify(results[0].geometry.location)
            .replace(/"/g, '')
            .replace('{', '')
            .replace('}', '');

            bezl.vars.geoLocsDone++;
            bezl.vars.geoTracker = Math.round((bezl.vars.geoLocsDone / bezl.vars.geoLocsNeeded)*100);
            var progressBar = document.getElementById('geoProgress');

            // Forces update of DOM
            setTimeout(function(){ 
                progressBar.style.width= bezl.vars.geoTracker + '%';
            }, 200);

            updateGeo(bezl, customerRecord, g);

                
            }
            else {
              // if we were sending the requests to fast, try this one again and increase the delay
              if (status == google.maps.GeocoderStatus.OVER_QUERY_LIMIT) {
                nextAddress--;
                delay++;
              } else {
                console.log('Geocoding Error');
              }   
            }
            next(bezl);
          }
        );
      }

    function updateGeo(bezl, customerRecord, g) {
         // Update the database so we don't need to look this up next time
            bezl.dataService.add('SetGeocodeOnAddress_' + customerRecord.custNum,'brdb','sales-rep-queries','ExecuteNonQuery',
                                { "QueryName": "SetGeocodeOnAddress",
                                    "Parameters": [
                                        { "Key": "Geocode_Location", "Value": g || '' },
                                        { "Key": "CustNum", "Value": customerRecord.custNum },
                                        { "Key": "CustID", "Value": customerRecord.data.CustID || '' }
                                    ] },0);  
    }

    function UpdateAddress(bezl) {
       
        
            bezl.vars.markers[nextAddress].setMap(null);
            
            var marker = new bezl.vars.client.Marker({
                position: bezl.vars.customers[nextAddress].Geocode_Location,
                map: bezl.vars.map,
                label: 'A',
                title: '',
                lat: bezl.vars.customers[nextAddress].Geocode_Location.geometry.location.lat(),
                lng: bezl.vars.customers[nextAddress].Geocode_Location.geometry.location.lng()
            });
              

            bezl.vars.markers[nextAddress] = marker;
            
    }
  
    return {
        getInfoWindowContent: GetInfoWindowContent,
        updateAddress: UpdateAddress,
        theNext: theNext
    }
});