define(["./account.js"], function (account) {
 
    function OnStartup (bezl) {        
        // Initiate the call to refresh the customer list
        account.runQuery(bezl, 'Accounts');
        account.runQuery(bezl, 'AccountContacts');
    }
  
  return {
    onStartup: OnStartup
  }
});