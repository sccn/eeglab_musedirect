% eegplugin_musedirect() - EEGLAB plugin for importing data saved
%             by the muse direct Android and iOS app.
%
% Usage:
%   >> eegplugin_musedirect(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% Author: Arnaud Delorme, SCC, INC, UCSD

% Copyright (C) 2017 Arnaud Delorme
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


function vers = eegplugin_musedirect(fig, trystrs, catchstrs)

    vers = 'musedirect1.1';
    if nargin < 3
        error('eegplugin_musedirect requires 3 arguments');
    end;
    
    % add folder to path
    % ------------------
    p = which('eegplugin_musedirect.m');
    p = p(1:findstr(p,'eegplugin_musedirect.m')-1);
    if ~exist('eegplugin_musedirect')
        addpath( p );
    end;
    
    % find import data menu
    % ---------------------
    menui = findobj(fig, 'tag', 'import data');
    
    % menu callbacks
    % --------------
    comcnt = [ trystrs.no_check '[EEGTMP LASTCOM] = pop_musedirect;'  catchstrs.new_non_empty ];
                
    % create menus
    % ------------
    uimenu( menui, 'label', 'From Muse Direct App .CSV file', 'separator', 'on', 'callback', comcnt);
