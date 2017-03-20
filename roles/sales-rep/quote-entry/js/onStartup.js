define(["./quote.js"], function (quote) {
    function OnStartup(bezl) {
        quote.runQuery(bezl, 'Quotes');
        quote.runQuery(bezl, 'SalesReps');
        quote.runQuery(bezl, 'Parts');

        bezl.vars.ds = new Array();
    }

    return {
        onStartup: OnStartup
    }
});