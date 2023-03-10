function Polar(Subj, Direc, Stim, Emul)
%Polar(Subj, Direc, Stim, Emul)
%
% Polar mapping
%   Subj :  String with subject ID
%   Direc : '+' or '-' for clockwise/expanding or anticlockwise/contracting
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%
Screen('Preference', 'SkipSyncTests', 1);
if nargin == 0
    Subj = 'Demo';
    Direc = '+';
    Stim = 'Checkerboard';
    Emul = 1;
end
addpath('Common_Functions');
Parameters = struct;    % Initialize the parameters variable

%% Engine parameters
Parameters.Screen=0;    % Main screen
% Parameters.Resolution=[0 0 768 768];   % Resolution
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 20;   % Size of font
Parameters.FontName = 'Comic Sans MS';  % Font to use

%% Scanner parameters
Parameters.TR=2;   % Seconds per volume
Parameters.Number_of_Slices=30  ; % Number of slices
Parameters.Dummies=1;   % Dummy volumes
Parameters.Overrun=1;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=1;  % Stimulus cycles per run
Parameters.Vols_per_Cycle=1  ;   % Volumes per cycle 

%% Background
load(Stim);
Parameters.Stimulus=Stimulus;
Parameters.Refreshs_per_Stim=12  ;  % How many screen refreshed before background flips 
Parameters.Rotate_Stimulus=false;   % Image rotates
Parameters.Sine_Rotation=0;  % No rotation back & forth 

%% apature stuff
Parameters.Apperture_Width=40 ;  % Width of wedge in degrees
Parameters.Apperture='Wedge';   % Stimulus type
Parameters.Direction=Direc; % Direction of cycling
 
%%target events
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event
% Parameters.Event_Size=30;  % Width of target circle



%% Various parameters
Parameters.Instruction='Please fixate at all times!\n\nPress button when a target appears!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_' Stim '_Polar' Direc]); % Determine current session

%% Run the experiment
Retinotopic_Mapping_FlicCheck(Parameters, Emul);
