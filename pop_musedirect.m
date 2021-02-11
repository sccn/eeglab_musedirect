% pop_musedirect() - import data from Muse Direct Android or iOS app
%
% Usage:
%   >> [EEG, com] = pop_musedirect; % pop-up window mode
%   >> [EEG, com] = pop_musedirect(filename);
%
% Optional inputs:
%   filename  - name of Muse Direct .csv file
%
% Outputs:
%   EEG       - EEGLAB EEG structure
%   com       - history string
%
% Author: Arnaud Delorme, 2020-

% Copyright (C) 2020 Arnaud Delorme, arno@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Id: pop_loadbv.m 53 2010-05-22 21:57:38Z arnodelorme $
% Revision 1.5 2010/03/23 21:19:52 roy
% added some lines so that the function can deal with the space lines in the ASCII multiplexed data file

% edits on 2/10/2021 by Cedri Cannard:
% fixed import issues and added timestamp ms accuracy

function [EEG, com] = pop_musedirect(fileName, varargin)

com = '';
% EEG = [];
EEG = eeg_emptyset;

if nargin < 1
    [fileName, filePath] = uigetfile2({ '*.csv' '*.CSV' }, 'Select Muse Direct .csv file - pop_musedirect()');
    if fileName(1) == 0, return; end
    fileName = fullfile(filePath, fileName);
    
    promptstr    = { { 'style'  'checkbox'  'string' 'Import auxilary channel (coming soon)' 'tag' 'aux' 'value' 0 'enable' 'off' } ...
                     { 'style'  'checkbox'  'string' 'Import power values (coming soon)'     'tag' 'power' 'value' 0  'enable' 'off'  } ...
                     { 'style'  'checkbox'  'string' 'Import accelerometer (and gyro) values (coming soon)' 'tag' 'acc' 'value' 0 'enable' 'off'  } ...
                     { 'style'  'checkbox'  'string' 'Import everything (coming soon)' 'tag' 'importall' 'value' 0 'enable' 'off'  } ...
                     { 'style'  'text'      'string' 'Sampling rate' } ...
                     { 'style'  'edit'      'string' 'auto' 'tag' 'srate' } ...
                     };
    geometry = { [1] [1] [1] [1] [2 1] };

    [~,~,~,res] = inputgui( 'geometry', geometry, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_musedirect'')', 'title', 'Import muse direct data -- pop_musedirect()');
    if isempty(res), return; end
    
    options = { 'srate' res.srate };
    if res.aux,       options = { options{:} 'aux' 'on' }; end
    if res.power,     options = { options{:} 'power' 'on' }; end
    if res.acc,       options = { options{:} 'acc' 'on' }; end
    if res.importall, options = { options{:} 'importall' 'on' }; end
else
    options = varargin;
end

opt = finputcheck(options, { 'aux'       'string'    { 'on' 'off' }    'off';
                             'power'     'string'    { 'on' 'off' }    'off';
                             'acc'       'string'    { 'on' 'off' }    'off';
                             'srate'     { 'string' 'real' } { {} {} }        'auto';
                             'importall' 'string'    { 'on' 'off' }    'off' }, 'pop_musedirect');
if isstr(opt), error(opt); end

% M = importdata(fileName, ',');
% headerNames =  M.textdata(1,:);
% if length(headerNames) == 1, headerNames = strsplit(headerNames{1}, ','); end
% 
% % fist column (time stamp is not imported as 0)
% if size(M.data,2) < length(headerNames)-1, headerNames(1)   = []; end
% if size(M.data,2) < length(headerNames)  , headerNames(end) = []; end
% 
% % unique time stamps
% allTimes = datetime(M.data(:,1), 'ConvertFrom', 'posixtime');
% 
% % convert the EEG
% nonNan = ~isnan(M.data(:,2:5));
% eegTime = allTimes(nonNan(1:length(nonNan)));
% eegData = M.data(nonNan(1:length(nonNan)), 2:5);

%Import csv data
disp('Importing data...');
csv_data = readtable(fileName);

%Variable names
headerNames = csv_data.Properties.VariableNames(2:18); 

%Timestamps
allTimes = datetime(table2array(csv_data(:,1)), 'ConvertFrom','posixtime', ...
    'TicksPerSecond', str2double(opt.srate),'Format','dd-MMM-yyyy HH:mm:ss.SSSSS');

%EEG data
csv_data = table2array(csv_data(:,2:18));
nonNan = ~isnan(csv_data(:,1:4));
eegTime = allTimes(nonNan(1:length(nonNan)));
EEG.data = csv_data(nonNan(1:length(nonNan)), 1:4)';

% sampling rate
if isnan(str2double(opt.srate)) && ~isnumeric(opt.srate)
    fprintf('Figuring out optimal sampling rate...\n');
    nSrate = 1./seconds(unique(diff(eegTime)));
    if length(nSrate) > 7
        disp('Warning: sampling rate might be unstable')
    end
    if (max(nSrate)-min(nSrate))/max(nSrate) > 0.1
        disp('Warning: sampling rate unstable and differs 10% between samples; this is a serious problem')
    elseif (max(nSrate)-min(nSrate))/max(nSrate) > 0.01
        disp('Warning: sampling rate might be unstable and differs 1% between samples')
    elseif (max(nSrate)-min(nSrate))/max(nSrate) > 0.001
        disp('Warning: sampling rate might be unstable and differs 0.1% between samples')
    end
    opt.srate = median(nSrate);
    fprintf('Sampling rate: %2.2f Hz\n', opt.srate);
elseif ~isnumeric(opt.srate)
    opt.srate = str2double(opt.srate);
end
if opt.srate < 100 || opt.srate > 1200
    opt.srate = 256;
    disp('Cannot find sampling rate, defaulting to 256 Hz');
end

% Channel labels
% EEG = eeg_emptyset;
EEG.chanlocs = struct('labels', { 'TP9'	'AF7'	'AF8'	'TP10' });
% EEG.data = eegData';
%EEG.data = bsxfun(@minus, EEG.data, mean(EEG.data,2));

% Interpolate other EEG struct variables
EEG.pnts   = size(EEG.data,2);
EEG.nbchan = size(EEG.data,1);
EEG.xmin = 0;
EEG.trials = 1;
EEG.srate = opt.srate;
EEG = eeg_checkset(EEG);

if isempty(options)
    com = sprintf('EEG = pop_musedirect(''%s'');', fileName);
else
    com = sprintf('EEG = pop_musedirect(''%s'', %s);', fileName, vararg2str(options));
end
