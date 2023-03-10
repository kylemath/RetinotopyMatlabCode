function Eccen(Subj, Direc, Stim, Emul)
%Eccen(Subj, Direc, Stim, Emul)
%
% Eccentricity mapping
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
% Parameters.Resolution=[0 0 800 800];   % Resolution 
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 20;   % Size of font
Parameters.FontName = 'Comic Sans MS';  % Font to use

%% Scanner parameters
Parameters.TR=2;   % Seconds per volume
Parameters.Number_of_Slices=30; % Number of slices
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=4;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=10 ;  % Stimulus cycles per run
Parameters.Vols_per_Cycle=36;   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event
% Parameters.Event_Size=30;  % Width of target circle
Parameters.Apperture='Ring';    % Stimulus type
Parameters.Apperture_Width=60 ;  % Width of ring in pixels
Parameters.Direction=Direc; % Direction of cycling
% Load stimulus movie
load(Stim);
Parameters.Stimulus=Stimulus;
Parameters.Rotate_Stimulus=false;   % Image rotates
Parameters.Refreshs_per_Stim=12  % Video frames per stimulus frame
Parameters.Sine_Rotation=0;  % Rotating movie back & forth by this angle

%% Various parameters
Parameters.Instruction='Please fixate at all times!\n\nPress button when a target appears!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_' Stim '_Eccen' Direc]); % Determine current session

%% Run the experiment
Retinotopic_Mapping(Parameters, Emul);
