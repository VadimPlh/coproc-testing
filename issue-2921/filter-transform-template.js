const {
    SimpleTransform,
    PolicyError,
    PolicyInjection
} = require("@vectorizedio/wasm-api");
const transform = new SimpleTransform();
/* Topics that fire the transform function */
transform.subscribe([["_input", PolicyInjection.Stored]]);
/* The strategy the transform engine will use when handling errors */
transform.errorHandler(PolicyError.SkipOnFailure);
/* Transform function */
transform.processRecord((recordBatch) => {
    const result = new Map();
    const transformedRecord = recordBatch.map(({ header, records }) => {
        res = new Array(Record);
        records.forEach(element => {
            if (element.valSize < 1000) {
                res.push(element)
            }
        })
        return {
            header,
            records: res,
        };
    });
    result.set("output", transformedRecord);
    // processRecord function returns a Promise
    return Promise.resolve(result);
});
exports["default"] = transform;