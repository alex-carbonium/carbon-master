var cp = require("child_process");
var path = require("path");
var fs = require("fs");

var npm = process.platform === "win32" ? "npm.cmd" : "npm";

spawnAndPipe("core: ", npm, ["start"], fullPath("../carbon-core"));
spawnAndPipe("ui: ", npm, ["start", "--", "--linkCore"], fullPath("../carbon-ui"));
watchFolder(fullPath("../carbon-core/mylibs/definitions"), fullPath("../carbon-ui/node_modules/@carbonium/carbon-core/types"), /carbon\-.*ts$/gi);

function spawnAndPipe(prefix, program, args, cwd){
    var childProcess = cp.spawn(program, args, {
        cwd: cwd,
        shell: true
    });

    childProcess.stdout.on("data", function(data){
        writeLines(process.stdout, data, prefix);
    });
    childProcess.stderr.on("data", function(data){
        writeLines(process.stderr, data, prefix);
    });
}

function writeLines(stream, data, prefix){
    var lines = data.toString().split("\n");
    for (var i = 0; i < lines.length; ++i){
        var line = lines[i];
        if (line.length === 0){
            continue;
        }
        if (!line.startsWith(" ") && !line.startsWith("ERROR")){
            stream.write(prefix + line + "\n");
        }
        else{
            stream.write(line + "\n");
        }
    }
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