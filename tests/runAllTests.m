% You should be in the decar_animate top folder to run this script, with
% this whole repo added to the path.
addpath(pwd);
results = runtests('./tests')
table(results)