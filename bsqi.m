function [ F1, Se, PPV, TP, FP, FN ] = bsqi(refqrs, testqrs, thresh, fs)
%BSQI_MATLAB Calculate bSQI of two inputs
%   Detailed explanation goes here

% == managing inputs
if nargin<3; thresh=0.05; end;
if nargin<4; fs=250; end;

thresh_samples = thresh * fs;
NB_REF  = length(refqrs);
NB_TEST = length(testqrs);

% == core function
[IndMatch,Dist] = dsearchn(refqrs,testqrs);         % closest ref for each point in test qrs
IndMatchInWindow = IndMatch(Dist < thresh_samples); % keep only the ones within a certain window
NB_MATCH_UNIQUE = length(unique(IndMatchInWindow)); % how many unique matching
TP = NB_MATCH_UNIQUE;                               % number of identified ref QRS
FN = NB_REF-TP;                                     % number of missed ref QRS
FP = NB_TEST-TP;                                    % how many extra detection?

Se  = TP/(TP+FN);
PPV = TP/(FP+TP);
F1 = 2*Se*PPV/(Se+PPV);                             % accuracy measure
if isnan(F1); F1 = 0; end                           % make sure F1 is valid
end