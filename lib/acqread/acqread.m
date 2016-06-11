function [info, data] = acqread(filename)
% ACQREAD  Read a Biopac AcqKnowledge file.
%    [INFO, DATA] = ACQREAD(FILENAME) reads the content of the AcqKnowledge 
%    file specified in the string FILENAME.  INFO is a structure containing   
%    the metadata (header, markers, etc.).  DATA is a cell array, indexed    
%    by the channel number, containing the acquired physiological signals.
%
%    [INFO, DATA] = ACQREAD displays a dialog box that is used to retrieve
%    the desired file.
%
%    ACQREAD supports all files created with Windows/PC versions of
%    AcqKnowledge (3.9.1 or below), BSL (3.7.0 or below), and BSL PRO
%    (3.7.0 or below).
%
%    ACQREAD supports channels that were acquired using different sampling
%    rates, therefore having a different number of samples.
%
%    Details of the AcqKnowledge file format are presented in Biopac's
%    Application Note #156 (last updated on June 29, 2007), and
%    available at : "http://www.biopac.com/Manuals/app_pdf/app156.pdf".

%    ACQREAD, version 3.0 (2010-12-20) 
%    Copyright (c) 2010, Sebastien Authier and Vincent Finnerty
%    All rights reserved.
% 
%    Redistribution and use in source and binary forms, with or without 
%    modification, are permitted provided that the following conditions are 
%    met:
% 
%        * Redistributions of source code must retain the above copyright 
%          notice, this list of conditions and the following disclaimer.
%        * Redistributions in binary form must reproduce the above
%          copyright notice, this list of conditions and the following
%          disclaimer in the documentation and/or other materials provided
%          with the distribution
%       
%    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
%    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
%    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
%    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
%    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


%% Opening file...

error(nargchk(0,1,nargin))
if nargin==1
    if exist(filename,'file')~=2
        error(['File "',filename,'" not found.'])
    else
        [fid,message] = fopen(filename,'r');
        if fid==-1
            error(message)
        end
    end
else
    [filename,pathname] = uigetfile({'*.acq','AcqKnowledge File (*.acq)';...
        '*.*','All Files (*.*)'});
    if filename==0
        return
    else
        filename = fullfile(pathname,filename);
        [fid,message] = fopen(filename,'r');
        if fid==-1
            error(message)
        end
    end
end

%% GRAPH HEADER SECTION

info.nItemHeaderLen = fread(fid,1,'*int16');
info.lVersion = fread(fid,1,'*int32');  % File version identifier
% 30 = Pre-version 2.0
% 31 = Version 2.0 Beta 1
% 32 = Version 2.0 release
% 33 = Version 2.0.7 (Mac)
% 34 = Version 3.0 In-house Release 1
% 35 = Version 3.03
% 36 = Version 3.5x (Win 95, 98, NT)
% 37 = Version of BSL/PRO 3.6.x
% 38 = Version of Acq 3.7.0-3.7.2 (Win 98, 98SE, NT, Me, 2000)
% 39 = Version of Acq 3.7.3 or above (Win 98, 98SE, 2000, Me, XP)
% 41 = Version of Acq 3.8.1 or above (Win 98, 98SE, 2000, Me, XP)
% 42 = Version of BSL/PRO 3.7.X or above (Win 98, 98SE, 2000, Me, XP)
% 43 = Version of Acq 3.8.2 or above (Win 98, 98SE, 2000, Me, XP)
% 44 = Version of BSL/PRO 3.8.x or above
% 45 = Version of Acq 3.9.0 or above
if (info.lVersion<30) || (info.lVersion>45)
    error (['Unable to read file "',filename,'" : invalid file type, or unsupported file version.'])
end 
info.lExtItemHeaderLen = fread(fid,1,'*int32');
info.nChannels = fread(fid,1,'*int16');  % Number of channels
info.nHorizAxisType = fread(fid,1,'*int16');
info.nCurChannel = fread(fid,1,'*int16');
info.dSampleTime = fread(fid,1,'*double');  % Number of milliseconds per sample
info.dTimeOffset = fread(fid,1,'*double');  % Initial time offset in milliseconds
info.dTimeScale = fread(fid,1,'*double');  % Time scale in milliseconds per division
info.dTimeCursor1 = fread(fid,1,'*double');
info.dTimeCursor2 = fread(fid,1,'*double');
info.rcWindow = fread(fid,1,'*double');
info.nMeasurement = fread(fid,6,'*int16')';
info.fHilite = fread(fid,1,'*int16');
info.dFirstTimeOffset = fread(fid,1,'*double');
info.nRescale = fread(fid,1,'*int16');
info.szHorizUnits1 = deblank(fread(fid,40,'*char')');  % Horizontal units text
info.szHorizUnits2 = deblank(fread(fid,10,'*char')');  % Horizontal units text (abbreviated)
info.nInMemory = fread(fid,1,'*int16');
info.fGrid = fread(fid,1,'*int16');
info.fMarkers = fread(fid,1,'*int16');
info.nPlotDraft = fread(fid,1,'*int16');
info.nDispMode = fread(fid,1,'*int16');
info.nReserved = fread(fid,1,'*int16');

% Version 3.0 and above...
if info.lVersion>=34
    info.BShowToolBar = fread(fid,1,'*int16');
    info.BShowChannelButtons = fread(fid,1,'*int16');
    info.BShowMeasurements = fread(fid,1,'int16');
    info.BShowMarkers = fread(fid,1,'*int16');
    info.BShowJournal = fread(fid,1,'*int16');
    info.CurXChannel = fread(fid,1,'*int16');
    info.MmtPrecision = fread(fid,1,'*int16');
end

% Version 3.02 and above...
if info.lVersion>=35
    info.NMeasurementRows = fread(fid,1,'*int16');
    info.mmt = fread(fid,40,'*int16')';
    info.mmtChan = fread(fid,40,'*int16')';
end

% Version 3.5x and above...
if info.lVersion>=36
    info.MmtCalcOpnd1 = fread(fid,40,'*int16')';
    info.MmtCalcOpnd2 = fread(fid,40,'*int16')';
    info.MmtCalcOp = fread(fid,40,'*int16')';
    info.MmtCalcConstant = fread(fid,40,'*double')';
end

% Version 3.7.0 and above...
if info.lVersion>=38
    tmp = fread(fid,1,'*int32');
    tmp = sprintf('%6s',dec2hex(tmp,6));
    info.bNewGridwithMinor = [hex2dec(tmp(5:6)) hex2dec(tmp(3:4)) hex2dec(tmp(1:2))]./255;
    tmp = fread(fid,1,'*int32');
    tmp = sprintf('%6s',dec2hex(tmp,6));
    info.colorMajorGrid = [hex2dec(tmp(5:6)) hex2dec(tmp(3:4)) hex2dec(tmp(1:2))]./255; 
    info.colorMinorGrid = fread(fid,1,'*int32');
    info.wMajorGridStyle = fread(fid,1,'*int16');
    info.wMinorGridStyle = fread(fid,1,'*int16');
    info.wMajorGridWidth = fread(fid,1,'*int16');
    info.wMinorGridWidth = fread(fid,1,'*int16');
    info.bFixedUnitsDiv = fread(fid,1,'*int32');
    info.bMid_Range_Show = fread(fid,1,'*int32');
    info.dStart_Middle_Point = fread(fid,1,'*double');
    info.dOffset_Point = fread(fid,60,'*double')';
    info.hGrid = fread(fid,1,'*double');
    info.vGrid = fread(fid,60,'*double')';
    info.bEnableWaveTools = fread(fid,1,'*int32');
end

% Version 3.7.3 and above...
if info.lVersion>=39
    info.horizPrecision = fread(fid,1,'*int16');
end

% Version 3.8.1 and above...
if info.lVersion>=41
    fseek(fid,20,'cof');  % RESERVED
    info.bOverlapMode = fread(fid,1,'*int32');
    info.bShowHardware = fread(fid,1,'*int32');
    info.bXAutoplot = fread(fid,1,'*int32');
    info.bXAutoScroll = fread(fid,1,'*int32');
    info.bStartButtonVisible = fread(fid,1,'*int32');
    info.bCompressed = fread(fid,1,'*int32');
    info.AlwaysStartButtonVisible = fread(fid,1,'*int32');
end

% Version 3.8.2 and above...
if info.lVersion>=43
   info.pathVideo = deblank(fread(fid,260,'*char')');
   info.optSyncDelay = fread(fid,1,'*int32');
   info.syncDelay = fread(fid,1,'*double');
   info.bHRP_PasteMeasurements = fread(fid,1,'*int32');
end

% Version 3.9.0 and above...
if info.lVersion>=45
    info.graphType = fread(fid,1,'*int32')';
    for n = 1:40
        info.mmtCalcExpr{n} = deblank(fread(fid,256,'*char')');
    end
    info.mmtMomentOrder = fread(fid,40,'*int32')';
    info.mmtTimeDelay = fread(fid,40,'*int32')';
    info.mmtEmbedDim = fread(fid,40,'*int32')';
    info.mmtMIDelay = fread(fid,40,'*int32')';
end

%% PER CHANNEL DATA SECTION

for n = 1:info.nChannels
    info.lChanHeaderLen(n) = fread(fid,1,'*int32');
    info.nNum(n) = fread(fid,1,'*int16');
    info.szCommentText{n} = deblank(fread(fid,40,'*char')');  % Comment text
    tmp = fread(fid,1,'*int32');
    tmp = sprintf('%6s',dec2hex(tmp,6));
    info.rgbColor{n} = [hex2dec(tmp(5:6)) hex2dec(tmp(3:4)) hex2dec(tmp(1:2))]./255;
    info.nDispChan(n) = fread(fid,1,'*int16');
    info.dVoltOffset(n) = fread(fid,1,'*double');  % Amplitude offset (volts)
    info.dVoltScale(n) = fread(fid,1,'*double');  % Amplitude scale (volts/div.)
    info.szUnitsText{n} = deblank(fread(fid,20,'*char')');  % Units text
    info.lBufLength(n) = fread(fid,1,'*int32');  % Number of data samples
    info.dAmplScale(n) = fread(fid,1,'*double');  % Units/count
    info.dAmplOffset(n) = fread(fid,1,'*double');  % Units
    info.nChanOrder(n) = fread(fid,1,'*int16');
    info.nDispSize(n) = fread(fid,1,'*int16');

    % Version 3.0 and above...
    if info.lVersion>=34
        info.plotMode(n) = fread(fid,1,'*int16');  
        info.vMid(n) = fread(fid,1,'*double');
    end

    % Version 3.7.0 and above...
    if info.lVersion>=38
        info.szDescription{n} = deblank(fread(fid,128,'*char')');  % String of channel description
        info.nVarSampleDivider(n) = fread(fid,1,'*int16');  % Channel divider of main frequency
    end

    % Version 3.7.3 and above...
    if info.lVersion>=39
        info.vertPrecision(n) = fread(fid,1,'*int16');
    end
    
    % Version 3.8.2 and above...
    if info.lVersion>=43
        tmp = fread(fid,1,'*int32');
        tmp = sprintf('%6s',dec2hex(tmp,6));
        info.ActiveSegmentColor{n} = [hex2dec(tmp(5:6)) hex2dec(tmp(3:4)) hex2dec(tmp(1:2))]./255;
        info.ActiveSegmentStyle(n) = fread(fid,1,'*int32');
    end
end


%% FOREIGN DATA SECTION

info.nLength = fread(fid,1,'*int16');
info.nID = fread(fid,1,'*int16');
info.ByForeignData = fread(fid,double(info.nLength-4),'*int8')';


%% PER CHANNEL DATA TYPES SECTION

for m = 1:info.nChannels
    info.nSize(m) = fread(fid,1,'*int16');  % Channel data size in bytes
    info.nType(m) = fread(fid,1,'*int16');  % Channel data type : 1 = double, and 2 = short (int16)
end


%% CHANNEL DATA SECTION

% Raw data vector in interleaved format (indexed by bytes)
rawData = fread(fid,double(info.lBufLength)*double(info.nSize'),'*int8');

% Channel sequence (indexed by bytes)
cnt = 1;
for m = 1:max(info.nVarSampleDivider)
    for n = 1:info.nChannels
        if mod(m-1,info.nVarSampleDivider(n))==0
            channelSequence(cnt:(cnt+info.nSize(n)-1)) = int8(n);  
            cnt = cnt + info.nSize(n);
        end  
   end
end

% Raw data vector is padded with NaN's in order to have an integer number 
% of channel sequence repetitions
tmp3 = numel(channelSequence) - rem(numel(rawData),numel(channelSequence));
if tmp3>0
    rawData(end+1:end+tmp3) = NaN;  
end

% Raw data vector is reshaped into a matrix (rows correspond to the channel 
% sequence, and columns correspond to each repetition of the sequence)
rawData = reshape(rawData,numel(channelSequence),[]);

% Raw data is extracted channel by channel, and converted into the 
% specified numeric type
data = cell(1,info.nChannels);
for n = 1:info.nChannels
    tmpChannel = rawData(channelSequence==n,:);
    if info.nType(n)==1;
        typ = 'double';
    elseif info.nType(n)==2;
        typ = 'int16';
    end
    data{n} = typecast(tmpChannel(:),typ);
    data{n}(info.lBufLength(n)+1:end) = [];
end


%% MARKERS HEADER SECTION

info.lLength = fread(fid,1,'*int32');
info.lMarkers = fread(fid,1,'*int32');  % Number of markers

if (isempty(info.lLength))
    info.lLength = 0;
end
if (isempty(info.lMarkers))
    info.lMarkers = 0;
end

%% MARKER ITEM SECTION

if (info.lLength > 0) && (info.lMarkers > 0)
    for n = 1:info.lMarkers
        info.lSample(n) = fread(fid,1,'*int32');  % Location of marker
        info.fSelected(n) = fread(fid,1,'*int16');
        info.fTextLocked(n) = fread(fid,1,'*int16');
        info.fPositionLocked(n) = fread(fid,1,'*int16');
        info.nTextLength(n) = fread(fid,1,'*int16');  % Length of marker text string
        info.szText{n} = deblank(fread(fid,double(info.nTextLength(n)+1),'*char')');  % Marker text string
    end
else
    info.lSample = [];
    info.fSelected = [];
    info.fTextLocked = [];
    info.fPositionLocked = [];
    info.nTextLength = [];
    info.szText = [];
end


%% Closing file...

fclose(fid);