function [ res, out ] = jsystem( cmd )
%JSYSTEM Execute a shell command
%   Executes a shell command as a subprocess using java's ProcessBuilder
%   class. This is much faster than using the builtin matlab 'system'
%   command.

pb = java.lang.ProcessBuilder({'/bin/sh', '-c', cmd});
pb.environment.put('PATH', [char(pb.environment.get('PATH')) ':/usr/local/bin']);
pb.directory(java.io.File(pwd));
pb.redirectErrorStream(true);

process = pb.start();

is = process.getInputStream();
scanner = java.util.Scanner(is).useDelimiter('\\A');
if scanner.hasNext()
    out = scanner.next();
else
    out = '';
end

res = process.waitFor();

end