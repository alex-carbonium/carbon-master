var cp = require("child_process");
var path = require("path");
var fs = require("fs");

var npm = process.platform === "win32" ? "npm.cmd" : "npm";

spawnAndPipe("core: ", npm, ["start"], fullPath("../carbon-core"));
spawnAndPipe("ui: ", npm, ["start", "--", "--linkCore"], fullPath("../carbon-ui"));
watchFolder(fullPath("../carbon-core/mylibs/definitions"), fullPath("../carbon-ui/target"), /carbon\-.*ts$/gi);

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

function watchFolder(source, target, filePattern){
    var files = fs.readdirSync(source).filter(x => {
        filePattern.lastIndex = 0;
        return filePattern.test(x)
    });

    for (var i = 0; i < files.length; ++i){
        copyFile(path.join(source, files[i]), path.join(target, files[i]));
    }

    fs.watch(source, (e, filename) => {
        if (filePattern.test(filename)){
            copyFile(path.join(source, filename), path.join(target, filename));
        }
    });
}

function copyFile(source, target){
    console.log("Copying", path.basename(source), "to", target);
    fs.createReadStream(source).pipe(fs.createWriteStream(target));
}

function fullPath(relativePath){
    return path.join(__dirname, relativePath);
}