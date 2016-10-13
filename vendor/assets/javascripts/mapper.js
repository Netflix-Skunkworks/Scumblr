function mapFunction(obj, arr, state) {
    var extractURIVars = function(script, path) {
        var scriptSegments = script.split('/');

        scriptSegments = scriptSegments.map(function(segment) {
            if (segment.startsWith('{') && segment.endsWith('}')) {
                return segment.replace('{', '').replace('}', '');
            } else {
                return '';
            }
        });
        var pathSegments = path.split('/');
        var result = pathSegments.reduce(function(state, segment, i) {
            // crude filter for auth tokens that are url variable values
            if (scriptSegments[i] !== '' && segment.length < 20) {
                state[scriptSegments[i]] = segment;
            }
            return state;
        }, {});
        return result;
    }

    var addCmdsToSet = function(cmds, set) {
        return cmds.reduce(function(set, cmd) {
            if (cmd === undefined || cmd === '') {
                return set;
            }

            set[cmd] = true;
            return set;
        }, set);
    }

    var extractHystrixCommands = function(hystrixLog) {
        // Clean log string of status and count
        var l = hystrixLog.replace(/\[[^\[]+\]/g, "");
        l = l.replace(/x[0-9]+/g, "");

        var cmds = l.split(',');
        cmds = cmds.map(function(cmd) {
            return cmd.trim();
        });
        return cmds;
    }

    var path = obj.path;
    var script = obj['response.header.X-Netflix.api-script-endpoint'];
    if (script === undefined || path === undefined) {
        return null;
    }

    /*
    * Initial state for a new script
    */
    var newScriptState = function () {
        return {
            uriVars: {
            },
            postSamples: [],
            getSamples: [],
            //queryString: "",
            hystrixCommands: {},
            //requestMethod: ""
        };
    }
    if (state[script] === undefined) {
        state[script] = newScriptState();
    }

    if (state["track"] === undefined){
        state["date"] = new Date();
        state["track"] = true;
    }

    /*
    * 1. Extract hystrix commands and push them to the set of known commands executed for this script.
    */
    var hystrixLog = obj['response.header.X-Netflix.dependency-command.executions'];
    var cmds = extractHystrixCommands(hystrixLog);
    state[script].hystrixCommands = addCmdsToSet(cmds, state[script].hystrixCommands);
    //state[script].requestMethod = obj['method'];

    /*
    * 2. Extract any URI vars and push them to the set of known values for this script.
    */
    var uriVars = extractURIVars(script, path);
    Object.keys(uriVars).forEach(function(key) {
        if (key === undefined || key === 'undefined' || key === '') {
            return;
        }
        if (state[script].uriVars[key] === undefined) {
            state[script].uriVars[key] = {};
        }
        state[script].uriVars[key][uriVars[key]] = true;
    });

    /*
     * 3. Save away POST samples (cap at 5)
     */
     // if (obj["query"] != undefined)
     // {
     //    state[script].queryString = obj["query"]
     // }

    if (obj.method === 'POST') {
        if (undefined !== obj['request.body'] && obj['request.body'].length >= 1) {
            var requestBody = obj['request.body'];
            if (state[script].postSamples.length < 5) {
                if (requestBody.indexOf("mastertoken") == -1)
                {
                    //var path = obj.path;
                    var postObject = {};
                    postObject[path] = requestBody;
                    state[script].postSamples.push(postObject);
                }else{
                    state[script].postSamples.push('MSL Truncated');
                }
                state[script].requestMethod = 'POST';
            }
        }
    }
    // //Sample GET requests with same rigor
    if (obj.method === 'GET') {
        if (obj["query"] != undefined) {
            var requestQuery = obj["query"];
            if (state[script].getSamples.length < 5) {
                var getObject = {};
                getObject[path] = requestQuery;
                state[script].getSamples.push(getObject);
                //state[script].requestMethod = 'POST';
            }
        }
    }
/*
* We need mechanism to grab GET URI parameters for both POST requests and GET requests
*/
    /*
     * Emit state only once every minute.
     */

    /*
    if (state.lastOutput === null) {
        state.lastOutput = Date.now();
        return state;
    } else {
        var now = Date.now();
        var elapsed = (now - state.lastOutput) / 1000;
        if (elapsed >= 60) {
            state.lastOutput = now;
            return state;
        } else {
            return {};
        }
    }
    */


    //Report every 30 minutes
    if (Math.floor((new Date() - state["date"])/1000/60) >=  30){
        state["date"] = new Date();
        return state;
    } else {
        return null;
    }
}
