%% Main function to generate tests
function tests = dfaTest
tests = functiontests(localfunctions);
end

%% Fixtures
function setupOnce(testCase)  % do not change function name
% Load input file
testdir = fileparts(mfilename('fullpath'));
resource_path = fullfile(testdir, 'resources', 'dfa');
testCase.TestData.resource_path = resource_path;

% Input data: single column of RR interval values
testCase.TestData.input_data = dlmread(fullfile(resource_path, 'rr-intervals'));

% Expected output data: columns are n, F(n) in log scale
testCase.TestData.expected_ouput = dlmread(fullfile(resource_path, 'dfa.out'));

% First and last box size (n) values
testCase.TestData.n_min = floor(10^testCase.TestData.expected_ouput(1,  1));
testCase.TestData.n_max = floor(10^testCase.TestData.expected_ouput(end,1));
end

function teardownOnce(testCase)  % do not change function name
end

function setup(testCase)  % do not change function name
end

function teardown(testCase)  % do not change function name
end


%% Test Functions

function testDFA(testCase)
sig = testCase.TestData.input_data;
t =  (0:1:(length(sig)-1))';
expected = testCase.TestData.expected_ouput;

expected_n = expected(:,1);
expected_fn = expected(:,2);

[actual_n, actual_fn] = mhrv.rri.dfa(t, sig, 'n_min', testCase.TestData.n_min, 'n_max', testCase.TestData.n_max);
actual_n = log10(actual_n);
actual_fn = log10(actual_fn);

% interpolate to same box-sizes
actual_fn_interp = interp1(actual_n, actual_fn, expected_n);

% mean squared error
mse = nanmean((actual_fn_interp - expected_fn).^2);

assert(mse < 1e-4);
end
