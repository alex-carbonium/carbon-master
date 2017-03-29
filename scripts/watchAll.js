var cp = require("child_process");
var path = require("path");

spawnAndPipe("core: ", "npm.cmd", ["start"], fullPath("../carbon-core"));
spawnAndPipe("ui: ", "npm.cmd", ["start", "--", "--linkCore"], fullPath("../carbon-ui"));

function spawnAndPipe(prefix, program, args, cwd){
    var childProcess = cp.spawn(program, args, {
        cwd: cwd,
        shell: true
    });

    childProcess.stdout.on("data", function(data){
        process.stdout.write(prefix + data.toString());
    });
    childProcess.stderr.on("data", function(data){
        process.stderr.write(prefix + data.toString());
    });
}

function fullPath(relativePath){
    return path.join(__dirname, relativePath);
}