define(function () {
    /** Returns a new quote DS for the current customer
    @param {Object[]} bezl - reference to calling bezl
    @param {string} company - Company ID for the calling
    @param {Number} custNum - customer number
    */

    function NewQuote(bezl, company, custNum) {
        bezl.dataService.add('newQuote', 'brdb', 'Epicor10', 'Quote_NewQuoteByCustomer',
            {
                "Connection": "Epicor 10 RS",
                "Company": "EPIC03",
                "CustNum": custNum,
            }, 0);

        bezl.vars.newQuote = true;
    }

    function SaveQuote(bezl, company, quoteNum) {

        bezl.vars.ds.QuoteHed.CustNum = 3;
        bezl.vars.ds.QuoteHed.Company = 'EPIC03';

        bezl.vars.ds.QuoteDtl.forEach(dtl => {
            dtl.QuoteNum = bezl.vars.ds.QuoteHed.QuoteNum;
            dtl.Company = 'EPIC03';
            dtl.RowMod = 'U';
            dtl.CustNum = 3;
            dtl.LineDesc = 'TEST';
        });

        console.log("Quote Update: ");
        console.log(bezl.vars.ds);
        console.log(JSON.stringify(bezl.vars.ds));

        bezl.dataService.add('saveQuote', 'brdb', 'Epicor10', 'Quote_SaveQuote',
            {
                "Connection": "Epicor 10 RS",
                "Company": "EPIC03",
                "QuoteNum": quoteNum,
                "ds": JSON.stringify(bezl.vars.ds)
            }, 0);
    }

    return {
        newQuote: NewQuote,
        saveQuote: SaveQuote
    }
});